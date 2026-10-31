import 'package:flutter/material.dart';

import '../services/church_api.dart';
import '../services/prayer_wall_api.dart';
import '../services/user_facing_error.dart';
import '../theme/church_colors.dart';
import '../theme/church_type.dart';
import 'church_buttons.dart';
import 'prayer_card.dart';

/// A short, calm confirmation along the bottom of the screen.
void showPrayerSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: ChurchColors.button,
        behavior: SnackBarBehavior.floating,
      ),
    );
}

/// The outcome of a "…" menu action: the request as it now stands, or
/// [removed] when it should leave the list (deleted, or reported by this
/// member — reporters stop seeing what they reported).
class PrayerActionResult {
  const PrayerActionResult.updated(PrayerRequestItem this.updated) : removed = false;
  const PrayerActionResult.removed()
      : updated = null,
        removed = true;

  final PrayerRequestItem? updated;
  final bool removed;
}

/// Runs a [PrayerAction], asking first where it needs to. Null when the member
/// cancelled or the call failed (a message has already been shown).
Future<PrayerActionResult?> runPrayerAction(
  BuildContext context,
  PrayerRequestItem prayer,
  PrayerAction action,
) async {
  try {
    switch (action) {
      case PrayerAction.markAnswered:
        final answer = await showAnsweredSheet(context, anonymous: prayer.anonymous);
        if (answer == null) return null;
        final updated = await PrayerWallApi.setAnswered(
          prayer.id,
          answered: true,
          note: answer.note.isEmpty ? null : answer.note,
          shareAtService: answer.shareAtService,
        );
        if (context.mounted) showPrayerSnack(context, 'Praise God! Your church family will rejoice with you.');
        return PrayerActionResult.updated(updated);
      case PrayerAction.markUnanswered:
        return PrayerActionResult.updated(
          await PrayerWallApi.setAnswered(prayer.id, answered: false),
        );
      case PrayerAction.keepPraying:
        final updated = await PrayerWallApi.renew(prayer.id);
        if (context.mounted) {
          showPrayerSnack(context, prayer.archived ? 'It’s back on the wall.' : 'We’ll keep praying with you.');
        }
        return PrayerActionResult.updated(updated);
      case PrayerAction.archive:
        final updated = await PrayerWallApi.archive(prayer.id);
        if (context.mounted) {
          showPrayerSnack(context, 'It’s off the wall. You’ll still find it under My requests.');
        }
        return PrayerActionResult.updated(updated);
      case PrayerAction.delete:
        final ok = await confirmPrayerDialog(
          context,
          title: 'Delete this request?',
          message: 'It and its replies will be removed for everyone.',
          confirmLabel: 'Delete',
        );
        if (!ok) return null;
        await PrayerWallApi.delete(prayer.id);
        if (context.mounted) showPrayerSnack(context, 'Your request was deleted.');
        return const PrayerActionResult.removed();
      case PrayerAction.report:
        if (!context.mounted) return null;
        final reason = await showReportSheet(context, what: 'request');
        if (reason == null) return null;
        await PrayerWallApi.report(prayer.id, reason);
        if (context.mounted) {
          showPrayerSnack(context, 'Thank you. We’ve hidden it for you and a pastor will take a look.');
        }
        return const PrayerActionResult.removed();
    }
  } catch (e) {
    if (context.mounted) showPrayerSnack(context, userFacingError(e));
    return null;
  }
}

/// A cream dialog with a destructive choice and a safe one.
Future<bool> confirmPrayerDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.4),
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        decoration: ChurchColors.cardDecoration(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, textAlign: TextAlign.center, style: ChurchType.headline),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: ChurchType.body.copyWith(color: ChurchColors.muted)),
            const SizedBox(height: 24),
            ChurchDangerButton(label: confirmLabel, onPressed: () => Navigator.pop(ctx, true)),
            const SizedBox(height: 10),
            ChurchSecondaryButton(label: 'Keep it', onPressed: () => Navigator.pop(ctx, false)),
          ],
        ),
      ),
    ),
  );
  return confirmed == true;
}

