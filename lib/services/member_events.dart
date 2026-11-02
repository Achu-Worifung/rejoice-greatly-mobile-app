import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import 'church_api.dart';

/// The member's bacenta meeting that is on now or next.
@immutable
class BacentaMeetingInfo {
  const BacentaMeetingInfo({
    required this.bacentaId,
    required this.name,
    required this.leaderName,
    required this.date,
    required this.hour,
    required this.minute,
    required this.location,
    required this.joinUrl,
    required this.cancelled,
    required this.joinCountsNow,
    required this.present,
  });

  factory BacentaMeetingInfo.fromJson(Map<String, dynamic> json) {
    final time = (json['time'] as String?)?.split(':');
    return BacentaMeetingInfo(
      bacentaId: '${json['bacentaId']}',
      name: json['name'] as String? ?? 'Your bacenta',
      leaderName: json['leaderName'] as String?,
      date: DateTime.tryParse('${json['date']}') ?? DateTime.now(),
      hour: time != null && time.length >= 2 ? int.tryParse(time[0]) : null,
      minute: time != null && time.length >= 2 ? int.tryParse(time[1]) : null,
      location: (json['location'] as String?)?.trim() ?? '',
      joinUrl: json['joinUrl'] as String?,
      cancelled: json['cancelled'] as bool? ?? false,
      joinCountsNow: json['joinCountsNow'] as bool? ?? false,
      present: json['present'] as bool? ?? false,
    );
  }

  final String bacentaId;
  final String name;
  final String? leaderName;

  /// The meeting's date in church time.
  final DateTime date;
  final int? hour;
  final int? minute;
  final String location;

  /// Set when the meeting is online.
  final String? joinUrl;
  final bool cancelled;

  /// Tapping "Join online" now would also count the member present.
  final bool joinCountsNow;
  final bool present;

  bool get online => joinUrl != null;

  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  /// "Tonight · 7:00 PM", "Tuesday, Nov 3 · 7:00 PM".
  String get whenLabel {
    final day = isToday
        ? ((hour ?? 0) >= 17 ? 'Tonight' : 'Today')
        : DateFormat('EEEE, MMM d').format(date);
    if (hour == null) return day;
    final time = DateFormat('h:mm a').format(DateTime(2000, 1, 1, hour!, minute ?? 0));
    return '$day · $time';
  }

  String get placeLabel => MemberEvents.placeLabel(location);
}

/// What tapping "Join online" did. The link opens either way.
@immutable
class BacentaJoin {
  const BacentaJoin(this.url, this.markedPresent, this.message);
  final String url;
  final bool markedPresent;
  final String message;
}

/// Sign-ups for one event occurrence, as this member sees them.
@immutable
class EventSignup {
  const EventSignup({
    required this.open,
    this.closedBecause,
    required this.going,
    this.capacity,
    this.spotsLeft,
    required this.guestsMax,
    this.question,
    this.status,
    required this.guests,
    this.answer,
    this.waitlistPosition,
  });

  factory EventSignup.fromJson(Map<String, dynamic> j) => EventSignup(
        open: j['open'] == true,
        closedBecause: j['closedBecause'] as String?,
        going: (j['going'] as num?)?.toInt() ?? 0,
        capacity: (j['capacity'] as num?)?.toInt(),
        spotsLeft: (j['spotsLeft'] as num?)?.toInt(),
        guestsMax: (j['guestsMax'] as num?)?.toInt() ?? 0,
        question: (j['question'] as String?)?.trim().isEmpty == true ? null : j['question'] as String?,
        status: j['status'] as String?,
        guests: (j['guests'] as num?)?.toInt() ?? 0,
        answer: j['answer'] as String?,
        waitlistPosition: (j['waitlistPosition'] as num?)?.toInt(),
      );

  final bool open;

  /// Why sign-ups are closed, in a sentence; null while open.
  final String? closedBecause;

  /// People with a place, guests included.
  final int going;

  /// Places in all; null for no limit.
  final int? capacity;
  final int? spotsLeft;

  /// Guests each member may bring.
  final int guestsMax;
  final String? question;

  /// GOING, WAITLIST, or null when not signed up.
  final String? status;
  final int guests;

  /// Their answer to [question].
  final String? answer;
  final int? waitlistPosition;

