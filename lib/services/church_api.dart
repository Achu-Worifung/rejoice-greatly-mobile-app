import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Spring Boot API (`/events`, `/sermons`, `/weekly-verse`, etc.) — one place for base URL and calls.
class ChurchApi {
  ChurchApi._();

  static const String _accountJsonKey = 'account_json';

  static String get baseUrl => 'http://${dotenv.env['IP_ADDRESS'] ?? 'localhost'}:8080';

  /// Persists the last [AuthAccount]-shaped map from `POST /auth/firebase` for offline display.
  static Future<void> cacheAccountJson(Map<String, dynamic> account) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_accountJsonKey, json.encode(account));
  }

  static Future<Map<String, dynamic>?> getCachedAccountJson() async {
    final p = await SharedPreferences.getInstance();
    final s = p.getString(_accountJsonKey);
    if (s == null || s.isEmpty) return null;
    try {
      return json.decode(s) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Refreshes the member account from `POST /auth/firebase` (same as login) and updates the cache.
  static Future<Map<String, dynamic>> refreshAccountWithFirebaseToken(
    String idToken, {
    String provider = 'app',
    String? name,
  }) async {
    final body = <String, dynamic>{
      'idToken': idToken,
      'provider': provider,
    };
    if (name != null) body['name'] = name;

    final r = await http.post(
      Uri.parse('$baseUrl/auth/firebase'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );
    if (r.statusCode != 200) {
      throw Exception('auth/firebase failed: ${r.statusCode}');
    }
    final map = json.decode(r.body) as Map<String, dynamic>;
    await cacheAccountJson(map);
    return map;
  }

  static int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? 0;
  }

  /// Shapes [AuthAccount] JSON for [AttendanceSheet] (dashboard lightning modal).
  static Map<String, dynamic> accountToAttendanceSheetData(Map<String, dynamic> a) {
    return {
      'attendanceStreak': {
        'streakLabel': 'Current streak',
        'currentStreak': _asInt(a['currentStreak']),
        'totalLabel': 'Total attendances',
        'totalAttendance': _asInt(a['totalAttendance']),
        'bestLabel': 'Longest streak',
        'bestStreak': _asInt(a['longestStreak']),
        'absences': _asInt(a['totalAbsences']),
        'absenceStreak': _asInt(a['absenceStreak']),
      },
    };
  }

  static Future<Map<String, dynamic>> getCurrentVerse() async {
    final r = await http.get(Uri.parse('$baseUrl/weekly-verse/current'));
    if (r.statusCode != 200) {
      throw Exception('weekly-verse/current failed: ${r.statusCode}');
    }
    return json.decode(r.body) as Map<String, dynamic>;
  }

  /// Dashboard highlight rail — `GET /events/top4` (EventInstance list).
  static Future<List<dynamic>> getTop4Events() async {
    final r = await http.get(Uri.parse('$baseUrl/events/top4'));
    if (r.statusCode != 200) {
      throw Exception('events/top4 failed: ${r.statusCode}');
    }
    return json.decode(r.body) as List<dynamic>;
  }

  /// Full upcoming list for the Events tab — `GET /events/upcoming`.
  static Future<List<dynamic>> getUpcomingEvents() async {
    final r = await http.get(Uri.parse('$baseUrl/events/upcoming'));
    if (r.statusCode != 200) {
      throw Exception('events/upcoming failed: ${r.statusCode}');
    }
    return json.decode(r.body) as List<dynamic>;
  }

  static Future<List<dynamic>> getSermons() async {
    final r = await http.get(Uri.parse('$baseUrl/sermons'));
    if (r.statusCode != 200) {
      throw Exception('sermons failed: ${r.statusCode}');
    }
    return json.decode(r.body) as List<dynamic>;
  }

  static Future<Map<String, dynamic>> getSermonById(Object id) async {
    final r = await http.get(Uri.parse('$baseUrl/sermons/$id'));
    if (r.statusCode != 200) {
      throw Exception('sermons/$id failed: ${r.statusCode}');
    }
    return json.decode(r.body) as Map<String, dynamic>;
  }

  /// Normalizes [EventInstance] JSON into a row for UI lists.
  static List<Map<String, dynamic>> mapEventInstances(List<dynamic> list) {
    final out = <Map<String, dynamic>>[];
    for (final e in list) {
      final m = e as Map<String, dynamic>;
      if (m['cancelled'] == true) continue;
      final t = m['template'] as Map<String, dynamic>? ?? {};
      final dateStr = m['date'] as String? ?? '';
      if (dateStr.isEmpty) continue;
      out.add({
        'title': t['title'] ?? 'Church event',
        'time': _formatTime(m['specificTime'] as String?, t['defaultTime'] as String?),
        'date': dateStr.length >= 10 ? dateStr.substring(0, 10) : dateStr,
        'location': t['location'] ?? '',
        'imageUrl': t['posterUrl'],
        'category': (t['category'] as String?)?.trim().isNotEmpty == true
            ? t['category'] as String
            : 'General',
      });
    }
    return out;
  }

  static String _formatTime(String? specific, String? def) {
    final raw = specific ?? def;
    if (raw == null || raw.isEmpty) return '';
    final parts = raw.split(':');
    if (parts.length < 2) return raw;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1].split('.').first) ?? 0;
    return DateFormat.jm().format(DateTime(2000, 1, 1, h, m));
  }
}
