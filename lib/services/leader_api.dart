import 'package:flutter/foundation.dart';

import 'church_api.dart';

DateTime? _date(Object? v) => v == null ? null : DateTime.tryParse('$v');

/// "19:00:00" → "7:00 PM".
String? clockLabel(Object? time) {
  if (time == null) return null;
  final parts = '$time'.split(':');
  if (parts.length < 2) return null;
  final h = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  if (h == null || m == null) return null;
  final hour = h % 12 == 0 ? 12 : h % 12;
  return '$hour:${m.toString().padLeft(2, '0')} ${h < 12 ? 'AM' : 'PM'}';
}

/// "TUESDAY" → "Tuesday".
String? dayLabel(Object? day) {
  if (day == null) return null;
  final s = '$day'.toLowerCase();
  return s.isEmpty ? null : s[0].toUpperCase() + s.substring(1);
}

/// A bacenta the member leads, for the home card.
@immutable
class LedBacenta {
  const LedBacenta({
    required this.id,
    required this.name,
    this.meetingDay,
    this.meetingTime,
    this.members = 0,
    this.toFollowUp = 0,
  });

  factory LedBacenta.fromJson(Map<String, dynamic> j) => LedBacenta(
        id: '${j['id']}',
        name: j['name'] as String? ?? 'Your bacenta',
        meetingDay: dayLabel(j['meetingDay']),
        meetingTime: clockLabel(j['meetingTime']),
        members: (j['members'] as num?)?.toInt() ?? 0,
        toFollowUp: (j['toFollowUp'] as num?)?.toInt() ?? 0,
      );

  final String id;
  final String name;
  final String? meetingDay;
  final String? meetingTime;
  final int members;
  final int toFollowUp;

  /// Whether today is this bacenta's meeting day.
  bool get meetsToday => meetingDay != null && meetingDay == _weekday(DateTime.now());
}

String _weekday(DateTime d) =>
    const ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][d.weekday - 1];

@immutable
class LeaderMeeting {
  const LeaderMeeting({
    required this.date,
    required this.recordable,
    required this.cancelled,
    required this.present,
    this.time,
    this.closesAt,
  });

  factory LeaderMeeting.fromJson(Map<String, dynamic> j) => LeaderMeeting(
        date: DateTime.parse('${j['date']}'),
        time: clockLabel(j['time']),
        recordable: j['recordable'] as bool? ?? false,
        closesAt: _date(j['closesAt']),
        cancelled: j['cancelled'] as bool? ?? false,
        present: {for (final id in (j['present'] as List? ?? const [])) '$id'},
      );

  final DateTime date;
  final String? time;
  final bool recordable;
  final DateTime? closesAt;
  final bool cancelled;
  final Set<String> present;

  bool get recorded => cancelled || present.isNotEmpty;
}

@immutable
class LeaderMember {
  const LeaderMember({required this.id, required this.name, required this.onApp, this.lastSunday});

  factory LeaderMember.fromJson(Map<String, dynamic> j) => LeaderMember(
        id: '${j['accountId']}',
        name: j['name'] as String? ?? 'A member',
        onApp: j['onApp'] as bool? ?? true,
        lastSunday: _date(j['lastSunday']),
      );

  final String id;
  final String name;
  final bool onApp;
  final DateTime? lastSunday;
}

@immutable
class FollowUpPerson {
  const FollowUpPerson({
    required this.id,
    required this.name,
    required this.weeksMissed,
    this.lastAttended,
    this.checkedAt,
    this.checkedBy,
    this.note,
  });

  factory FollowUpPerson.fromJson(Map<String, dynamic> j) {
    final check = j['check'] as Map?;
    return FollowUpPerson(
      id: '${j['accountId']}',
      name: j['name'] as String? ?? 'A member',
      weeksMissed: (j['weeksMissed'] as num?)?.toInt() ?? 0,
      lastAttended: _date(j['lastAttended']),
      checkedAt: _date(check?['at']),
      checkedBy: check?['byName'] as String?,
      note: check?['note'] as String?,
    );
  }

  final String id;
  final String name;
  final int weeksMissed;
  final DateTime? lastAttended;
  final DateTime? checkedAt;
  final String? checkedBy;
  final String? note;

  bool get checked => checkedAt != null;
}

@immutable
class LeaderMessage {
  const LeaderMessage({required this.body, required this.recipients, required this.sentAt});

  factory LeaderMessage.fromJson(Map<String, dynamic> j) => LeaderMessage(
        body: j['body'] as String? ?? '',
        recipients: (j['recipients'] as num?)?.toInt() ?? 0,
        sentAt: _date(j['sentAt'])?.toLocal() ?? DateTime.now(),
      );

  final String body;
  final int recipients;
  final DateTime sentAt;
}

/// Everything on a leader's bacenta screen.
@immutable
class LeaderView {
  const LeaderView({
    required this.id,
    required this.name,
    required this.members,
    required this.followUps,
    required this.messages,
    this.meetingDay,
    this.meetingTime,
    this.location,
    this.meeting,
  });

  factory LeaderView.fromJson(Map<String, dynamic> j) {
    List<T> list<T>(String key, T Function(Map<String, dynamic>) f) => (j[key] as List? ?? const [])
        .whereType<Map>()
        .map((e) => f(Map<String, dynamic>.from(e)))
        .toList();
    final meeting = j['meeting'];
    return LeaderView(
      id: '${j['id']}',
      name: j['name'] as String? ?? 'Your bacenta',
      meetingDay: dayLabel(j['meetingDay']),
      meetingTime: clockLabel(j['meetingTime']),
      location: j['location'] as String?,
      meeting: meeting is Map ? LeaderMeeting.fromJson(Map<String, dynamic>.from(meeting)) : null,
      members: list('members', LeaderMember.fromJson),
      followUps: list('followUps', FollowUpPerson.fromJson),
      messages: list('messages', LeaderMessage.fromJson),
    );
  }

  final String id;
  final String name;
  final String? meetingDay;
  final String? meetingTime;
  final String? location;
  final LeaderMeeting? meeting;
  final List<LeaderMember> members;
  final List<FollowUpPerson> followUps;
  final List<LeaderMessage> messages;
}

/// Typed calls for `/member/leader/**`.
class LeaderApi {
  LeaderApi._();

  /// The bacentas the member leads; empty for everyone else.
  static Future<List<LedBacenta>> led() async {
    final map = await ChurchApi.memberLeader('');
    return (map['bacentas'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => LedBacenta.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<LeaderView> view(String bacentaId) async =>
      LeaderView.fromJson(await ChurchApi.memberLeader('bacentas/$bacentaId'));

  static Future<LeaderView> takeAttendance(
    String bacentaId,
    DateTime date,
    Set<String> present, {
    bool cancelled = false,
  }) async =>
      LeaderView.fromJson(await ChurchApi.memberLeader('bacentas/$bacentaId/attendance', {
        'date': _iso(date),
        'present': present.toList(),
        'cancelled': cancelled,
      }));

  static Future<LeaderView> addPerson(String bacentaId, String name) async =>
      LeaderView.fromJson(await ChurchApi.memberLeader('bacentas/$bacentaId/people', {'text': name}));

  /// Returns how many it went to.
  static Future<int> message(String bacentaId, String text) async {
    final map = await ChurchApi.memberLeader('bacentas/$bacentaId/message', {'text': text});
    return (map['sentTo'] as num?)?.toInt() ?? 0;
  }

  static Future<void> checkIn(String accountId, String? note) =>
      ChurchApi.memberLeader('follow-ups/$accountId/check', {'text': note});

  static String _iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
