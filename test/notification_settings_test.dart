import 'package:church_app/pages/notification_settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

NotificationSetting _s(String type, String label, {bool on = true}) =>
    NotificationSetting(type: type, label: label, description: 'About $label.', enabled: on);

void main() {
  setUpAll(() => dotenv.loadFromString(envString: 'BASE_URL=https://api.example.org'));

  Future<void> pump(WidgetTester tester, NotificationSettingsPage page) async {
    tester.view.physicalSize = const Size(1200, 2600);
    tester.view.devicePixelRatio = 1.5;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(home: page));
    await tester.pumpAndSettle();
  }

  testWidgets('turning a kind off saves it, and says it still reaches the inbox', (tester) async {
    final saved = <String, bool>{};
    await pump(
      tester,
      NotificationSettingsPage(
        load: () async => [_s('event', 'Events and reminders'), _s('birthday', 'Birthdays')],
        update: (type, enabled) async {
          saved[type] = enabled;
          return [_s('event', 'Events and reminders'), _s('birthday', 'Birthdays', on: enabled)];
        },
        phoneAllows: () async => true,
      ),
    );

    expect(find.textContaining('still shows up in your inbox'), findsOneWidget);
    expect(find.text('Notifications are off on this phone'), findsNothing);
    await tester.tap(find.text('Birthdays'));
    await tester.pumpAndSettle();
    expect(saved, {'birthday': false});
    final birthday = tester.widget<SwitchListTile>(find.widgetWithText(SwitchListTile, 'Birthdays'));
    expect(birthday.value, isFalse);
  });

  testWidgets('a failed save puts the switch back', (tester) async {
    await pump(
      tester,
      NotificationSettingsPage(
        load: () async => [_s('prayer', 'Prayer wall')],
        update: (_, _) async => throw Exception('offline'),
        phoneAllows: () async => true,
      ),
    );
    await tester.tap(find.text('Prayer wall'));
    await tester.pumpAndSettle();
    expect(tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value, isTrue);
    expect(find.textContaining('Couldn’t save that'), findsOneWidget);
  });

  testWidgets('says so when the phone itself has notifications off', (tester) async {
    await pump(
      tester,
      NotificationSettingsPage(
        load: () async => [_s('event', 'Events and reminders')],
        update: (_, _) async => [],
        phoneAllows: () async => false,
      ),
    );
    expect(find.text('Notifications are off on this phone'), findsOneWidget);
    expect(find.text('Turn them on'), findsOneWidget);
  });
}
