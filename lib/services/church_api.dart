import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

/// Spring Boot API (`/events`, `/sermons`, `/weekly-verse`, etc.) — one place for base URL and calls.
class ChurchApi {
  ChurchApi._();

  static String get baseUrl => 'http://${dotenv.env['IP_ADDRESS'] ?? 'localhost'}:8080';

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
