import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../main.dart' show navigatorKey;
import '../services/milestones.dart';
import '../theme/church_colors.dart';
import '../theme/church_type.dart';
import 'church_buttons.dart';
import 'dashboard_label_title.dart';

/// What a milestone's seal shows: a count with a word under it, or an icon.
({String? number, IconData? icon, String caption}) _face(String key) {
  final count = int.tryParse(key.substring(key.indexOf('_') + 1));
  if (key.startsWith('SUNDAYS_') && count != null) return (number: '$count', icon: null, caption: 'Sundays');
  if (key.startsWith('YEARS_') && count != null) {
    return (number: '$count', icon: null, caption: count == 1 ? 'Year' : 'Years');
  }
  if (key.startsWith('SERMONS_') && count != null) return (number: '$count', icon: null, caption: 'Sermons');
  return switch (key) {
    'FIRST_SUNDAY' => (number: null, icon: Icons.door_front_door_outlined, caption: 'Welcome'),
    'FIRST_BACENTA' => (number: null, icon: Icons.groups_2_outlined, caption: 'Bacenta'),
    'FULL_MONTH' => (number: null, icon: Icons.calendar_month_outlined, caption: 'A month'),
    'FIRST_SERMON' => (number: null, icon: Icons.headphones_outlined, caption: 'Sermon'),
    'SERIES' => (number: null, icon: Icons.auto_stories_outlined, caption: 'Series'),
    _ => (number: null, icon: Icons.star_outline_rounded, caption: 'Milestone'),
  };
}

/// "Sunday, October 25" this year, "October 25, 2025" before.
String milestoneDate(DateTime d, {DateTime? now}) {
  final today = now ?? DateTime.now();
  return d.year == today.year ? DateFormat('EEEE, MMMM d').format(d) : DateFormat('MMMM d, y').format(d);
}

/// A milestone as an ink stamp in the register: a double-ruled square in the
/// accent, set a degree or so off true the way a hand-pressed stamp lands.
class MilestoneSeal extends StatelessWidget {
  const MilestoneSeal({super.key, required this.milestoneKey, this.size = 52});

  final String milestoneKey;
  final double size;

  @override
  Widget build(BuildContext context) {
    final face = _face(milestoneKey);
    final ink = ChurchColors.accent;
    // −1.5° to +1.5°, fixed per milestone so it doesn't wobble on rebuild.
    final angle = ((milestoneKey.codeUnits.fold<int>(0, (a, b) => a + b) % 7) - 3) * 0.0087;
    final scale = size / 52;
    return Semantics(
      excludeSemantics: true,
      child: Transform.rotate(
        angle: angle,
        child: Container(
          width: size,
          height: size,
          padding: EdgeInsets.all(3 * scale),
          decoration: BoxDecoration(
            borderRadius: ChurchRadius.smAll,
            border: Border.all(color: ink.withValues(alpha: 0.75), width: 2 * scale),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: ChurchRadius.smAll,
              border: Border.all(color: ink.withValues(alpha: 0.45)),
            ),
            alignment: Alignment.center,
            child: FittedBox(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 4 * scale, vertical: 2 * scale),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (face.number != null)
                      Text(face.number!, style: ChurchType.data.copyWith(color: ink, fontSize: 20 * scale, height: 1.05))
                    else
                      Icon(face.icon, color: ink, size: 20 * scale),
                    SizedBox(height: 2 * scale),
                    Text(
                      face.caption.toUpperCase(),
                      style: ChurchType.eyebrow.copyWith(color: ink, fontSize: 7 * scale, letterSpacing: 0.8 * scale),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The card a new milestone gets, once: a seal, the words, and "Thank you".
/// Marks them shown as soon as it opens.
class MilestoneSheet extends StatelessWidget {
  const MilestoneSheet({super.key, required this.milestones});

  /// Newest first; the first is the one the sheet is about.
  final List<Milestone> milestones;

  static Future<void> show(BuildContext context, List<Milestone> milestones) {
    if (milestones.isEmpty) return Future.value();
    unawaited(Milestones.markCelebrated(milestones.map((m) => m.key)));
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: ChurchColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(ChurchRadius.lg)),
      ),
      builder: (_) => MilestoneSheet(milestones: milestones),
    );
  }

  @override
  Widget build(BuildContext context) {
    final main = milestones.first;
    final others = milestones.skip(1).map((m) => m.title).toList();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: ChurchColors.divider, borderRadius: ChurchRadius.smAll),
            ),
            const SizedBox(height: 28),
            MilestoneSeal(milestoneKey: main.key, size: 96),
            const SizedBox(height: 24),
            ChurchEyebrow('A milestone', color: ChurchColors.accent),
            const SizedBox(height: 8),
            Text(main.title, textAlign: TextAlign.center, style: ChurchType.display),
            const SizedBox(height: 10),
            Text(main.message, textAlign: TextAlign.center, style: ChurchType.body),
            const SizedBox(height: 8),
            Text(milestoneDate(main.earnedOn), style: ChurchType.dataSmall),
            if (others.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('And: ${others.join(' · ')}', textAlign: TextAlign.center, style: ChurchType.label),
            ],
            const SizedBox(height: 28),
            ChurchPrimaryButton(label: 'Thank you', onPressed: () => Navigator.pop(context)),
          ],
        ),
      ),
    );
  }
}

