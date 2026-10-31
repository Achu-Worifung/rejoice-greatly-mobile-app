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
    required this.danger,
    required this.successSurface,
    required this.successInk,
    required this.errorSurface,
    required this.errorBorder,
    required this.errorInk,
    required this.skeleton,
    required this.skeletonHighlight,
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

  /// Destructive actions and "absent" marks.
  final Color danger;

  /// The check-in banner's "you're in" and the warm-rose error callout.
  final Color successSurface;
  final Color successInk;
  final Color errorSurface;
  final Color errorBorder;
  final Color errorInk;

  /// Loading placeholders, and the shimmer across them.
  final Color skeleton;
  final Color skeletonHighlight;

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
    danger: Color(0xFFC62828),
    successSurface: Color(0xFFEAF6EC),
    successInk: Color(0xFF1B5E20),
    errorSurface: Color(0xFFFFF1EE),
    errorBorder: Color(0xFFE1B0A9),
    errorInk: Color(0xFF8A2C1F),
    skeleton: Color(0xFFEDE4D6),
    skeletonHighlight: Color(0xFFF8F2E8),
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
    danger: Color(0xFFF2A097),
    successSurface: Color(0xFF1D2E1F),
    successInk: Color(0xFFA8D5AB),
    errorSurface: Color(0xFF3A201C),
    errorBorder: Color(0xFF6E3A33),
    errorInk: Color(0xFFF5BDB4),
    skeleton: Color(0xFF2B231B),
    skeletonHighlight: Color(0xFF3A3027),
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
  static Color get danger => _palette.danger;
  static Color get successSurface => _palette.successSurface;
  static Color get successInk => _palette.successInk;
  static Color get errorSurface => _palette.errorSurface;
  static Color get errorBorder => _palette.errorBorder;
  static Color get errorInk => _palette.errorInk;
  static Color get skeleton => _palette.skeleton;
  static Color get skeletonHighlight => _palette.skeletonHighlight;

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
