import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../theme/church_colors.dart';
import '../theme/church_type.dart';

// ChurchPrimaryButton now lives with the app-wide button vocabulary; re-exported
// here so the auth screens can keep importing it from auth_ui.
export 'church_buttons.dart' show ChurchPrimaryButton;

/// Shared building blocks for the auth screens (landing, sign in, sign up,
/// forgot password). Extracted so the four screens stop drifting: one button
/// vocabulary, one error style, one input decoration — all aligned to
/// DESIGN.md (primary = crisp radius, flat; secondary = cream, ruled, flat).

// The warm-rose error palette (DESIGN.md error-callout tokens).
const Color _errorSurface = Color(0xFFFFF1EE);
const Color _errorBorder = Color(0xFFE1B0A9);
const Color _errorInk = Color(0xFF8A2C1F);

/// Screen title for auth pages ("Let's Get Started!", "Reset your password").
const TextStyle kAuthTitleStyle = ChurchType.display;

/// Supporting line beneath the title.
const TextStyle kAuthSubtitleStyle = ChurchType.label;

/// The one input decoration every auth field uses: muted label + icon, and
/// the ruled, crisp-cornered box from the app theme (sand rule at rest, cocoa
/// rule on focus).
InputDecoration authInputDecoration({
  required String label,
  required IconData icon,
  Widget? suffixIcon,
}) {
  return InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, color: ChurchColors.muted),
    suffixIcon: suffixIcon,
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
        borderRadius: ChurchRadius.mdAll,
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
    this.elevation = 0,
    this.height = 52,
    this.iconSize = 20,
    this.fontSize = 15,
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
    this.fontSize = 15,
  })  : background = Colors.transparent,
        foreground = ChurchColors.card,
        borderColor = ChurchColors.card,
        elevation = 0;

  final String label;
  /// Material [IconData] or Font Awesome [FaIconData] (when [isFa] is true).
  final Object icon;
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
    final bc = borderColor ?? ChurchColors.divider;

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
          side: BorderSide(color: bc),
          shape: const RoundedRectangleBorder(
            borderRadius: ChurchRadius.mdAll,
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
                      ? FaIcon(icon as FaIconData, size: iconSize, color: fg)
                      : Icon(icon as IconData, size: iconSize, color: fg),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ChurchType.button.copyWith(
                        color: fg,
                        fontSize: fontSize,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
