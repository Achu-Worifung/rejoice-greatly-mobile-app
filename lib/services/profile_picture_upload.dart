import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'api_envelope.dart';
import 'church_api.dart';

/// Why a profile picture upload failed, in a form the UI can switch on.
///
/// The face-validation cases are carried as `errorCode` in the response
/// envelope rather than as HTTP statuses. The previous multipart endpoint
/// overloaded 400/401/403 for "not clear"/"multiple faces"/"no face", which
/// collides with the real meanings of 401 and 403 — and the commit call *can*
/// genuinely 401 on an expired id token, so the two must stay distinguishable.
enum PictureUploadError {
  faceNotClear,
  multipleFaces,
  noFaceDetected,
  notAuthenticated,
  accountMissing,
  network,
  unknown,
}

class PictureUploadException implements Exception {
  const PictureUploadException(this.kind, this.message);

  final PictureUploadError kind;

  /// Already phrased for the member — surface it directly.
  final String message;

  @override
  String toString() => 'PictureUploadException($kind): $message';
}

/// A short-lived, single-use authorization to upload one profile picture.
///
/// [key] and [iv] are minted by the backend per grant and wrapped into Key
/// Vault before the grant is handed out, so the app never holds long-lived key
/// material and never learns the storage account key.
class _UploadGrant {
  const _UploadGrant({
    required this.uploadUrl,
    required this.uploadToken,
    required this.key,
    required this.iv,
    required this.expiresAt,
  });

  final Uri uploadUrl;
  final String uploadToken;
  final Uint8List key;
  final Uint8List iv;
  final DateTime? expiresAt;

  /// Treats a grant as spent slightly early: the PUT itself takes time, and a
  /// SAS that expires mid-upload fails in a way that looks like a network
  /// error rather than an expiry.
  bool get isUsable {
    final exp = expiresAt;
    if (exp == null) return true;
    return DateTime.now().isBefore(exp.subtract(const Duration(seconds: 30)));
  }
}

/// Uploads the signup selfie straight to Azure Blob Storage using a
/// backend-issued SAS URL, so the storage account key never ships in the app.
///
/// Three steps:
///   1. `POST /auth/picture-upload/sas`    — SAS URL + a fresh AES-256-GCM key
///   2. `PUT <uploadUrl>`                  — AES-GCM ciphertext, direct to Azure
///   3. `POST /auth/picture-upload/commit` — backend decrypts, runs face
///      validation, publishes the servable image, deletes the staging blob
///
/// The blob written in step 2 is a *staging* artifact and is encrypted: a
/// leaked SAS URL yields ciphertext only. The image the app later renders via
/// `imgURL` is written by the backend in step 3 and is not encrypted, because
/// it is fetched by `Image.network` all over the app.
///
/// See `docs/PROFILE_PICTURE_UPLOAD.md` for the backend contract.
class ProfilePictureUpload {
  ProfilePictureUpload._();

  static const Duration _httpTimeout = Duration(seconds: 60);

  static final AesGcm _algorithm = AesGcm.with256bits();

  /// Uploads [jpegBytes] and returns the published `imgURL`.
  ///
  /// Throws [PictureUploadException] with a member-facing message.
  static Future<String> upload(Uint8List jpegBytes) async {
    try {
      var grant = await _requestGrant();

      // A grant that expired between issue and use is retried once with a
      // fresh one. Beyond that, something other than latency is wrong.
      if (!grant.isUsable) {
        debugPrint('ProfilePictureUpload: grant expired before use, reissuing');
        grant = await _requestGrant();
      }

      final ciphertext = await _encrypt(jpegBytes, grant);
      await _putBlob(grant, ciphertext);
      return await _commit(grant);
    } on PictureUploadException {
      rethrow;
    } catch (e, st) {
      debugPrint('ProfilePictureUpload failed: $e\n$st');
      throw const PictureUploadException(
        PictureUploadError.network,
        'Network error. Please try again.',
      );
    }
  }

  static Future<_UploadGrant> _requestGrant() async {
    final tokenBundle = await ChurchApi.requireIdToken();
    final data = await _post('/auth/picture-upload/sas', {
      'idToken': tokenBundle.token,
      'contentType': 'image/jpeg',
    });

    final uploadUrl = data['uploadUrl'] as String?;
    final uploadToken = data['uploadToken'] as String?;
    final key = _decodeBytes(data['key'], 32, 'key');
    final iv = _decodeBytes(data['iv'], 12, 'iv');

    if (uploadUrl == null || uploadUrl.isEmpty || uploadToken == null) {
      throw const PictureUploadException(
        PictureUploadError.unknown,
        'The server did not return a valid upload link. Please try again.',
      );
    }

    return _UploadGrant(
      uploadUrl: Uri.parse(uploadUrl),
      uploadToken: uploadToken,
      key: key,
      iv: iv,
      expiresAt: DateTime.tryParse('${data['expiresAt']}')?.toLocal(),
    );
  }

  /// Rejects a key or IV of the wrong length rather than letting the platform
  /// throw further in. A short IV in particular is the kind of backend bug that
  /// silently weakens GCM, so it must fail loudly here.
  static Uint8List _decodeBytes(Object? raw, int expectedLength, String label) {
    if (raw is! String || raw.isEmpty) {
      throw PictureUploadException(
        PictureUploadError.unknown,
        'The server did not return a valid upload $label. Please try again.',
      );
    }
    final bytes = base64Decode(raw);
    if (bytes.length != expectedLength) {
      throw PictureUploadException(
        PictureUploadError.unknown,
        'The server returned an upload $label of the wrong size. '
        'Please try again.',
      );
    }
    return bytes;
  }

