import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:nfc_manager/nfc_manager.dart';

import 'church_api.dart';

/// Why an NFC check-in did not succeed. Callers use this to react distinctly —
/// e.g. prompt re-login on [unauthorized], vs. surface a network hint on
/// [network] — while the human-readable copy lives on [NfcCheckinResult.message].
enum NfcCheckinErrorKind {
  /// The device has no NFC hardware or it is disabled/unsupported (incl. web).
  unavailable,

  /// A tag was found but carries no readable NDEF Text record.
  unreadableTag,

  /// The NFC session ended without a tag being tapped (timeout/cancel).
  noTag,

  /// 401 — the Firebase id token was rejected; the member should sign in again.
  unauthorized,

  /// 404 — the tag is not a registered+active tag, or the account was not found.
  unrecognizedTag,

  /// Could not reach the church server (timeout / no connection).
  network,

  /// Any other server-side failure (400, 5xx, unexpected shape).
  server,
}

/// Outcome of [NfcCheckinService.checkIn]. On success carries the banner
/// [message] and whether the member was [alreadyPresent]; on failure carries an
/// [errorKind] plus a member-friendly [message].
class NfcCheckinResult {
  const NfcCheckinResult._({
    required this.success,
    required this.message,
    this.alreadyPresent = false,
    this.name,
    this.attendedAt,
    this.errorKind,
  });

  final bool success;
  final String message;
  final bool alreadyPresent;
  final String? name;
  final String? attendedAt;
  final NfcCheckinErrorKind? errorKind;

  factory NfcCheckinResult.ok({
    required String message,
    required bool alreadyPresent,
    String? name,
    String? attendedAt,
  }) =>
      NfcCheckinResult._(
        success: true,
        message: message,
        alreadyPresent: alreadyPresent,
        name: name,
        attendedAt: attendedAt,
      );

  factory NfcCheckinResult.failure(
    NfcCheckinErrorKind kind,
    String message,
  ) =>
      NfcCheckinResult._(
        success: false,
        message: message,
        errorKind: kind,
      );
}

/// Internal signal raised while reading/writing a tag, carrying the error kind
/// so the orchestration layer can translate it into a [NfcCheckinResult].
class _TagException implements Exception {
  const _TagException(this.kind);
  final NfcCheckinErrorKind kind;
}

/// Reads NFC tags for attendance check-in and (admin) writes tag ids onto blank
/// tags. All member-facing flows funnel through [checkIn], which returns a
/// [NfcCheckinResult] rather than throwing so the UI stays declarative.
class NfcCheckinService {
  NfcCheckinService._();

  static const Set<NfcPollingOption> _pollingOptions = {
    NfcPollingOption.iso14443,
    NfcPollingOption.iso15693,
    NfcPollingOption.iso18092,
  };

  /// How long to wait for a tag before giving up. iOS shows its own system
  /// sheet; on Android there is no sheet, so this timeout is what ends a
  /// forgotten session.
  static const Duration _sessionTimeout = Duration(seconds: 25);

  /// Whether this device can scan NFC tags right now. Returns false (rather than
  /// throwing) on web/desktop or when NFC is switched off.
  static Future<bool> isAvailable() async {
    if (kIsWeb) return false;
    try {
      return await NfcManager.instance.isAvailable();
    } catch (e) {
      debugPrint('NfcCheckinService.isAvailable failed: $e');
      return false;
    }
  }

  /// Submits a check-in for a tag id the caller already has. Used by the NFC
  /// deep-link flow (`NfcAutoCheckinPage`), where the OS already handed the
  /// app the tag id from the tapped link, so no on-device NFC session is
  /// needed — the physical tap itself is the read.
  static Future<NfcCheckinResult> checkInWithTagId(String tagId) {
    final trimmed = tagId.trim();
    if (trimmed.isEmpty) {
      return Future.value(NfcCheckinResult.failure(
        NfcCheckinErrorKind.unreadableTag,
        'That check-in link is missing its tag id.',
      ));
    }
    return _submitCheckin(trimmed);
  }

  static Future<NfcCheckinResult> _submitCheckin(String tagId) async {
    try {
      final data = await ChurchApi.nfcCheckin(tagId);
      final alreadyPresent = data['alreadyPresent'] == true;
      final serverMessage = (data['message'] as String?)?.trim();
      return NfcCheckinResult.ok(
        message: (serverMessage != null && serverMessage.isNotEmpty)
            ? serverMessage
            : (alreadyPresent
                ? 'Already marked present today.'
                : 'Marked present for today.'),
        alreadyPresent: alreadyPresent,
        name: (data['name'] as String?)?.trim(),
        attendedAt: (data['attendedAt'] as String?)?.trim(),
      );
    } on ChurchApiException catch (e) {
      return _resultForApiError(e);
    } on TimeoutException {
      return NfcCheckinResult.failure(
        NfcCheckinErrorKind.network,
        'Couldn’t reach the church server. Check your connection and try again.',
      );
    } catch (e) {
      debugPrint('NfcCheckinService checkin request failed: $e');
      return NfcCheckinResult.failure(
        NfcCheckinErrorKind.network,
        'Couldn’t reach the church server. Check your connection and try again.',
      );
    }
  }

