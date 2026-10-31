import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/member_events.dart';
import '../services/user_facing_error.dart';
import '../theme/church_colors.dart';
import '../theme/church_type.dart';
import 'church_buttons.dart';

void _snack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: ChurchColors.button,
      behavior: SnackBarBehavior.floating,
    ));
}

/// Opens [url] outside the app; says so if nothing could open it.
Future<void> openExternal(BuildContext context, Uri url) async {
  var opened = false;
  try {
    opened = await launchUrl(url, mode: LaunchMode.externalApplication);
  } catch (_) {
    opened = false;
  }
  if (!opened && context.mounted) {
    _snack(context, 'Couldn’t open that link. Check that you have an app for it.');
  }
}

/// The things a member does with an event: join it online when it's remote,
/// get reminded, and put it in their calendar.
class EventActions extends StatelessWidget {
  const EventActions({super.key, required this.event});

  final Map<String, dynamic> event;

  @override
  Widget build(BuildContext context) {
    final id = event['id'] as String?;
    final link = MemberEvents.onlineLink(event['location'] as String?);
    final calendar = MemberEvents.calendarUri(event);

    return ValueListenableBuilder<Map<String, int>>(
      valueListenable: MemberEvents.reminders,
      builder: (context, reminders, _) {
        final minutes = id == null ? null : reminders[id];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (link != null) ...[
              ChurchPrimaryButton(
                label: 'Join online',
                icon: Icons.videocam_outlined,
                onPressed: () => openExternal(context, Uri.parse(link)),
              ),
              const SizedBox(height: 10),
            ],
            Row(
              children: [
                if (id != null) ...[
                  Expanded(
                    child: ChurchSecondaryButton(
                      label: minutes == null ? 'Remind me' : 'Reminder on',
                      icon: minutes == null
                          ? Icons.notifications_none_rounded
                          : Icons.notifications_active_rounded,
                      onPressed: () => showEventReminderSheet(context, event),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                if (calendar != null)
                  Expanded(
                    child: ChurchSecondaryButton(
                      label: 'Add to calendar',
                      icon: Icons.event_available_outlined,
                      onPressed: () => openExternal(context, calendar),
                    ),
                  ),
              ],
            ),
            if (minutes != null) ...[
              const SizedBox(height: 8),
              Text(
                'We’ll remind you ${MemberEvents.reminderLabel(minutes).toLowerCase()}.',
                style: ChurchType.label,
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Lets the member pick when to be reminded, or turn the reminder off. Only
/// choices still in the future are offered.
Future<void> showEventReminderSheet(BuildContext context, Map<String, dynamic> event) async {
  final id = event['id'] as String?;
  final start = MemberEvents.startOf(event);
  if (id == null || start == null) return;
  final now = DateTime.now();
  final current = MemberEvents.reminders.value[id];
  final choices = MemberEvents.reminderChoices
      .where((m) => start.subtract(Duration(minutes: m)).isAfter(now))
      .toList();

  final picked = await showModalBottomSheet<int>(
    context: context,
    useSafeArea: true,
    backgroundColor: ChurchColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(ChurchRadius.lg)),
    ),
    builder: (ctx) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Remind me', style: ChurchType.headline),
          const SizedBox(height: 4),
          Text(event['title'] as String? ?? '', style: ChurchType.label),
          const SizedBox(height: 8),
          if (choices.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('It’s starting too soon for a reminder.', style: ChurchType.body),
            ),
          for (final m in choices)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(MemberEvents.reminderLabel(m), style: ChurchType.body),
              trailing: m == current
                  ? Icon(Icons.check_rounded, color: ChurchColors.accent)
                  : null,
              onTap: () => Navigator.pop(ctx, m),
            ),
          if (current != null) ...[
            Divider(color: ChurchColors.divider),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.notifications_off_outlined, color: ChurchColors.muted),
              title: Text('Turn off reminder', style: ChurchType.body),
              onTap: () => Navigator.pop(ctx, -1),
            ),
          ],
        ],
      ),
    ),
  );
  if (picked == null || picked == current || !context.mounted) return;

  try {
    if (picked == -1) {
      await MemberEvents.clearReminder(id);
      if (context.mounted) _snack(context, 'Reminder turned off.');
    } else {
      await MemberEvents.setReminder(id, picked);
      if (context.mounted) {
        _snack(context, 'We’ll remind you ${MemberEvents.reminderLabel(picked).toLowerCase()}.');
      }
    }
  } catch (e) {
    if (context.mounted) _snack(context, userFacingError(e));
  }
}

/// The member's own bacenta meeting: when and where, and for an online one,
/// "Join online" — which also counts them present while the meeting is on.
class BacentaMeetingCard extends StatefulWidget {
  const BacentaMeetingCard({super.key, required this.meeting, this.onJoined});

  final BacentaMeetingInfo meeting;

  /// Called after a join marked the member present, so the screen can refresh.
  final VoidCallback? onJoined;

  @override
  State<BacentaMeetingCard> createState() => _BacentaMeetingCardState();
}

class _BacentaMeetingCardState extends State<BacentaMeetingCard> {
  bool _joining = false;

  Future<void> _join() async {
    setState(() => _joining = true);
    try {
      final joined = await MemberEvents.joinBacenta();
      if (!mounted) return;
      if (joined.message.isNotEmpty) _snack(context, joined.message);
      if (joined.url.isNotEmpty) await openExternal(context, Uri.parse(joined.url));
      if (joined.markedPresent) widget.onJoined?.call();
    } catch (e) {
      if (mounted) _snack(context, userFacingError(e));
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.meeting;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: ChurchColors.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ChurchEyebrow('Your small group'),
                    const SizedBox(height: 4),
                    Text(m.name, style: ChurchType.title),
                  ],
                ),
              ),
              if (m.present) const ChurchStampBadge('Present'),
            ],
          ),
          const SizedBox(height: 10),
          _Line(icon: Icons.schedule_rounded, text: m.whenLabel),
          if (m.location.isNotEmpty)
            _Line(
              icon: m.online ? Icons.videocam_outlined : Icons.place_outlined,
              text: m.placeLabel,
            ),
          if (m.leaderName != null && m.leaderName!.isNotEmpty)
            _Line(icon: Icons.person_outline_rounded, text: 'Led by ${m.leaderName}'),
          if (m.cancelled) ...[
            const SizedBox(height: 6),
            Text('This week’s meeting is called off.', style: ChurchType.bodyStrong),
          ] else if (m.online) ...[
            const SizedBox(height: 12),
            ChurchPrimaryButton(
              label: 'Join online',
              icon: Icons.videocam_outlined,
              loading: _joining,
              onPressed: _join,
            ),
            if (m.joinCountsNow && !m.present) ...[
              const SizedBox(height: 6),
              Text('Joining marks you present for this meeting.', style: ChurchType.caption),
            ],
          ],
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: ChurchColors.muted),
          const SizedBox(width: 6),
          Expanded(child: Text(text, style: ChurchType.body.copyWith(fontSize: 14))),
        ],
      ),
    );
  }
}
