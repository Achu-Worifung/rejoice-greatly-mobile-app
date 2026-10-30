import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'church_api.dart';

/// A milestone the member has reached: their first Sunday, 25 Sundays, a
/// year with us, a whole series heard. Worked out by the backend from what's
/// recorded; private to them.
@immutable
class Milestone {
  const Milestone({
    required this.key,
    required this.title,
    required this.message,
    required this.earnedOn,
    this.isNew = false,
  });

  factory Milestone.fromJson(Map<String, dynamic> j) => Milestone(
        key: '${j['key']}',
        title: j['title'] as String? ?? 'A milestone',
        message: j['message'] as String? ?? '',
        earnedOn: DateTime.tryParse('${j['earnedOn']}') ?? DateTime.now(),
        isNew: j['isNew'] == true,
      );

  final String key;
  final String title;
  final String message;
  final DateTime earnedOn;

  /// Reached lately and not yet greeted with a card.
  final bool isNew;

  Milestone celebrated() =>
      Milestone(key: key, title: title, message: message, earnedOn: earnedOn);
}

/// Their milestones, newest first, and the next Sunday count to look forward to.
@immutable
class MilestoneSummary {
  const MilestoneSummary({
    this.earned = const [],
    this.sundays = 0,
    this.nextSundays,
    this.nextRemaining,
  });

  factory MilestoneSummary.fromJson(Map<String, dynamic> j) {
    final next = j['next'];
    return MilestoneSummary(
      earned: [
        for (final m in (j['earned'] as List? ?? const []))
          if (m is Map) Milestone.fromJson(Map<String, dynamic>.from(m)),
      ],
      sundays: (j['sundays'] as num?)?.toInt() ?? 0,
      nextSundays: next is Map ? (next['sundays'] as num?)?.toInt() : null,
      nextRemaining: next is Map ? (next['remaining'] as num?)?.toInt() : null,
    );
  }

  final List<Milestone> earned;

  /// Service weeks they've been at church.
  final int sundays;
  final int? nextSundays;
  final int? nextRemaining;

  List<Milestone> get fresh => earned.where((m) => m.isNew).toList();

  /// "3 more Sundays until 25." — or null when there's nothing to say yet.
  String? get nextLine {
    final remaining = nextRemaining;
    final target = nextSundays;
    if (remaining == null || target == null || remaining <= 0) return null;
    return remaining == 1
        ? 'One more Sunday until $target.'
        : '$remaining more Sundays until $target.';
  }

  MilestoneSummary withCelebrated(Set<String> keys) => MilestoneSummary(
        earned: [for (final m in earned) keys.contains(m.key) ? m.celebrated() : m],
        sundays: sundays,
        nextSundays: nextSundays,
        nextRemaining: nextRemaining,
      );
}

/// Loads milestones, tells the backend about sermons heard to the end, and
/// remembers which cards have been shown.
class Milestones {
  Milestones._();

  /// The latest summary, or null before the first load. Listen to repaint.
  static final ValueNotifier<MilestoneSummary?> current = ValueNotifier(null);

  static const _reportedKey = 'sermons_finished_reported';

  /// Fetches them afresh. Never throws: milestones are a nicety, and a
  /// failure keeps whatever was showing.
  static Future<MilestoneSummary?> refresh() async {
    try {
      final summary = MilestoneSummary.fromJson(await ChurchApi.memberMilestones(''));
      current.value = summary;
      return summary;
    } catch (e) {
      debugPrint('Milestones.refresh failed: $e');
      return current.value;
    }
  }

  /// The card for these has been shown; they stop being new here and on the server.
  static Future<void> markCelebrated(Iterable<String> keys) async {
    final set = keys.toSet();
    if (set.isEmpty) return;
    final now = current.value;
    if (now != null) current.value = now.withCelebrated(set);
    try {
      await ChurchApi.memberMilestones('celebrated', {'keys': set.toList()});
    } catch (e) {
      debugPrint('Milestones.markCelebrated failed: $e');
    }
  }

  /// They heard [sermonId] to the end. Reported once per sermon from this
  /// phone; the backend ignores repeats anyway.
  static Future<void> sermonFinished(String sermonId) async {
    if (int.tryParse(sermonId) == null) return; // only real sermons have numeric ids
    try {
      final prefs = await SharedPreferences.getInstance();
      final reported = prefs.getStringList(_reportedKey) ?? const <String>[];
      if (reported.contains(sermonId)) return;
      final data = await ChurchApi.memberSermonFinished(sermonId);
      await prefs.setStringList(_reportedKey, [...reported, sermonId]);
      current.value = MilestoneSummary.fromJson(data);
    } catch (e) {
      debugPrint('Milestones.sermonFinished failed: $e');
    }
  }

  /// Forgets everything on sign-out.
  static Future<void> clear() async {
    current.value = null;
    try {
      (await SharedPreferences.getInstance()).remove(_reportedKey);
    } catch (_) {}
  }
}
