import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import 'church_api.dart';

/// One shared sermon audio player: starting a new sermon stops the previous.
class ChurchAudioPlayer extends ChangeNotifier {
  ChurchAudioPlayer._internal() {
    _playerStateSub = _player.playerStateStream.listen(_onPlayerState);
    _positionSub = _player.positionStream.listen(_onPosition);
  }

  static final ChurchAudioPlayer instance = ChurchAudioPlayer._internal();

  final AudioPlayer _player = AudioPlayer();

  String? _activeKey;
  String? _loadingKey;

  bool _showPauseIcon = false;
  bool _handlingPlaybackEnded = false;

  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<Duration>? _positionSub;

  AudioPlayer get player => _player;

  static String? sermonKey(Map<String, dynamic> m) {
    final id = m['id'];
    if (id != null) return id.toString();
    final url = m['audioUrl'];
    if (url is String && url.trim().isNotEmpty) return url.trim();
    final title = m['title'];
    if (title != null) return title.toString();
    return null;
  }

  bool isAudioFocus(Map<String, dynamic> m) {
    final key = sermonKey(m);
    if (key == null) return false;
    return _activeKey == key;
  }

  bool isPlayingFor(Map<String, dynamic> m) => isAudioFocus(m) && _showPauseIcon;

  bool isPausedFor(Map<String, dynamic> m) {
    if (!isAudioFocus(m) || _showPauseIcon) return false;
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

  bool isLoadingFor(Map<String, dynamic> m) {
    final key = sermonKey(m);
    if (key == null) return false;
    if (_loadingKey != null && _loadingKey == key) return true;
    if (!isAudioFocus(m) || _showPauseIcon) return false;
    final p = _player.processingState;
    return p == ProcessingState.loading || p == ProcessingState.buffering;
  }

  Future<String?> _resolveAudioUrl(Map<String, dynamic> m) async {
    final raw = m['audioUrl'];
    if (raw is String && raw.trim().isNotEmpty) return raw.trim();
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

  Future<bool> toggle(Map<String, dynamic> m) async {
    final key = sermonKey(m);
    if (key == null) return false;

    // Ignore taps on a different sermon while one is loading
    if (_loadingKey != null && _loadingKey != key) return true;

    // Same sermon — just pause or resume
    if (_activeKey == key) {
      if (_showPauseIcon) {
        _setShowPauseIcon(false);
        notifyListeners();
        await _player.pause();
      } else {
        final ps = _player.processingState;
        if (ps == ProcessingState.completed || _isNearEnd) {
          await _player.seek(Duration.zero);
        }
        _setShowPauseIcon(true);
        notifyListeners();
        await _player.play();
      }
      return true;
    }

    // New sermon — load and play
    _loadingKey = key;
    _activeKey = null;
    _setShowPauseIcon(false);
    notifyListeners();

    await _player.stop();

    try {
      final url = await _resolveAudioUrl(m);
      if (url == null || url.isEmpty) {
        _loadingKey = null;
        notifyListeners();
        return false;
      }

      await _player.setUrl(url);

      _activeKey = key;
      _loadingKey = null;
      _setShowPauseIcon(true);
      notifyListeners();

      await _player.play();
      return true;
    } catch (e, st) {
      debugPrint('ChurchAudioPlayer.toggle: $e\n$st');
      _activeKey = null;
      _loadingKey = null;
      _setShowPauseIcon(false);
      await _player.stop();
      notifyListeners();
      return false;
    }
  }

  Future<void> stop() async {
    _activeKey = null;
    _setShowPauseIcon(false);
    notifyListeners();
    await _player.stop();
  }

  void _setShowPauseIcon(bool value) {
    _showPauseIcon = value;
  }

  bool get _isNearEnd {
    final duration = _player.duration;
    if (duration == null || duration <= Duration.zero) return false;
    final position = _player.position;
    if (position <= Duration.zero) return false;
    final slackMs = duration.inMilliseconds < 800 ? 50 : 400;
    return position >= duration - Duration(milliseconds: slackMs);
  }

  // Streams ONLY handle natural playback completion — nothing else
  void _onPlayerState(PlayerState state) {
    if (!_showPauseIcon) return; // we're not playing, ignore all stream noise
    if (state.processingState == ProcessingState.completed) {
      _handlePlaybackEnded();
    }
  }

  void _onPosition(Duration position) {
    if (!_showPauseIcon) return;
    final duration = _player.duration;
    if (duration == null || duration <= Duration.zero) return;
    final slackMs = duration.inMilliseconds < 800 ? 50 : 400;
    if (position > Duration.zero &&
        position >= duration - Duration(milliseconds: slackMs)) {
      _handlePlaybackEnded();
    }
  }

  Future<void> _handlePlaybackEnded() async {
    if (_handlingPlaybackEnded) return;
    _handlingPlaybackEnded = true;

    _setShowPauseIcon(false);
    _activeKey = null;
    notifyListeners();

    try {
      if (_player.playing) await _player.pause();
      final duration = _player.duration;
      if (duration != null && duration > Duration.zero) {
        await _player.seek(Duration.zero);
      }
    } finally {
      _handlingPlaybackEnded = false;
    }
  }

  @override
  void dispose() {
    _playerStateSub?.cancel();
    _positionSub?.cancel();
    _player.dispose();
    super.dispose();
  }
}