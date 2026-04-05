import 'dart:convert';
import 'package:http/http.dart' as http;
import '../dataobject/reminder_items.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ReminderApiService {
  // Change this to your actual backend URL
  String ip_addr = dotenv.env['IP_ADDRESS'] ?? 'localhost';
  // 'late' allows one variable to depend on another during initialization
  late final String _baseUrl = "http://$ip_addr:8080/schedule"; //iOS simulator / web

  final String? churchId;
  final String? authToken;

  ReminderApiService({this.churchId, this.authToken});

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (authToken != null) 'Authorization': 'Bearer $authToken',
  };

  // ── GET all reminders ──
  Future<List<ReminderItem>> fetchReminders() async {
    try {
      final uri = Uri.parse('$_baseUrl/getschedule');

      final response = await http.get(uri, headers: _headers);
      print("API response body: ${response.body}");

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

  // ── GET single reminder ──
  Future<ReminderItem> fetchReminder(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/reminders/$id'),
        headers: _headers,
      );

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

  // ── POST create reminder ──
  Future<ReminderItem> createReminder(ReminderItem reminder) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/reminders'),
        headers: _headers,
        body: json.encode(reminder.toJson()),
      );

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

  // ── PUT update reminder ──
  Future<ReminderItem> updateReminder(ReminderItem reminder) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/reminders/${reminder.id}'),
        headers: _headers,
        body: json.encode(reminder.toJson()),
      );

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

  // ── DELETE reminder ──
  Future<bool> deleteReminder(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/reminders/$id'),
        headers: _headers,
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      throw ApiException('Network error: $e', 0);
    }
  }

  // ── PATCH toggle active status ──
  Future<ReminderItem> toggleActive(String id, bool isActive) async {
    try {
      final response = await http.patch(
        Uri.parse('$_baseUrl/reminders/$id/toggle'),
        headers: _headers,
        body: json.encode({'isActive': isActive}),
      );

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

  // ── POST send immediately ──
  Future<bool> sendNow(String id) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/reminders/$id/send'),
        headers: _headers,
      );

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
