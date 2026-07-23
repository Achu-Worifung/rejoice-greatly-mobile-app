import 'dart:async';

import 'package:flutter/material.dart';

import '../main.dart' show scaffoldMessengerKey;
import '../theme/church_colors.dart';

/// Visual weight of an attendance banner.
enum AttendanceBannerTone {
  /// A fresh check-in — the celebratory case.
  success,

  /// Informational, e.g. "already marked present today".
  info,

  /// Something went wrong (unreadable tag, network, expired session).
  error,
}

/// A small, church-themed confirmation banner used by the NFC check-in flow.
///
/// It shows via the app-wide [scaffoldMessengerKey] so it can be raised from
/// anywhere — including the OneSignal foreground listener, which lives outside
/// the widget tree. It also records when it was last shown so that listener can
/// de-dupe the backend's "You're marked present" push against the in-app banner
/// and avoid notifying the member twice for one check-in.
class AttendanceBanner {
  AttendanceBanner._();

  static DateTime? _lastShownAt;
  static Timer? _dismissTimer;

  /// How long after showing an in-app banner a matching foreground push is
  /// treated as a duplicate.
  static const Duration _dedupWindow = Duration(seconds: 15);

  /// How long the banner stays up before auto-dismissing.
  static const Duration _visibleFor = Duration(seconds: 5);

  /// True when an attendance banner was surfaced in-app within the dedup
  /// window. The foreground push listener uses this to suppress the duplicate
  /// system notification the backend sends on a fresh check-in.
  static bool get recentlyShown {
    final t = _lastShownAt;
    return t != null && DateTime.now().difference(t) < _dedupWindow;
  }

  /// Shows [message] (optionally under a bold [title]) as a themed banner.
  static void show({
    required String message,
    String? title,
    AttendanceBannerTone tone = AttendanceBannerTone.success,
  }) {
    _lastShownAt = DateTime.now();
    final messenger = scaffoldMessengerKey.currentState;
    if (messenger == null) return;

    _dismissTimer?.cancel();
    messenger.clearMaterialBanners();

    final palette = _paletteFor(tone);
    messenger.showMaterialBanner(
      MaterialBanner(
        backgroundColor: palette.background,
        elevation: 3,
        dividerColor: Colors.transparent,
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 6),
        leading: Icon(palette.icon, color: palette.foreground),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (title != null && title.isNotEmpty) ...[
              Text(
                title,
                style: TextStyle(
                  color: palette.foreground,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 2),
            ],
            Text(
              message,
              style: TextStyle(
                color: palette.foreground,
                fontSize: 14,
                height: 1.3,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () =>
                scaffoldMessengerKey.currentState?.hideCurrentMaterialBanner(),
            child: Text(
              'Dismiss',
              style: TextStyle(
                color: palette.foreground,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    _dismissTimer = Timer(_visibleFor, () {
      scaffoldMessengerKey.currentState?.hideCurrentMaterialBanner();
    });
  }

  static _BannerPalette _paletteFor(AttendanceBannerTone tone) {
    switch (tone) {
      case AttendanceBannerTone.success:
        return const _BannerPalette(
          background: Color(0xFFEAF6EC),
          foreground: Color(0xFF1B5E20),
          icon: Icons.check_circle_rounded,
        );
      case AttendanceBannerTone.info:
        return const _BannerPalette(
          background: ChurchColors.card,
          foreground: ChurchColors.accent,
          icon: Icons.event_available_rounded,
        );
      case AttendanceBannerTone.error:
        return const _BannerPalette(
          background: Color(0xFFFDECEA),
          foreground: Color(0xFFB3261E),
          icon: Icons.error_outline_rounded,
        );
    }
  }
}

class _BannerPalette {
  const _BannerPalette({
    required this.background,
    required this.foreground,
    required this.icon,
  });

  final Color background;
  final Color foreground;
  final IconData icon;
}
