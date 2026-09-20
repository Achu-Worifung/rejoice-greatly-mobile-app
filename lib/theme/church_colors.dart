import 'package:flutter/material.dart';

import 'church_type.dart';

/// User-facing home palette: white surface, warm cream cards, deep brown actions.
class ChurchColors {
  ChurchColors._();

  static const Color background = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFFFF7EB);
  static const Color button = Color(0xFF633A02);
  static const Color buttonText = Color(0xFFFFFFFF);
  static const Color accent = Color(0xFF633A02);
  static const Color bodyText = Color(0xFF1A1A1A);
  static const Color muted = Color(0xFF6B5C4D);
  static const Color divider = Color(0xFFE8DFD0);

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
