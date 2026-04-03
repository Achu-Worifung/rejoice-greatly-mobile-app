import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PushNotificationSender {
  late String _appId;
  late String _restApiKey;
  static const String _oneSignalApiUrl = 'https://onesignal.com/api/v1/notifications';
  
  PushNotificationSender() {
    _loadEnvVariables();
  }

  void _loadEnvVariables() {
    _appId = dotenv.env['ONESIGNAL_APP_ID'] ?? '';
    _restApiKey = dotenv.env['ONESIGNAL_REST_API_KEY'] ?? '';
    
    if (_appId.isEmpty) {
      throw Exception('ONESIGNAL_APP_ID not found in .env file');
    }
    if (_restApiKey.isEmpty) {
      throw Exception('ONESIGNAL_REST_API_KEY not found in .env file');
    }
  }

  // Send to all users
  Future<bool> sendToAll({
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

      print('SendToAll response: ${response.statusCode} - ${response.body}');
      return response.statusCode == 200;
    } catch (e) {
      print('Error sending notification: $e');
      return false;
    }
  }

  // Send to specific users
  Future<bool> sendToUsers({
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

      print('SendToUsers response: ${response.statusCode} - ${response.body}');
      return response.statusCode == 200;
    } catch (e) {
      print('Error sending notification: $e');
      return false;
    }
  }

  // Send to users with specific tags
  Future<bool> sendToTags({
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

      print('SendToTags response: ${response.statusCode} - ${response.body}');
      return response.statusCode == 200;
    } catch (e) {
      print('Error sending notification: $e');
      return false;
    }
  }

  // Schedule notification
  Future<String?> scheduleNotification({
    required String title,
    required String message,
    required DateTime sendAfter,
    List<String>? userIds,
    Map<String, dynamic>? data,
  }) async {
    try {
      final Map<String, dynamic> payload = {
        'app_id': _appId,
        'headings': {'en': title},
        'contents': {'en': message},
        'send_after': sendAfter.toUtc().toIso8601String(),
        if (data != null) 'data': data,
      };

      if (userIds != null && userIds.isNotEmpty) {
        payload['include_external_user_ids'] = userIds;
      } else {
        payload['included_segments'] = ['All'];
      }

      final response = await http.post(
        Uri.parse(_oneSignalApiUrl),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Basic $_restApiKey',
        },
        body: jsonEncode(payload),
      );

      print('Schedule response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData['id'];
      }
      return null;
    } catch (e) {
      print('Error scheduling notification: $e');
      return null;
    }
  }

  // Cancel scheduled notification
  Future<bool> cancelNotification(String notificationId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_oneSignalApiUrl/$notificationId?app_id=$_appId'),
        headers: {
          'Authorization': 'Basic $_restApiKey',
        },
      );

      print('Cancel response: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('Error canceling notification: $e');
      return false;
    }
  }
}