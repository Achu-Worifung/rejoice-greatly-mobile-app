import 'package:flutter/material.dart';

/// A soft, unhurried page transition used across the whole app.
///
/// The incoming page fades in while gently rising a few pixels into place; the
/// page it covers eases back with a light fade and a small upward drift so the
/// handoff feels layered rather than abrupt. It intentionally avoids the sharp
/// full-width slide of the platform defaults — the motion here should read like
/// being *greeted at the door*: warm, calm, and never jarring.
///
/// Wired into [ThemeData.pageTransitionsTheme] so it applies to every route —
/// named routes and direct `Navigator.push` calls alike — without changing any
/// navigation call site.
class ChurchPageTransitionsBuilder extends PageTransitionsBuilder {
  const ChurchPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Incoming page: fade in + rise gently into place.
    final entering = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    // Outgoing page (the one being covered): ease back with a soft fade and a
    // small upward drift so it recedes rather than snapping away.
    final leaving = CurvedAnimation(
      parent: secondaryAnimation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    return FadeTransition(
      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(entering),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.035),
          end: Offset.zero,
        ).animate(entering),
        child: FadeTransition(
          opacity: Tween<double>(begin: 1.0, end: 0.94).animate(leaving),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: Offset.zero,
              end: const Offset(0, -0.02),
            ).animate(leaving),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// App-wide transition theme: the same warm greeting on every platform.
///
/// Applied uniformly across Android, iOS and the rest so the app feels the same
/// no matter the device, in keeping with the product's warmth-through-restraint
/// principle.
const PageTransitionsTheme kChurchPageTransitionsTheme = PageTransitionsTheme(
  builders: <TargetPlatform, PageTransitionsBuilder>{
    TargetPlatform.android: ChurchPageTransitionsBuilder(),
    TargetPlatform.iOS: ChurchPageTransitionsBuilder(),
    TargetPlatform.macOS: ChurchPageTransitionsBuilder(),
    TargetPlatform.windows: ChurchPageTransitionsBuilder(),
    TargetPlatform.linux: ChurchPageTransitionsBuilder(),
    TargetPlatform.fuchsia: ChurchPageTransitionsBuilder(),
  },
);