  /// The host our check-in links resolve through (Android App/NDEF dispatch
  /// and iOS Universal Links both verify against this domain — see the admin
  /// app's `/.well-known` files).
  ///
  /// Also read by `NfcDeepLinkService`, which only acts on links from this
  /// host, and mirrored in `ios/Runner/AppDelegate.swift` (which claims these
  /// links so iOS doesn't also open them in Safari) and in the Android
  /// manifest's `NDEF_DISCOVERED` intent filter. Keep all four in step.
  static const String checkinLinkHost = 'rejoice-greatly-admin.vercel.app';

  /// Admin utility: writes [tagId] onto a blank/writable tag so it can be
  /// used for check-in. Writes two NDEF records — a URI record first (so
  /// Android's NDEF dispatch and iOS Universal Links can auto-open the app
  /// straight from a tap, even when it's closed) and a Well-Known Text
  /// record second (read by [_extractTagId] for the existing in-app manual
  /// "Check in with NFC" flow, so both paths work off one tag). Throws on
  /// failure (used by the provisioning UI, which reports the error itself).
  static Future<void> writeTag(String tagId) async {
    final trimmed = tagId.trim();
    if (trimmed.isEmpty) {
      throw const _TagException(NfcCheckinErrorKind.unreadableTag);
    }
    if (!await isAvailable()) {
      throw const _TagException(NfcCheckinErrorKind.unavailable);
    }

    final checkinUri = Uri.https(checkinLinkHost, '/nfc-checkin/$trimmed');

    final completer = Completer<void>();
    await NfcManager.instance.startSession(
      pollingOptions: _pollingOptions,
      alertMessage: 'Hold a blank tag against the phone to write it.',
      onDiscovered: (NfcTag tag) async {
        try {
          final ndef = Ndef.from(tag);
          if (ndef == null || !ndef.isWritable) {
            throw const _TagException(NfcCheckinErrorKind.unreadableTag);
          }
          final message = NdefMessage([
            NdefRecord.createUri(checkinUri),
            NdefRecord.createText(trimmed),
          ]);
          await ndef.write(message);
          await NfcManager.instance.stopSession(alertMessage: 'Tag written.');
          if (!completer.isCompleted) completer.complete();
        } catch (e) {
          await NfcManager.instance
              .stopSession(errorMessage: 'Could not write this tag.');
          if (!completer.isCompleted) completer.completeError(e);
        }
      },
    );

    return completer.future.timeout(_sessionTimeout, onTimeout: () {
      NfcManager.instance.stopSession();
      throw TimeoutException('No tag detected while writing');
    });
  }

  // ── Error copy ───────────────────────────────────────────────────────────────

  static NfcCheckinResult _resultForApiError(ChurchApiException e) {
    switch (e.statusCode) {
      case 401:
        return NfcCheckinResult.failure(
          NfcCheckinErrorKind.unauthorized,
          'Your session has expired. Please sign in again to check in.',
        );
      case 404:
        // 404 = account not found OR the tag isn't a registered+active tag.
        // Both read as an unrecognized tag to the member; prefer the server's
        // wording when it provides it.
        return NfcCheckinResult.failure(
          NfcCheckinErrorKind.unrecognizedTag,
          _serverOr(e, 'Unrecognized tag. Please ask a volunteer for help.'),
        );
      case 400:
        return NfcCheckinResult.failure(
          NfcCheckinErrorKind.server,
          _serverOr(e, 'That tag couldn’t be read. Please try again.'),
        );
      case 403:
        // Not a service day, or outside the service-hours window (see
        // NfcService on the backend) — the server's message names the days
        // or hours check-in is open, so show it rather than our fallback.
        return NfcCheckinResult.failure(
          NfcCheckinErrorKind.server,
          _serverOr(e, 'NFC check-in isn’t available right now.'),
        );
      default:
        return NfcCheckinResult.failure(
          NfcCheckinErrorKind.server,
          _serverOr(e, 'Something went wrong on our end. Please try again.'),
        );
    }
  }

  static String _serverOr(ChurchApiException e, String fallback) {
    final msg = e.serverMessage?.trim();
    return (msg != null && msg.isNotEmpty) ? msg : fallback;
  }
}
