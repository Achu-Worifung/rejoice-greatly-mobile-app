// import 'package:onesignal_flutter/onesignal_flutter.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';

// class NotificationService {
//   static final NotificationService _instance = NotificationService._internal();
//   factory NotificationService() => _instance;
//   NotificationService._internal();

//   String get appId => dotenv.env['ONESIGNAL_APP_ID'] ?? '';

//   Future<void> initialize() async {
//     if (!dotenv.isInitialized) {
//       await dotenv.load(fileName: ".env");
//     }

//     final appId = dotenv.env['ONESIGNAL_APP_ID'];
//     if (appId == null || appId.isEmpty) {
//       throw Exception('ONESIGNAL_APP_ID not found in .env file');
//     }

//     OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
//     OneSignal.initialize(appId);

//     await OneSignal.Notifications.requestPermission(true);

//     _setupListeners();
//   }

//   void _setupListeners() {
//     OneSignal.Notifications.addForegroundWillDisplayListener((event) {
//       print('Notification received in foreground: ${event.notification.body}');
//       event.notification.display();
//     });

//     OneSignal.Notifications.addClickListener((event) {
//       print('Notification clicked: ${event.notification.body}');
//       print('Additional data: ${event.notification.additionalData}');
//       _handleNotificationClick(event.notification);
//     });

//     OneSignal.Notifications.addPermissionObserver((state) {
//       print("Notification permission state changed: $state");
//     });
//   }

//   void _handleNotificationClick(OSNotification notification) {
//     final data = notification.additionalData;
//     if (data != null && data.containsKey('page')) {
//       print('Navigate to: ${data['page']}');
//     }
//   }

//   String? getPlayerId() {
//     return OneSignal.User.pushSubscription.id;
//   }

//   Future<void> setExternalUserId(String externalId) async {
//     await OneSignal.login(externalId);
//   }

//   Future<void> removeExternalUserId() async {
//     await OneSignal.logout();
//   }

//   Future<void> sendTags(Map<String, dynamic> tags) async {
//     await OneSignal.User.addTags(tags);
//   }

//   Future<void> removeTags(List<String> keys) async {
//     await OneSignal.User.removeTags(keys);
//   }

//   bool isSubscribed() {
//     return OneSignal.User.pushSubscription.optedIn ?? false;
//   }

//   bool hasPermission() {
//     return OneSignal.Notifications.permission;
//   }
// }