import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'church_api.dart';
import 'milestones.dart';

/// "Your year at Rejoice Greatly": the member's own year, from
/// `POST /member/year-review`. Only what they did and what was done for them.
@immutable
class YearReview {
  const YearReview({
    required this.year,
    this.available = false,
    this.firstYear = false,
    this.sundays = 0,
    this.fullestMonth,
    this.bacentaMeetings = 0,
    this.sermonsHeard = 0,
    this.favouriteSeries,
    this.prayedForOthers = 0,
    this.prayersForThem = 0,
    this.requestsShared = 0,
    this.requestsAnswered = 0,
    this.milestones = const [],
  });

  factory YearReview.fromJson(Map<String, dynamic> j) {
    int n(String k) => (j[k] as num?)?.toInt() ?? 0;
    String? s(String k) => (j[k] as String?)?.trim().isNotEmpty == true ? (j[k] as String).trim() : null;
    return YearReview(
      year: n('year'),
      available: j['available'] == true,
      firstYear: j['firstYear'] == true,
      sundays: n('sundays'),
      fullestMonth: s('fullestMonth'),
      bacentaMeetings: n('bacentaMeetings'),
      sermonsHeard: n('sermonsHeard'),
      favouriteSeries: s('favouriteSeries'),
      prayedForOthers: n('prayedForOthers'),
      prayersForThem: n('prayersForThem'),
      requestsShared: n('requestsShared'),
      requestsAnswered: n('requestsAnswered'),
      milestones: [
        for (final m in (j['milestones'] as List? ?? const []))
          if (m is Map) Milestone.fromJson(Map<String, dynamic>.from(m)),
      ],
    );
  }

  final int year;

  /// Offered in December and January.
  final bool available;
  final bool firstYear;
  final int sundays;
  final String? fullestMonth;
  final int bacentaMeetings;
  final int sermonsHeard;
  final String? favouriteSeries;
  final int prayedForOthers;
  final int prayersForThem;
  final int requestsShared;
  final int requestsAnswered;
  final List<Milestone> milestones;

  /// Whether there's a year worth telling back.
  bool get hasContent =>
      sundays > 0 || bacentaMeetings > 0 || sermonsHeard > 0 || prayedForOthers > 0 || prayersForThem > 0;

  /// What sharing it says: their own numbers, nothing about anyone else.
  String get shareText {
    final parts = [
      if (sundays > 0) '$sundays ${sundays == 1 ? 'Sunday' : 'Sundays'} together',
      if (sermonsHeard > 0) '$sermonsHeard ${sermonsHeard == 1 ? 'sermon' : 'sermons'} heard',
      if (prayedForOthers > 0) '$prayedForOthers ${prayedForOthers == 1 ? 'prayer' : 'prayers'} for others',
    ];
    final what = parts.isEmpty ? 'a year of church family' : parts.join(', ');
    return 'My $year at Rejoice Greatly: $what. Thankful for this church family.';
  }
}

class YearReviews {
  YearReviews._();

  /// December and January, when the review is offered. The server decides
  /// too; this only saves asking the rest of the year.
  static bool inSeason(DateTime now) => now.month == DateTime.december || now.month == DateTime.january;

  static Future<YearReview> load({int? year}) async =>
      YearReview.fromJson(await ChurchApi.memberYearReview(year: year));

  static String _seenKey(int year) => 'year_review_seen_$year';

  /// Whether they've opened this year's review on this phone.
  static Future<bool> seen(int year) async {
    try {
      return (await SharedPreferences.getInstance()).getBool(_seenKey(year)) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> markSeen(int year) async {
    try {
      await (await SharedPreferences.getInstance()).setBool(_seenKey(year), true);
    } catch (_) {}
  }
}
