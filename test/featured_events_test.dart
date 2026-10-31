import 'package:church_app/services/member_events.dart';
import 'package:church_app/widgets/featured_events_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _e(String id, String title, {String date = '2026-11-14', String time = '7:00 PM'}) =>
    {'id': id, 'title': title, 'date': date, 'time': time, 'imageUrl': null};

void main() {
  setUpAll(() => dotenv.loadFromString(envString: 'BASE_URL=https://api.example.org'));

  test('the feed’s featured ids pick events out, in order, skipping any not listed', () {
    final events = [_e('a', 'Revival'), _e('b', 'Prayer night'), _e('c', 'Picnic')];
    expect(MemberEventsFeed.pickFeatured(events, ['c', 'zz', 'a']).map((e) => e['title']), ['Picnic', 'Revival']);
    expect(MemberEventsFeed.pickFeatured(events, null), isEmpty);
  });

  test('when, in a few words', () {
    expect(featuredEventWhen(_e('a', 'x')), 'Sat, Nov 14 · 7:00 PM');
    expect(featuredEventWhen({'date': '2026-11-14', 'time': ''}), 'Sat, Nov 14');
  });

  Future<void> pump(WidgetTester tester, List<Map<String, dynamic>> events, {bool still = false}) async {
    tester.view.physicalSize = const Size(1170, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: const Size(390, 800), disableAnimations: still),
        child: Scaffold(body: SingleChildScrollView(child: FeaturedEventsBanner(events: events, turnEvery: const Duration(seconds: 2)))),
      ),
    ));
  }

  testWidgets('nothing featured, nothing shown', (tester) async {
    await pump(tester, const []);
    expect(find.text('Coming up'), findsNothing);
  });

  testWidgets('several featured turn over on their own', (tester) async {
    await pump(tester, [_e('a', 'Revival'), _e('b', 'Prayer night')]);
    expect(find.text('COMING UP'), findsOneWidget);
    expect(find.text('Revival'), findsWidgets);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('Prayer night'), findsWidgets);
  });

  testWidgets('with reduced motion they stay put', (tester) async {
    await pump(tester, [_e('a', 'Revival'), _e('b', 'Prayer night')], still: true);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    final page = tester.state<State<PageView>>(find.byType(PageView));
    expect((page.widget).controller!.page, 0);
  });
}
