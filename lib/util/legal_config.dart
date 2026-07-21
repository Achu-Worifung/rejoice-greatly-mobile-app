import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Church-specific identity used by the Terms of Service and Privacy Policy.
///
/// Every value is read from the app's `.env` (loaded in `main`) so the legal
/// text can be finalised without a code change: set the keys below and the
/// documents fill themselves in. Anything left unset renders as an obvious
/// `[BRACKETED]` placeholder, so a missing value is visible rather than silent.
///
/// `.env` keys (all optional, but fill them before release):
///
/// ```ini
/// LEGAL_ENTITY_NAME=Rejoice Greatly Church, Inc.
/// APP_NAME=Rejoice Greatly
/// PRIVACY_CONTACT_EMAIL=privacy@yourchurch.org
/// SUPPORT_CONTACT_EMAIL=hello@yourchurch.org
/// MAILING_ADDRESS=123 Main St, Springfield, IL 62701
/// GOVERNING_STATE=Illinois
/// LEGAL_EFFECTIVE_DATE=July 21, 2026
/// WEBSITE_URL=https://yourchurch.org
/// ```
class LegalConfig {
  LegalConfig._();

  static String _env(String key, String fallback) {
    final value = dotenv.env[key];
    if (value == null || value.trim().isEmpty) return fallback;
    return value.trim();
  }

  /// Legal entity that owns the app and is the data controller.
  static String get legalEntity =>
      _env('LEGAL_ENTITY_NAME', '[CHURCH LEGAL NAME]');

  /// Public app / brand name members see.
  static String get appName => _env('APP_NAME', 'Rejoice Greatly');

  /// Where members send privacy, biometric-deletion, and data-rights requests.
  static String get privacyEmail =>
      _env('PRIVACY_CONTACT_EMAIL', '[PRIVACY CONTACT EMAIL]');

  /// General support contact. Falls back to the privacy address.
  static String get supportEmail =>
      _env('SUPPORT_CONTACT_EMAIL', privacyEmail);

  /// Physical/registered address for legal notices.
  static String get mailingAddress =>
      _env('MAILING_ADDRESS', '[CHURCH MAILING ADDRESS]');

  /// US state whose law governs the agreement (e.g. "Illinois").
  static String get governingState => _env('GOVERNING_STATE', '[STATE]');

  /// Human-readable effective/last-updated date.
  static String get effectiveDate =>
      _env('LEGAL_EFFECTIVE_DATE', '[EFFECTIVE DATE]');

  /// Optional public website. Empty string when unset.
  static String get websiteUrl => _env('WEBSITE_URL', '');
}
