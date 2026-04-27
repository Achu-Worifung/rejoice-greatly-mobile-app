import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
// import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'firebase_options.dart';
import 'routes.dart';
// import 'package:firebase_auth/firebase_auth.dart';
import 'pages/RootPage.dart';
import 'theme/church_colors.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_web/webview_flutter_web.dart';
// import 'notifications/notification_service.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  WebViewPlatform.instance = WebWebViewPlatform();
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
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: ChurchColors.button,
          brightness: Brightness.light,
          primary: ChurchColors.button,
        ),
        scaffoldBackgroundColor: ChurchColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: ChurchColors.background,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: ChurchColors.bodyText,
            fontSize: 17,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
          iconTheme: IconThemeData(color: ChurchColors.accent, size: 24),
        ),
      ),
      routes: {
        '/': (context) => const RootPage(),
        ...AppRoutes.getRoutes(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
  

