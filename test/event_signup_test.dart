import 'package:church_app/services/member_events.dart';
import 'package:church_app/widgets/event_signup_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

EventSignup _s(Map<String, dynamic> j) => EventSignup.fromJson({
      'open': true,
      'going': 12,
      'capacity': 20,
      'spotsLeft': 8,
      'guestsMax': 0,
      'guests': 0,
      ...j,
    });

void main() {
  setUpAll(() => dotenv.loadFromString(envString: 'BASE_URL=https://api.example.org'));
  tearDown(() => MemberEvents.signups.value = const {});

  Future<void> pump(WidgetTester tester, EventSignupCard card) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.5;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: SingleChildScrollView(child: card))));
    await tester.pumpAndSettle();
  }

  test('counts in plain words', () {
    expect(_s({}).countLabel, '12 going · 8 places left');
    expect(_s({'spotsLeft': 0}).countLabel, '12 going · Full');
    expect(_s({'going': 0, 'capacity': null, 'spotsLeft': null}).countLabel, 'Be the first to sign up');
  });

  testWidgets('shows nothing for an event without sign-ups', (tester) async {
    await pump(tester, const EventSignupCard(instanceId: 'i1'));
    expect(find.text('Coming?'), findsNothing);
  });

  testWidgets('"I\'m coming" signs up straight away when there is nothing to ask', (tester) async {
    MemberEvents.signups.value = {'i1': _s({})};
    final calls = <(String, int, String?)>[];
    await pump(
      tester,
      EventSignupCard(
        instanceId: 'i1',
        signUp: (id, g, a) async {
          calls.add((id, g, a));
          final r = _s({'status': 'GOING', 'going': 13, 'spotsLeft': 7});
          MemberEvents.signups.value = {'i1': r};
          return r;
        },
      ),
    );
    expect(find.text('Coming?'), findsOneWidget);
    expect(find.text('12 going · 8 places left'), findsOneWidget);
    await tester.tap(find.text('I’m coming'));
    await tester.pumpAndSettle();
    expect(calls, [('i1', 0, null)]);
    expect(find.text('You’re coming'), findsOneWidget);
    expect(find.text('Can’t make it'), findsOneWidget);
    expect(find.text('You’re in. See you there!'), findsOneWidget);
  });

  testWidgets('asks for guests and the question first when the event wants them', (tester) async {
    MemberEvents.signups.value = {'i1': _s({'guestsMax': 2, 'question': 'Any dietary needs?'})};
    (int, String?)? sent;
    await pump(
      tester,
      EventSignupCard(
        instanceId: 'i1',
        signUp: (id, g, a) async {
          sent = (g, a);
          return _s({'status': 'GOING', 'guests': g, 'answer': a});
        },
      ),
    );
    await tester.tap(find.text('I’m coming'));
    await tester.pumpAndSettle();
    expect(find.text('Bringing anyone?'), findsOneWidget);
    await tester.tap(find.byTooltip('More guests'));
    await tester.tap(find.byTooltip('More guests'));
    await tester.pump();
    expect(tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.add_circle_outline_rounded)).onPressed, isNull);
    await tester.enterText(find.widgetWithText(TextField, 'Any dietary needs?'), 'Vegetarian');
    await tester.tap(find.widgetWithText(ElevatedButton, 'I’m coming').last);
    await tester.pumpAndSettle();
    expect(sent, (2, 'Vegetarian'));
  });

  testWidgets('when it\'s full, offers the waiting list and shows the place in line', (tester) async {
    MemberEvents.signups.value = {'i1': _s({'going': 20, 'spotsLeft': 0})};
    await pump(
      tester,
      EventSignupCard(
        instanceId: 'i1',
        signUp: (id, g, a) async {
          final r = _s({'going': 20, 'spotsLeft': 0, 'status': 'WAITLIST', 'waitlistPosition': 3});
          MemberEvents.signups.value = {'i1': r};
          return r;
        },
      ),
    );
    await tester.tap(find.text('Join the waiting list'));
    await tester.pumpAndSettle();
    expect(find.text('You’re number 3 on the waiting list'), findsOneWidget);
    expect(find.text('Leave the waiting list'), findsOneWidget);
  });

  testWidgets('says why sign-ups are closed', (tester) async {
    MemberEvents.signups.value = {'i1': _s({'open': false, 'closedBecause': 'Sign-ups closed on Wednesday, Nov 18.'})};
    await pump(tester, const EventSignupCard(instanceId: 'i1'));
    expect(find.text('Sign-ups are closed'), findsOneWidget);
    expect(find.text('Sign-ups closed on Wednesday, Nov 18.'), findsOneWidget);
    expect(find.text('I’m coming'), findsNothing);
  });
}
