import 'dart:convert';
import 'package:http/http.dart' as http;
import '../dataobject/reminder_items.dart';
import '../services/church_api.dart';

class ReminderApiService {
  late final String _baseUrl = '${ChurchApi.baseUrl}/schedule';

  static const Duration _timeout = Duration(seconds: 30);

  final String? churchId;
  final String? authToken;

  ReminderApiService({this.churchId, this.authToken});

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (authToken != null) 'Authorization': 'Bearer $authToken',
      };

  Future<List<ReminderItem>> fetchReminders() async {
    try {
      // Backend list endpoint is GET /schedule (no /getschedule suffix).
      final uri = Uri.parse(_baseUrl);
      final response = await http.get(uri, headers: _headers).timeout(_timeout);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((j) => ReminderItem.fromJson(j)).toList();
      } else {
        throw ApiException('Failed to fetch reminders', response.statusCode);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: $e', 0);
    }
  }

  Future<ReminderItem> fetchReminder(String id) async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/getschedule/$id'), headers: _headers)
          .timeout(_timeout);

      if (response.statusCode == 200) {
        return ReminderItem.fromJson(json.decode(response.body));
      } else {
        throw ApiException('Reminder not found', response.statusCode);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: $e', 0);
    }
  }

  Future<ReminderItem> createReminder(ReminderItem reminder) async {
    try {
      final response = await http
          .post(
            Uri.parse(_baseUrl),
            headers: _headers,
            body: json.encode(reminder.toJson()),
          )
          .timeout(_timeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ReminderItem.fromJson(json.decode(response.body));
      } else {
        throw ApiException('Failed to create reminder', response.statusCode);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: $e', 0);
    }
  }

  Future<ReminderItem> updateReminder(ReminderItem reminder) async {
    try {
      final response = await http
          .put(
            Uri.parse('$_baseUrl/updateschedule/${reminder.id}'),
            headers: _headers,
            body: json.encode(reminder.toJson()),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        return ReminderItem.fromJson(json.decode(response.body));
      } else {
        throw ApiException('Failed to update reminder', response.statusCode);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: $e', 0);
    }
  }

  Future<bool> deleteReminder(String id) async {
    try {
      final response = await http
          .delete(Uri.parse('$_baseUrl/$id'), headers: _headers)
          .timeout(_timeout);

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      throw ApiException('Network error: $e', 0);
    }
  }

  Future<ReminderItem> toggleActive(String id, bool isActive) async {
    try {
      final response = await http
          .patch(
            Uri.parse('$_baseUrl/toggleschedule/$id'),
            headers: _headers,
            body: json.encode({'isActive': isActive}),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        return ReminderItem.fromJson(json.decode(response.body));
      } else {
        throw ApiException('Failed to toggle reminder', response.statusCode);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: $e', 0);
    }
  }

  Future<bool> sendNow(String id) async {
    try {
      final response = await http
          .post(Uri.parse('$_baseUrl/sendnow/$id'), headers: _headers)
          .timeout(_timeout);

      return response.statusCode == 200;
    } catch (e) {
      throw ApiException('Network error: $e', 0);
    }
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, this.statusCode);

  @override
  String toString() => 'ApiException($statusCode): $message';
}