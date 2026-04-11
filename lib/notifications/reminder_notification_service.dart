import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ReminderNotificationService {
  static const String _oneSignalApiUrl =
      'https://onesignal.com/api/v1/notifications';

  /// How far ahead recurring weekday reminders should be pre-scheduled.
  static const int recurringHorizonDays = 90;

  String get _appId {
    final appId = dotenv.env['ONESIGNAL_APP_ID'];
    if (appId == null || appId.isEmpty) {
      throw Exception('ONESIGNAL_APP_ID not found in .env file');
    }
    return appId;
  }

  String get _restApiKey {
    final apiKey = dotenv.env['ONESIGNAL_REST_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('ONESIGNAL_REST_API_KEY not found in .env file');
    }
    return apiKey;
  }

  Future<bool> sendImmediateReminder({
    required String subject,
    required String message,
    required String sendTo,
    required bool sendPush,
    required bool sendEmail,
    List<String>? userIds,
  }) async {
    if (!sendPush && !sendEmail) return false;

    bool pushSuccess = true;
    bool emailSuccess = true;

    if (sendPush) {
      pushSuccess = await _sendPushNotification(
        subject: subject,
        message: message,
        sendTo: sendTo,
        userIds: userIds,
      );
    }

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

  /// Schedules notifications.
  ///
  /// - If recurringDays is empty: schedules the next occurrence of the chosen time.
  /// - If recurringDays has values: schedules all matching weekdays for the next 90 days.
  Future<List<String>> scheduleReminder({
    required String subject,
    required String message,
    required DateTime scheduledAt,
    required List<int> recurringDays,
    required String sendTo,
    required bool sendPush,
    required bool sendEmail,
    List<String>? userIds,
  }) async {
    final ids = <String>[];

    if (!sendPush && !sendEmail) return ids;

    final occurrences = _buildOccurrences(
      scheduledAt: scheduledAt,
      recurringDays: recurringDays,
    );

    for (final occurrence in occurrences) {
      if (sendPush) {
        final pushId = await _createScheduledPushNotification(
          subject: subject,
          message: message,
          scheduledAt: occurrence,
          sendTo: sendTo,
          userIds: userIds,
        );
        if (pushId != null) ids.add(pushId);
      }

      if (sendEmail) {
        final emailId = await _createScheduledEmailNotification(
          subject: subject,
          message: message,
          scheduledAt: occurrence,
          sendTo: sendTo,
          userIds: userIds,
        );
        if (emailId != null) ids.add(emailId);
      }
    }

    return ids;
  }

  Future<void> cancelScheduledNotifications(
    List<String> notificationIds,
  ) async {
    for (final id in notificationIds) {
      await cancelScheduledNotification(id);
    }
  }

  Future<bool> cancelScheduledNotification(String notificationId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_oneSignalApiUrl/$notificationId?app_id=$_appId'),
        headers: {'Authorization': 'Basic $_restApiKey'},
      );

      print('Cancel response for $notificationId: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('Error canceling notification $notificationId: $e');
      return false;
    }
  }

  Future<String?> _createScheduledPushNotification({
    required String subject,
    required String message,
    required DateTime scheduledAt,
    required String sendTo,
    List<String>? userIds,
  }) async {
    print("Local scheduled time: $scheduledAt");
    print("UTC scheduled time: ${scheduledAt.toUtc()}");
    try {
      final payload = <String, dynamic>{
        'app_id': _appId,
        'target_channel': 'push',
        'headings': {'en': subject},
        'contents': {'en': message},
        'send_after': scheduledAt.toUtc().toIso8601String().replaceAll('T', ' ').replaceAll('Z', ' GMT'),
        'data': {'type': 'reminder', 'sendTo': sendTo},
      };

      _applyAudienceTargeting(payload, sendTo: sendTo, userIds: userIds);

      final response = await http.post(
        Uri.parse(_oneSignalApiUrl),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Basic $_restApiKey',
        },
        body: jsonEncode(payload),
      );

      print(
        'Scheduled push response: ${response.statusCode} - ${response.body}',
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData['id']?.toString();
      }

      return null;
    } catch (e) {
      print('Error scheduling push notification: $e');
      return null;
    }
  }

  Future<String?> _createScheduledEmailNotification({
    required String subject,
    required String message,
    required DateTime scheduledAt,
    required String sendTo,
    List<String>? userIds,
  }) async {
    try {
      final payload = <String, dynamic>{
        'app_id': _appId,
        'target_channel': 'email',
        'email_subject': subject,
        'email_body': _formatEmailBody(subject, message),
        'send_after': scheduledAt.toUtc().toIso8601String(),
        'data': {'type': 'reminder', 'sendTo': sendTo},
      };

      _applyAudienceTargeting(payload, sendTo: sendTo, userIds: userIds);

      final response = await http.post(
        Uri.parse(_oneSignalApiUrl),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Basic $_restApiKey',
        },
        body: jsonEncode(payload),
      );

      print(
        'Scheduled email response: ${response.statusCode} - ${response.body}',
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData['id']?.toString();
      }

      return null;
    } catch (e) {
      print('Error scheduling email notification: $e');
      return null;
    }
  }

  Future<bool> _sendPushNotification({
    required String subject,
    required String message,
    required String sendTo,
    List<String>? userIds,
  }) async {
    try {
      final payload = <String, dynamic>{
        'app_id': _appId,
        'target_channel': 'push',
        'headings': {'en': subject},
        'contents': {'en': message},
        'data': {'type': 'reminder', 'sendTo': sendTo},
      };

      _applyAudienceTargeting(payload, sendTo: sendTo, userIds: userIds);

      final response = await http.post(
        Uri.parse(_oneSignalApiUrl),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Basic $_restApiKey',
        },
        body: jsonEncode(payload),
      );

      print('Push response: ${response.statusCode} - ${response.body}');
      return response.statusCode == 200;
    } catch (e) {
      print('Error sending push notification: $e');
      return false;
    }
  }

  Future<bool> _sendEmailNotification({
    required String subject,
    required String message,
    required String sendTo,
    List<String>? userIds,
  }) async {
    try {
      final payload = <String, dynamic>{
        'app_id': _appId,
        'target_channel': 'email',
        'email_subject': subject,
        'email_body': _formatEmailBody(subject, message),
        'data': {'type': 'reminder', 'sendTo': sendTo},
      };

      _applyAudienceTargeting(payload, sendTo: sendTo, userIds: userIds);

      final response = await http.post(
        Uri.parse(_oneSignalApiUrl),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Basic $_restApiKey',
        },
        body: jsonEncode(payload),
      );

      print('Email response: ${response.statusCode} - ${response.body}');
      return response.statusCode == 200;
    } catch (e) {
      print('Error sending email notification: $e');
      return false;
    }
  }

  void _applyAudienceTargeting(
    Map<String, dynamic> payload, {
    required String sendTo,
    List<String>? userIds,
  }) {
    if (userIds != null && userIds.isNotEmpty) {
      payload['include_external_user_ids'] = userIds;
      return;
    }

    final filters = _buildFiltersForSendTo(sendTo);
    if (filters.isNotEmpty) {
      payload['filters'] = filters;
    } else {
      payload['included_segments'] = ['All'];
    }
  }

  List<Map<String, dynamic>> _buildFiltersForSendTo(String sendTo) {
    switch (sendTo.toLowerCase()) {
      case 'absent':
        return [
          {
            'field': 'tag',
            'key': 'attendance_status',
            'relation': '=',
            'value': 'absent',
          },
        ];
      case 'present':
        return [
          {
            'field': 'tag',
            'key': 'attendance_status',
            'relation': '=',
            'value': 'present',
          },
        ];
      case 'all':
      default:
        return [];
    }
  }

  List<DateTime> _buildOccurrences({
    required DateTime scheduledAt,
    required List<int> recurringDays,
  }) {
    if (recurringDays.isEmpty) {
      return [_nextOccurrenceForTime(scheduledAt)];
    }

    final results = <DateTime>[];
    final uniqueDays = recurringDays.toSet().toList()..sort();
    final endDate = DateTime.now().add(
      const Duration(days: recurringHorizonDays),
    );

    for (final weekday in uniqueDays) {
      DateTime occurrence = _nextOccurrenceForWeekday(weekday, scheduledAt);

      while (!occurrence.isAfter(endDate)) {
        results.add(occurrence);
        occurrence = occurrence.add(const Duration(days: 7));
      }
    }

    results.sort();
    return results;
  }

  DateTime _nextOccurrenceForTime(DateTime timeOnly) {
    final now = DateTime.now();

    DateTime candidate = DateTime(
      now.year,
      now.month,
      now.day,
      timeOnly.hour,
      timeOnly.minute,
    ).toLocal(); // ADD THIS

    if (!candidate.isAfter(now)) {
      candidate = candidate.add(const Duration(days: 1));
    }

    return candidate;
  }

  DateTime _nextOccurrenceForWeekday(int weekday, DateTime timeOnly) {
    final now = DateTime.now();

    DateTime candidate = DateTime(
      now.year,
      now.month,
      now.day,
      timeOnly.hour,
      timeOnly.minute,
    ).toLocal(); // ADD THIS

    int diff = weekday - candidate.weekday;
    if (diff < 0) diff += 7;

    candidate = candidate.add(Duration(days: diff));

    if (candidate.weekday == weekday && !candidate.isAfter(now)) {
      candidate = candidate.add(const Duration(days: 7));
    }

    return candidate;
  }

  String _formatEmailBody(String subject, String message) {
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

  String replacePlaceholders({
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
