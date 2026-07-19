import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pins the wire format that `ProfilePictureUpload` writes to the staging blob.
///
/// The backend splits the trailing 16 bytes off as the GCM tag (see
/// `docs/PROFILE_PICTURE_UPLOAD.md`). There is no backend to integration-test
/// against yet, so this asserts the layout independently — if the encoding ever
/// drifts, uploads would otherwise fail only at decrypt time, in production.
void main() {
  final algorithm = AesGcm.with256bits();

  test('blob layout is ciphertext || 16-byte tag and round-trips', () async {
    final key = Uint8List.fromList(List.generate(32, (i) => i));
    final iv = Uint8List.fromList(List.generate(12, (i) => 200 - i));
    final plaintext = Uint8List.fromList(
      List.generate(5000, (i) => (i * 31) % 256),
    );

    final box = await algorithm.encrypt(
      plaintext,
      secretKey: SecretKey(key),
      nonce: iv,
    );

    // The layout the client PUTs.
    final blob = Uint8List.fromList([...box.cipherText, ...box.mac.bytes]);

    expect(box.mac.bytes, hasLength(16), reason: 'GCM tag must be 16 bytes');
    expect(
      box.cipherText,
      hasLength(plaintext.length),
      reason: 'GCM is a stream mode: ciphertext must not carry the tag',
    );
    expect(blob, hasLength(plaintext.length + 16));

    // What the backend does: split the trailing tag, then decrypt.
    final recovered = await algorithm.decrypt(
      SecretBox(
        blob.sublist(0, blob.length - 16),
        nonce: iv,
        mac: Mac(blob.sublist(blob.length - 16)),
      ),
      secretKey: SecretKey(key),
    );

    expect(recovered, equals(plaintext));
  });

  test('a tampered blob fails the tag check', () async {
    final key = Uint8List.fromList(List.filled(32, 7));
    final iv = Uint8List.fromList(List.filled(12, 3));
    final plaintext = Uint8List.fromList([1, 2, 3, 4, 5]);

    final box = await algorithm.encrypt(
      plaintext,
      secretKey: SecretKey(key),
      nonce: iv,
    );
    final blob = Uint8List.fromList([...box.cipherText, ...box.mac.bytes]);
    blob[0] ^= 0xFF; // flip a bit in the ciphertext

    expect(
      () => algorithm.decrypt(
        SecretBox(
          blob.sublist(0, blob.length - 16),
          nonce: iv,
          mac: Mac(blob.sublist(blob.length - 16)),
        ),
        secretKey: SecretKey(key),
      ),
      throwsA(isA<SecretBoxAuthenticationError>()),
    );
  });
}
