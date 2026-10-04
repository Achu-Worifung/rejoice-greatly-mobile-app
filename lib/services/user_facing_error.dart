import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;

import 'church_api.dart';
import 'network_error/is_io_error_stub.dart'
    if (dart.library.io) 'network_error/is_io_error_io.dart';

/// Copy for when the phone can't reach the server at all.
const String offlineMessage =
    "You're offline. Check your internet connection and try again.";

const String _timeoutMessage =
    'The connection is slow and the request timed out. Please try again.';

const String _serverMessage =
    "We're having trouble on our end. Please try again in a few minutes.";

const String _sessionMessage = 'Your session has ended. Please sign in again.';

const String _genericMessage = 'Something went wrong. Please try again.';

/// Turns any error into a short message that's safe to show a member.
///
/// Never shows the raw exception. With no connection, `package:http` throws a
/// `ClientException` whose text includes the full request URL, which would put
/// the backend's address on the screen. Callers should still `debugPrint` the
/// raw error for diagnosis.
String userFacingError(Object error) {
  if (error is http.ClientException || isIoError(error)) {
    return offlineMessage;
  }
  if (error is TimeoutException) return _timeoutMessage;
  if (error is SessionInvalidException) return _sessionMessage;
  if (error is FirebaseException) {
    return error.code == 'network-request-failed'
        ? offlineMessage
        : _genericMessage;
  }
  if (error is ChurchApiException) {
    final status = error.statusCode;
    if (status == 401 || status == 403) return _sessionMessage;
    if (status >= 500) return _serverMessage;
    // The backend writes its envelope messages for people, so prefer one.
    final serverMessage = error.serverMessage?.trim();
    if (serverMessage != null && serverMessage.isNotEmpty) {
      return serverMessage;
    }
    if (status == 404) {
      return "We couldn't find that. It may have been removed.";
    }
    return _genericMessage;
  }
  return _genericMessage;
}