/// After a fresh check-in: a moment for the banner to land, then the card
/// for any milestone that check-in reached. Quietly does nothing otherwise.
Future<void> celebrateAfterCheckIn() async {
  await Future<void>.delayed(const Duration(milliseconds: 1500));
  final summary = await Milestones.refresh();
  final fresh = summary?.fresh ?? const <Milestone>[];
  final context = navigatorKey.currentContext;
  if (fresh.isEmpty || context == null || !context.mounted) return;
  await MilestoneSheet.show(context, fresh);
}

/// On Home, only while there's a milestone they haven't seen: the seal, the
/// words, and "Thank you", which puts it away. Shows nothing otherwise.
class NewMilestoneCard extends StatelessWidget {
  const NewMilestoneCard({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<MilestoneSummary?>(
      valueListenable: Milestones.current,
      builder: (context, summary, _) {
        final fresh = summary?.fresh ?? const <Milestone>[];
        if (fresh.isEmpty) return const SizedBox.shrink();
        final m = fresh.first;
        return Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const DashboardLabelText(label: 'A milestone'),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                decoration: ChurchColors.cardDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MilestoneSeal(milestoneKey: m.key, size: 56),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(m.title, style: ChurchType.title),
                              const SizedBox(height: 4),
                              Text(m.message, style: ChurchType.body.copyWith(fontSize: 14)),
                              if (fresh.length > 1) ...[
                                const SizedBox(height: 6),
                                Text(
                                  'And: ${fresh.skip(1).map((f) => f.title).join(' · ')}',
                                  style: ChurchType.label,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Milestones.markCelebrated(fresh.map((f) => f.key)),
                        child: const Text('Thank you'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// On the Me page: their latest milestones, the next Sunday count, and the
/// way to all of them. Loads itself the first time.
class MilestonesShelf extends StatefulWidget {
  const MilestonesShelf({super.key});

  /// How many show before "See all".
  static const int shown = 3;

  @override
  State<MilestonesShelf> createState() => _MilestonesShelfState();
}

class _MilestonesShelfState extends State<MilestonesShelf> {
  @override
  void initState() {
    super.initState();
    if (Milestones.current.value == null) Milestones.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<MilestoneSummary?>(
      valueListenable: Milestones.current,
      builder: (context, summary, _) {
        if (summary == null) return const SizedBox.shrink();
        final earned = summary.earned;
        final next = summary.nextLine;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const DashboardLabelText(label: 'Milestones'),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
              decoration: ChurchColors.cardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (earned.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'Your first Sunday will be the first one here. We’d love to see you.',
                        style: ChurchType.label,
                      ),
                    ),
                  for (final (i, m) in earned.take(MilestonesShelf.shown).indexed) ...[
                    if (i > 0) Divider(height: 1, color: ChurchColors.divider),
                    MilestoneRow(milestone: m),
                  ],
                  if (next != null) ...[
                    if (earned.isNotEmpty) Divider(height: 1, color: ChurchColors.divider),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          Icon(Icons.wb_sunny_outlined, size: 18, color: ChurchColors.muted),
                          const SizedBox(width: 10),
                          Expanded(child: Text(next, style: ChurchType.label)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (earned.length > MilestonesShelf.shown)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const MilestonesPage()),
                  ),
                  child: Text('See all ${earned.length}'),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// One milestone in a list: seal, title, when; [withMessage] adds the words.
class MilestoneRow extends StatelessWidget {
  const MilestoneRow({super.key, required this.milestone, this.withMessage = false});

  final Milestone milestone;
  final bool withMessage;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: withMessage ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          MilestoneSeal(milestoneKey: milestone.key, size: 44),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(milestone.title, style: ChurchType.title.copyWith(fontSize: 16)),
                const SizedBox(height: 2),
                Text(milestoneDate(milestone.earnedOn), style: ChurchType.dataSmall),
                if (withMessage && milestone.message.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(milestone.message, style: ChurchType.body.copyWith(fontSize: 14)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Every milestone they've reached, newest first, with the words for each.
class MilestonesPage extends StatelessWidget {
  const MilestonesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ChurchColors.background,
      appBar: AppBar(title: Text('Milestones', style: ChurchType.headline)),
      body: ValueListenableBuilder<MilestoneSummary?>(
        valueListenable: Milestones.current,
        builder: (context, summary, _) {
          final earned = summary?.earned ?? const <Milestone>[];
          return RefreshIndicator(
            onRefresh: Milestones.refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
              children: [
                if (summary?.nextLine != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(summary!.nextLine!, style: ChurchType.label),
                  ),
                for (final (i, m) in earned.indexed) ...[
                  if (i > 0) Divider(height: 1, color: ChurchColors.divider),
                  MilestoneRow(milestone: m, withMessage: true),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
