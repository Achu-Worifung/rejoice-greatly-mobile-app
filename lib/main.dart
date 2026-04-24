import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
// import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'firebase_options.dart';
import 'routes.dart';
// import 'package:firebase_auth/firebase_auth.dart';
import 'pages/RootPage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'notifications/notification_service.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await dotenv.load(fileName: ".env");
  // await NotificationService().initialize();

  runApp(const MyApp());
}

// 1. Create a global navigator key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rejoice Greatly PHX',
      navigatorKey: navigatorKey, 
      initialRoute: '/',
      routes: {
        '/': (context) => const RootPage(),
        ...AppRoutes.getRoutes(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
  

