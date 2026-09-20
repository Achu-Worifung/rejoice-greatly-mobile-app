import 'package:flutter/material.dart';

import '../theme/church_colors.dart';
import '../theme/church_type.dart';

/// A section label used across the dashboard and profile: the register's mono,
/// uppercase micro-label. Quiet by design — it names the section, the content
/// carries the weight.
class DashboardLabelText extends StatelessWidget {
  const DashboardLabelText({
    super.key,
    required this.label,
    this.color = ChurchColors.muted,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ChurchEyebrow(label, color: color),
    );
  }
}
