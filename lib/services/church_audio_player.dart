import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import 'church_api.dart';

/// One shared sermon audio player: starting a new sermon stops the previous.
class ChurchAudioPlayer extends ChangeNotifier {
  ChurchAudioPlayer._internal() {
    _playerStateSub = _player.playerStateStream.listen((_) => notifyListeners());
    _processingSub = _player.processingStateStream.listen((_) => notifyListeners());
  }

  static final ChurchAudioPlayer instance = ChurchAudioPlayer._internal();

  final AudioPlayer _player = AudioPlayer();

  Object? _activeKey;
  Object? _loadingKey;

  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<ProcessingState>? _processingSub;

  AudioPlayer get player => _player;

  /// Match list/detail sermon rows (prefer stable id).
  static Object? sermonKey(Map<String, dynamic> m) => m['id'] ?? m['audioUrl'] ?? m['title'];

  bool isAudioFocus(Map<String, dynamic> m) {
    final key = sermonKey(m);
    if (key == null) return false;
    return _activeKey == key;
  }

  bool isPlayingFor(Map<String, dynamic> m) => isAudioFocus(m) && _player.playing;

  /// True when this sermon is the current source but playback is not active (ready to play / completed), not while resolving URL or buffering.
  bool isPausedFor(Map<String, dynamic> m) {
    if (!isAudioFocus(m) || _player.playing) return false;
    switch (_player.processingState) {
      case ProcessingState.ready:
      case ProcessingState.completed:
        return true;
      case ProcessingState.idle:
      case ProcessingState.loading:
      case ProcessingState.buffering:
        return false;
    }
  }

  /// Resolving URL / [AudioPlayer.setUrl], or buffering before playback; never while `playing` is true (avoids spinner over waveform).
  bool isLoadingFor(Map<String, dynamic> m) {
    final key = sermonKey(m);
    if (key == null) return false;
    if (_loadingKey != null && _loadingKey == key) return true;
    if (!isAudioFocus(m) || _player.playing) return false;
    final p = _player.processingState;
    return p == ProcessingState.loading || p == ProcessingState.buffering;
  }

  Future<String?> _resolveAudioUrl(Map<String, dynamic> m) async {
    final raw = m['audioUrl'];
    if (raw is String && raw.trim().isNotEmpty) {
      return raw.trim();
    }
    final id = m['id'];
    if (id == null) return null;
    try {
      final detail = await ChurchApi.getSermonById(id);
      final u = detail['audioUrl'];
      if (u is String && u.trim().isNotEmpty) return u.trim();
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Play/pause for this sermon. Starts load if needed. Returns false if no audio URL.
  Future<bool> toggle(Map<String, dynamic> m) async {
    final key = sermonKey(m);
    if (key == null) return false;
    if (_loadingKey != null && _loadingKey != key) {
      return true;
    }

    if (_activeKey != null && _activeKey == key) {
      if (_player.playing) {
        await _player.pause();
      } else if (_player.processingState == ProcessingState.ready ||
          _player.processingState == ProcessingState.completed) {
        await _player.seek(Duration.zero);
        await _player.play();
      } else {
        await _player.play();
      }
      notifyListeners();
      return true;
    }

    _loadingKey = key;
    notifyListeners();

    await _player.stop();

    try {
      final url = await _resolveAudioUrl(m);
      if (url == null || url.isEmpty) {
        _activeKey = null;
        _loadingKey = null;
        notifyListeners();
        return false;
      }

      _activeKey = key;
      await _player.setUrl(url);
      _loadingKey = null;
      notifyListeners();

      await _player.play();
      return true;
    } catch (e, st) {
      debugPrint('ChurchAudioPlayer.toggle: $e\n$st');
      _activeKey = null;
      _loadingKey = null;
      await _player.stop();
      notifyListeners();
      return false;
    }
  }

  Future<void> stop() async {
    await _player.stop();
    _activeKey = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _playerStateSub?.cancel();
    _processingSub?.cancel();
    _player.dispose();
    super.dispose();
  }
}
