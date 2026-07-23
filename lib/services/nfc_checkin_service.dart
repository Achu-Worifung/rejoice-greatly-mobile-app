import 'dart:async';
import 'dart:convert';

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

  /// Runs the full check-in: verify NFC, read the tag id, POST it, and map the
  /// outcome to a [NfcCheckinResult].
  static Future<NfcCheckinResult> checkIn() async {
    if (!await isAvailable()) {
      return NfcCheckinResult.failure(
        NfcCheckinErrorKind.unavailable,
        'NFC isn’t available on this device. Turn it on in Settings, or '
        'ask a volunteer to check you in.',
      );
    }

    final String tagId;
    try {
      tagId = await _readTagId();
    } on _TagException catch (e) {
      return NfcCheckinResult.failure(e.kind, _messageForTagError(e.kind));
    } on TimeoutException {
      return NfcCheckinResult.failure(
        NfcCheckinErrorKind.noTag,
        'No tag detected. Hold your phone flat against the tag and try again.',
      );
    } catch (e) {
      debugPrint('NfcCheckinService read failed: $e');
      return NfcCheckinResult.failure(
        NfcCheckinErrorKind.unreadableTag,
        'We couldn’t read that tag. Please try again.',
      );
    }

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

  /// Admin utility: writes [tagId] onto a blank/writable tag as an NDEF Text
  /// record so it can be used for check-in. Throws on failure (used by the
  /// provisioning UI, which reports the error itself).
  static Future<void> writeTag(String tagId) async {
    final trimmed = tagId.trim();
    if (trimmed.isEmpty) {
      throw const _TagException(NfcCheckinErrorKind.unreadableTag);
    }
    if (!await isAvailable()) {
      throw const _TagException(NfcCheckinErrorKind.unavailable);
    }

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
          final message = NdefMessage([NdefRecord.createText(trimmed)]);
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

  // ── Tag reading ────────────────────────────────────────────────────────────

  static Future<String> _readTagId() async {
    final completer = Completer<String>();
    await NfcManager.instance.startSession(
      pollingOptions: _pollingOptions,
      alertMessage: 'Hold your phone near the check-in tag.',
      onDiscovered: (NfcTag tag) async {
        try {
          final tagId = _extractTagId(tag);
          await NfcManager.instance.stopSession();
          if (!completer.isCompleted) completer.complete(tagId);
        } catch (e) {
          await NfcManager.instance
              .stopSession(errorMessage: 'Could not read this tag.');
          if (!completer.isCompleted) completer.completeError(e);
        }
      },
    );

    return completer.future.timeout(_sessionTimeout, onTimeout: () {
      NfcManager.instance.stopSession();
      throw TimeoutException('No tag detected');
    });
  }

  /// Pulls the tag id out of the first NDEF Text record on the tag.
  static String _extractTagId(NfcTag tag) {
    final ndef = Ndef.from(tag);
    if (ndef == null) {
      throw const _TagException(NfcCheckinErrorKind.unreadableTag);
    }
    final message = ndef.cachedMessage;
    if (message == null || message.records.isEmpty) {
      throw const _TagException(NfcCheckinErrorKind.unreadableTag);
    }
    for (final record in message.records) {
      final text = _decodeTextRecord(record);
      if (text != null && text.trim().isNotEmpty) return text.trim();
    }
    throw const _TagException(NfcCheckinErrorKind.unreadableTag);
  }

  /// Decodes a Well-Known Text ('T') record to its text payload, or null if the
  /// record isn't a Text record. Layout: `payload[0]` low 6 bits hold the
  /// language-code length; the value is the utf8 of the bytes after it.
  ///
  /// A Text record is identified by its type being the single byte 'T' (0x54) —
  /// which is what [NdefRecord.createText] (used to provision our tags) writes.
  static String? _decodeTextRecord(NdefRecord record) {
    if (record.type.length != 1 || record.type.first != 0x54) return null;

    final payload = record.payload;
    if (payload.isEmpty) return null;
    final languageCodeLength = payload.first & 0x3F; // low 6 bits
    final start = 1 + languageCodeLength;
    if (start > payload.length) return null;
    try {
      return utf8.decode(payload.sublist(start));
    } catch (_) {
      return null;
    }
  }

  // ── Error copy ───────────────────────────────────────────────────────────────

  static String _messageForTagError(NfcCheckinErrorKind kind) {
    switch (kind) {
      case NfcCheckinErrorKind.unavailable:
        return 'NFC isn’t available on this device.';
      case NfcCheckinErrorKind.unreadableTag:
        return 'This tag couldn’t be read. Please ask a volunteer for help.';
      case NfcCheckinErrorKind.noTag:
        return 'No tag detected. Hold your phone flat against the tag and try again.';
      default:
        return 'Something went wrong reading the tag. Please try again.';
    }
  }

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
