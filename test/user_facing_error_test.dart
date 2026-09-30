import 'dart:async';
import 'dart:io';

import 'package:church_app/services/church_api.dart';
import 'package:church_app/services/user_facing_error.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  const backend = 'https://api.example-church.net';

  test(
    'no connection reads as offline and never shows the backend address',
    () {
      final error = http.ClientException(
        'SocketException: Failed host lookup: api.example-church.net',
        Uri.parse('$backend/sermons'),
      );

      final message = userFacingError(error);

      expect(message, offlineMessage);
      expect(message, isNot(contains('example-church')));
    },
  );

  test('an unwrapped socket error is also offline', () {
    expect(
      userFacingError(const SocketException('Connection refused')),
      offlineMessage,
    );
  });

  test('Firebase network failures are offline', () {
    expect(
      userFacingError(FirebaseAuthException(code: 'network-request-failed')),
      offlineMessage,
    );
  });

  test('a timeout says so', () {
    expect(userFacingError(TimeoutException('slow')), contains('timed out'));
  });

  test('server errors hide their details', () {
    final message = userFacingError(
      const ChurchApiException(
        500,
        serverMessage: 'NullPointerException at ...',
      ),
    );

    expect(message, isNot(contains('NullPointer')));
    expect(message, contains('trouble on our end'));
  });

  test("the backend's own message is used for a client error", () {
    expect(
      userFacingError(
        const ChurchApiException(400, serverMessage: 'That tag is not active.'),
      ),
      'That tag is not active.',
    );
  });

  test('an expired session asks the member to sign in', () {
    expect(userFacingError(const ChurchApiException(401)), contains('sign in'));
    expect(
      userFacingError(const SessionInvalidException('auth/firebase:404')),
      contains('sign in'),
    );
  });

  test('anything else falls back to generic copy', () {
    expect(
      userFacingError(Exception('$backend/member/stats failed: 418')),
      isNot(contains('example-church')),
    );
  });
}
