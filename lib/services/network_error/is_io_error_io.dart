import 'dart:io';

/// Socket, DNS and TLS failures that reach us without being wrapped by
/// `package:http` (e.g. a TLS handshake that fails mid-request).
bool isIoError(Object error) => error is IOException;
