import 'package:flutter/material.dart';

import '../theme/church_colors.dart';

/// A single block inside a legal section: a paragraph, a bullet, or a small
/// sub-heading. Kept deliberately small so the Terms and Privacy pages can be
/// authored as plain structured data rather than hand-laid-out widgets.
sealed class LegalBlock {
  const LegalBlock();
}

/// A body paragraph.
class LegalParagraph extends LegalBlock {
  const LegalParagraph(this.text);
  final String text;
}

/// A bold lead-in line inside a section (e.g. "What we collect").
class LegalSubheading extends LegalBlock {
  const LegalSubheading(this.text);
  final String text;
}

/// A bulleted point. [lead] is rendered bold before [text] when present, so a
/// "term — definition" bullet reads cleanly.
class LegalBullet extends LegalBlock {
  const LegalBullet(this.text, {this.lead});
  final String text;
  final String? lead;
}

/// A numbered, titled top-level section.
class LegalSection {
  const LegalSection({required this.heading, required this.blocks});
  final String heading;
  final List<LegalBlock> blocks;
}

/// Renders a legal document (Terms / Privacy) in the church's warm, legible
/// style: an intro, an effective-date line, then numbered sections. Scrolls as
/// one long, unhurried page rather than tabs or accordions — a broad,
/// non-technical congregation should be able to read it top to bottom.
class LegalDocument extends StatelessWidget {
  const LegalDocument({
    super.key,
    required this.title,
    required this.effectiveDate,
    required this.intro,
    required this.sections,
    this.footer,
  });

  /// Document title shown above the sections (e.g. "Privacy Policy").
  final String title;

  /// Human-readable effective/last-updated date.
  final String effectiveDate;

  /// One or more short intro paragraphs.
  final List<String> intro;

  final List<LegalSection> sections;

  /// Optional closing note (e.g. a plain-language summary or contact line).
  final List<LegalBlock>? footer;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          Text(
            title,
            style: const TextStyle(
              color: ChurchColors.bodyText,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Last updated: $effectiveDate',
            style: const TextStyle(
              color: ChurchColors.muted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          for (final paragraph in intro) ...[
            _paragraph(paragraph),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 4),
          for (var i = 0; i < sections.length; i++) ...[
            _sectionHeading(i + 1, sections[i].heading),
            const SizedBox(height: 10),
            ..._blocks(sections[i].blocks),
            const SizedBox(height: 24),
          ],
          if (footer != null) ...[
            const Divider(color: ChurchColors.divider, height: 1),
            const SizedBox(height: 20),
            ..._blocks(footer!),
          ],
        ],
      ),
    );
  }

  List<Widget> _blocks(List<LegalBlock> blocks) {
    final widgets = <Widget>[];
    for (final block in blocks) {
      switch (block) {
        case LegalParagraph(:final text):
          widgets.add(_paragraph(text));
          widgets.add(const SizedBox(height: 12));
        case LegalSubheading(:final text):
          widgets.add(const SizedBox(height: 4));
          widgets.add(Text(
            text,
            style: const TextStyle(
              color: ChurchColors.bodyText,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ));
          widgets.add(const SizedBox(height: 8));
        case LegalBullet(:final text, :final lead):
          widgets.add(_bullet(text, lead));
          widgets.add(const SizedBox(height: 8));
      }
    }
    return widgets;
  }

  Widget _sectionHeading(int number, String heading) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$number.',
          style: const TextStyle(
            color: ChurchColors.accent,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            heading,
            style: const TextStyle(
              color: ChurchColors.bodyText,
              fontSize: 17,
              fontWeight: FontWeight.w800,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }

  Widget _paragraph(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: ChurchColors.bodyText,
        fontSize: 15,
        height: 1.55,
      ),
    );
  }

  Widget _bullet(String text, String? lead) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 7, right: 10),
            child: SizedBox(
              width: 5,
              height: 5,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: ChurchColors.accent,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: const TextStyle(
                  color: ChurchColors.bodyText,
                  fontSize: 15,
                  height: 1.5,
                ),
                children: [
                  if (lead != null)
                    TextSpan(
                      text: '$lead ',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  TextSpan(text: text),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
