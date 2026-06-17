import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'routes.dart';
import 'pages/RootPage.dart';
import 'theme/church_colors.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'notifications/notification_service.dart';
import 'services/user_session_store.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    try {
      await dotenv.load(fileName: '.env');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('dotenv load failed (using defaults): $e');
      }
    }

    await UserSessionStore.initialize();

    // Registers this device with OneSignal so backend push/email reminders
    // are actually delivered. Not awaited: the OS permission prompt must not
    // block app startup.
    NotificationService().initialize();

    runApp(const MyApp());
  } catch (e, st) {
    if (kDebugMode) {
      debugPrint('App startup failed: $e\n$st');
    }
    runApp(StartupErrorApp(message: e.toString()));
  }
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rejoice Greatly',
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

class StartupErrorApp extends StatelessWidget {
  const StartupErrorApp({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: ChurchColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: ChurchColors.muted),
                const SizedBox(height: 16),
                const Text(
                  'Could not start the app',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: ChurchColors.bodyText,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: ChurchColors.muted, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