  /// AES-256-GCM, output laid out as `ciphertext || tag` so the backend can
  /// split the trailing 16 bytes off without a second field.
  static Future<Uint8List> _encrypt(
    Uint8List plaintext,
    _UploadGrant grant,
  ) async {
    final secretKey = SecretKey(grant.key);
    try {
      final box = await _algorithm.encrypt(
        plaintext,
        secretKey: secretKey,
        nonce: grant.iv,
      );
      final out = BytesBuilder(copy: false)
        ..add(box.cipherText)
        ..add(box.mac.bytes);
      return out.takeBytes();
    } finally {
      // The grant is single-use; keeping the key in memory past this point
      // only widens the window for a heap dump to catch it.
      grant.key.fillRange(0, grant.key.length, 0);
    }
  }

  static Future<void> _putBlob(_UploadGrant grant, Uint8List body) async {
    final r = await http
        .put(
          grant.uploadUrl,
          headers: const {
            'x-ms-blob-type': 'BlockBlob',
            'Content-Type': 'application/octet-stream',
          },
          body: body,
        )
        .timeout(_httpTimeout);

    debugPrint('ProfilePictureUpload: PUT blob -> ${r.statusCode}');
    if (r.statusCode == 201 || r.statusCode == 200) return;

    // Azure answers an expired or malformed SAS with 403 and an XML body; it
    // is not the app's own auth failing, so do not report it as one.
    if (r.statusCode == 403) {
      throw const PictureUploadException(
        PictureUploadError.network,
        'Your upload link expired. Please try again.',
      );
    }
    throw PictureUploadException(
      PictureUploadError.network,
      'Could not upload your photo (${r.statusCode}). Please try again.',
    );
  }

  /// Hands the blob back to the backend, which decrypts it, runs face
  /// validation, and publishes the servable image.
  static Future<String> _commit(_UploadGrant grant) async {
    final tokenBundle = await ChurchApi.requireIdToken();
    final data = await _post('/auth/picture-upload/commit', {
      'idToken': tokenBundle.token,
      'uploadToken': grant.uploadToken,
    });

    final imgUrl = data['imgURL'] as String?;
    if (imgUrl == null || imgUrl.isEmpty) {
      throw const PictureUploadException(
        PictureUploadError.unknown,
        'Your photo was uploaded but the server did not return it. '
        'Please try again.',
      );
    }
    return imgUrl;
  }

  /// Like [ChurchApi.postJson], but preserves the envelope's `errorCode` and
  /// `message` on failure instead of collapsing them into a generic throw.
  static Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final uri = Uri.parse('${ChurchApi.baseUrl}$path');
    final r = await http
        .post(
          uri,
          headers: const {'Content-Type': 'application/json'},
          body: json.encode(body),
        )
        .timeout(_httpTimeout);

    debugPrint('ProfilePictureUpload: POST ${uri.path} -> ${r.statusCode}');
    if (r.statusCode == 200 || r.statusCode == 201) {
      try {
        return unwrapApiMap(r.body);
      } on FormatException {
        throw const PictureUploadException(
          PictureUploadError.unknown,
          'The server sent back an unexpected response. Please try again.',
        );
      }
    }
    throw _errorFromBody(r.statusCode, r.body);
  }

  static PictureUploadException _errorFromBody(int statusCode, String body) {
    // A failure envelope carries `errorCode`/`message` at the top level with a
    // null `data`, so it is read unwrapped.
    Map<String, dynamic>? decoded;
    try {
      final v = json.decode(body);
      if (v is Map) decoded = Map<String, dynamic>.from(v);
    } catch (_) {}

    final code = '${decoded?['errorCode'] ?? ''}'.toUpperCase();
    final serverMessage = _firstNonEmpty(decoded, const [
      'message',
      'msg',
      'error',
      'detail',
    ]);

    switch (code) {
      case 'FACE_NOT_CLEAR':
        return const PictureUploadException(
          PictureUploadError.faceNotClear,
          'Facial image not clear enough.',
        );
      case 'MULTIPLE_FACES':
        return const PictureUploadException(
          PictureUploadError.multipleFaces,
          'Multiple faces detected.',
        );
      case 'NO_FACE_DETECTED':
        return const PictureUploadException(
          PictureUploadError.noFaceDetected,
          'No face detected.',
        );
      case 'UPLOAD_TOKEN_EXPIRED':
        return const PictureUploadException(
          PictureUploadError.network,
          'Your upload link expired. Please try again.',
        );
    }

    if (statusCode == 401 || statusCode == 403) {
      return const PictureUploadException(
        PictureUploadError.notAuthenticated,
        'Your session expired. Please sign in again.',
      );
    }
    if (statusCode == 404) {
      return const PictureUploadException(
        PictureUploadError.accountMissing,
        'Account could not be found. Please check your connection and try again.',
      );
    }
    return PictureUploadException(
      PictureUploadError.unknown,
      serverMessage ?? 'Upload failed ($statusCode). Please try again.',
    );
  }

  static String? _firstNonEmpty(Map<String, dynamic>? map, List<String> keys) {
    if (map == null) return null;
    for (final key in keys) {
      final v = map[key];
      if (v is String && v.trim().isNotEmpty) return v.trim();
    }
    return null;
  }
}
