import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pointycastle/export.dart';

import 'church_api.dart';

/// Raised when the backend rejects an upload with a stable error code, so the
/// UI can branch on [code] (retake the photo vs. re-authenticate vs. retry).
class PictureUploadException implements Exception {
  PictureUploadException(this.code, this.message);

  /// One of the backend's stable codes, e.g. `NO_FACE_DETECTED`,
  /// `MULTIPLE_FACES`, `FACE_NOT_CLEAR`, `UPLOAD_TOKEN_EXPIRED`.
  final String code;
  final String message;

  @override
  String toString() => 'PictureUploadException($code): $message';
}

/// Client half of the encrypted profile-picture upload.
///
/// The storage account key never ships in the app: the backend hands out a
/// short-lived, write-only SAS plus one-shot AES-256-GCM material. The photo is
/// encrypted on-device and PUT straight to Azure as ciphertext, so a leaked SAS
/// yields nothing readable. The backend only sees the photo at commit, where it
/// validates the face and publishes it.
///
/// Mirrors `ProfilePictureController` / `PictureCryptoService` on the backend:
///   1. POST /auth/picture-upload/sas   -> { uploadUrl, uploadToken, key, iv }
///   2. PUT  <uploadUrl>  (AES-256-GCM ciphertext||tag, x-ms-blob-type: BlockBlob)
///   3. POST /auth/picture-upload/commit -> { imgURL }
class ProfilePictureUploadService {
  static const Duration _timeout = Duration(seconds: 60);

  /// GCM nonce length the backend uses (96-bit), and the 128-bit tag it expects
  /// appended to the ciphertext — exactly what `AES/GCM/NoPadding` produces.
  static const int _ivBytes = 12;
  static const int _tagBits = 128;

  /// Runs the full SAS -> encrypt -> PUT -> commit flow. Returns the signed,
  /// readable `imgURL` of the published picture.
  ///
  /// [idToken] is a fresh Firebase ID token; [jpegBytes] the captured photo.
  static Future<String> upload({
    required String idToken,
    required Uint8List jpegBytes,
  }) async {
    final grant = await _requestGrant(idToken);

    final key = base64.decode(grant.keyBase64);
    final iv = base64.decode(grant.ivBase64);
    final ciphertext = _encryptGcm(key: key, iv: iv, plaintext: jpegBytes);

    await _putToAzure(grant.uploadUrl, ciphertext);

    return _commit(idToken: idToken, uploadToken: grant.uploadToken);
  }

  // --- Step 1: grant --------------------------------------------------------

  static Future<_SasGrant> _requestGrant(String idToken) async {
    final data = await _postForData(
      '/auth/picture-upload/sas',
      {'idToken': idToken, 'contentType': 'image/jpeg'},
    );
    return _SasGrant(
      uploadUrl: data['uploadUrl'] as String,
      uploadToken: data['uploadToken'] as String,
      keyBase64: data['key'] as String,
      ivBase64: data['iv'] as String,
    );
  }

  // --- Step 2: encrypt + PUT ------------------------------------------------

  /// AES-256-GCM over the raw JPEG. PointyCastle returns `ciphertext || tag`
  /// with a 128-bit tag, byte-for-byte what the backend's
  /// `PictureCryptoService.decryptBlob` feeds to `AES/GCM/NoPadding`.
  static Uint8List _encryptGcm({
    required Uint8List key,
    required Uint8List iv,
    required Uint8List plaintext,
  }) {
    if (iv.length != _ivBytes) {
      throw StateError('Expected a $_ivBytes-byte IV, got ${iv.length}');
    }
    final cipher = GCMBlockCipher(AESEngine())
      ..init(
        true,
        AEADParameters(KeyParameter(key), _tagBits, iv, Uint8List(0)),
      );
    return cipher.process(plaintext);
  }

  static Future<void> _putToAzure(String uploadUrl, Uint8List ciphertext) async {
    final resp = await http
        .put(
          Uri.parse(uploadUrl),
          // Azure requires the blob type on a create-blob PUT; the content is
          // opaque ciphertext, so an octet-stream type is honest.
          headers: {
            'x-ms-blob-type': 'BlockBlob',
            'Content-Type': 'application/octet-stream',
          },
          body: ciphertext,
        )
        .timeout(_timeout);

    if (resp.statusCode != 201 && resp.statusCode != 200) {
      throw PictureUploadException(
        'UPLOAD_FAILED',
        'Could not upload your photo (${resp.statusCode}). Please try again.',
      );
    }
  }

  // --- Step 3: commit -------------------------------------------------------

  static Future<String> _commit({
    required String idToken,
    required String uploadToken,
  }) async {
    final data = await _postForData(
      '/auth/picture-upload/commit',
      {'idToken': idToken, 'uploadToken': uploadToken},
    );
    return data['imgURL'] as String;
  }

  // --- Envelope-aware POST helper ------------------------------------------

  /// POSTs JSON and returns the `data` object. Tolerates both the backend's
  /// `ApiResponse` envelope ({success, data, errorCode}) and a bare body, and
  /// surfaces the backend's stable error code as a [PictureUploadException].
  static Future<Map<String, dynamic>> _postForData(
    String path,
    Map<String, dynamic> body,
  ) async {
    final uri = Uri.parse('${ChurchApi.baseUrl}$path');
    final resp = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: json.encode(body),
        )
        .timeout(_timeout);

    Map<String, dynamic>? decoded;
    try {
      final parsed = json.decode(resp.body);
      if (parsed is Map<String, dynamic>) decoded = parsed;
    } catch (_) {
      // Fall through to status-based handling below.
    }

    if (resp.statusCode == 200 || resp.statusCode == 201) {
      if (decoded != null) {
        final inner = decoded['data'];
        if (inner is Map<String, dynamic>) return inner; // enveloped
        if (!decoded.containsKey('success')) return decoded; // bare body
      }
      throw PictureUploadException(
        'BAD_RESPONSE',
        'The server returned an unexpected response. Please try again.',
      );
    }

    final code = (decoded?['errorCode'] as String?) ?? 'UPLOAD_FAILED';
    final message = (decoded?['message'] as String?) ??
        'Upload failed (${resp.statusCode}). Please try again.';
    debugPrint('ProfilePictureUpload: $path -> ${resp.statusCode} $code');
    throw PictureUploadException(code, message);
  }
}

class _SasGrant {
  _SasGrant({
    required this.uploadUrl,
    required this.uploadToken,
    required this.keyBase64,
    required this.ivBase64,
  });

  final String uploadUrl;
  final String uploadToken;
  final String keyBase64;
  final String ivBase64;
}
