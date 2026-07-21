import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../main.dart' show navigatorKey;
import '../services/auth_service.dart';
import '../services/church_api.dart';
import '../theme/church_colors.dart';
import '../widgets/church_buttons.dart';

/// First onboarding step: the member confirms their date of birth so we can set
/// up the right experience.
///
/// - **18 and older** continue the normal flow to the facial-recognition intro
///   ([UserPrepPage] → `/complete-signup`).
/// - **Under 18** skip the face check-in entirely: signup is marked complete
///   on-device (see [ChurchApi.markSignupCompleteLocally]) and they go straight
///   to the dashboard.
class DobPage extends StatefulWidget {
  const DobPage({super.key});

  @override
  State<DobPage> createState() => _DobPageState();
}

class _DobPageState extends State<DobPage> {
  DateTime? _dob;
  bool _working = false;

  /// Members this age or older go through facial-recognition setup; younger
  /// members skip it and head straight to the dashboard.
  static const int _adultAge = 18;

  /// Sign-in wipes the navigation stack before showing this page, so the only
  /// way "back" from the onboarding root is to sign out.
  Future<void> _goBack() async {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
      return;
    }
    await AuthService().logout();
    navigatorKey.currentState?.pushNamedAndRemoveUntil('/', (route) => false);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = _dob ?? DateTime(now.year - 25, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 120),
      lastDate: now,
      helpText: 'Select your date of birth',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: ChurchColors.button,
            onPrimary: ChurchColors.buttonText,
            onSurface: ChurchColors.bodyText,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) setState(() => _dob = picked);
  }

  int _ageOn(DateTime dob, DateTime now) {
    var age = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }

  Future<void> _continue() async {
    final dob = _dob;
    if (dob == null || _working) return;

    if (_ageOn(dob, DateTime.now()) >= _adultAge) {
      // Normal workflow: on to the facial-recognition intro.
      Navigator.pushNamed(context, '/user-prep');
      return;
    }

    // Under 18: skip facial recognition and finish onboarding here.
    setState(() => _working = true);
    try {
      await ChurchApi.markSignupCompleteLocally();
    } catch (e) {
      debugPrint('DobPage: markSignupCompleteLocally failed: $e');
    }
    if (!mounted) return;
    navigatorKey.currentState
        ?.pushNamedAndRemoveUntil('/dashboard', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final dob = _dob;
    final dateLabel = dob == null
        ? 'Select your date of birth'
        : DateFormat('MMMM d, yyyy').format(dob);

    return Scaffold(
      backgroundColor: ChurchColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              IconButton(
                onPressed: _working ? null : _goBack,
                padding: EdgeInsets.zero,
                alignment: Alignment.centerLeft,
                icon: const Icon(Icons.arrow_back, color: ChurchColors.bodyText),
              ),
              const SizedBox(height: 8),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: ChurchColors.button.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.cake_outlined,
                  size: 32,
                  color: ChurchColors.accent,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'When were you born?',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: ChurchColors.bodyText,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "We ask so we can set up the right experience for you. Members "
                "under 18 skip the face check-in and head straight in.",
                style: TextStyle(
                  fontSize: 15,
                  color: ChurchColors.muted,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              GestureDetector(
                onTap: _working ? null : _pickDate,
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                  decoration: ChurchColors.cardDecoration(shadow: const []),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 20,
                        color: ChurchColors.accent,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          dateLabel,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: dob == null
                                ? ChurchColors.muted
                                : ChurchColors.bodyText,
                          ),
                        ),
                      ),
                      const Icon(Icons.expand_more_rounded,
                          color: ChurchColors.muted),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              ChurchPrimaryButton(
                label: 'Continue',
                loading: _working,
                onPressed: dob == null ? null : _continue,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
