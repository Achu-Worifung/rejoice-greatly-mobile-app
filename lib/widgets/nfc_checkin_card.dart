import 'package:flutter/material.dart';

import '../services/nfc_checkin_service.dart';
import '../theme/church_colors.dart';
import 'attendance_banner.dart';
import 'church_buttons.dart';

/// The member-facing "Check in with NFC" action. Tapping it scans a venue tag,
/// posts the check-in, and raises an [AttendanceBanner] with the outcome.
///
/// [onCheckedIn] fires only on a fresh (not already-present) check-in so the
/// host screen can refresh streak/attendance stats.
class NfcCheckInCard extends StatefulWidget {
  const NfcCheckInCard({super.key, this.onCheckedIn});

  final VoidCallback? onCheckedIn;

  @override
  State<NfcCheckInCard> createState() => _NfcCheckInCardState();
}

class _NfcCheckInCardState extends State<NfcCheckInCard> {
  bool _busy = false;

  Future<void> _checkIn() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final result = await NfcCheckinService.checkIn();
      if (!mounted) return;

      if (result.success) {
        AttendanceBanner.show(
          title: result.alreadyPresent
              ? 'Already checked in'
              : 'You’re marked present ✅',
          message: result.message,
          tone: result.alreadyPresent
              ? AttendanceBannerTone.info
              : AttendanceBannerTone.success,
        );
        if (!result.alreadyPresent) widget.onCheckedIn?.call();
      } else {
        AttendanceBanner.show(
          message: result.message,
          tone: AttendanceBannerTone.error,
        );
        if (result.errorKind == NfcCheckinErrorKind.unauthorized) {
          await _promptReLogin();
        }
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _promptReLogin() async {
    if (!mounted) return;
    final goToLogin = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          decoration: ChurchColors.cardDecoration(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: ChurchColors.button.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  color: ChurchColors.accent,
                  size: 28,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Session expired',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: ChurchColors.accent,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Please sign in again so we can check you in.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: ChurchColors.muted,
                  height: 1.45,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              ChurchPrimaryButton(
                label: 'Sign in again',
                onPressed: () => Navigator.pop(ctx, true),
              ),
              const SizedBox(height: 10),
              ChurchSecondaryButton(
                label: 'Not now',
                onPressed: () => Navigator.pop(ctx, false),
              ),
            ],
          ),
        ),
      ),
    );

    if (goToLogin == true && mounted) {
      Navigator.pushNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: ChurchColors.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: ChurchColors.button.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.nfc_rounded,
                    color: ChurchColors.button, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Check in for today',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: ChurchColors.bodyText,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Tap the tag at the entrance to mark yourself present.',
                      style: TextStyle(
                        fontSize: 13,
                        color: ChurchColors.muted,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ChurchPrimaryButton(
            label: 'Check in with NFC',
            icon: Icons.nfc_rounded,
            loading: _busy,
            onPressed: _checkIn,
          ),
        ],
      ),
    );
  }
}
