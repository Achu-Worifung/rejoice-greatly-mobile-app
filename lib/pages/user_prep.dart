import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:auto_size_text/auto_size_text.dart';

import '../theme/church_colors.dart';
import '../services/auth_service.dart';
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
                "You can explore the app right away. Without a face photo you "
                "won't be able to check in automatically — you can add one "
                "anytime from your profile.",
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
    navigatorKey.currentState
        ?.pushNamedAndRemoveUntil('/dashboard', (route) => false);
  }

  final List<Map<String, dynamic>> _slides = [
    {
      'icon': Icons.lock_outline,
      'title': 'Your Data is Secure',
      'description':
          'Your facial data is encrypted and stored securely. It is never shared with third parties or used outside of attendance tracking.',
    },
    {
      'icon': Icons.timer_outlined,
      'title': 'Takes Less Than 30 Seconds',
      'description':
          'The registration process is quick and simple. Just look at the camera and we\'ll handle the rest.',
    },
    {
      'icon': Icons.visibility_off_outlined,
      'title': 'Privacy First',
      'description':
          'Only your church administrators can access attendance records. Your facial data is never visible to other members.',
    },
    {
      'icon': Icons.delete_outline,
      'title': 'You\'re in Control',
      'description':
          'You can request to have your facial data deleted at any time by contacting your church administrator.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ChurchColors.background,
      body: SafeArea(
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
                "To take attendance with your face, we need to register your facial data. Don\'t worry, it\'s quick and secure!",
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
                  enlargeCenterPage: true, // Optional: makes the middle one pop
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

              const Spacer(),

              Center(
                child: Text(
                  "${_currentIndex + 1} of ${_slides.length}",
                  style: const TextStyle(fontSize: 13, color: ChurchColors.muted),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),

      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _skipping
                      ? null
                      : () {
                          Navigator.pushNamed(context, '/complete-signup');
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ChurchColors.button,
                    foregroundColor: ChurchColors.buttonText,
                    disabledBackgroundColor: ChurchColors.button,
                    disabledForegroundColor: ChurchColors.buttonText,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    "I Understand, Continue",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: _skipping ? null : _skipFacialScan,
                child: Text(
                  "No thanks, maybe later",
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
