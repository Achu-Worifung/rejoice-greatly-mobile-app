import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'routes.dart';
import 'pages/splash_screen.dart';
import 'theme/church_colors.dart';
import 'theme/church_theme.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'notifications/notification_service.dart';
import 'services/user_session_store.dart';
import 'services/nfc_deep_link_service.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'services/user_facing_error.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Background audio, Firebase and the .env bundle don't depend on one
    // another, so start them together rather than paying for each in turn
    // on every cold start.
    await Future.wait([
      _initBackgroundAudio(),
      if (Firebase.apps.isEmpty)
        Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
      _loadEnv(),
    ]);

    await UserSessionStore.initialize();

    // Registers this device with OneSignal so backend push/email reminders
    // are actually delivered. Not awaited: the OS permission prompt must not
    // block app startup.
    NotificationService().initialize();

    runApp(const MyApp());

    // Cold-start NFC tag taps arrive as an app link — the plugin re-sends
    // the initial link once Dart subscribes, so this one listener covers
    // both cold start and the app already being open.
    NfcDeepLinkService.startListening();
  } catch (e, st) {
    if (kDebugMode) {
      debugPrint('App startup failed: $e\n$st');
    }
    runApp(StartupErrorApp(message: userFacingError(e)));
  }
}

/// Hands sermon playback to the OS media session: audio continues with the
/// app backgrounded or the screen locked, and play/pause show up on the lock
/// screen, in the notification shade and in Control Center. Must finish before
/// the first AudioPlayer is created (ChurchAudioPlayer is lazy, and main awaits
/// this before runApp, so that holds), and never blocks startup if the
/// platform channel is unavailable — playback then just falls back to
/// foreground-only.
Future<void> _initBackgroundAudio() async {
  if (kIsWeb) return;
  try {
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.rejoicegreatly.app.audio',
      androidNotificationChannelName: 'Sermon audio',
      androidNotificationChannelDescription:
          'Playback controls for the sermon you are listening to.',
      androidNotificationIcon: 'mipmap/ic_launcher',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
      notificationColor: ChurchColors.button,
    );
  } catch (e) {
    if (kDebugMode) {
      debugPrint('Background audio init failed: $e');
    }
  }
}

Future<void> _loadEnv() async {
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    if (kDebugMode) {
      debugPrint('dotenv load failed (using defaults): $e');
    }
  }
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// App-wide messenger so banners (e.g. the NFC check-in confirmation, and
/// foreground attendance pushes) can be shown from outside the widget tree —
/// notably from the OneSignal foreground listener.
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rejoice Greatly',
      navigatorKey: navigatorKey,
      scaffoldMessengerKey: scaffoldMessengerKey,
      initialRoute: '/',
      theme: buildChurchTheme(),
      routes: {
        '/': (context) => const SplashScreen(),
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
                const Icon(
                  Icons.error_outline,
                  size: 48,
                  color: ChurchColors.muted,
                ),
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
                  style: const TextStyle(
                    color: ChurchColors.muted,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
