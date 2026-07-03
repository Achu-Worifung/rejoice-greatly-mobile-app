import 'package:flutter/material.dart';
import '../theme/church_colors.dart';

/// Shared visual language for the app's cold-start "Warm Welcome" surface.
///
/// Both the animated [SplashScreen] and RootPage's loading state resolve to
/// this same resting composition — emblem, scripture, and a calm progress
/// line on Roasted Cocoa. That's deliberate: the launch should read as one
/// continuous moment (brown → richer brown → app), never a brown splash
/// flashing into a bare white spinner.
const Color kSplashBackground = ChurchColors.button; // Roasted Cocoa #633A02
const Color kSplashCream = ChurchColors.card; //        Candlelight Cream #FFF7EB
// Matches the native splash's rendered size (splash_logo.png 640px ÷ 4 ≈ 160dp)
// so the emblem never changes size across the native → Flutter handoff.
const double kEmblemSize = 160;

/// The square the emblem lives in on both surfaces. Larger than the emblem so
/// the splash can start the emblem near the native size and settle it inward
/// without shifting anything below it. Both surfaces share it so the crossfade
/// from the splash into RootPage's loading state has no vertical jump.
const double kEmblemBox = 220;

/// The front-door scripture. One editable place. Chosen to *welcome* the
/// congregation rather than repeat the emblem's own "Rejoice Greatly" wordmark.
const String kSplashScripture = 'Rejoice greatly, O Daughter of Zion!';
const String kSplashScriptureRef = 'Zechariah 9:9';

/// The gold "Rejoice Greatly" emblem, sized to match the native splash so the
/// native → Flutter handoff has no visible jump.
class SplashEmblem extends StatelessWidget {
  const SplashEmblem({super.key, this.size = kEmblemSize});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}

/// Welcoming scripture line + reference, in cream on brown.
class SplashScripture extends StatelessWidget {
  const SplashScripture({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          kSplashScripture,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: kSplashCream.withValues(alpha: 0.94),
            fontSize: 15,
            height: 1.4,
            fontStyle: FontStyle.italic,
            letterSpacing: 0.2,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          kSplashScriptureRef.toUpperCase(),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: kSplashCream.withValues(alpha: 0.66),
            fontSize: 11,
            letterSpacing: 2.4,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// A slim, calm indeterminate progress line — a soft cream glow that drifts
/// back and forth across a faint track. No spinner: the tone is unhurried.
class CalmProgressLine extends StatefulWidget {
  const CalmProgressLine({super.key, this.width = 132, this.animate = true});

  final double width;
  final bool animate;

  @override
  State<CalmProgressLine> createState() => _CalmProgressLineState();
}

class _CalmProgressLineState extends State<CalmProgressLine>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    if (widget.animate) _c.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant CalmProgressLine oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !_c.isAnimating) {
      _c.repeat(reverse: true);
    } else if (!widget.animate && _c.isAnimating) {
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final track = kSplashCream.withValues(alpha: 0.16);

    if (!widget.animate) {
      // Reduced-motion: a static, centered glow. Still reads as "working".
      return SizedBox(
        width: widget.width,
        height: 3,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: Stack(
            children: [
              Container(color: track),
              Align(
                alignment: Alignment.center,
                child: FractionallySizedBox(
                  widthFactor: 0.42,
                  child: Container(
                    color: kSplashCream.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      width: widget.width,
      height: 3,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final t = Curves.easeInOut.transform(_c.value);
            return Stack(
              children: [
                Container(color: track),
                Align(
                  alignment: Alignment(-1 + 2 * t, 0),
                  child: FractionallySizedBox(
                    widthFactor: 0.42,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            kSplashCream.withValues(alpha: 0.9),
                            Colors.transparent,
                          ],
                        ),
                      ),
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

/// The resting "Warm Welcome" surface, shown by RootPage while Firebase auth
/// and session restore resolve. Visually identical to [SplashScreen]'s settled
/// state, so the fade between them is invisible on a slow connection.
class BrandedLoader extends StatelessWidget {
  const BrandedLoader({super.key, this.showScripture = true});

  final bool showScripture;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.of(context).disableAnimations;
    return Scaffold(
      backgroundColor: kSplashBackground,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: kEmblemBox,
                    height: kEmblemBox,
                    child: Center(child: SplashEmblem()),
                  ),
                  if (showScripture) ...[
                    const SizedBox(height: 28),
                    const SplashScripture(),
                  ],
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 56,
              child: Center(child: CalmProgressLine(animate: !reduce)),
            ),
          ],
        ),
      ),
    );
  }
}
