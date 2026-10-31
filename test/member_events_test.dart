import 'package:church_app/services/member_events.dart';
import 'package:church_app/widgets/event_actions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _event({String? time = '19:00:00', String location = 'Main hall'}) => {
      'id': 'inst-1',
      'title': 'Prayer night',
      'date': '2026-11-03',
      'startTime': time,
      'location': location,
      'description': 'Bring a friend',
    };

Widget _host(Widget child) =>
    MaterialApp(home: Scaffold(body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: child)));

void main() {
  setUpAll(() => dotenv.loadFromString(envString: 'BASE_URL=https://api.example.org'));

  tearDown(() {
    MemberEvents.reminders.value = const {};
    debugDefaultTargetPlatformOverride = null;
  });

  group('online links', () {
    test('finds the link in a location and drops trailing punctuation', () {
      expect(MemberEvents.onlineLink('Zoom: https://zoom.us/j/123456. Passcode 7'), 'https://zoom.us/j/123456');
      expect(MemberEvents.onlineLink('The Okafors’ living room'), isNull);
    });

    test('shows "Online" instead of a raw link', () {
      expect(MemberEvents.placeLabel('https://meet.google.com/abc'), 'Online');
      expect(MemberEvents.placeLabel('Zoom: https://zoom.us/j/1'), 'Online · Zoom');
      expect(MemberEvents.placeLabel('Main hall'), 'Main hall');
    });
  });

  group('calendar', () {
    test('Android gets a Google Calendar link in UTC (Phoenix is UTC−7 all year)', () {
      final uri = MemberEvents.calendarUri(_event())!;
      expect(uri.host, 'calendar.google.com');
      expect(uri.queryParameters['dates'], '20261104T020000Z/20261104T033000Z');
      expect(uri.queryParameters['text'], 'Prayer night');
      expect(uri.queryParameters['location'], 'Main hall');
    });

    test('an event with no time is an all-day entry', () {
      final uri = MemberEvents.calendarUri(_event(time: null))!;
      expect(uri.queryParameters['dates'], '20261103/20261104');
    });

    test('iOS gets the backend’s calendar file', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      expect(MemberEvents.calendarUri(_event()).toString(),
          'https://api.example.org/events/instances/inst-1/calendar.ics');
    });
  });

  test('reminder labels read as people say them', () {
    expect(MemberEvents.reminderLabel(0), 'When it starts');
    expect(MemberEvents.reminderLabel(15), '15 minutes before');
    expect(MemberEvents.reminderLabel(60), '1 hour before');
    expect(MemberEvents.reminderLabel(1440), '1 day before');
  });

  test('a bacenta meeting parses and describes itself', () {
    final m = BacentaMeetingInfo.fromJson({
      'bacentaId': 'b1',
      'name': 'Grace',
      'leaderName': 'Ada Lovelace',
      'date': '2026-11-03',
      'time': '19:00:00',
      'location': 'Zoom: https://zoom.us/j/1',
      'joinUrl': 'https://zoom.us/j/1',
      'cancelled': false,
      'joinCountsNow': true,
      'present': false,
    });
    expect(m.online, isTrue);
    expect(m.whenLabel, 'Tuesday, Nov 3 · 7:00 PM');
    expect(m.placeLabel, 'Online · Zoom');
  });

  group('widgets', () {
    testWidgets('event actions offer join, reminder and calendar', (tester) async {
      await tester.pumpWidget(_host(EventActions(event: _event(location: 'https://zoom.us/j/9'))));
      expect(find.text('Join online'), findsOneWidget);
      expect(find.text('Remind me'), findsOneWidget);
      expect(find.text('Add to calendar'), findsOneWidget);

      MemberEvents.reminders.value = {'inst-1': 60};
      await tester.pump();
      expect(find.text('Reminder on'), findsOneWidget);
      expect(find.text('We’ll remind you 1 hour before.'), findsOneWidget);
    });

    testWidgets('an in-person event has no join button', (tester) async {
      await tester.pumpWidget(_host(EventActions(event: _event())));
      expect(find.text('Join online'), findsNothing);
    });

    testWidgets('the bacenta card shows the meeting, presence and join', (tester) async {
      final meeting = BacentaMeetingInfo.fromJson({
        'bacentaId': 'b1',
        'name': 'Grace',
        'leaderName': 'Ada Lovelace',
        'date': '2026-11-03',
        'time': '19:00:00',
        'location': 'https://zoom.us/j/1',
        'joinUrl': 'https://zoom.us/j/1',
        'cancelled': false,
        'joinCountsNow': false,
        'present': true,
      });
      await tester.pumpWidget(_host(BacentaMeetingCard(meeting: meeting)));
      expect(find.text('Grace'), findsOneWidget);
      expect(find.text('PRESENT'), findsOneWidget);
      expect(find.text('Led by Ada Lovelace'), findsOneWidget);
      expect(find.text('Join online'), findsOneWidget);
    });

    testWidgets('a called-off meeting says so instead of offering to join', (tester) async {
      final meeting = BacentaMeetingInfo.fromJson({
        'bacentaId': 'b1',
        'name': 'Grace',
        'date': '2026-11-03',
        'time': '19:00:00',
        'location': 'https://zoom.us/j/1',
        'joinUrl': 'https://zoom.us/j/1',
        'cancelled': true,
      });
      await tester.pumpWidget(_host(BacentaMeetingCard(meeting: meeting)));
      expect(find.text('This week’s meeting is called off.'), findsOneWidget);
      expect(find.text('Join online'), findsNothing);
    });
  });
}
