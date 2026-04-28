import 'package:flutter/material.dart';

import '../theme/church_colors.dart';

class DashboardLabelText extends StatelessWidget {
  const DashboardLabelText({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: ChurchColors.button,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: ChurchColors.accent,
            letterSpacing: 1.8,
          ),
        ),
      ],
    );
  }
}