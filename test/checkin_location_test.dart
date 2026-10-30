import 'package:church_app/services/checkin_location.dart';
import 'package:church_app/services/nfc_checkin_service.dart';
import 'package:church_app/widgets/checkin_location_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A phone whose location answers are scripted.
class _Phone extends CheckinLocation {
  _Phone(this._access, {this.position});

  LocationAccess _access;
  final CheckinPosition? position;
  int asked = 0;
  int settingsOpened = 0;

  @override
  Future<LocationAccess> access() async => _access;

  @override
  Future<LocationAccess> request() async {
    asked++;
    return _access = LocationAccess.granted;
  }

  @override
  Future<CheckinPosition?> current() async => position;

  @override
  Future<void> openSettings(LocationAccess access) async => settingsOpened++;
}

/// The church server: wants a location until it gets one.
class _Server {
  _Server({this.needsPlace = true});

  final bool needsPlace;
  final List<CheckinPosition?> received = [];

  Future<NfcCheckinResult> submit(String tagId, {CheckinPosition? position}) async {
    received.add(position);
    if (needsPlace && position == null) {
      return NfcCheckinResult.failure(NfcCheckinErrorKind.needsLocation, 'needs location');
    }
    return NfcCheckinResult.ok(message: 'Marked present for today.', alreadyPresent: false);
  }
}

const _atChurch = CheckinPosition(33.4152, -111.8315, 18);

void main() {
  late BuildContext context;

  Future<void> host(WidgetTester tester) => tester.pumpWidget(MaterialApp(
        home: Builder(builder: (c) {
          context = c;
          return const Scaffold();
        }),
      ));

  testWidgets('a tag without a place never asks for location', (tester) async {
    await host(tester);
    final server = _Server(needsPlace: false);
    final phone = _Phone(LocationAccess.canAsk);

    final result = await checkInAtTag(context, 'entrance', submit: server.submit, location: phone);

    expect(result.success, isTrue);
    expect(server.received, [null]);
    expect(phone.asked, 0);
  });

  testWidgets('once location is allowed, a tag that needs it just takes it', (tester) async {
    await host(tester);
    final server = _Server();
    final phone = _Phone(LocationAccess.granted, position: _atChurch);

    final result = await checkInAtTag(context, 'entrance', submit: server.submit, location: phone);

    expect(result.success, isTrue);
    expect(server.received, [null, _atChurch]);
    expect(find.text('One more step'), findsNothing);
  });

  testWidgets('the first time, it explains before the system asks', (tester) async {
    await host(tester);
    final server = _Server();
    final phone = _Phone(LocationAccess.canAsk, position: _atChurch);

    final pending = checkInAtTag(context, 'entrance', submit: server.submit, location: phone);
    await tester.pumpAndSettle();
    expect(find.text('One more step'), findsOneWidget);
    expect(find.textContaining('We keep only how far you were'), findsOneWidget);

    await tester.tap(find.text('Share my location'));
    await tester.pumpAndSettle();
    final result = await pending;

    expect(phone.asked, 1);
    expect(result.success, isTrue);
    expect(server.received.last, _atChurch);
  });

  testWidgets('"Not now" checks nobody in and points to the welcome desk', (tester) async {
    await host(tester);
    final server = _Server();
    final phone = _Phone(LocationAccess.canAsk, position: _atChurch);

    final pending = checkInAtTag(context, 'entrance', submit: server.submit, location: phone);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();
    final result = await pending;

    expect(result.success, isFalse);
    expect(result.errorKind, NfcCheckinErrorKind.needsLocation);
    expect(result.message, contains('welcome desk'));
    expect(server.received, [null]);
    expect(phone.asked, 0);
  });

  testWidgets('location turned off for the app sends them to Settings', (tester) async {
    await host(tester);
    final server = _Server();
    final phone = _Phone(LocationAccess.blocked);

    final pending = checkInAtTag(context, 'entrance', submit: server.submit, location: phone);
    await tester.pumpAndSettle();
    expect(find.text('Location is turned off for Rejoice Greatly.'), findsOneWidget);
    await tester.tap(find.text('Open Settings'));
    await tester.pumpAndSettle();
    final result = await pending;

    expect(phone.settingsOpened, 1);
    expect(result.message, contains('tap the tag again'));
    expect(server.received, [null]);
  });

  testWidgets('a phone that can’t find itself says so instead of guessing', (tester) async {
    await host(tester);
    final server = _Server();
    final phone = _Phone(LocationAccess.granted);

    final result = await checkInAtTag(context, 'entrance', submit: server.submit, location: phone);

    expect(result.success, isFalse);
    expect(result.message, contains('couldn’t find where it is'));
    expect(server.received, [null]);
  });

  test('only the position and its accuracy are sent', () {
    expect(_atChurch.toJson(), {'latitude': 33.4152, 'longitude': -111.8315, 'accuracyMeters': 18.0});
    expect(const CheckinPosition(1, 2, null).toJson(), {'latitude': 1.0, 'longitude': 2.0});
  });
}
