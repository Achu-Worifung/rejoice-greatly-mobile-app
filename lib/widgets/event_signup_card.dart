import 'package:flutter/material.dart';

import '../services/member_events.dart';
import '../services/user_facing_error.dart';
import '../theme/church_colors.dart';
import '../theme/church_type.dart';
import 'church_buttons.dart';

/// "I'm coming" for an event that takes sign-ups: the headcount, the
/// member's own place (or spot on the waiting list), and "Can't make it".
/// Shows nothing for events without sign-ups.
class EventSignupCard extends StatelessWidget {
  const EventSignupCard({super.key, required this.instanceId, this.signUp, this.cancel});

  final String instanceId;

  /// Stand-ins for the API, for tests.
  final Future<EventSignup> Function(String id, int guests, String? answer)? signUp;
  final Future<EventSignup> Function(String id)? cancel;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Map<String, EventSignup>>(
      valueListenable: MemberEvents.signups,
      builder: (context, all, _) {
        final s = all[instanceId];
        if (s == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 16),
          child: _Card(signup: s, instanceId: instanceId, signUp: signUp, cancel: cancel),
        );
      },
    );
  }
}

class _Card extends StatefulWidget {
  const _Card({required this.signup, required this.instanceId, this.signUp, this.cancel});

  final EventSignup signup;
  final String instanceId;
  final Future<EventSignup> Function(String id, int guests, String? answer)? signUp;
  final Future<EventSignup> Function(String id)? cancel;

  @override
  State<_Card> createState() => _CardState();
}

class _CardState extends State<_Card> {
  bool _busy = false;

  Future<EventSignup> _signUp(int guests, String? answer) =>
      (widget.signUp ?? (id, g, a) => MemberEvents.signUp(id, guests: g, answer: a))(widget.instanceId, guests, answer);

