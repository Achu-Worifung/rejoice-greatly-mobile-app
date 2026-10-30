import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// How far into a sermon the member got, kept on this phone.
@immutable
class SermonListen {
  const SermonListen({
    required this.position,
    required this.duration,
    required this.updatedAt,
    required this.sermon,
  });

  factory SermonListen.fromJson(Map<String, dynamic> json) => SermonListen(
        position: Duration(milliseconds: (json['p'] as num?)?.toInt() ?? 0),
        duration: Duration(milliseconds: (json['d'] as num?)?.toInt() ?? 0),
        updatedAt: DateTime.tryParse('${json['at']}') ?? DateTime.fromMillisecondsSinceEpoch(0),
        sermon: Map<String, dynamic>.from(json['s'] as Map? ?? const {}),
      );

  final Duration position;
  final Duration duration;
  final DateTime updatedAt;

  /// Enough of the sermon to show it in "Continue listening" without the network.
  final Map<String, dynamic> sermon;

  /// 0–1, for a progress bar.
  double get fraction =>
      duration.inMilliseconds <= 0 ? 0 : (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);

  Duration get remaining => duration > position ? duration - position : Duration.zero;

  Map<String, dynamic> toJson() => {
        'p': position.inMilliseconds,
        'd': duration.inMilliseconds,
        'at': updatedAt.toIso8601String(),
        's': sermon,
      };
}

/// Where each sermon was left off, so listening picks up from there, and the
/// "Continue listening" list. Finished sermons drop off the list.
class SermonProgress {
  SermonProgress._();

  static const _key = 'sermon_progress';

  /// Within this of the end counts as finished.
  static const Duration finishedWithin = Duration(seconds: 45);

  /// Less than this in isn't worth resuming.
  static const Duration minimumToResume = Duration(seconds: 30);

  /// Sermon id → where they got to. Listen to repaint progress bars.
  static final ValueNotifier<Map<String, SermonListen>> all = ValueNotifier(const {});

  static bool _loaded = false;

  static Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final raw = (await SharedPreferences.getInstance()).getString(_key);
      if (raw == null) return;
      final map = json.decode(raw) as Map<String, dynamic>;
      all.value = {
        for (final e in map.entries) e.key: SermonListen.fromJson(Map<String, dynamic>.from(e.value as Map)),
      };
    } catch (e) {
      debugPrint('SermonProgress.load failed: $e');
    }
  }

  /// Where to start [sermonId] from, or null to start at the beginning.
  static Duration? resumeAt(String sermonId) {
    final listen = all.value[sermonId];
    if (listen == null || listen.position < minimumToResume) return null;
    if (listen.duration > Duration.zero && listen.remaining <= finishedWithin) return null;
    return listen.position;
  }

  /// Records where they are. Finishing a sermon forgets it.
  static Future<void> record(String sermonId, Map<String, dynamic> sermon, Duration position, Duration duration) async {
    final next = Map<String, SermonListen>.from(all.value);
    final finished = duration > Duration.zero && duration - position <= finishedWithin;
    if (finished) {
      if (next.remove(sermonId) == null) return;
    } else if (position < const Duration(seconds: 5)) {
      return;
    } else {
      next[sermonId] = SermonListen(
        position: position,
        duration: duration,
        updatedAt: DateTime.now(),
        sermon: _snapshot(sermon),
      );
    }
    all.value = next;
    await _save();
  }

  /// Unfinished sermons, most recently listened first.
  static List<SermonListen> get inProgress {
    final list = all.value.values.where((l) => l.position >= minimumToResume).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  static Future<void> clear() async {
    all.value = const {};
    await _save();
  }

  static Map<String, dynamic> _snapshot(Map<String, dynamic> m) => {
        for (final k in const ['id', 'title', 'speaker', 'datePreached', 'imageUrl', 'audioUrl', 'category', 'series'])
          if (m[k] != null) k: m[k],
      };

  static Future<void> _save() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_key, json.encode({for (final e in all.value.entries) e.key: e.value.toJson()}));
    } catch (e) {
      debugPrint('SermonProgress: could not save: $e');
    }
  }
}
