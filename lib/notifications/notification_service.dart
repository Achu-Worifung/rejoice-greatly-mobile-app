import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

/// Wires up the OneSignal SDK so this device registers a push subscription
/// and can receive the notifications the backend sends/schedules via the
/// OneSignal REST API.
///
/// Without [initialize] running at startup, the device never subscribes and
/// every send (including to the "All" segment) reaches nobody.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  bool _initialized = false;

  /// onesignal_flutter has no web implementation; all calls must be skipped
  /// on web or they throw MissingPluginException.
  bool get isSupported => !kIsWeb;

  Future<void> initialize() async {
    if (!isSupported || _initialized) return;

    final appId = dotenv.env['ONESIGNAL_APP_ID'] ?? '';
    if (appId.isEmpty) {
      debugPrint(
          'NotificationService: ONESIGNAL_APP_ID missing from .env; push disabled');
      return;
    }

    try {
      OneSignal.initialize(appId);

      // Show notifications while the app is in the foreground too.
      OneSignal.Notifications.addForegroundWillDisplayListener((event) {
        event.notification.display();
      });

      await OneSignal.Notifications.requestPermission(true);
      _initialized = true;
      debugPrint('NotificationService: OneSignal initialized');
    } catch (e) {
      debugPrint('NotificationService: init failed: $e');
    }
  }

  /// Ties this device's subscription to the signed-in user so audience
  /// targeting by external id works. Also registers the user's email so
  /// "send email" reminders have a subscription to deliver to.
  Future<void> login(String externalId, {String? email}) async {
    if (!isSupported || externalId.isEmpty) return;
    try {
      await OneSignal.login(externalId);
      if (email != null && email.isNotEmpty) {
        OneSignal.User.addEmail(email);
      }
    } catch (e) {
      debugPrint('NotificationService: OneSignal login failed: $e');
    }
  }

  Future<void> logout() async {
    if (!isSupported) return;
    try {
      await OneSignal.logout();
    } catch (e) {
      debugPrint('NotificationService: OneSignal logout failed: $e');
    }
  }
}
