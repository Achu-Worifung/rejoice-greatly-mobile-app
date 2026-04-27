import 'package:flutter/material.dart';

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

  static const double cardRadius = 16;
  static BorderRadius borderRadiusCard =
      BorderRadius.circular(cardRadius);

  static BoxDecoration cardDecoration({Color? color, List<BoxShadow>? shadow}) {
    return BoxDecoration(
      color: color ?? card,
      borderRadius: borderRadiusCard,
      border: Border.all(color: divider.withValues(alpha: 0.4)),
      boxShadow: shadow ??
          [
            BoxShadow(
              color: const Color(0xFF633A02).withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
    );
  }
}
