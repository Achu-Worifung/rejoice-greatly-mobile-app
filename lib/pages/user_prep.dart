import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:auto_size_text/auto_size_text.dart';

import '../theme/church_colors.dart';
import '../services/auth_service.dart';
import '../services/biometric_consent.dart';
import '../services/church_api.dart';
import '../widgets/church_buttons.dart';
import '../main.dart' show navigatorKey;

class UserPrepPage extends StatefulWidget {
  const UserPrepPage({super.key});

  @override
  State<UserPrepPage> createState() => _UserPrepPageState();
}

class _UserPrepPageState extends State<UserPrepPage> {
  int _currentIndex = 0;

  /// Sign-in wipes the navigation stack before showing this page, so the only
  /// way "back" is to sign out and return to the login screen.
  Future<void> _goBack() async {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
      return;
    }
    await AuthService().logout();
    navigatorKey.currentState?.pushNamedAndRemoveUntil('/', (route) => false);
  }

  bool _skipping = false;

  /// The Biometric Information Notice is the written notice shown at the moment
  /// of collection; this tick is the member's release. Enrollment cannot start
  /// until it is given. See `docs/BIOMETRIC_NOTICE_AND_CONSENT.md`.
  bool _consented = false;

  /// Owned by the State so it is disposed with the page rather than leaked on
  /// every rebuild of the consent row.
  late final TapGestureRecognizer _noticeTap;

  @override
  void initState() {
    super.initState();
    _noticeTap = TapGestureRecognizer()
      ..onTap = () => Navigator.pushNamed(context, '/biometric-notice');
  }

  @override
  void dispose() {
    _noticeTap.dispose();
    super.dispose();
  }

  Future<void> _agreeAndContinue() async {
    if (!_consented || _skipping) return;
    await BiometricConsent.record();
    if (!mounted) return;
    Navigator.pushNamed(context, '/complete-signup');
  }

  /// Lets a member decline facial recognition for now. Signup is finished
  /// on-device (they can add a photo later from their profile) and they go
  /// straight to the dashboard.
  Future<void> _skipFacialScan() async {
    if (_skipping) return;
    final confirm = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
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
                  Icons.no_photography_outlined,
                  color: ChurchColors.accent,
                  size: 28,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Skip face check-in?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: ChurchColors.bodyText,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "You can explore the app right away. Without a face photo the "
                "cameras won't check you in — you can still tap the NFC tag at "
                "the entrance or check in with a greeter, and you can set up "
                "your face anytime from your profile.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: ChurchColors.muted,
                  height: 1.45,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              ChurchPrimaryButton(
                label: 'Skip for now',
                onPressed: () => Navigator.pop(ctx, true),
              ),
              const SizedBox(height: 10),
              ChurchSecondaryButton(
                label: 'Set up my face',
                onPressed: () => Navigator.pop(ctx, false),
              ),
            ],
          ),
        ),
      ),
    );
    if (confirm != true || !mounted) return;

    setState(() => _skipping = true);
    try {
      await ChurchApi.markSignupCompleteLocally();
    } catch (e) {
      debugPrint('UserPrepPage: markSignupCompleteLocally failed: $e');
    }
    if (!mounted) return;
    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      '/dashboard',
      (route) => false,
    );
  }

  final List<Map<String, dynamic>> _slides = [
    {
      'icon': Icons.lock_outline,
      'title': 'Encrypted End to End',
      'description':
          'Each photo is encrypted on your phone (AES-256-GCM) before it is uploaded, and stays encrypted in transit and at rest. Only ciphertext ever leaves your device.',
    },
    {
      'icon': Icons.how_to_reg_outlined,
      'title': 'Only for Attendance',
      'description':
          'Your face is used for one thing: marking you present. It is never your password, never signs you in, and is never used for ads or profiling.',
    },
    {
      'icon': Icons.visibility_off_outlined,
      'title': 'Kept Private',
      'description':
          'Only your church administrators can see attendance records. Your facial data is never sold, traded, or visible to other members.',
    },
    {
      'icon': Icons.delete_outline,
      'title': 'You\'re in Control',
      'description':
          'Enrollment is voluntary. Withdraw your consent anytime and your enrollment photos and face data are permanently deleted.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ChurchColors.background,
      // Scrollable rather than a bare Column: the eligibility notice and the
      // consent release make the bottom bar tall, and on a short screen the
      // slides must give way instead of overflowing. (A Spacer can't be used
      // here — the carousel reports no intrinsic height, so the column must be
      // free to size itself.)
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),

                IconButton(
                  onPressed: _goBack,
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerLeft,
                  icon: const Icon(
                    Icons.arrow_back,
                    color: ChurchColors.bodyText,
                  ),
                ),
                const SizedBox(height: 8),

                const Text(
                  "Set Up Facial Recognition",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: ChurchColors.bodyText,
                  ),
                ),
                const SizedBox(height: 12),

                const Text(
                  "To take attendance with your face, we need to register your facial data. Don't worry, it's quick and secure!",
                  style: TextStyle(
                    fontSize: 15,
                    color: ChurchColors.muted,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 25),

                CarouselSlider(
                  options: CarouselOptions(
                    height: 280,
                    // This is the equivalent to onScrollIndexChanged
                    onPageChanged: (index, reason) {
                      setState(() {
                        _currentIndex = index;
                      });
                    },
                    viewportFraction:
                        0.82, // Controls how much of the side items are visible
                    enlargeCenterPage:
                        true, // Optional: makes the middle one pop
                  ),
                  items: _slides.map((slide) => _buildSlide(slide)).toList(),
                ),

                const SizedBox(height: 20),

                // Dot indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_slides.length, (index) {
                    final isActive = index == _currentIndex;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: isActive ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isActive
                            ? ChurchColors.button
                            : ChurchColors.divider,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 24),

                Center(
                  child: Text(
                    "${_currentIndex + 1} of ${_slides.length}",
                    style: const TextStyle(
                      fontSize: 13,
                      color: ChurchColors.muted,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),

      // The bar carries the eligibility notice and the written release, so it
      // is text-heavy and grows with the member's font-size setting. Capped and
      // scrollable so it can never push itself off a small screen — the release
      // and the button must always be reachable.
      bottomNavigationBar: SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.62,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // The eligibility notice is guidance to read *before* agreeing;
                  // once the member has ticked the release it has served its
                  // purpose, so it collapses away and leaves the two clear
                  // choices — continue with facial, or not now — uncluttered.
                  AnimatedSize(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeInOut,
                    alignment: Alignment.topCenter,
                    child: _consented
                        ? const SizedBox(width: double.infinity)
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildEligibilityNotice(),
                              const SizedBox(height: 14),
                            ],
                          ),
                  ),
                  _buildConsentTick(),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: (_skipping || !_consented)
                          ? null
                          : _agreeAndContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ChurchColors.button,
                        foregroundColor: ChurchColors.buttonText,
                        disabledBackgroundColor: ChurchColors.button.withValues(
                          alpha: 0.35,
                        ),
                        disabledForegroundColor: ChurchColors.buttonText
                            .withValues(alpha: 0.8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        "Continue with facial recognition",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextButton(
                    onPressed: _skipping ? null : _skipFacialScan,
                    child: Text(
                      "Not now",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: ChurchColors.muted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Eligibility, stated plainly on the last screen before the camera opens.
  ///
  /// The app already blocks under-18 members at the date-of-birth gate, but
  /// the other conditions — participating location, jurisdiction, church
  /// authorisation — are ones only the member can answer, so they are put in
  /// front of them here rather than buried in the Notice. Mirrors Section 2 of
  /// `docs/BIOMETRIC_NOTICE_AND_CONSENT.md`.
  Widget _buildEligibilityNotice() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: ChurchColors.cardDecoration(shadow: const []),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.place_outlined, size: 18, color: ChurchColors.accent),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Facial recognition eligibility',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: ChurchColors.bodyText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Facial recognition is available only to eligible members attending '
            'participating church locations. If you are under 18, are outside a '
            'participating church, or are in a jurisdiction where this feature '
            'is unavailable (such as certain U.S. states), please do not '
            'continue with facial enrollment — you can keep using NFC or '
            'another available check-in method.',
            style: TextStyle(
              fontSize: 13,
              color: ChurchColors.muted,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  /// The written release. Tapping the row toggles it; tapping the Notice name
  /// opens the full text, which the member can read before agreeing.
  Widget _buildConsentTick() {
    return InkWell(
      onTap: _skipping ? null : () => setState(() => _consented = !_consented),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: _consented,
                onChanged: _skipping
                    ? null
                    : (val) => setState(() => _consented = val ?? false),
                activeColor: ChurchColors.button,
                side: const BorderSide(color: ChurchColors.muted, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text.rich(
                TextSpan(
                  style: const TextStyle(
                    fontSize: 13,
                    color: ChurchColors.muted,
                    height: 1.45,
                  ),
                  children: [
                    const TextSpan(text: 'I have read the '),
                    TextSpan(
                      text: 'Biometric Information Notice',
                      style: const TextStyle(
                        color: ChurchColors.accent,
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: _noticeTap,
                    ),
                    const TextSpan(
                      text:
                          ', and I consent to my facial data being used to '
                          'record my attendance. I am 18 or older, I attend a '
                          'participating church location, I am eligible as '
                          'described above, and I can withdraw this at any '
                          'time.',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlide(Map<String, dynamic> slide) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: ChurchColors.cardDecoration(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: ChurchColors.button.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              slide['icon'] as IconData,
              size: 40,
              color: ChurchColors.accent,
            ),
          ),
          const SizedBox(height: 10),
          AutoSizeText(
            slide['title'] as String,
            textAlign: TextAlign.center,
            minFontSize: 18,
            maxFontSize: 30,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: ChurchColors.bodyText,
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: AutoSizeText(
              slide['description'] as String,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: ChurchColors.muted,
                height: 1.4,
              ),
              minFontSize: 11,
              maxFontSize: 14,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
