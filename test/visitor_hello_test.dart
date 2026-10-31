import 'package:church_app/pages/visitor_hello_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() => dotenv.loadFromString(envString: 'BASE_URL=https://api.example.org'));

  testWidgets('asks for a name, and a way to reach them when they want to be reached', (tester) async {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1.5;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: VisitorHelloPage()));

    await tester.tap(find.text('Say hello'));
    await tester.pump();
    expect(find.text('Please tell us your name.'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'Your name'), 'Ama Owusu');
    await tester.tap(find.text('Say hello'));
    await tester.pump();
    expect(find.textContaining('Leave a phone number or email'), findsOneWidget);
  });
}
