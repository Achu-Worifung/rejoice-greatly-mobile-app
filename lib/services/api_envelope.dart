/// Unwraps the backend's `ApiResponse` envelope.
///
/// Every Spring controller response is wrapped by `ApiResponseAdvice` into
/// `{success, message?, data, errorCode?, path?, timestamp}`, so the payload
/// the app actually wants sits under `data` rather than at the top level.
///
/// These helpers tolerate a bare, un-enveloped body as well. That matters in
/// two places: the advice deliberately skips some paths (`/actuator`,
/// `/error`), and a build of this app may run against a backend deployed
/// before the envelope existed. Tolerating both shapes means neither case
/// needs special-casing at the call site.
///
/// Do **not** use these for OneSignal responses or for JSON read back out of
/// SharedPreferences — neither is enveloped, and passing them through here
/// would be a no-op at best and misleading at worst.
///
/// Error bodies are also left alone by callers: a failure envelope carries its
/// `message` at the top level with a null `data`, so unwrapping one would throw
/// away the very field the caller wants.
library;

import 'dart:convert';

/// Returns the payload from an already-decoded body.
///
/// `success` is the discriminator rather than `data`, because `data` is
/// omitted entirely when null (the record is serialized with Jackson's
/// `NON_NULL`), and because a real payload could legitimately carry its own
/// `data` field.
dynamic unwrapApiValue(dynamic decoded) {
  if (decoded is Map && decoded['success'] is bool) {
    return decoded['data'];
  }
  return decoded;
}

/// Decodes a raw response body and returns the payload.
dynamic unwrapApiBody(String body) => unwrapApiValue(json.decode(body));

/// Payload as a map. An absent/null `data` becomes an empty map rather than
/// throwing, which is what a 200-with-no-body should mean to a caller.
Map<String, dynamic> unwrapApiMap(String body) {
  final payload = unwrapApiBody(body);
  if (payload == null) return <String, dynamic>{};
  return Map<String, dynamic>.from(payload as Map);
}

/// Payload as a list. An absent/null `data` becomes an empty list.
List<dynamic> unwrapApiList(String body) {
  final payload = unwrapApiBody(body);
  if (payload == null) return <dynamic>[];
  return List<dynamic>.from(payload as List);
}