  Future<void> _join() async {
    final s = widget.signup;
    var guests = s.guests;
    String? answer = s.answer;
    // Ask only what the event wants to know.
    if (s.guestsMax > 0 || s.question != null) {
      final picked = await showModalBottomSheet<(int, String?)>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: ChurchColors.background,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(ChurchRadius.lg)),
        ),
        builder: (_) => _SignupSheet(signup: s),
      );
      if (picked == null) return;
      (guests, answer) = picked;
    }
    await _run(() => _signUp(guests, answer), (r) => r.isWaiting
        ? 'You’re on the waiting list. We’ll let you know if a place opens up.'
        : s.isGoing
            ? 'Updated.'
            : 'You’re in. See you there!');
  }

  Future<void> _leave() async {
    final s = widget.signup;
    await _run(
      () => (widget.cancel ?? MemberEvents.cancelSignup)(widget.instanceId),
      (_) => s.isWaiting ? 'You’ve left the waiting list.' : 'Thanks for letting us know.',
    );
  }

  Future<void> _run(Future<EventSignup> Function() call, String Function(EventSignup) done) async {
    setState(() => _busy = true);
    try {
      final result = await call();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(done(result))));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(userFacingError(e))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.signup;
    final guests = s.guests > 0 ? ' with ${s.guests} ${s.guests == 1 ? 'guest' : 'guests'}' : '';
    final (IconData icon, Color color, String headline, String detail) = s.isGoing
        ? (Icons.check_circle_outline_rounded, ChurchColors.successInk, 'You’re coming$guests', s.countLabel)
        : s.isWaiting
            ? (
                Icons.hourglass_empty_rounded,
                ChurchColors.accent,
                s.waitlistPosition != null
                    ? 'You’re number ${s.waitlistPosition} on the waiting list'
                    : 'You’re on the waiting list',
                'We’ll let you know if a place opens up.',
              )
            : s.open
                ? (Icons.how_to_reg_outlined, ChurchColors.accent, 'Coming?', s.countLabel)
                : (Icons.event_busy_outlined, ChurchColors.muted, 'Sign-ups are closed', s.closedBecause ?? s.countLabel);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: ChurchColors.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(headline, style: ChurchType.title.copyWith(fontSize: 17)),
                    const SizedBox(height: 2),
                    Text(detail, style: ChurchType.label),
                    if (s.isGoing && (s.answer ?? '').isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text('“${s.answer}”', style: ChurchType.label),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (s.open && s.status == null) ...[
            const SizedBox(height: 14),
            ChurchPrimaryButton(
              label: s.full ? 'Join the waiting list' : 'I’m coming',
              icon: s.full ? Icons.playlist_add_rounded : Icons.how_to_reg_outlined,
              loading: _busy,
              onPressed: _join,
            ),
          ],
          if (s.status != null && s.open) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 4,
              children: [
                if (s.isGoing && (s.guestsMax > 0 || s.question != null))
                  TextButton(onPressed: _busy ? null : _join, child: const Text('Change')),
                TextButton(
                  onPressed: _busy ? null : _leave,
                  style: TextButton.styleFrom(foregroundColor: ChurchColors.muted),
                  child: Text(s.isWaiting ? 'Leave the waiting list' : 'Can’t make it'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

String _guestsLabel(int n) => n <= 0 ? 'no guests' : '$n ${n == 1 ? 'guest' : 'guests'}';

/// Guests and the event's question, before signing up.
class _SignupSheet extends StatefulWidget {
  const _SignupSheet({required this.signup});

  final EventSignup signup;

  @override
  State<_SignupSheet> createState() => _SignupSheetState();
}

class _SignupSheetState extends State<_SignupSheet> {
  late int _guests = widget.signup.guests.clamp(0, widget.signup.guestsMax);
  late final _answer = TextEditingController(text: widget.signup.answer ?? '');

  @override
  void dispose() {
    _answer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.signup;
    // Room left for this member's party, counting the place they may already hold.
    final room = s.spotsLeft == null ? null : s.spotsLeft! + (s.isGoing ? 1 + s.guests : 0);
    final overflow = room != null && 1 + _guests > room;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(s.isGoing ? 'Change your sign-up' : 'Sign up', style: ChurchType.headline),
          const SizedBox(height: 16),
          if (s.guestsMax > 0) ...[
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Bringing anyone?', style: ChurchType.bodyStrong),
                      Text('Up to ${s.guestsMax}, not counting you.', style: ChurchType.label),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _guests > 0 ? () => setState(() => _guests--) : null,
                  icon: const Icon(Icons.remove_circle_outline_rounded),
                  tooltip: 'Fewer guests',
                ),
                SizedBox(
                  width: 28,
                  child: Text('$_guests',
                      textAlign: TextAlign.center, style: ChurchType.data, semanticsLabel: '$_guests guests'),
                ),
                IconButton(
                  onPressed: _guests < s.guestsMax ? () => setState(() => _guests++) : null,
                  icon: const Icon(Icons.add_circle_outline_rounded),
                  tooltip: 'More guests',
                ),
              ],
            ),
            if (overflow)
              Text(
                s.isGoing
                    // Someone with a place keeps it; there's only room for so many more.
                    ? 'There’s room for ${_guestsLabel(room - 1)} now.'
                    : room <= 0
                        ? 'It’s full, so you’ll join the waiting list.'
                        : 'There’s room for ${_guestsLabel(room - 1)} now. With more, you’ll join the waiting list.',
                style: ChurchType.label.copyWith(color: ChurchColors.accent),
              ),
            const SizedBox(height: 16),
          ],
          if (s.question != null) ...[
            TextField(
              controller: _answer,
              maxLength: 500,
              minLines: 1,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: s.question, counterText: ''),
            ),
            const SizedBox(height: 16),
          ],
          ChurchPrimaryButton(
            label: s.isGoing ? 'Save' : (s.full || overflow ? 'Join the waiting list' : 'I’m coming'),
            onPressed: s.isGoing && overflow
                ? null
                : () => Navigator.pop(context, (_guests, _answer.text.trim().isEmpty ? null : _answer.text.trim())),
          ),
        ],
      ),
    );
  }
}
