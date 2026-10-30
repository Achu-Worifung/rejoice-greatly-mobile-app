import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A sermon kept on this phone for listening without a connection.
@immutable
class SermonDownload {
  const SermonDownload({required this.path, required this.bytes, required this.sermon});

  factory SermonDownload.fromJson(Map<String, dynamic> json) => SermonDownload(
        path: json['path'] as String,
        bytes: (json['bytes'] as num?)?.toInt() ?? 0,
        sermon: Map<String, dynamic>.from(json['sermon'] as Map? ?? const {}),
      );

  final String path;
  final int bytes;

  /// The sermon as it was when downloaded, so the list works offline.
  final Map<String, dynamic> sermon;

  Map<String, dynamic> toJson() => {'path': path, 'bytes': bytes, 'sermon': sermon};
}

/// Downloads sermon audio to the phone, and remembers what's there.
class SermonDownloads {
  SermonDownloads._();

  static const _key = 'sermon_downloads';

  /// Sermon id → its download. Listen to repaint download buttons.
  static final ValueNotifier<Map<String, SermonDownload>> all = ValueNotifier(const {});

  /// Sermon id → 0–1 while downloading.
  static final ValueNotifier<Map<String, double>> inFlight = ValueNotifier(const {});

  static bool _loaded = false;

  static Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final raw = (await SharedPreferences.getInstance()).getString(_key);
      if (raw == null) return;
      final map = json.decode(raw) as Map<String, dynamic>;
      final kept = <String, SermonDownload>{};
      for (final e in map.entries) {
        final d = SermonDownload.fromJson(Map<String, dynamic>.from(e.value as Map));
        // The OS can clear app storage; forget files that are gone.
        if (await File(d.path).exists()) kept[e.key] = d;
      }
      all.value = kept;
      if (kept.length != map.length) await _save();
    } catch (e) {
      debugPrint('SermonDownloads.load failed: $e');
    }
  }

  /// The downloaded file for [sermonId], if there is one.
  static String? fileFor(String sermonId) => all.value[sermonId]?.path;

  /// Downloads [sermon]'s audio. Throws if it can't.
  static Future<void> download(String sermonId, Map<String, dynamic> sermon, String audioUrl) async {
    if (all.value.containsKey(sermonId) || inFlight.value.containsKey(sermonId)) return;
    _progress(sermonId, 0);
    final dir = Directory('${(await getApplicationDocumentsDirectory()).path}/sermons');
    await dir.create(recursive: true);
    final file = File('${dir.path}/$sermonId${_extension(audioUrl)}');
    final partial = File('${file.path}.part');
    final client = http.Client();
    try {
      final response = await client.send(http.Request('GET', Uri.parse(audioUrl)));
      if (response.statusCode != 200) {
        throw HttpException('Download failed (${response.statusCode})');
      }
      final total = response.contentLength ?? 0;
      var received = 0;
      final sink = partial.openWrite();
      try {
        await for (final chunk in response.stream) {
          sink.add(chunk);
          received += chunk.length;
          if (total > 0) _progress(sermonId, received / total);
        }
      } finally {
        await sink.close();
      }
      await partial.rename(file.path);
      all.value = {
        ...all.value,
        sermonId: SermonDownload(path: file.path, bytes: received, sermon: sermon),
      };
      await _save();
    } catch (e) {
      if (await partial.exists()) await partial.delete();
      rethrow;
    } finally {
      client.close();
      inFlight.value = Map.of(inFlight.value)..remove(sermonId);
    }
  }

  static Future<void> remove(String sermonId) async {
    final d = all.value[sermonId];
    if (d == null) return;
    all.value = Map.of(all.value)..remove(sermonId);
    await _save();
    try {
      final f = File(d.path);
      if (await f.exists()) await f.delete();
    } catch (e) {
      debugPrint('SermonDownloads: could not delete ${d.path}: $e');
    }
  }

  /// "48 MB" for the download button.
  static String sizeLabel(int bytes) {
    if (bytes >= 1024 * 1024) return '${(bytes / (1024 * 1024)).round()} MB';
    return '${(bytes / 1024).ceil()} KB';
  }

  static void _progress(String id, double value) => inFlight.value = {...inFlight.value, id: value};

  static String _extension(String url) {
    final path = Uri.tryParse(url)?.path ?? '';
    final dot = path.lastIndexOf('.');
    final ext = dot >= 0 ? path.substring(dot).toLowerCase() : '';
    return RegExp(r'^\.[a-z0-9]{2,4}$').hasMatch(ext) ? ext : '.mp3';
  }

  static Future<void> _save() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_key, json.encode({for (final e in all.value.entries) e.key: e.value.toJson()}));
    } catch (e) {
      debugPrint('SermonDownloads: could not save: $e');
    }
  }
}
