import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/branded_loader.dart';
import 'RootPage.dart';

/// The app's animated front door.
///
/// It boots looking *identical* to the native splash (Roasted Cocoa + the gold
/// emblem, same size and position), so the native → Flutter handoff has no
/// flash. From there it plays a restrained, warm reveal — a halo blooms behind
/// the emblem, a soft shimmer sweeps across the gold, the welcome scripture
/// fades up, and a calm progress line settles in — then cross-fades into
/// [RootPage]. Because RootPage's own loading state is the same [BrandedLoader]
/// surface, the whole cold-start reads as one continuous moment.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  /// One-shot entrance timeline.
  late final AnimationController _entrance;

  /// Gentle continuous "breath" on the emblem.
  late final AnimationController _breath;

  /// Soft highlight sweeping across the gold emblem.
  late final AnimationController _shimmer;

  bool _started = false;
  bool _reduce = false;
  bool _navigated = false;

  /// Minimum time the welcome stays on screen, so it never feels like a flicker
  /// even when auth resolves instantly.
  static const Duration _minHold = Duration(milliseconds: 1900);
  static const Duration _entranceDur = Duration(milliseconds: 1500);

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(vsync: this, duration: _entranceDur);
    _breath = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    // Match the fullscreen native splash: hide the system bars so no status bar
    // pops in at the handoff. Restored in [_goNext] before entering the app.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // MediaQuery is available here; start once.
    if (!_started) {
      _started = true;
      _reduce = MediaQuery.of(context).disableAnimations;
      _run();
    }
  }

  void _run() {
    if (_reduce) {
      _entrance.value = 1.0;
      Future.delayed(const Duration(milliseconds: 750), _goNext);
    } else {
      _entrance.forward();
      _breath.repeat(reverse: true);
      _shimmer.repeat();
      Future.delayed(_minHold, _goNext);
    }
  }

  void _goNext() {
    if (_navigated || !mounted) return;
    _navigated = true;

    // Bring the system bars back for the app, and hand the light-content style
    // back to the app's light theme.
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const RootPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _entrance.dispose();
    _breath.dispose();
    _shimmer.dispose();
    super.dispose();
  }

  /// Eased sub-segment of the entrance timeline in [a, b].
  double _seg(double a, double b, Curve curve) {
    final t = ((_entrance.value - a) / (b - a)).clamp(0.0, 1.0);
    return curve.transform(t);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSplashBackground,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: Listenable.merge([_entrance, _breath, _shimmer]),
          builder: (context, _) {
            final haloOpacity = _seg(0.0, 0.5, Curves.easeOutCubic) * 0.9;
            final haloScale = 0.7 + 0.3 * _seg(0.0, 0.55, Curves.easeOutCubic);

            // The emblem holds at exactly the native splash's size and position
            // across the handoff — no entrance scale, so there is no size pop.
            // The reveal is carried by the halo, shimmer, and scripture instead.
            const entranceScale = 1.0;
            final breathScale = 1.0 + 0.016 * _breath.value;

            final scriptureOpacity = _seg(0.55, 0.85, Curves.easeOut);
            final scriptureDy = (1 - _seg(0.55, 0.92, Curves.easeOutCubic)) * 12;

            final progressOpacity = _seg(0.45, 0.78, Curves.easeOut);

            return Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: kEmblemBox,
                        height: kEmblemBox,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Warm halo bloom behind the emblem.
                            Opacity(
                              opacity: haloOpacity,
                              child: Transform.scale(
                                scale: haloScale,
                                child: Container(
                                  width: 210,
                                  height: 210,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        kSplashCream.withValues(alpha: 0.16),
                                        kSplashCream.withValues(alpha: 0.05),
                                        Colors.transparent,
                                      ],
                                      stops: const [0.0, 0.55, 1.0],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // The emblem — visible from the first frame at the
                            // native splash's size, then settling into the
                            // composed layout. No fade-in: that's what keeps the
                            // native → Flutter handoff seamless.
                            Transform.scale(
                              scale: entranceScale * breathScale,
                              child: SizedBox(
                                width: kEmblemSize,
                                height: kEmblemSize,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    const SplashEmblem(),
                                    if (!_reduce)
                                      _EmblemShimmer(progress: _shimmer.value),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      Opacity(
                        opacity: scriptureOpacity,
                        child: Transform.translate(
                          offset: Offset(0, scriptureDy),
                          child: const SplashScripture(),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 56,
                  child: Center(
                    child: Opacity(
                      opacity: progressOpacity,
                      child: CalmProgressLine(animate: !_reduce),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// A soft diagonal highlight that drifts across the emblem, clipped to the
/// badge's circle. Subtle by design — a whisper of life on the gold, not a
/// flashy sweep.
class _EmblemShimmer extends StatelessWidget {
  const _EmblemShimmer({required this.progress});

  /// 0 → 1, loops.
  final double progress;

  @override
  Widget build(BuildContext context) {
    final dx = (-1.3 + 2.6 * progress) * kEmblemSize;
    return ClipOval(
      child: SizedBox(
        width: kEmblemSize,
        height: kEmblemSize,
        child: Transform.translate(
          offset: Offset(dx, 0),
          child: Transform.rotate(
            angle: 0.42,
            child: Container(
              width: kEmblemSize * 0.5,
              height: kEmblemSize * 2,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.transparent,
                    Color(0x2EFFFFFF), // white @ ~18%
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
