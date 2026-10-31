import 'package:church_app/pages/year_review_page.dart';
import 'package:church_app/services/year_review.dart';
import 'package:church_app/widgets/year_review_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

YearReview _full() => YearReview.fromJson({
      'year': 2026, 'available': true, 'firstYear': true, 'sundays': 38, 'fullestMonth': 'April',
      'bacentaMeetings': 21, 'sermonsHeard': 14, 'favouriteSeries': 'Rooted', 'prayedForOthers': 61,
      'prayersForThem': 34, 'requestsShared': 3, 'requestsAnswered': 2,
      'milestones': [
        {'key': 'SUNDAYS_25', 'title': '25 Sundays', 'message': '', 'earnedOn': '2026-09-13'},
      ],
    });

void main() {
  setUpAll(() => dotenv.loadFromString(envString: 'BASE_URL=https://api.example.org'));
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('offered in December and January only', () {
    expect(YearReviews.inSeason(DateTime(2026, 12, 3)), isTrue);
    expect(YearReviews.inSeason(DateTime(2027, 1, 30)), isTrue);
    expect(YearReviews.inSeason(DateTime(2026, 11, 2)), isFalse);
  });

  test('pages only for what they did, and a thank-you', () {
    final full = yearSlides(_full());
    expect(full.map((s) => s.title), [
      'Your year at Rejoice Greatly',
      'Sundays together',
      'bacenta meetings',
      'sermons heard to the end',
      'times you prayed for someone',
      'Milestones this year',
      'Thank you for a beautiful year.',
    ]);
    expect(full[1].lines, ['Your first year with us. Welcome home.', 'You were with us most in April.']);
    expect(full[4].lines, ['And your church prayed for you 34 times.', '2 of your requests were answered.']);

    // Only prayed for: no empty Sundays or sermons pages, no "you missed".
    final quiet = yearSlides(YearReview.fromJson({'year': 2026, 'prayersForThem': 1}));
    expect(quiet.map((s) => s.title),
        ['Your year at Rejoice Greatly', 'time your church prayed for you', 'Thank you for a beautiful year.']);
  });

  test('sharing says only their own numbers', () {
    expect(_full().shareText,
        'My 2026 at Rejoice Greatly: 38 Sundays together, 14 sermons heard, 61 prayers for others. Thankful for this church family.');
  });

  testWidgets('tapping goes on through the year, then closes', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => YearReviewPage(review: _full()))),
          child: const Text('open'),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Your year at Rejoice Greatly'), findsOneWidget);
    await tester.tapAt(const Offset(300, 400));
    await tester.pumpAndSettle();
    expect(find.text('38'), findsOneWidget);
    expect(find.text('Sundays together'), findsOneWidget);
    for (var i = 0; i < 6; i++) {
      await tester.tapAt(const Offset(300, 400));
      await tester.pumpAndSettle();
    }
    expect(find.text('open'), findsOneWidget); // closed after the last page
    expect(await YearReviews.seen(2026), isTrue);
  });

  testWidgets('the Home card shows in season until seen, and never out of it', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: YearReviewCard(now: DateTime(2026, 11, 2), load: () async => _full())),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Your year at Rejoice Greatly'), findsNothing);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: YearReviewCard(key: UniqueKey(), now: DateTime(2026, 12, 2), load: () async => _full())),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Your year at Rejoice Greatly'), findsOneWidget);

    await YearReviews.markSeen(2026);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: YearReviewCard(key: UniqueKey(), now: DateTime(2026, 12, 2), load: () async => _full())),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Your year at Rejoice Greatly'), findsNothing);
  });
}