Future<T?> _sheet<T>(BuildContext context, Widget child) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: ChurchColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(ChurchRadius.lg)),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: child,
      ),
    ),
  );
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 36,
        height: 4,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(color: ChurchColors.divider, borderRadius: ChurchRadius.smAll),
      ),
    );
  }
}

// ── Share a request ───────────────────────────────────────────────────────

/// Opens the composer and returns the shared request, or null if dismissed.
Future<PrayerRequestItem?> showPrayerComposer(BuildContext context) async {
  final account = await ChurchApi.getCachedAccountJson();
  if (!context.mounted) return null;
  return _sheet<PrayerRequestItem>(
    context,
    _PrayerComposer(isMinor: ChurchApi.isMinorAccount(account)),
  );
}

class _PrayerComposer extends StatefulWidget {
  const _PrayerComposer({required this.isMinor});

  /// Under-18s share with the pastors only; the backend enforces it too.
  final bool isMinor;

  @override
  State<_PrayerComposer> createState() => _PrayerComposerState();
}

class _PrayerComposerState extends State<_PrayerComposer> {
  final _controller = TextEditingController();
  PrayerVisibility _visibility = PrayerVisibility.church;
  bool _anonymous = false;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.isMinor) _visibility = PrayerVisibility.pastors;
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _share() async {
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final created = await PrayerWallApi.create(
        body: _controller.text.trim(),
        anonymous: _visibility == PrayerVisibility.church && _anonymous,
        visibility: _visibility,
      );
      if (mounted) Navigator.pop(context, created);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = userFacingError(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final canShare = _controller.text.trim().isNotEmpty && !_sending;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const _SheetHandle(),
        Text('Share a prayer request', style: ChurchType.headline),
        const SizedBox(height: 6),
        Text(
          widget.isMinor
              ? 'Your request goes to the pastors, who will be praying with you.'
              : '“Carry each other’s burdens.” — Galatians 6:2',
          style: ChurchType.label,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _controller,
          autofocus: true,
          minLines: 4,
          maxLines: 8,
          maxLength: PrayerWallApi.maxRequestLength,
          textCapitalization: TextCapitalization.sentences,
          style: ChurchType.body,
          decoration: const InputDecoration(
            hintText: 'What can we pray with you about?',
          ),
        ),
        if (!widget.isMinor) ...[
          const SizedBox(height: 8),
          const ChurchEyebrow('Who can see it'),
          const SizedBox(height: 8),
          _VisibilityOption(
            selected: _visibility == PrayerVisibility.church,
            icon: Icons.groups_outlined,
            title: 'Church family',
            subtitle: 'Members can pray and leave encouragement.',
            onTap: () => setState(() => _visibility = PrayerVisibility.church),
          ),
          const SizedBox(height: 8),
          _VisibilityOption(
            selected: _visibility == PrayerVisibility.pastors,
            icon: Icons.lock_outline_rounded,
            title: 'Pastors only',
            subtitle: 'Only the pastoral team will see it.',
            onTap: () => setState(() => _visibility = PrayerVisibility.pastors),
          ),
          if (_visibility == PrayerVisibility.church)
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: _anonymous,
              activeTrackColor: ChurchColors.button,
              // Off has to read as a switch too: the default cream track and
              // pale thumb all but vanish on the white sheet.
              inactiveThumbColor: ChurchColors.muted,
              inactiveTrackColor: ChurchColors.background,
              trackOutlineColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.selected) ? ChurchColors.button : ChurchColors.muted,
              ),
              onChanged: (v) => setState(() => _anonymous = v),
              title: Text('Share anonymously', style: ChurchType.bodyStrong),
              subtitle: Text(
                'Your name won’t be shown. The pastors can still see it’s you.',
                style: ChurchType.label,
              ),
            ),
        ],
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: ChurchType.label.copyWith(color: Theme.of(context).colorScheme.error)),
        ],
        const SizedBox(height: 16),
        ChurchPrimaryButton(
          label: 'Share request',
          loading: _sending,
          onPressed: canShare ? _share : null,
        ),
      ],
    );
  }
}

