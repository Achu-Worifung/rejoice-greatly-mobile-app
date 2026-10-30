import 'package:flutter/material.dart';

import 'church_type.dart';

/// One set of the app's colours. [light] is the home palette — white surface,
/// warm cream cards, deep brown actions; [dark] is the same warmth after dark:
/// a roasted near-black surface, cocoa cards and candlelit tan actions. Every
/// text/surface pair in both meets WCAG AA.
@immutable
class ChurchPalette {
  const ChurchPalette({
    required this.brightness,
    required this.background,
    required this.card,
    required this.button,
    required this.buttonText,
    required this.accent,
    required this.bodyText,
    required this.muted,
    required this.divider,
  });

  final Brightness brightness;
  final Color background;
  final Color card;
  final Color button;
  final Color buttonText;
  final Color accent;
  final Color bodyText;
  final Color muted;
  final Color divider;

  static const ChurchPalette light = ChurchPalette(
    brightness: Brightness.light,
    background: Color(0xFFFFFFFF),
    card: Color(0xFFFFF7EB),
    button: Color(0xFF633A02),
    buttonText: Color(0xFFFFFFFF),
    accent: Color(0xFF633A02),
    bodyText: Color(0xFF1A1A1A),
    muted: Color(0xFF6B5C4D),
    divider: Color(0xFFE8DFD0),
  );

  static const ChurchPalette dark = ChurchPalette(
    brightness: Brightness.dark,
    background: Color(0xFF17130F),
    card: Color(0xFF231C15),
    button: Color(0xFFDDB988),
    buttonText: Color(0xFF241505),
    accent: Color(0xFFE4C49A),
    bodyText: Color(0xFFF3ECE3),
    muted: Color(0xFFB9A994),
    divider: Color(0xFF3B3128),
  );
}

/// The app's colour tokens, read from whichever [ChurchPalette] is showing.
/// They're getters, not constants, so the whole app can switch between light
/// and dark; [DisplaySettings] does the switching.
class ChurchColors {
  ChurchColors._();

  static ChurchPalette _palette = ChurchPalette.light;

  static ChurchPalette get palette => _palette;

  /// Switches palette. Returns whether anything changed, so the caller knows
  /// to repaint the widgets that read these.
  static bool use(ChurchPalette palette) {
    if (identical(palette, _palette)) return false;
    _palette = palette;
    return true;
  }

  /// Runs [build] with [palette] showing, then puts the current one back —
  /// for building both themes up front.
  static T paint<T>(ChurchPalette palette, T Function() build) {
    final previous = _palette;
    _palette = palette;
    try {
      return build();
    } finally {
      _palette = previous;
    }
  }

  static bool get isDark => _palette.brightness == Brightness.dark;

  static Color get background => _palette.background;
  static Color get card => _palette.card;
  static Color get button => _palette.button;
  static Color get buttonText => _palette.buttonText;
  static Color get accent => _palette.accent;
  static Color get bodyText => _palette.bodyText;
  static Color get muted => _palette.muted;
  static Color get divider => _palette.divider;

  /// Crisp, not soft — see `church_type.dart` for the full radius scale.
  static const double cardRadius = ChurchRadius.lg;
  static BorderRadius borderRadiusCard = ChurchRadius.lgAll;

  /// A card is a form slipped into the register: flat, cream, closed by a 1px
  /// rule. No shadow — depth comes from the cream-on-white layering, and a
  /// [shadow] is only honoured when a caller genuinely needs a lifted sheet.
  static BoxDecoration cardDecoration({Color? color, List<BoxShadow>? shadow}) {
    return BoxDecoration(
      color: color ?? card,
      borderRadius: borderRadiusCard,
      border: Border.all(color: divider),
      boxShadow: shadow,
    );
  }
}
