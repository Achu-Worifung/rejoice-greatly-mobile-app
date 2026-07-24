import 'package:church_app/pages/user_prep.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpAt(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: UserPrepPage()));
    await tester.pump();
  }

  testWidgets('the eligibility notice is shown before the camera step', (
    tester,
  ) async {
    await pumpAt(tester, const Size(390, 844));

    expect(find.text('Facial recognition eligibility'), findsOneWidget);
    expect(
      find.textContaining('participating church locations'),
      findsWidgets,
    );
    // The release the member ticks must carry the representation too.
    expect(find.textContaining('I attend a participating church location'),
        findsOneWidget);
  });

  testWidgets('the screen does not overflow on a short device', (tester) async {
    // A 320x568-class screen: the notice and release make the bottom bar tall,
    // so the slides above must scroll rather than overflow.
    await pumpAt(tester, const Size(320, 568));

    expect(tester.takeException(), isNull);
    expect(find.text('Facial recognition eligibility'), findsOneWidget);
  });
}
