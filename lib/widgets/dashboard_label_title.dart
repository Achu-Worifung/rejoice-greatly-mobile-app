import 'package:flutter/material.dart';

import '../theme/church_colors.dart';

/// A clean section header used across the dashboard and profile. Solid, quiet,
/// no side-stripe — the weight and color carry it.
class DashboardLabelText extends StatelessWidget {
  const DashboardLabelText({
    super.key,
    required this.label,
    this.color = ChurchColors.accent,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
