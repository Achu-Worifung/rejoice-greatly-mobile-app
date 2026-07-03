import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../theme/church_colors.dart';

/// Shared building blocks for the auth screens (landing, sign in, sign up,
/// forgot password). Extracted so the four screens stop drifting: one button
/// vocabulary, one error style, one input decoration — all aligned to
/// DESIGN.md (primary = 14px radius, flat; secondary = cream, bordered, lifted).

// The warm-rose error palette (DESIGN.md error-callout tokens).
const Color _errorSurface = Color(0xFFFFF1EE);
const Color _errorBorder = Color(0xFFE1B0A9);
const Color _errorInk = Color(0xFF8A2C1F);

/// Screen title for auth pages ("Let's Get Started!", "Reset your password").
const TextStyle kAuthTitleStyle = TextStyle(
  color: ChurchColors.bodyText,
  fontSize: 28,
  fontWeight: FontWeight.w700,
  letterSpacing: 0.2,
  height: 1.15,
);

/// Supporting line beneath the title.
const TextStyle kAuthSubtitleStyle = TextStyle(
  color: ChurchColors.muted,
  fontSize: 14,
  fontWeight: FontWeight.w400,
  letterSpacing: 0.2,
  height: 1.4,
);

/// The one input decoration every auth field uses: muted label + icon, sand
/// border at rest, cocoa border on focus (radius grows 12 → 14, per DESIGN.md).
InputDecoration authInputDecoration({
  required String label,
  required IconData icon,
  Widget? suffixIcon,
}) {
  OutlineInputBorder border(Color color, double radius) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: BorderSide(color: color),
      );

  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: ChurchColors.muted),
    prefixIcon: Icon(icon, color: ChurchColors.muted),
    suffixIcon: suffixIcon,
    enabledBorder: border(ChurchColors.divider, 12),
    focusedBorder: border(ChurchColors.button, 14),
    errorBorder: border(Colors.redAccent, 12),
    focusedErrorBorder: border(Colors.redAccent, 14),
  );
}

/// Inline validation / failure message — warm rose surface, never a harsh red
/// block. One consistent treatment across every auth screen.
class AuthErrorCallout extends StatelessWidget {
  const AuthErrorCallout(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _errorSurface,
        border: Border.all(color: _errorBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, color: _errorInk, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: _errorInk,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The single "do this" action: cocoa fill, white text, 14px radius, flat.
/// Pass [loading] to swap the label for a spinner.
class ChurchPrimaryButton extends StatelessWidget {
  const ChurchPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.height = 52,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final double height;

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
            : Text(
                label,
                style: const TextStyle(
                  color: ChurchColors.buttonText,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}

/// A provider / alternative sign-in button (Google, Apple, Email). Defaults to
/// the cream "secondary" look; override colors for the ghost variant used on
/// the brown landing. Works full-width or inside an [Expanded] side-by-side.
class ChurchSocialButton extends StatelessWidget {
  const ChurchSocialButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isFa = true,
    this.loading = false,
    this.enabled = true,
    this.background,
    this.foreground,
    this.borderColor,
    this.elevation = 2,
    this.height = 52,
    this.iconSize = 20,
    this.fontSize = 16,
  });

  /// The cream-bordered ghost variant for dark (brown) surfaces.
  const ChurchSocialButton.ghost({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isFa = false,
    this.loading = false,
    this.enabled = true,
    this.height = 52,
    this.iconSize = 20,
    this.fontSize = 16,
  })  : background = Colors.transparent,
        foreground = ChurchColors.card,
        borderColor = ChurchColors.card,
        elevation = 0;

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isFa;
  final bool loading;
  final bool enabled;
  final Color? background;
  final Color? foreground;
  final Color? borderColor;
  final double elevation;
  final double height;
  final double iconSize;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final bg = background ?? ChurchColors.card;
    final fg = foreground ?? ChurchColors.bodyText;
    final bc = borderColor ?? ChurchColors.divider.withValues(alpha: 0.6);

    return SizedBox(
      width: double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: (!enabled || loading) ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          disabledBackgroundColor: bg,
          disabledForegroundColor: fg.withValues(alpha: 0.55),
          elevation: elevation,
          shadowColor: Colors.black.withValues(alpha: 0.15),
          side: BorderSide(color: bc),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        child: loading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: fg),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  isFa
                      ? FaIcon(icon, size: iconSize, color: fg)
                      : Icon(icon, size: iconSize, color: fg),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: fg,
                        fontSize: fontSize,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
