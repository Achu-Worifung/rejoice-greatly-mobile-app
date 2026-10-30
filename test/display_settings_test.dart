import 'package:church_app/theme/church_colors.dart';
import 'package:church_app/theme/church_theme.dart';
import 'package:church_app/theme/display_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(AppearanceChoice appearance, Widget home) => MaterialApp(
      theme: buildChurchTheme(ChurchPalette.light),
      darkTheme: buildChurchTheme(ChurchPalette.dark),
      themeMode: appearance.mode,
      builder: (context, child) => DisplayScope(child: child!),
      home: home,
    );

void main() {
  tearDown(() {
    DisplaySettings.current.value = const DisplayPrefs();
    ChurchColors.use(ChurchPalette.light);
  });

  testWidgets('dark appearance switches the colour tokens, light switches them back', (tester) async {
    await tester.pumpWidget(_app(AppearanceChoice.dark, const SizedBox()));
    await tester.pumpAndSettle();
    expect(ChurchColors.isDark, isTrue);
    expect(ChurchColors.background, ChurchPalette.dark.background);

    await tester.pumpWidget(_app(AppearanceChoice.light, const SizedBox()));
    await tester.pumpAndSettle();
    expect(ChurchColors.isDark, isFalse);
  });

  testWidgets('the chosen text size scales on top of the phone’s own', (tester) async {
    late double scale;
    DisplaySettings.current.value = const DisplayPrefs(textSize: TextSizeChoice.larger);
    tester.platformDispatcher.textScaleFactorTestValue = 1.2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(_app(
      AppearanceChoice.light,
      Builder(builder: (context) {
        scale = MediaQuery.textScalerOf(context).scale(10) / 10;
        return const SizedBox();
      }),
    ));

    expect(scale, closeTo(1.2 * 1.3, 0.001));
  });

  test('both palettes keep body text and muted text readable on their surfaces', () {
    double luminance(Color c) => c.computeLuminance();
    double contrast(Color a, Color b) {
      final hi = luminance(a) > luminance(b) ? luminance(a) : luminance(b);
      final lo = luminance(a) > luminance(b) ? luminance(b) : luminance(a);
      return (hi + 0.05) / (lo + 0.05);
    }

    for (final p in [ChurchPalette.light, ChurchPalette.dark]) {
      for (final surface in [p.background, p.card]) {
        expect(contrast(p.bodyText, surface), greaterThanOrEqualTo(4.5));
        expect(contrast(p.muted, surface), greaterThanOrEqualTo(4.5));
        expect(contrast(p.accent, surface), greaterThanOrEqualTo(4.5));
        expect(contrast(p.danger, surface), greaterThanOrEqualTo(4.5));
      }
      expect(contrast(p.buttonText, p.button), greaterThanOrEqualTo(4.5));
      expect(contrast(p.successInk, p.successSurface), greaterThanOrEqualTo(4.5));
      expect(contrast(p.errorInk, p.errorSurface), greaterThanOrEqualTo(4.5));
    }
  });
}