  bool get isGoing => status == 'GOING';
  bool get isWaiting => status == 'WAITLIST';
  bool get full => spotsLeft != null && spotsLeft! <= 0;

  /// "12 going · 8 places left"
  String get countLabel {
    final parts = <String>[if (going > 0) '$going going'];
    if (spotsLeft != null) {
      parts.add(spotsLeft! <= 0 ? 'Full' : '$spotsLeft ${spotsLeft == 1 ? 'place' : 'places'} left');
    }
    return parts.isEmpty ? 'Be the first to sign up' : parts.join(' · ');
  }
}

@immutable
class MemberEventsFeed {
  const MemberEventsFeed(this.events, this.meeting, [this.featured = const []]);

  /// Upcoming events in [ChurchApi.mapEventInstances] shape.
  final List<Map<String, dynamic>> events;
  final BacentaMeetingInfo? meeting;

  /// The events the church is featuring in the Home banner, soonest first.
  final List<Map<String, dynamic>> featured;

  /// [events] picked out by the ids in the feed's `featured`, in that order.
  static List<Map<String, dynamic>> pickFeatured(List<Map<String, dynamic>> events, Object? ids) {
    if (ids is! List) return const [];
    final byId = {for (final e in events) '${e['id']}': e};
    return [for (final id in ids) ?byId['$id']];
  }
}

/// `/member/events` and friends: the member's own view of events — everyone's,
/// plus their bacenta's and basontas' — with "remind me" and "add to calendar".
class MemberEvents {
  MemberEvents._();

  /// The member's reminders, by event occurrence id, in minutes before the
  /// start. Lists and the detail page read this so a bell set on one shows
  /// on the other.
  static final ValueNotifier<Map<String, int>> reminders = ValueNotifier(const {});

  /// Sign-ups for occurrences that take them, by occurrence id.
  static final ValueNotifier<Map<String, EventSignup>> signups = ValueNotifier(const {});

  /// An event a tapped notification asked to open; the home screen picks it up.
  static final ValueNotifier<String?> pendingEvent = ValueNotifier(null);

  /// The reminder choices offered, in minutes before the start.
  static const List<int> reminderChoices = [0, 15, 60, 1440];

  static String reminderLabel(int minutes) => switch (minutes) {
        0 => 'When it starts',
        1440 => '1 day before',
        60 => '1 hour before',
        final m when m % 1440 == 0 => '${m ~/ 1440} days before',
        final m when m % 60 == 0 => '${m ~/ 60} hours before',
        final m => '$m minutes before',
      };

  static Future<MemberEventsFeed> load() async {
    final Map<String, dynamic> map;
    try {
      map = await ChurchApi.memberEvents('');
    } on ChurchApiException catch (e) {
      // A backend from before member events: show the public list instead.
      if (e.statusCode != 404) rethrow;
      final list = await ChurchApi.getUpcomingEvents();
      return MemberEventsFeed(ChurchApi.mapEventInstances(list), null);
    }
    final raw = map['events'];
    final rem = map['reminders'];
    reminders.value = rem is Map
        ? {for (final e in rem.entries) '${e.key}': (e.value as num).toInt()}
        : const {};
    final sign = map['signups'];
    signups.value = sign is Map
        ? {
            for (final e in sign.entries)
              if (e.value is Map) '${e.key}': EventSignup.fromJson(Map<String, dynamic>.from(e.value as Map)),
          }
        : const {};
    final meeting = map['bacentaMeeting'];
    final events = ChurchApi.mapEventInstances(raw is List ? raw : const []);
    return MemberEventsFeed(
      events,
      meeting is Map ? BacentaMeetingInfo.fromJson(Map<String, dynamic>.from(meeting)) : null,
      MemberEventsFeed.pickFeatured(events, map['featured']),
    );
  }

  static Future<void> setReminder(String instanceId, int minutesBefore) async {
    await ChurchApi.memberEvents('$instanceId/reminder', {'minutesBefore': minutesBefore});
    reminders.value = {...reminders.value, instanceId: minutesBefore};
  }

  static Future<void> clearReminder(String instanceId) async {
    await ChurchApi.memberEvents('$instanceId/reminder/delete');
    reminders.value = {...reminders.value}..remove(instanceId);
  }

