import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

import '../main.dart' show navigatorKey;
import '../pages/nfc_auto_checkin_page.dart';
import 'nfc_checkin_service.dart';

/// Watches for `/nfc-checkin/<tagId>` links — the ones written onto NFC tags
/// (see `NfcCheckinService.writeTag`) — and pushes [NfcAutoCheckinPage] when
/// one arrives, whether the app was cold-started by the tap (Android NDEF
/// dispatch) or already running (a repeat tap, or an iOS Universal Link).
///
/// `app_links`' native side re-sends the cold-start link as soon as Dart
/// subscribes, so a single [uriLinkStream] listener covers both cases —
/// there's no separate `getInitialLink()` call to make.
///
/// On iOS the same link can also be delivered more than once for a single tap
/// (the scene's connection options and `continue userActivity` can both carry
/// it, and Safari's "Open the app" fallback replays it), so deliveries are
/// de-duplicated below rather than acted on blindly.
class NfcDeepLinkService {
  NfcDeepLinkService._();

  static const String _checkinPathSegment = 'nfc-checkin';

  /// How long a tag id stays "already being handled". Long enough to swallow
  /// the OS re-delivering one tap, short enough that a member who taps again a
  /// moment later — to reassure themselves it worked — still gets a banner.
  static const Duration _duplicateWindow = Duration(seconds: 10);

  static StreamSubscription<Uri>? _subscription;

  static String? _lastTagId;
  static DateTime? _lastHandledAt;

  /// Starts listening. Call once, early in `main()` after `runApp`.
  static void startListening() {
    if (_subscription != null) return;
    _subscription = AppLinks().uriLinkStream.listen(
      _handleUri,
      onError: (Object e) => debugPrint('NfcDeepLinkService: stream error: $e'),
    );
  }

  static void _handleUri(Uri uri) {
    final tagId = _tagIdFromUri(uri);
    if (tagId == null) return;
    if (_isDuplicate(tagId)) {
      debugPrint('NfcDeepLinkService: ignoring repeat delivery of tag $tagId');
      return;
    }
    _lastTagId = tagId;
    _lastHandledAt = DateTime.now();
    _openAutoCheckin(tagId);
  }

  /// The tag id in [uri], or null when this isn't one of our check-in links.
  ///
  /// The host is checked as well as the path: only the domain our tags are
  /// written against ([NfcCheckinService.checkinLinkHost]) can send a member
  /// to the check-in flow, so an unrelated link that happens to contain
  /// `/nfc-checkin/` can't fire an attendance call.
  static String? _tagIdFromUri(Uri uri) {
    if (uri.host.toLowerCase() != NfcCheckinService.checkinLinkHost) return null;
    final segments = uri.pathSegments;
    final idx = segments.indexOf(_checkinPathSegment);
    if (idx == -1 || idx + 1 >= segments.length) return null;
    final tagId = segments[idx + 1].trim();
    return tagId.isEmpty ? null : tagId;
  }

  static bool _isDuplicate(String tagId) {
    final lastAt = _lastHandledAt;
    if (_lastTagId != tagId || lastAt == null) return false;
    return DateTime.now().difference(lastAt) < _duplicateWindow;
  }

  /// Pushes [NfcAutoCheckinPage] once the navigator is mounted. On a cold
  /// start the link can arrive before the widget tree's first frame, so this
  /// waits (bounded) rather than dropping the tap.
  static Future<void> _openAutoCheckin(String tagId) async {
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (navigatorKey.currentState == null) {
      if (DateTime.now().isAfter(deadline)) {
        debugPrint(
            'NfcDeepLinkService: navigator never became ready for tag $tagId');
        // Nothing was shown, so don't let the dropped tap block a re-tap.
        _lastTagId = null;
        _lastHandledAt = null;
        return;
      }
      await Future.delayed(const Duration(milliseconds: 50));
    }
    navigatorKey.currentState!.push(
      MaterialPageRoute(builder: (_) => NfcAutoCheckinPage(tagId: tagId)),
    );
  }
}
