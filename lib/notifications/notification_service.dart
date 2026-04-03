import 'package:onesignal_flutter/onesignal_flutter.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Initialize OneSignal
  Future<void> initialize() async {
    // Set log level for debugging
    OneSignal.Debug.setLogLevel(OSLogLevel.verbose);

    // Initialize with App ID
    OneSignal.initialize("YOUR_ONESIGNAL_APP_ID");

    // Request permission
    await OneSignal.Notifications.requestPermission(true);

    // Set up listeners
    _setupListeners();
  }

  // Setup notification listeners
  void _setupListeners() {
    // Notification received (foreground)
    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      print('Notification received in foreground: ${event.notification.body}');
      // You can prevent the notification from displaying
      // event.preventDefault();

      // Or display it
      event.notification.display();
    });

    // Notification clicked
    OneSignal.Notifications.addClickListener((event) {
      print('Notification clicked: ${event.notification.body}');
      print('Additional data: ${event.notification.additionalData}');

      // Handle navigation based on notification data
      _handleNotificationClick(event.notification);
    });

    // Permission changed
    OneSignal.Notifications.addPermissionObserver((state) {
      print("Notification permission state changed: $state");
    });

    // Subscription changed
    OneSignal.User.pushSubscription.addObserver((state) {
      print(
        "Push subscription state changed: ${state.current.jsonRepresentation()}",
      );
    });
  }

  // Handle notification click
  void _handleNotificationClick(OSNotification notification) {
    final data = notification.additionalData;

    if (data != null) {
      // Navigate based on custom data
      if (data.containsKey('page')) {
        // Navigate to specific page
        print('Navigate to: ${data['page']}');
      }
    }
  }

  // Get Player/User ID
  String? getPlayerId() {
    return OneSignal.User.pushSubscription.id;
  }

  // Get External User ID
  String? getExternalUserId() {
    return OneSignal.User.pushSubscription.id;
  }

  // Set External User ID (link to your backend user)
  Future<void> setExternalUserId(String externalId) async {
    await OneSignal.login(externalId);
  }

  // Remove External User ID (logout)
  Future<void> removeExternalUserId() async {
    await OneSignal.logout();
  }

  // Send tags (user properties)
  Future<void> sendTags(Map<String, dynamic> tags) async {
    await OneSignal.User.addTags(tags);
  }

  // Remove tags
  Future<void> removeTags(List<String> keys) async {
    await OneSignal.User.removeTags(keys);
  }

  // Get tags
  Future<Map<String, dynamic>> getTags() async {
    return await OneSignal.User.getTags();
  }

  // Set language
  void setLanguage(String language) {
    OneSignal.User.setLanguage(language);
  }

  // Opt in/out of push notifications
  Future<void> optIn() async {
    await OneSignal.User.pushSubscription.optIn();
  }

  Future<void> optOut() async {
    await OneSignal.User.pushSubscription.optOut();
  }

  // Check if user is subscribed
  bool isSubscribed() {
    return OneSignal.User.pushSubscription.optedIn ?? false;
  }

  // Check notification permission
  bool hasPermission() {
    return OneSignal.Notifications.permission;
  }

  // Request permission (iOS primarily)
  Future<bool> requestPermission() async {
    return await OneSignal.Notifications.requestPermission(true);
  }
}
