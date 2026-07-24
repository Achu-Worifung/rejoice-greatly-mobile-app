import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../theme/church_colors.dart';
import 'church_app_bar.dart';

/// Shared renderer for the Terms of Use and Privacy Policy screens.
///
/// Legal copy is long, so rather than hand-styling two 500-line pages we
/// describe each document as a list of [LegalSection]s built from four block
/// types ([LegalParagraph], [LegalBullets], [LegalCallout], [LegalContacts])
/// and render them consistently: numbered headings, generous line height, and
/// the cream card used for the passages members most need to notice.
///
/// The canonical copy of both documents lives in `docs/TERMS_OF_USE.md` and
/// `docs/PRIVACY_POLICY.md` — keep the two in sync when either changes.
class LegalDocumentView extends StatelessWidget {
  const LegalDocumentView({
    super.key,
    required this.appBarTitle,
    required this.title,
    required this.lastUpdated,
    required this.intro,
    required this.sections,
  });

  final String appBarTitle;
  final String title;

  /// Human-readable effective date, e.g. "July 24, 2026".
  final String lastUpdated;

  /// Lead-in blocks shown above the first numbered section.
  final List<LegalBlock> intro;
  final List<LegalSection> sections;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ChurchColors.background,
      appBar: ChurchAppBar.pageTitle(appBarTitle),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 48),
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: ChurchColors.bodyText,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${LegalValues.appName} · Last updated $lastUpdated',
              style: const TextStyle(
                fontSize: 13,
                color: ChurchColors.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            for (final block in intro) block,
            for (var i = 0; i < sections.length; i++) ...[
              const SizedBox(height: 28),
              _SectionHeading(number: i + 1, text: sections[i].heading),
              const SizedBox(height: 12),
              for (final block in sections[i].blocks) block,
            ],
            const SizedBox(height: 32),
            const Divider(color: ChurchColors.divider, height: 1),
            const SizedBox(height: 20),
            
          ],
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: ChurchColors.button.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$number',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: ChurchColors.accent,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: ChurchColors.bodyText,
                height: 1.3,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// One numbered section of a legal document.
class LegalSection {
  const LegalSection(this.heading, this.blocks);

  final String heading;
  final List<LegalBlock> blocks;
}

/// Marker type for the blocks a [LegalSection] can hold.
abstract class LegalBlock extends StatelessWidget {
  const LegalBlock({super.key});
}

/// A body paragraph. [lead] renders it slightly larger — used for the sentence
/// that carries a section, so members skimming still catch it.
class LegalParagraph extends LegalBlock {
  const LegalParagraph(this.text, {super.key, this.lead = false});

  final String text;
  final bool lead;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Text(
        text,
        style: TextStyle(
          fontSize: lead ? 16 : 15,
          color: lead ? ChurchColors.bodyText : ChurchColors.muted,
          fontWeight: lead ? FontWeight.w600 : FontWeight.normal,
          height: 1.6,
        ),
      ),
    );
  }
}

/// An unordered list. Each item is a full sentence or clause.
class LegalBullets extends LegalBlock {
  const LegalBullets(this.items, {super.key});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 9, right: 12, left: 2),
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: ChurchColors.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        fontSize: 15,
                        color: ChurchColors.muted,
                        height: 1.55,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// A cream card for the passages that carry the most weight — consent, the
/// promise that non-enrolled members have no face record, opting out.
class LegalCallout extends LegalBlock {
  const LegalCallout({super.key, required this.title, required this.text, this.icon});

  final String title;
  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: ChurchColors.cardDecoration(shadow: const []),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 19, color: ChurchColors.accent),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: ChurchColors.bodyText,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            text,
            style: const TextStyle(
              fontSize: 14.5,
              color: ChurchColors.muted,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

/// The "contact us" block: the church's email and mailing address, pulled from
/// `.env` so the documents stay correct without a code change.
class LegalContacts extends LegalBlock {
  const LegalContacts({super.key, required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _row(Icons.mail_outline_rounded, email),
          const SizedBox(height: 12),
          _row(Icons.place_outlined, LegalValues.mailingAddress),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: ChurchColors.accent),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              color: ChurchColors.bodyText,
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

/// Church-specific values the legal documents interpolate, read from `.env`
/// with safe fallbacks so a missing key never renders an empty sentence.
class LegalValues {
  LegalValues._();

  static String get appName => _env('APP_NAME', 'Rejoice Greatly');

  static String get legalEntity =>
      _env('LEGAL_ENTITY_NAME', 'Rejoice Greatly Church, Inc.');

  static String get privacyEmail =>
      _env('PRIVACY_CONTACT_EMAIL', 'privacy@rejoicegreatly.org');

  static String get supportEmail =>
      _env('SUPPORT_CONTACT_EMAIL', 'hello@rejoicegreatly.org');

  static String get mailingAddress =>
      _env('MAILING_ADDRESS', 'Ask any church leader for our mailing address.');

  static String get governingState => _env('GOVERNING_STATE', 'Arizona');

  static String get lastUpdated => _env('LEGAL_EFFECTIVE_DATE', 'July 24, 2026');

  static String _env(String key, String fallback) {
    // dotenv throws if `load` never ran (e.g. in a widget test), so guard it.
    try {
      final value = dotenv.env[key]?.trim();
      if (value == null || value.isEmpty || value == '...') return fallback;
      return value;
    } catch (_) {
      return fallback;
    }
  }
}
