import 'package:flutter/material.dart';

import 'church_colors.dart';

/// "The Register" — the look shared with the admin site, on the app's own
/// palette. Three faces, one job each:
///
///   - Source Serif 4 for headings: the one or two record-book moments on a
///     screen (page title, card title).
///   - IBM Plex Mono for numbers and micro-labels, with tabular figures, so a
///     count reads as typed into a ledger rather than set in a layout tool.
///   - IBM Plex Sans for everything else: body, buttons, inputs, nav.
///
/// Sizes are the app's own mobile scale, not the site's desktop one — nothing
/// user-facing goes below 12px (the 12px Floor Rule in DESIGN.md).
class ChurchFonts {
  ChurchFonts._();

  static const String serif = 'SourceSerif4';
  static const String sans = 'IBMPlexSans';
  static const String mono = 'IBMPlexMono';
}

/// Crisp, not soft. A ledger page, a form and a rubber stamp all have square
/// edges; the old 16px card radius is gone on purpose.
class ChurchRadius {
  ChurchRadius._();

  /// Chips, tags, progress bars.
  static const double sm = 3;

  /// Inputs, thumbnails, buttons.
  static const double md = 6;

  /// Cards and sheets — the largest radius in the system.
  static const double lg = 8;

  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
}

class ChurchType {
  ChurchType._();

  static const List<FontFeature> _tabular = [FontFeature.tabularFigures()];

  // ── Headings (serif) ──────────────────────────────────────────────────

  /// The one large headline a screen gets, inside its page hero.
  static const TextStyle display = TextStyle(
    fontFamily: ChurchFonts.serif,
    fontSize: 28,
    fontWeight: FontWeight.w600,
    height: 1.15,
    letterSpacing: -0.3,
    color: ChurchColors.bodyText,
  );

  /// App-bar titles and section-opening headings.
  static const TextStyle headline = TextStyle(
    fontFamily: ChurchFonts.serif,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: -0.2,
    color: ChurchColors.bodyText,
  );

  /// Card titles — a sermon or event name. Cap at two lines.
  static const TextStyle title = TextStyle(
    fontFamily: ChurchFonts.serif,
    fontSize: 17,
    fontWeight: FontWeight.w600,
    height: 1.25,
    color: ChurchColors.bodyText,
  );

  // ── Body (sans) ───────────────────────────────────────────────────────

  static const TextStyle body = TextStyle(
    fontFamily: ChurchFonts.sans,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.45,
    color: ChurchColors.bodyText,
  );

  static const TextStyle bodyStrong = TextStyle(
    fontFamily: ChurchFonts.sans,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.45,
    color: ChurchColors.bodyText,
  );

  /// Button labels.
  static const TextStyle button = TextStyle(
    fontFamily: ChurchFonts.sans,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
  );

  /// Secondary text: subtitles, captions, input labels.
  static const TextStyle label = TextStyle(
    fontFamily: ChurchFonts.sans,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.3,
    color: ChurchColors.muted,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: ChurchFonts.sans,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.3,
    color: ChurchColors.muted,
  );

  // ── Data and micro-labels (mono) ──────────────────────────────────────

  /// The small uppercase line above a heading or a section: "LATEST SERMON".
  /// Callers pass the text already upper-cased, or use [ChurchEyebrow].
  static const TextStyle eyebrow = TextStyle(
    fontFamily: ChurchFonts.mono,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.2,
    letterSpacing: 1.7, // 0.14em at 12px
    color: ChurchColors.muted,
  );

  /// A focal number — a streak, a count, an attendance rate.
  static const TextStyle data = TextStyle(
    fontFamily: ChurchFonts.mono,
    fontSize: 28,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: -0.5,
    fontFeatures: _tabular,
    color: ChurchColors.bodyText,
  );

  /// Dates, times, durations and counts set inline with body text.
  static const TextStyle dataSmall = TextStyle(
    fontFamily: ChurchFonts.mono,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.3,
    fontFeatures: _tabular,
    color: ChurchColors.muted,
  );

  /// The Material text theme built from the same styles, so widgets that read
  /// `Theme.of(context).textTheme` land on the register faces too.
  static TextTheme get textTheme => const TextTheme(
        displayLarge: display,
        displayMedium: display,
        displaySmall: headline,
        headlineLarge: display,
        headlineMedium: headline,
        headlineSmall: headline,
        titleLarge: title,
        titleMedium: bodyStrong,
        titleSmall: label,
        bodyLarge: body,
        bodyMedium: body,
        bodySmall: caption,
        labelLarge: button,
        labelMedium: label,
        labelSmall: caption,
      );
}

/// The register's ruled lines. A single hairline separates rows; a double rule
/// closes a structurally important block — the page hero, a sheet header.
class ChurchRules {
  ChurchRules._();

  /// The one recurring border colour: a 1px "rule" in warm sand.
  static const BorderSide hairline = BorderSide(color: ChurchColors.divider);

  /// The ink a double rule is drawn in.
  static Color get inkRule => ChurchColors.bodyText.withValues(alpha: 0.6);
}

/// Two 1px ink lines with a 2px gap — Flutter has no `border-style: double`,
/// so this draws the site's signature rule by hand.
class ChurchDoubleRule extends StatelessWidget {
  const ChurchDoubleRule({super.key, this.color});

  final Color? color;

  @override
  Widget build(BuildContext context) {
    final ink = color ?? ChurchRules.inkRule;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(height: 1, color: ink),
        const SizedBox(height: 2),
        Container(height: 1, color: ink),
      ],
    );
  }
}

/// A mono, uppercase micro-label — the line above a section or a hero title.
class ChurchEyebrow extends StatelessWidget {
  const ChurchEyebrow(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: color == null
          ? ChurchType.eyebrow
          : ChurchType.eyebrow.copyWith(color: color),
    );
  }
}

/// The site's rubber-stamp badge: a slightly rotated, outlined, mono label in
/// the accent — the way an ink stamp marks the one thing that matters.
class ChurchStampBadge extends StatelessWidget {
  const ChurchStampBadge(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.0175, // −1°
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: ChurchRadius.smAll,
          border: Border.all(
            color: ChurchColors.accent.withValues(alpha: 0.7),
            width: 2,
          ),
        ),
        child: Text(
          text.toUpperCase(),
          style: ChurchType.eyebrow.copyWith(color: ChurchColors.accent),
        ),
      ),
    );
  }
}

/// The page-opening block: eyebrow, one serif headline, an optional muted
/// description, closed by a double rule. Exactly one per screen.
class ChurchPageHero extends StatelessWidget {
  const ChurchPageHero({
    super.key,
    required this.eyebrow,
    required this.title,
    this.description,
    this.badge,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 0),
  });

  final String eyebrow;
  final String title;
  final String? description;
  final String? badge;
  final Widget? trailing;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ChurchEyebrow(eyebrow),
                    const SizedBox(height: 4),
                    Text(title, style: ChurchType.display),
                    if (description != null) ...[
                      const SizedBox(height: 6),
                      Text(description!, style: ChurchType.label),
                    ],
                  ],
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 12),
                ChurchStampBadge(badge!),
              ],
              if (trailing != null) ...[
                const SizedBox(width: 12),
                trailing!,
              ],
            ],
          ),
          const SizedBox(height: 14),
          const ChurchDoubleRule(),
        ],
      ),
    );
  }
}
