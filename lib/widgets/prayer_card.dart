import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../services/prayer_wall_api.dart';
import '../theme/church_colors.dart';
import '../theme/church_type.dart';
import 'member_avatar.dart';

/// What a member can do to a request from its "…" menu.
enum PrayerAction { markAnswered, markUnanswered, delete, report }

/// "Just now", "3h ago", "Tue 9:41 AM", "Mar 4" — a wall reads by recency.
String prayerWhen(DateTime t) {
  final age = DateTime.now().difference(t);
  if (age.inMinutes < 1) return 'Just now';
  if (age.inHours < 1) return '${age.inMinutes}m ago';
  if (age.inDays < 1) return '${age.inHours}h ago';
  if (age.inDays < 7) return DateFormat('EEE h:mm a').format(t);
  return DateFormat('MMM d').format(t);
}

/// One prayer request on the wall: who and when, the request itself, any
/// praise report, then "Pray" and the reply count.
class PrayerCard extends StatelessWidget {
  const PrayerCard({
    super.key,
    required this.prayer,
    required this.onPrayed,
    required this.onAction,
    this.onOpen,
    this.expanded = false,
  });

  final PrayerRequestItem prayer;
  final ValueChanged<bool> onPrayed;
  final ValueChanged<PrayerAction> onAction;

  /// Opens the thread. Null on the thread page itself.
  final VoidCallback? onOpen;

  /// Shows the whole request rather than the first few lines.
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final card = Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(context),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(
              prayer.body,
              style: ChurchType.body,
              maxLines: expanded ? null : 6,
              overflow: expanded ? null : TextOverflow.ellipsis,
            ),
          ),
          if (prayer.hidden) ...[
            const SizedBox(height: 12),
            const _Note(
              icon: Icons.pause_circle_outline_rounded,
              text: 'Paused while a pastor takes a look. Only you can see it for now.',
            ),
          ],
          if (prayer.answered) ...[
            const SizedBox(height: 12),
            _PraiseReport(note: prayer.answeredNote),
          ],
          const SizedBox(height: 8),
          const Divider(height: 1, color: ChurchColors.divider),
          const SizedBox(height: 4),
          Row(
            children: [
              PrayButton(
                prayed: prayer.prayedByMe,
                count: prayer.prayerCount,
                onChanged: onPrayed,
              ),
              const Spacer(),
              if (onOpen != null)
                TextButton.icon(
                  onPressed: onOpen,
                  style: TextButton.styleFrom(foregroundColor: ChurchColors.accent),
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                  label: Text(
                    switch (prayer.commentCount) {
                      0 => 'Encourage',
                      1 => '1 reply',
                      final n => '$n replies',
                    },
                    style: ChurchType.label.copyWith(
                      color: ChurchColors.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );

    return Container(
      decoration: ChurchColors.cardDecoration(),
      child: Material(
        color: Colors.transparent,
        child: onOpen == null
            ? card
            : InkWell(
                borderRadius: ChurchColors.borderRadiusCard,
                onTap: onOpen,
                child: card,
              ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    final meta = [
      prayerWhen(prayer.createdAt),
      if (prayer.visibility == PrayerVisibility.pastors) 'Pastors only',
      if (prayer.mine && prayer.anonymous) 'Shared anonymously',
    ].join(' · ');
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MemberAvatar(name: prayer.anonymous ? '' : prayer.authorName, size: 36, radius: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                prayer.mine ? 'You' : prayer.authorName,
                style: ChurchType.bodyStrong.copyWith(fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(meta, style: ChurchType.caption),
            ],
          ),
        ),
        if (prayer.answered)
          const Padding(
            padding: EdgeInsets.only(top: 4, left: 6),
            child: ChurchStampBadge('Answered'),
          ),
        PopupMenuButton<PrayerAction>(
          tooltip: 'More options',
          icon: const Icon(Icons.more_horiz_rounded, color: ChurchColors.muted),
          onSelected: onAction,
          itemBuilder: (_) => prayer.mine
              ? [
                  if (prayer.answered)
                    const PopupMenuItem(
                      value: PrayerAction.markUnanswered,
                      child: Text('Not answered yet'),
                    )
                  else
                    const PopupMenuItem(
                      value: PrayerAction.markAnswered,
                      child: Text('Mark as answered'),
                    ),
                  const PopupMenuItem(value: PrayerAction.delete, child: Text('Delete request')),
                ]
              : const [
                  PopupMenuItem(value: PrayerAction.report, child: Text('Report')),
                ],
        ),
      ],
    );
  }
}

/// "Pray" — and once tapped, "Prayed", with how many are praying alongside.
class PrayButton extends StatelessWidget {
  const PrayButton({
    super.key,
    required this.prayed,
    required this.count,
    required this.onChanged,
  });

  final bool prayed;
  final int count;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final label = prayed ? 'Prayed' : 'Pray';
    final button = Semantics(
      button: true,
      label: prayed ? 'You prayed for this. Tap to undo.' : 'Pray for this request',
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: prayed ? ChurchColors.button : Colors.transparent,
          borderRadius: ChurchRadius.mdAll,
          border: Border.all(color: prayed ? ChurchColors.button : ChurchColors.divider),
        ),
        child: InkWell(
          borderRadius: ChurchRadius.mdAll,
          onTap: () {
            HapticFeedback.lightImpact();
            onChanged(!prayed);
          },
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 40, minWidth: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    prayed ? Icons.check_rounded : Icons.volunteer_activism_outlined,
                    size: 18,
                    color: prayed ? ChurchColors.buttonText : ChurchColors.accent,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: ChurchType.button.copyWith(
                      fontSize: 14,
                      color: prayed ? ChurchColors.buttonText : ChurchColors.accent,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(color: Colors.transparent, child: button),
          if (count > 0) ...[
            const SizedBox(width: 10),
            Text('$count praying', style: ChurchType.dataSmall),
          ],
        ],
      ),
    );
  }
}

class _PraiseReport extends StatelessWidget {
  const _PraiseReport({this.note});

  final String? note;

  @override
  Widget build(BuildContext context) {
    final text = note?.trim();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: const BoxDecoration(
        color: ChurchColors.background,
        border: Border(left: BorderSide(color: ChurchColors.accent, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ChurchEyebrow('Praise report', color: ChurchColors.accent),
          const SizedBox(height: 4),
          Text(
            text == null || text.isEmpty ? 'God answered this prayer.' : text,
            style: ChurchType.body.copyWith(fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: ChurchColors.muted),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: ChurchType.label)),
        ],
      ),
    );
  }
}
