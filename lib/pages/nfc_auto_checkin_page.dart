import 'package:flutter/material.dart';

import '../services/church_api.dart';
import '../services/nfc_checkin_service.dart';
import '../theme/church_colors.dart';
import '../widgets/attendance_banner.dart';
import '../widgets/branded_loader.dart';

/// Landing screen for a tap on an NFC check-in tag that reached the app via
/// a deep link (Android NDEF dispatch — cold or warm; iOS Universal Link
/// after the system's one-tap NFC banner) instead of the member opening the
/// app and pressing the manual "Check in with NFC" button on their profile.
///
/// Fires the same check-in call that button uses
/// ([NfcCheckinService.checkInWithTagId]) and shows the same
/// [AttendanceBanner] outcome, then pops back to whatever was already on
/// screen underneath — there's nothing on this page worth returning to.
class NfcAutoCheckinPage extends StatefulWidget {
  const NfcAutoCheckinPage({super.key, required this.tagId});

  final String tagId;

  @override
  State<NfcAutoCheckinPage> createState() => _NfcAutoCheckinPageState();
}

class _NfcAutoCheckinPageState extends State<NfcAutoCheckinPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  Future<void> _run() async {
    final user = await ChurchApi.waitForSignedInUser();
    if (!mounted) return;

    if (user == null) {
      // Not signed in on this device. The root auth gate is already showing
      // the login screen underneath this one — step aside so the member can
      // sign in, then tap the tag again (or use the manual "Check in with
      // NFC" button on their profile once they're in).
      AttendanceBanner.show(
        title: 'Sign in to check in',
        message: 'Sign in, then tap the tag again to mark yourself present.',
        tone: AttendanceBannerTone.info,
      );
      _dismiss();
      return;
    }

    final result = await NfcCheckinService.checkInWithTagId(widget.tagId);
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
    } else {
      AttendanceBanner.show(
        message: result.message,
        tone: AttendanceBannerTone.error,
      );
    }
    _dismiss();
  }

  /// Step aside now the banner is up. Guarded: on a cold start the link can
  /// arrive before anything else is on the stack, and popping the only route
  /// would leave the member staring at a blank window instead of the app.
  void _dismiss() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: ChurchColors.background,
      body: Center(child: BrandedLoader()),
    );
  }
}
