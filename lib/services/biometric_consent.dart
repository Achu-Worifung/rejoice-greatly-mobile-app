import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'church_api.dart';

/// On-device record of the member's consent to facial enrollment.
///
/// The Biometric Information Notice is shown at the moment of collection (see
/// `lib/pages/user_prep.dart`), and ticking "I Agree" is the release. We stamp
/// that here so the app can tell whether — and when — consent was given, and so
/// a member can see it again from their profile.
///
/// It's also sent to the backend, which keeps it with the account and refuses
/// face scans without it — a record that vanished on reinstall wouldn't be
/// much of one. Deleting face data clears the server's copy.
class BiometricConsent {
  BiometricConsent._();

  static const String _grantedAtKey = 'biometric_consent_granted_at';

  /// Notice version the member agreed to, so a material change to the Notice
  /// can be detected and consent re-taken.
  static const String _versionKey = 'biometric_consent_version';

  /// Bump when the Notice changes materially.
  static const String currentVersion = '2026-07-24';

  /// Stamps consent as given now, against [currentVersion], here and (best
  /// effort) on the server; [sendToServer] makes sure of the latter before a scan.
  static Future<void> record() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_grantedAtKey, DateTime.now().toUtc().toIso8601String());
    await prefs.setString(_versionKey, currentVersion);
    try {
      await sendToServer();
    } catch (e) {
      debugPrint('BiometricConsent: not on the server yet: $e');
    }
  }

  /// Puts their agreement on record with their account. Throws [StateError]
  /// if they haven't agreed to the current notice on this phone, or the API's
  /// error if the server can't be reached — face scans are refused until it's there.
  static Future<void> sendToServer() async {
    if (!await isCurrent()) {
      throw StateError('No agreement to the current notice on this phone.');
    }
    await ChurchApi.memberBiometricConsent(currentVersion);
  }

  /// When consent was given, or null if it never was.
  static Future<DateTime?> grantedAt() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_grantedAtKey);
    if (raw == null) return null;
    return DateTime.tryParse(raw)?.toLocal();
  }

  /// True when consent was given against the version of the Notice currently
  /// shipping — a member who agreed to an older Notice is asked again.
  static Future<bool> isCurrent() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_grantedAtKey) != null &&
        prefs.getString(_versionKey) == currentVersion;
  }

  /// Clears the record — used when the member withdraws consent.
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_grantedAtKey);
    await prefs.remove(_versionKey);
  }
}
