import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

import '../main.dart' show navigatorKey;
import '../pages/nfc_auto_checkin_page.dart';

/// Watches for `/nfc-checkin/<tagId>` links — the ones written onto NFC tags
/// (see `NfcCheckinService.writeTag`) — and pushes [NfcAutoCheckinPage] when
/// one arrives, whether the app was cold-started by the tap (Android NDEF
/// dispatch) or already running (a repeat tap, or an iOS Universal Link).
///
/// `app_links`' native side re-sends the cold-start link as soon as Dart
/// subscribes, so a single [uriLinkStream] listener covers both cases —
/// there's no separate `getInitialLink()` call to make.
class NfcDeepLinkService {
  NfcDeepLinkService._();

  static const String _checkinPathSegment = 'nfc-checkin';

  static StreamSubscription<Uri>? _subscription;

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
    _openAutoCheckin(tagId);
  }

  static String? _tagIdFromUri(Uri uri) {
    final segments = uri.pathSegments;
    final idx = segments.indexOf(_checkinPathSegment);
    if (idx == -1 || idx + 1 >= segments.length) return null;
    final tagId = segments[idx + 1].trim();
    return tagId.isEmpty ? null : tagId;
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
        return;
      }
      await Future.delayed(const Duration(milliseconds: 50));
    }
    navigatorKey.currentState!.push(
      MaterialPageRoute(builder: (_) => NfcAutoCheckinPage(tagId: tagId)),
    );
  }
}
