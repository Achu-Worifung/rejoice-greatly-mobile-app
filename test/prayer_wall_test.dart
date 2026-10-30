import 'package:church_app/services/prayer_wall_api.dart';
import 'package:church_app/widgets/prayer_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _json({
  bool mine = false,
  bool prayed = false,
  int prayers = 3,
  String? answeredAt,
  String visibility = 'CHURCH',
}) =>
    {
      'id': 'p1',
      'body': 'Pray for my mother’s surgery on Friday.',
      'authorName': 'Ada L.',
      'anonymous': false,
      'mine': mine,
      'visibility': visibility,
      'createdAt': DateTime.now().subtract(const Duration(hours: 2)).toUtc().toIso8601String(),
      'answeredAt': answeredAt,
      'answeredNote': answeredAt == null ? null : 'Surgery went well!',
      'prayerCount': prayers,
      'prayedByMe': prayed,
      'commentCount': 1,
      'hidden': false,
    };

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child)));

void main() {
  group('PrayerRequestItem', () {
    test('parses the backend shape', () {
      final p = PrayerRequestItem.fromJson(_json(visibility: 'PASTORS'));
      expect(p.id, 'p1');
      expect(p.authorName, 'Ada L.');
      expect(p.visibility, PrayerVisibility.pastors);
      expect(p.prayerCount, 3);
      expect(p.answered, isFalse);
    });

    test('withPrayed adjusts the count once, and never below zero', () {
      final p = PrayerRequestItem.fromJson(_json(prayers: 0));
      final prayed = p.withPrayed(true);
      expect(prayed.prayedByMe, isTrue);
      expect(prayed.prayerCount, 1);
      expect(prayed.withPrayed(true).prayerCount, 1);
      expect(prayed.withPrayed(false).prayerCount, 0);
    });

    test('a thread tolerates a missing comment list', () {
      final t = PrayerThread.fromJson({'prayer': _json(), 'canComment': true});
      expect(t.replies, isEmpty);
      expect(t.canReply, isTrue);
    });
  });

  group('PrayerCard', () {
    testWidgets('shows who, the request, and how many are praying', (tester) async {
      await tester.pumpWidget(_host(PrayerCard(
        prayer: PrayerRequestItem.fromJson(_json()),
        onPrayed: (_) {},
        onAction: (_) {},
        onOpen: () {},
      )));
      expect(find.text('Ada L.'), findsOneWidget);
      expect(find.textContaining('surgery on Friday'), findsOneWidget);
      expect(find.text('Pray'), findsOneWidget);
      expect(find.text('3 praying'), findsOneWidget);
      expect(find.text('1 reply'), findsOneWidget);
    });

    testWidgets('tapping Pray asks for the opposite state', (tester) async {
      bool? asked;
      await tester.pumpWidget(_host(PrayerCard(
        prayer: PrayerRequestItem.fromJson(_json(prayed: true)),
        onPrayed: (v) => asked = v,
        onAction: (_) {},
      )));
      expect(find.text('Prayed'), findsOneWidget);
      await tester.tap(find.text('Prayed'));
      expect(asked, isFalse);
    });

    testWidgets('answered requests carry the praise report', (tester) async {
      await tester.pumpWidget(_host(PrayerCard(
        prayer: PrayerRequestItem.fromJson(_json(mine: true, answeredAt: DateTime.now().toIso8601String())),
        onPrayed: (_) {},
        onAction: (_) {},
      )));
      expect(find.text('You'), findsOneWidget);
      expect(find.text('ANSWERED'), findsOneWidget);
      expect(find.text('Surgery went well!'), findsOneWidget);
    });

    testWidgets('the menu offers report on others’ requests, and answered/delete on your own',
        (tester) async {
      final actions = <PrayerAction>[];
      await tester.pumpWidget(_host(PrayerCard(
        prayer: PrayerRequestItem.fromJson(_json()),
        onPrayed: (_) {},
        onAction: actions.add,
      )));
      await tester.tap(find.byTooltip('More options'));
      await tester.pumpAndSettle();
      expect(find.text('Mark as answered'), findsNothing);
      await tester.tap(find.text('Report'));
      await tester.pumpAndSettle();
      expect(actions, [PrayerAction.report]);

      await tester.pumpWidget(_host(PrayerCard(
        prayer: PrayerRequestItem.fromJson(_json(mine: true)),
        onPrayed: (_) {},
        onAction: actions.add,
      )));
      await tester.tap(find.byTooltip('More options'));
      await tester.pumpAndSettle();
      expect(find.text('Report'), findsNothing);
      expect(find.text('Mark as answered'), findsOneWidget);
      expect(find.text('Delete request'), findsOneWidget);
    });
  });
}
