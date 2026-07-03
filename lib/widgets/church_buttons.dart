import 'package:flutter/material.dart';

import '../theme/church_colors.dart';

/// App-wide button vocabulary, aligned to DESIGN.md:
/// - Primary: cocoa fill, 14px radius, flat (elevation 0).
/// - Secondary: cream, sand border, lifted — the "also tappable" affordance.
/// - Danger: flat outlined red for destructive actions (no gradient, no glow).

const Color _danger = Color(0xFFC62828);

/// The one "do this" action.
class ChurchPrimaryButton extends StatelessWidget {
  const ChurchPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.height = 52,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final double height;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: ChurchColors.button,
          foregroundColor: ChurchColors.buttonText,
          disabledBackgroundColor: ChurchColors.button,
          disabledForegroundColor: ChurchColors.buttonText,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: ChurchColors.buttonText,
                  strokeWidth: 2,
                ),
              )
            : _labelRow(label, icon, ChurchColors.buttonText),
      ),
    );
  }
}

/// Secondary / "also tappable" action: cream, bordered, gently lifted.
class ChurchSecondaryButton extends StatelessWidget {
  const ChurchSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.height = 50,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final double height;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: ChurchColors.card,
          foregroundColor: ChurchColors.bodyText,
          disabledBackgroundColor: ChurchColors.card,
          elevation: 2,
          shadowColor: Colors.black.withValues(alpha: 0.12),
          side: BorderSide(color: ChurchColors.divider.withValues(alpha: 0.7)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _labelRow(label, icon, ChurchColors.bodyText),
      ),
    );
  }
}

/// Destructive action — flat, outlined red. No gradient, no glow.
class ChurchDangerButton extends StatelessWidget {
  const ChurchDangerButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.height = 52,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final double height;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: _danger,
          backgroundColor: _danger.withValues(alpha: 0.05),
          side: const BorderSide(color: _danger, width: 1.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _labelRow(label, icon, _danger),
      ),
    );
  }
}

Widget _labelRow(String label, IconData? icon, Color color) {
  final text = Text(
    label,
    style: TextStyle(
      color: color,
      fontSize: 16,
      fontWeight: FontWeight.w600,
    ),
  );
  if (icon == null) return text;
  return Row(
    mainAxisSize: MainAxisSize.min,
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(icon, size: 20, color: color),
      const SizedBox(width: 8),
      Flexible(child: text),
    ],
  );
}
