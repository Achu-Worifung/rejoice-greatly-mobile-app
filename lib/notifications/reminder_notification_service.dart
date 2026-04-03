import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ReminderNotificationService {
  static const String _oneSignalApiUrl = 'https://onesignal.com/api/v1/notifications';
  
  static String get _appId {
    final appId = dotenv.env['ONESIGNAL_APP_ID'];
    if (appId == null || appId.isEmpty) {
      throw Exception('ONESIGNAL_APP_ID not found in .env file');
    }
    return appId;
  }

  static String get _restApiKey {
    final apiKey = dotenv.env['ONESIGNAL_REST_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('ONESIGNAL_REST_API_KEY not found in .env file');
    }
    return apiKey;
  }

  /// Send immediate reminder notification
  static Future<bool> sendImmediateReminder({
    required String subject,
    required String message,
    required String sendTo,
    required bool sendPush,
    required bool sendEmail,
    List<String>? userIds,
  }) async {
    if (!sendPush && !sendEmail) return false;

    bool pushSuccess = true;
    if (sendPush) {
      pushSuccess = await _sendPushNotification(
        subject: subject,
        message: message,
        sendTo: sendTo,
        userIds: userIds,
      );
    }

    bool emailSuccess = true;
    if (sendEmail) {
      emailSuccess = await _sendEmailNotification(
        subject: subject,
        message: message,
        sendTo: sendTo,
        userIds: userIds,
      );
    }

    return pushSuccess || emailSuccess;
  }

  /// Schedule a reminder notification
  static Future<String?> scheduleReminder({
    required String subject,
    required String message,
    required DateTime scheduledAt,
    required String sendTo,
    required bool sendPush,
    required bool sendEmail,
    String? recurring,
    List<String>? userIds,
  }) async {
    if (!sendPush) return null;

    try {
      final Map<String, dynamic> payload = {
        'app_id': _appId,
        'headings': {'en': subject},
        'contents': {'en': message},
        'send_after': scheduledAt.toUtc().toIso8601String(),
        'data': {
          'type': 'reminder',
          'sendTo': sendTo,
        },
      };

      // Add user targeting
      if (userIds != null && userIds.isNotEmpty) {
        payload['include_external_user_ids'] = userIds;
        payload['target_channel'] = 'push';
      } else {
        final filters = _buildFiltersForSendTo(sendTo);
        if (filters.isNotEmpty) {
          payload['filters'] = filters;
        } else {
          payload['included_segments'] = ['All'];
        }
      }

      // Add recurring settings
      if (recurring != null && recurring != 'none') {
        payload['delayed_option'] = 'timezone';
        final hour = scheduledAt.hour;
        final minute = scheduledAt.minute.toString().padLeft(2, '0');
        final ampm = hour >= 12 ? 'PM' : 'AM';
        final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
        payload['delivery_time_of_day'] = '$displayHour:$minute$ampm';
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

  /// Cancel a scheduled notification
  static Future<bool> cancelScheduledNotification(String notificationId) async {
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

  /// Send push notification
  static Future<bool> _sendPushNotification({
    required String subject,
    required String message,
    required String sendTo,
    List<String>? userIds,
  }) async {
    try {
      final Map<String, dynamic> payload = {
        'app_id': _appId,
        'headings': {'en': subject},
        'contents': {'en': message},
        'data': {
          'type': 'reminder',
          'sendTo': sendTo,
        },
      };

      if (userIds != null && userIds.isNotEmpty) {
        payload['include_external_user_ids'] = userIds;
        payload['target_channel'] = 'push';
      } else {
        final filters = _buildFiltersForSendTo(sendTo);
        if (filters.isNotEmpty) {
          payload['filters'] = filters;
        } else {
          payload['included_segments'] = ['All'];
        }
      }

      final response = await http.post(
        Uri.parse(_oneSignalApiUrl),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Basic $_restApiKey',
        },
        body: jsonEncode(payload),
      );

      print('Push notification response: ${response.statusCode} - ${response.body}');
      return response.statusCode == 200;
    } catch (e) {
      print('Error sending push notification: $e');
      return false;
    }
  }

  /// Send email notification
  static Future<bool> _sendEmailNotification({
    required String subject,
    required String message,
    required String sendTo,
    List<String>? userIds,
  }) async {
    try {
      final Map<String, dynamic> payload = {
        'app_id': _appId,
        'email_subject': subject,
        'email_body': _formatEmailBody(subject, message),
        'data': {
          'type': 'reminder',
          'sendTo': sendTo,
        },
      };

      if (userIds != null && userIds.isNotEmpty) {
        payload['include_external_user_ids'] = userIds;
        payload['target_channel'] = 'email';
      } else {
        final filters = _buildFiltersForSendTo(sendTo);
        if (filters.isNotEmpty) {
          payload['filters'] = filters;
        } else {
          payload['included_segments'] = ['All'];
        }
      }

      final response = await http.post(
        Uri.parse(_oneSignalApiUrl),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Basic $_restApiKey',
        },
        body: jsonEncode(payload),
      );

      print('Email notification response: ${response.statusCode} - ${response.body}');
      return response.statusCode == 200;
    } catch (e) {
      print('Error sending email notification: $e');
      return false;
    }
  }

  /// Build OneSignal filters based on sendTo parameter
  static List<Map<String, dynamic>> _buildFiltersForSendTo(String sendTo) {
    switch (sendTo) {
      case 'absent':
        return [
          {'field': 'tag', 'key': 'attendance_status', 'relation': '=', 'value': 'absent'}
        ];
      case 'present':
        return [
          {'field': 'tag', 'key': 'attendance_status', 'relation': '=', 'value': 'present'}
        ];
      case 'all':
      default:
        return [];
    }
  }

  /// Format email body with HTML
  static String _formatEmailBody(String subject, String message) {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333; margin: 0; padding: 0;">
  <div style="max-width: 600px; margin: 0 auto; padding: 20px;">
    <h2 style="color: #438FFC; margin-bottom: 20px;">$subject</h2>
    <div style="background-color: #f5f7fa; padding: 20px; border-radius: 10px;">
      ${message.replaceAll('\n', '<br>')}
    </div>
    <p style="margin-top: 20px; color: #888; font-size: 12px;">
      This is an automated message from your church app.
    </p>
  </div>
</body>
</html>
''';
  }

  /// Replace placeholders in message
  static String replacePlaceholders({
    required String message,
    String? firstName,
    String? serviceDate,
    String? churchName,
  }) {
    String result = message;
    if (firstName != null) {
      result = result.replaceAll('[First Name]', firstName);
    }
    if (serviceDate != null) {
      result = result.replaceAll('[Service Date]', serviceDate);
    }
    if (churchName != null) {
      result = result.replaceAll('[Church Name]', churchName);
    }
    return result;
  }
}