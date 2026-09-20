import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

import 'church_api.dart';

/// One shared sermon audio player: starting a new sermon stops the previous.
///
/// Playback runs through `just_audio_background`, so a sermon keeps playing
/// with the app backgrounded or the screen locked, and the OS shows transport
/// controls (notification shade / lock screen / Control Center). Those system
/// controls talk straight to [_player], so every piece of UI state here is
/// derived from the player rather than from what the last in-app tap did —
/// otherwise a pause from the lock screen would leave the app showing "Pause".
class ChurchAudioPlayer extends ChangeNotifier {
  ChurchAudioPlayer._internal() {
    _playerStateSub = _player.playerStateStream.listen(_onPlayerState);
    _positionSub = _player.positionStream.listen(_onPosition);
  }

  static final ChurchAudioPlayer instance = ChurchAudioPlayer._internal();

  final AudioPlayer _player = AudioPlayer();

  String? _activeKey;
  String? _loadingKey;

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

  bool isPlayingFor(Map<String, dynamic> m) {
    if (!isAudioFocus(m)) return false;
    if (!_player.playing) return false;
    return _player.processingState != ProcessingState.completed;
  }

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

  bool isLoadingFor(Map<String, dynamic> m) {
    final key = sermonKey(m);
    if (key == null) return false;
    if (_loadingKey != null && _loadingKey == key) return true;
    if (!isAudioFocus(m) || !_player.playing) return false;
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

  /// What the lock screen and notification show for this sermon.
  MediaItem _mediaItem(Map<String, dynamic> m, String key) {
    final title = (m['title'] as String?)?.trim();
    final speaker = (m['speaker'] as String?)?.trim();
    final category = (m['category'] as String?)?.trim();
    return MediaItem(
      id: key,
      title: title == null || title.isEmpty ? 'Sermon' : title,
      artist: speaker == null || speaker.isEmpty ? null : speaker,
      album: category == null || category.isEmpty ? 'Rejoice Greatly' : category,
      artUri: _artUri(m['imageUrl']),
    );
  }

  Uri? _artUri(Object? raw) {
    if (raw is! String) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) return null;
    return uri;
  }

  Future<bool> toggle(Map<String, dynamic> m) async {
    final key = sermonKey(m);
    if (key == null) return false;

    // Ignore taps on a different sermon while one is loading
    if (_loadingKey != null && _loadingKey != key) return true;

    // Same sermon — just pause or resume
    if (_activeKey == key) {
      if (_player.playing) {
        await _player.pause();
      } else {
        final ps = _player.processingState;
        if (ps == ProcessingState.completed || _isNearEnd) {
          await _player.seek(Duration.zero);
        }
        await _player.play();
      }
      notifyListeners();
      return true;
    }

    // New sermon — load and play
    _loadingKey = key;
    _activeKey = null;
    notifyListeners();

    await _player.stop();

    try {
      final url = await _resolveAudioUrl(m);
      if (url == null || url.isEmpty) {
        _loadingKey = null;
        notifyListeners();
        return false;
      }

      // The MediaItem tag is what `just_audio_background` publishes to the
      // OS, so the notification names the sermon instead of the app.
      await _player.setAudioSource(
        AudioSource.uri(Uri.parse(url), tag: _mediaItem(m, key)),
      );

      _activeKey = key;
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
    _activeKey = null;
    notifyListeners();
    await _player.stop();
  }

  bool get _isNearEnd {
    final duration = _player.duration;
    if (duration == null || duration <= Duration.zero) return false;
    final position = _player.position;
    if (position <= Duration.zero) return false;
    final slackMs = duration.inMilliseconds < 800 ? 50 : 400;
    return position >= duration - Duration(milliseconds: slackMs);
  }

  // Playback can now be driven from outside the app (lock screen, headset
  // buttons, Control Center), so every state change has to reach the UI.
  void _onPlayerState(PlayerState state) {
    if (state.processingState == ProcessingState.completed) {
      _handlePlaybackEnded();
      return;
    }
    notifyListeners();
  }

  void _onPosition(Duration position) {
    if (!_player.playing) return;
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

    _activeKey = null;
    notifyListeners();

    try {
      // stop() (rather than pause + seek) also tears down the media session,
      // so a finished sermon doesn't leave a stale control tile on the lock
      // screen after the app has gone back to "Listen to sermon".
      await _player.stop();
    } finally {
      _handlingPlaybackEnded = false;
      notifyListeners();
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
