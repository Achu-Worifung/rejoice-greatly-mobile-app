import 'package:church_app/services/leader_api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('times and days read the way people say them', () {
    expect(clockLabel('19:00:00'), '7:00 PM');
    expect(clockLabel('09:30'), '9:30 AM');
    expect(clockLabel('12:05:00'), '12:05 PM');
    expect(clockLabel(null), isNull);
    expect(dayLabel('TUESDAY'), 'Tuesday');
  });

  test('a leader’s bacenta screen parses, follow-ups and all', () {
    final view = LeaderView.fromJson({
      'id': 'b1',
      'name': 'Grace',
      'meetingDay': 'TUESDAY',
      'meetingTime': '19:00:00',
      'location': 'The Okafors’ living room',
      'meeting': {
        'date': '2026-11-03',
        'time': '19:00:00',
        'recordable': true,
        'closesAt': '2026-11-04T07:00:00',
        'cancelled': false,
        'present': ['a1'],
      },
      'members': [
        {'accountId': 'a1', 'name': 'Ada Lovelace', 'onApp': true, 'lastSunday': '2026-11-01'},
        {'accountId': 'k1', 'name': 'Kofi Mensah', 'onApp': false},
      ],
      'followUps': [
        {
          'accountId': 'b2',
          'name': 'Ben Okafor',
          'weeksMissed': 4,
          'lastAttended': '2026-10-04',
          'check': {'at': '2026-10-30T18:00:00Z', 'byName': 'Lydia Leader', 'note': 'Texted him'},
        },
      ],
      'messages': [
        {'body': 'Bring a friend!', 'recipients': 7, 'sentAt': '2026-10-28T19:00:00Z'},
      ],
    });

    expect(view.meetingTime, '7:00 PM');
    expect(view.meeting!.recordable, isTrue);
    expect(view.meeting!.present, {'a1'});
    expect(view.members.last.onApp, isFalse);
    expect(view.followUps.single.checked, isTrue);
    expect(view.followUps.single.note, 'Texted him');
    expect(view.messages.single.recipients, 7);
  });

  test('a bacenta with no meeting day has no meeting to record', () {
    final view = LeaderView.fromJson({'id': 'b1', 'name': 'Grace', 'members': [], 'followUps': [], 'messages': []});
    expect(view.meeting, isNull);
    expect(LedBacenta.fromJson({'id': 'b1', 'name': 'Grace'}).meetsToday, isFalse);
  });
}