class _VisibilityOption extends StatelessWidget {
  const _VisibilityOption({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? ChurchColors.card : ChurchColors.background,
        shape: RoundedRectangleBorder(
          borderRadius: ChurchRadius.mdAll,
          side: BorderSide(
            color: selected ? ChurchColors.accent : ChurchColors.divider,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: ChurchRadius.mdAll,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(icon, color: ChurchColors.accent),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: ChurchType.bodyStrong),
                      Text(subtitle, style: ChurchType.label),
                    ],
                  ),
                ),
                Icon(
                  selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                  color: selected ? ChurchColors.accent : ChurchColors.muted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Mark answered ─────────────────────────────────────────────────────────

/// What the member said when marking a request answered.
typedef PrayerAnswer = ({String note, bool shareAtService});

/// Asks for an optional praise report, and whether it may be shared at
/// Sunday service. Null if the member backed out.
Future<PrayerAnswer?> showAnsweredSheet(BuildContext context, {bool anonymous = false}) {
  return _sheet<PrayerAnswer>(context, _AnsweredSheet(anonymous: anonymous));
}

class _AnsweredSheet extends StatefulWidget {
  const _AnsweredSheet({required this.anonymous});

  /// The request was shared anonymously, so it would be shared that way too.
  final bool anonymous;

  @override
  State<_AnsweredSheet> createState() => _AnsweredSheetState();
}

class _AnsweredSheetState extends State<_AnsweredSheet> {
  final _controller = TextEditingController();
  bool _share = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const _SheetHandle(),
        Text('Mark as answered', style: ChurchType.headline),
        const SizedBox(height: 6),
        Text(
          'Share what happened, so everyone who prayed can rejoice with you.',
          style: ChurchType.label,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _controller,
          minLines: 3,
          maxLines: 6,
          maxLength: 500,
          textCapitalization: TextCapitalization.sentences,
          style: ChurchType.body,
          decoration: const InputDecoration(hintText: 'How was your prayer answered? (optional)'),
        ),
        CheckboxListTile(
          value: _share,
          onChanged: (v) => setState(() => _share = v ?? false),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: ChurchColors.button,
          title: Text('Share it at Sunday service too', style: ChurchType.body),
          subtitle: Text(
            widget.anonymous
                ? 'It would be shared as from “Someone from church”.'
                : 'With your first name and initial, as on the wall.',
            style: ChurchType.caption,
          ),
        ),
        const SizedBox(height: 8),
        ChurchPrimaryButton(
          label: 'Share the good news',
          onPressed: () => Navigator.pop<PrayerAnswer>(
            context,
            (note: _controller.text.trim(), shareAtService: _share),
          ),
        ),
      ],
    );
  }
}

// ── Report ────────────────────────────────────────────────────────────────

const _reportReasons = [
  'Spam or advertising',
  'Unkind or hurtful',
  'Shares someone else’s private details',
  'Something else',
];

/// Asks why something is being reported. Returns the reason, or null.
Future<String?> showReportSheet(BuildContext context, {required String what}) {
  return _sheet<String>(
    context,
    Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const _SheetHandle(),
        Text('Report this $what', style: ChurchType.headline),
        const SizedBox(height: 6),
        Text(
          'It’ll be hidden for you straight away, and a pastor will take a look. '
          'They won’t be told who reported it.',
          style: ChurchType.label,
        ),
        const SizedBox(height: 12),
        for (final reason in _reportReasons)
          Builder(
            builder: (ctx) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(reason, style: ChurchType.body),
              trailing: Icon(Icons.chevron_right_rounded, color: ChurchColors.muted),
              onTap: () => Navigator.pop(ctx, reason),
            ),
          ),
      ],
    ),
  );
}