  /// "I'm coming", or a change to guests or the answer.
  static Future<EventSignup> signUp(String instanceId, {int guests = 0, String? answer}) async {
    final map = await ChurchApi.memberEvents('${Uri.encodeComponent(instanceId)}/signup', {
      'guests': guests,
      if ((answer ?? '').trim().isNotEmpty) 'answer': answer!.trim(),
    });
    final signup = EventSignup.fromJson(map);
    signups.value = {...signups.value, instanceId: signup};
    return signup;
  }

  /// "Can't make it": gives the place to the next on the waiting list.
  static Future<EventSignup> cancelSignup(String instanceId) async {
    final map = await ChurchApi.memberEvents('${Uri.encodeComponent(instanceId)}/signup/cancel');
    final signup = EventSignup.fromJson(map);
    signups.value = {...signups.value, instanceId: signup};
    return signup;
  }

  static Future<BacentaJoin> joinBacenta() async {
    final map = await ChurchApi.joinBacentaMeeting();
    return BacentaJoin(
      map['url'] as String? ?? '',
      map['markedPresent'] as bool? ?? false,
      map['message'] as String? ?? '',
    );
  }

  /// When an event starts, in church time. One with no time is taken as 9 AM,
  /// as the backend does.
  static DateTime? startOf(Map<String, dynamic> event) {
    final date = DateTime.tryParse(event['date'] as String? ?? '');
    if (date == null) return null;
    final parts = (event['startTime'] as String?)?.split(':');
    final hour = parts != null && parts.length >= 2 ? int.tryParse(parts[0]) ?? 9 : 9;
    final minute = parts != null && parts.length >= 2 ? int.tryParse(parts[1]) ?? 0 : 0;
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  /// The church keeps Arizona time: UTC−7 all year, with no daylight saving.
  static const Duration _churchUtcOffset = Duration(hours: -7);

  /// Assumed length when an event has no end time, matching the backend's
  /// calendar file.
  static const Duration _assumedLength = Duration(minutes: 90);

  /// "Add to calendar": the backend's .ics file on iOS, which Safari offers to
  /// add, and a Google Calendar link elsewhere, which opens the calendar app.
  static Uri? calendarUri(Map<String, dynamic> event) {
    final id = event['id'] as String?;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS && id != null) {
      return Uri.parse('${ChurchApi.baseUrl}/events/instances/$id/calendar.ics');
    }
    final start = startOf(event);
    if (start == null) return null;
    final hasTime = (event['startTime'] as String?)?.isNotEmpty == true;
    final String dates;
    if (hasTime) {
      String utc(DateTime t) =>
          '${DateFormat('yyyyMMdd').format(t)}T${DateFormat('HHmmss').format(t)}Z';
      final startUtc = start.subtract(_churchUtcOffset);
      dates = '${utc(startUtc)}/${utc(startUtc.add(_assumedLength))}';
    } else {
      final day = DateFormat('yyyyMMdd');
      dates = '${day.format(start)}/${day.format(start.add(const Duration(days: 1)))}';
    }
    return Uri.https('calendar.google.com', '/calendar/render', {
      'action': 'TEMPLATE',
      'text': event['title'] as String? ?? 'Church event',
      'dates': dates,
      if ((event['location'] as String? ?? '').isNotEmpty) 'location': event['location'] as String,
      if ((event['description'] as String? ?? '').isNotEmpty) 'details': event['description'] as String,
    });
  }

  /// A location for display: "Online · Zoom" rather than a raw link.
  static String placeLabel(String location) {
    final link = onlineLink(location);
    if (link == null) return location;
    final rest = location
        .replaceAll(link, '')
        .replaceAll(RegExp(r'^[\s:–-]+|[\s:.,;–-]+$'), '')
        .trim();
    return rest.isEmpty ? 'Online' : 'Online · $rest';
  }

  /// The meeting link in a location such as "Zoom: https://zoom.us/j/123".
  static String? onlineLink(String? location) {
    if (location == null) return null;
    final match = RegExp(r'''https?://[^\s<>"']+''', caseSensitive: false).firstMatch(location);
    return match?.group(0)?.replaceAll(RegExp(r'[.,;:)\]]+$'), '');
  }
}
