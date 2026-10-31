import 'package:church_app/services/milestones.dart';
import 'package:church_app/services/sermon_progress.dart';
import 'package:church_app/widgets/milestone_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, dynamic> _m(String key, String title, String on, {bool isNew = false}) =>
    {'key': key, 'title': title, 'message': 'Words for $title.', 'earnedOn': on, 'isNew': isNew};

MilestoneSummary _summary({List<Map<String, dynamic>>? earned, int sundays = 22, Object? next}) =>
    MilestoneSummary.fromJson({
      'earned': earned ??
          [
            _m('SUNDAYS_10', '10 Sundays', '2026-10-25', isNew: true),
            _m('YEARS_1', 'A year with us', '2026-09-13'),
            _m('FULL_MONTH', 'A whole month of Sundays', '2026-03-29'),
            _m('FIRST_SERMON', 'Your first sermon in the app', '2026-02-02'),
            _m('FIRST_SUNDAY', 'Your first Sunday', '2025-09-13'),
          ],
      'sundays': sundays,
      'next': next ?? {'sundays': 25, 'remaining': 3},
    });

Future<void> _pump(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(1200, 2600);
  tester.view.devicePixelRatio = 1.5;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child))));
}

void main() {
  setUpAll(() => dotenv.loadFromString(envString: 'BASE_URL=https://api.example.org'));
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    Milestones.current.value = null;
  });

  test('reads the summary, what’s new, and the next Sunday count in words', () {
    final s = _summary();
    expect(s.earned, hasLength(5));
    expect(s.fresh.map((m) => m.key), ['SUNDAYS_10']);
    expect(s.nextLine, '3 more Sundays until 25.');
    expect(_summary(next: {'sundays': 25, 'remaining': 1}).nextLine, 'One more Sunday until 25.');
    expect(MilestoneSummary.fromJson({'earned': [], 'sundays': 0}).nextLine, isNull);
    expect(s.withCelebrated({'SUNDAYS_10'}).fresh, isEmpty);
  });

  test('a sermon heard to the end is passed on, once it’s close enough to the end', () async {
    final finished = <String>[];
    SermonProgress.onFinished = finished.add;
    addTearDown(() => SermonProgress.onFinished = null);
    const sermon = {'id': 7, 'title': 'Rooted'};
    await SermonProgress.record('7', sermon, const Duration(minutes: 10), const Duration(minutes: 40));
    expect(finished, isEmpty);
    await SermonProgress.record('7', sermon, const Duration(minutes: 39, seconds: 30), const Duration(minutes: 40));
    expect(finished, ['7']);
  });

  testWidgets('Home shows a new milestone until “Thank you” puts it away', (tester) async {
    await _pump(tester, const NewMilestoneCard());
    expect(find.text('10 Sundays'), findsNothing);

    Milestones.current.value = _summary();
    await tester.pump();
    expect(find.text('A MILESTONE'), findsOneWidget);
    expect(find.text('10 Sundays'), findsOneWidget);
    // Older ones never pop up.
    expect(find.text('A year with us'), findsNothing);

    await tester.tap(find.text('Thank you'));
    await tester.pump();
    expect(find.text('10 Sundays'), findsNothing);
  });

  testWidgets('the Me page shelf shows the latest three, the next count and the way to the rest', (tester) async {
    Milestones.current.value = _summary();
    await _pump(tester, const MilestonesShelf());

    expect(find.text('10 Sundays'), findsOneWidget);
    expect(find.text('A whole month of Sundays'), findsOneWidget);
    expect(find.text('Your first Sunday'), findsNothing);
    expect(find.text('3 more Sundays until 25.'), findsOneWidget);

    await tester.tap(find.text('See all 5'));
    await tester.pumpAndSettle();
    expect(find.text('Your first Sunday'), findsOneWidget);
    expect(find.text('Words for Your first Sunday.'), findsOneWidget);
  });

  testWidgets('before their first Sunday, the shelf says so kindly', (tester) async {
    Milestones.current.value = MilestoneSummary.fromJson({'earned': [], 'sundays': 0});
    await _pump(tester, const MilestonesShelf());
    expect(find.textContaining('Your first Sunday will be the first one here'), findsOneWidget);
    expect(find.textContaining('See all'), findsNothing);
  });

  testWidgets('the card after check-in shows the newest, and what else came with it', (tester) async {
    await _pump(
      tester,
      Builder(
        builder: (context) => TextButton(
          onPressed: () => MilestoneSheet.show(context, [
            Milestone.fromJson(_m('SUNDAYS_25', '25 Sundays', '2026-10-25', isNew: true)),
            Milestone.fromJson(_m('YEARS_1', 'A year with us', '2026-10-25', isNew: true)),
          ]),
          child: const Text('open'),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('25 Sundays'), findsOneWidget);
    expect(find.text('And: A year with us'), findsOneWidget);
    await tester.tap(find.text('Thank you'));
    await tester.pumpAndSettle();
    expect(find.text('25 Sundays'), findsNothing);
  });

  test('dates read like a person would say them', () {
    final now = DateTime(2026, 10, 30);
    expect(milestoneDate(DateTime(2026, 10, 25), now: now), 'Sunday, October 25');
    expect(milestoneDate(DateTime(2025, 9, 14), now: now), 'September 14, 2025');
  });
}
