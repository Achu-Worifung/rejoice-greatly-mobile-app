import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'firebase_options.dart';
import 'routes.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'pages/RootPage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await dotenv.load(fileName: ".env");
  String appId = dotenv.env['ONESIGNAL_APP_ID'] ?? '';
  if (appId.isEmpty) {
    print("Warning: ONESIGNAL_APP_ID is not set in .env file.");
  } else {
    OneSignal.initialize(appId);
    OneSignal.Notifications.requestPermission(true);
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rejoice Greatly PHX',
      initialRoute: '/', // start at RootPage
      routes: {'/': (context) => const RootPage(), ...AppRoutes.getRoutes()},
      debugShowCheckedModeBanner: false,
    );
  }
}
