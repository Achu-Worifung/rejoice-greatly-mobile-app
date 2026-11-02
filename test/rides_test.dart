import 'package:church_app/pages/rides_page.dart';
import 'package:church_app/services/rides_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _sun1 = DateTime(2026, 11, 1);
final _sun2 = DateTime(2026, 11, 8);

RidesOverview _overview(List<Map<String, dynamic>> rides) => RidesOverview.fromJson({
      'rides': rides,
      'sundays': ['2026-11-01', '2026-11-08', '2026-11-15'],
    });

Driving _driving({List<Map<String, dynamic>> riders = const [], List<String> available = const []}) =>
    Driving.fromJson({
      'driving': {
        'approved': true,
        'seats': 4,
        'car': 'Silver Honda Odyssey',
        'phone': '(480) 555-0141',
        'address': 'E Broadway Rd, Mesa',
        'located': true,
        'availableOn': available,
        'riders': riders,
      },
      'sundays': ['2026-11-01', '2026-11-08'],
    });

void main() {
  setUpAll(() => dotenv.loadFromString(envString: 'BASE_URL=https://api.example.org'));
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> pump(WidgetTester tester, Widget page) async {
    tester.view.physicalSize = const Size(1200, 2800);
    tester.view.devicePixelRatio = 1.5;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(home: page));
    await tester.pumpAndSettle();
  }

  group('models', () {
    test('Sundays already asked for are not offered again', () {
      final o = _overview([
        {'id': 'r1', 'date': '2026-11-01', 'label': 'Sunday service', 'seats': 2, 'status': 'OPEN'},
      ]);
      expect(o.rides.single.arranged, isFalse);
      expect(o.openSundays.map((d) => d.day), [8, 15]);
    });

    test('a pinned rider gets directions to the pin, else to the address', () {
      final pinned = RideRider(requestId: 'r', date: _sun1, label: 'x', name: 'Esther', seats: 1, lat: 33.4, lng: -111.8);
      expect(pinned.directions.toString(), contains('destination=33.4%2C-111.8'));
      final typed = RideRider(requestId: 'r', date: _sun1, label: 'x', name: 'Esther', seats: 1, address: '1200 E Southern Ave');
      expect(typed.directions.toString(), contains('destination=1200+E+Southern+Ave'));
      final nothing = RideRider(requestId: 'r', date: _sun1, label: 'x', name: 'Esther', seats: 1);
      expect(nothing.directions, isNull);
    });

    test('a driver needs a start point and a phone to be suggested', () {
      expect(_driving().ready, isTrue);
      expect(Driving.none.approved, isFalse);
      expect(_driving(available: ['2026-11-08']).canDriveOn(_sun2), isTrue);
      expect(_driving(available: ['2026-11-08']).canDriveOn(_sun1), isFalse);
    });
  });

  testWidgets('shows a waiting ride and an arranged one, with the driver to call', (tester) async {
    await pump(
      tester,
      RidesPage(
        load: () async => _overview([
          {'id': 'r1', 'date': '2026-11-01', 'label': 'Sunday service', 'seats': 2, 'status': 'OPEN'},
          {
            'id': 'r2',
            'date': '2026-11-08',
            'label': 'Sunday service',
            'seats': 1,
            'status': 'ASSIGNED',
            'driver': {'name': 'Kwame Mensah', 'car': 'Silver Honda Odyssey', 'phone': '(480) 555-0141'},
          },
        ]),
        loadDriving: () async => Driving.none,
      ),
    );
    expect(find.text('Finding you a driver'), findsOneWidget);
    expect(find.text('Kwame Mensah is picking you up'), findsOneWidget);
    expect(find.text('Call Kwame'), findsOneWidget);
    expect(find.text('Ask for another Sunday'), findsOneWidget);
    expect(find.text('You’re on the driving team'), findsNothing);
  });

  testWidgets('cancelling asks first, then cancels', (tester) async {
    String? cancelled;
    await pump(
      tester,
      RidesPage(
        load: () async => _overview([
          {'id': 'r1', 'date': '2026-11-01', 'label': 'Sunday service', 'seats': 1, 'status': 'OPEN'},
        ]),
        loadDriving: () async => Driving.none,
        cancel: (id) async => cancelled = id,
      ),
    );
    await tester.tap(find.text('I don’t need it anymore'));
    await tester.pumpAndSettle();
    expect(find.text('Cancel this ride?'), findsOneWidget);
    await tester.tap(find.text('Cancel ride'));
    await tester.pumpAndSettle();
    expect(cancelled, 'r1');
  });

  testWidgets('approved drivers see the driving team row', (tester) async {
    await pump(
      tester,
      RidesPage(
        load: () async => _overview(const []),
        loadDriving: () async => _driving(riders: [
          {'requestId': 'r1', 'date': '2026-11-01', 'label': 'Sunday service', 'name': 'Esther Adjei', 'seats': 2},
        ]),
      ),
    );
    expect(find.text('You’re on the driving team'), findsOneWidget);
    expect(find.text('You’re picking up 1 person.'), findsOneWidget);
  });

  testWidgets('asking needs an address and a phone, then sends the pickup', (tester) async {
    (DateTime, int, RidePlace, String?)? sent;
    await pump(
      tester,
      RideRequestPage(
        sundays: [_sun1, _sun2],
        submit: (d, s, p, n) async => sent = (d, s, p, n),
      ),
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Ask for a ride'));
    await tester.pumpAndSettle();
    expect(find.text('Add the address to pick you up from.'), findsOneWidget);
    expect(sent, isNull);

    await tester.tap(find.byType(ChoiceChip).at(1));
    await tester.tap(find.byTooltip('More'));
    await tester.enterText(find.widgetWithText(TextField, 'Pickup address'), '1200 E Southern Ave, Mesa');
    await tester.enterText(find.widgetWithText(TextField, 'Phone'), '(480) 555-0177');
    await tester.enterText(find.widgetWithText(TextField, 'Anything your driver should know? (optional)'), 'Walker');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Ask for a ride'));
    await tester.pumpAndSettle();

    expect(sent, isNotNull);
    expect(sent!.$1, _sun2);
    expect(sent!.$2, 2);
    expect(sent!.$3.toJson(), {'address': '1200 E Southern Ave, Mesa', 'phone': '(480) 555-0177'});
    expect(sent!.$4, 'Walker');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('rides.lastAddress'), '1200 E Southern Ave, Mesa');
  });

  testWidgets('a driver sees who they pick up and says which Sundays they can drive', (tester) async {
    final toggled = <DateTime, bool>{};
    await pump(
      tester,
      DrivingPage(
        load: () async => _driving(riders: [
          {
            'requestId': 'r1',
            'date': '2026-11-01',
            'label': 'Sunday service',
            'name': 'Esther Adjei',
            'seats': 2,
            'note': 'Walker fits in the boot.',
            'address': '1200 E Southern Ave, Mesa',
            'lat': 33.39,
            'lng': -111.8,
            'phone': '(480) 555-0177',
          },
        ]),
        setAvailable: (d, v) async {
          toggled[d] = v;
          return _driving(available: v ? ['2026-11-08'] : []);
        },
      ),
    );
    expect(find.text('Esther Adjei · 2 seats'), findsOneWidget);
    expect(find.text('Directions'), findsOneWidget);
    expect(find.text('Call Esther'), findsOneWidget);
    expect(find.text('Silver Honda Odyssey'), findsOneWidget);

    final second = find.byType(SwitchListTile).at(1);
    await tester.ensureVisible(second);
    await tester.tap(second);
    await tester.pumpAndSettle();
    expect(toggled, {_sun2: true});
    expect(tester.widget<SwitchListTile>(find.byType(SwitchListTile).at(1)).value, isTrue);
  });
}

