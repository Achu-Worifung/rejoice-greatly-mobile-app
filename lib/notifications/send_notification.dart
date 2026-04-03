import 'dart:convert';
import 'package:http/http.dart' as http;

class PushNotificationSender {
  static const String _oneSignalApiUrl = 'https://onesignal.com/api/v1/notifications';
  static const String _appId = 'YOUR_ONESIGNAL_APP_ID';
  static const String _restApiKey = 'YOUR_REST_API_KEY';

  // Send to all users
  static Future<bool> sendToAll({
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_oneSignalApiUrl),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Basic $_restApiKey',
        },
        body: jsonEncode({
          'app_id': _appId,
          'included_segments': ['All'],
          'headings': {'en': title},
          'contents': {'en': message},
          if (data != null) 'data': data,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error sending notification: $e');
      return false;
    }
  }

  // Send to specific users
  static Future<bool> sendToUsers({
    required List<String> userIds,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_oneSignalApiUrl),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Basic $_restApiKey',
        },
        body: jsonEncode({
          'app_id': _appId,
          'include_external_user_ids': userIds,
          'headings': {'en': title},
          'contents': {'en': message},
          if (data != null) 'data': data,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error sending notification: $e');
      return false;
    }
  }

  // Send to users with specific tags
  static Future<bool> sendToTags({
    required List<Map<String, dynamic>> filters,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_oneSignalApiUrl),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Basic $_restApiKey',
        },
        body: jsonEncode({
          'app_id': _appId,
          'filters': filters,
          'headings': {'en': title},
          'contents': {'en': message},
          if (data != null) 'data': data,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error sending notification: $e');
      return false;
    }
  }

  // Schedule notification
  static Future<bool> scheduleNotification({
    required String title,
    required String message,
    required DateTime sendAfter,
    List<String>? userIds,
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_oneSignalApiUrl),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Basic $_restApiKey',
        },
        body: jsonEncode({
          'app_id': _appId,
          if (userIds != null && userIds.isNotEmpty)
            'include_external_user_ids': userIds
          else
            'included_segments': ['All'],
          'headings': {'en': title},
          'contents': {'en': message},
          'send_after': sendAfter.toUtc().toIso8601String(),
          if (data != null) 'data': data,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error scheduling notification: $e');
      return false;
    }
  }

  // Schedule recurring notification
  static Future<bool> scheduleRecurringNotification({
    required String title,
    required String message,
    required DateTime sendAfter,
    required int delayedOption, // e.g., "timezone" for daily
    required String deliveryTimeOfDay, // e.g., "9:00AM"
    List<String>? userIds,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_oneSignalApiUrl),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Basic $_restApiKey',
        },
        body: jsonEncode({
          'app_id': _appId,
          if (userIds != null && userIds.isNotEmpty)
            'include_external_user_ids': userIds
          else
            'included_segments': ['All'],
          'headings': {'en': title},
          'contents': {'en': message},
          'send_after': sendAfter.toUtc().toIso8601String(),
          'delayed_option': 'timezone',
          'delivery_time_of_day': deliveryTimeOfDay,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error scheduling recurring notification: $e');
      return false;
    }
  }
}