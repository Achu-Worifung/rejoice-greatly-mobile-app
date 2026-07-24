import 'package:shared_preferences/shared_preferences.dart';

/// On-device record of the member's consent to facial enrollment.
///
/// The Biometric Information Notice is shown at the moment of collection (see
/// `lib/pages/user_prep.dart`), and ticking "I Agree" is the release. We stamp
/// that here so the app can tell whether — and when — consent was given, and so
/// a member can see it again from their profile.
///
/// NOTE: this is a device-local record only; there is no backend endpoint for
/// consent yet. A consent release should ultimately be stored server-side with
/// the account, since a record that disappears when the member reinstalls the
/// app is not much of a record.
class BiometricConsent {
  BiometricConsent._();

  static const String _grantedAtKey = 'biometric_consent_granted_at';

  /// Notice version the member agreed to, so a material change to the Notice
  /// can be detected and consent re-taken.
  static const String _versionKey = 'biometric_consent_version';

  /// Bump when the Notice changes materially.
  static const String currentVersion = '2026-07-24';

  /// Stamps consent as given now, against [currentVersion].
  static Future<void> record() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_grantedAtKey, DateTime.now().toUtc().toIso8601String());
    await prefs.setString(_versionKey, currentVersion);
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
