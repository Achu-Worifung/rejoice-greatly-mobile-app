import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'church_colors.dart';

/// How big the app's text is, on top of the phone's own setting.
enum TextSizeChoice {
  standard(1.0, 'Standard'),
  large(1.15, 'Large'),
  larger(1.3, 'Larger');

  const TextSizeChoice(this.factor, this.label);
  final double factor;
  final String label;
}

/// Light, dark, or whatever the phone is set to.
enum AppearanceChoice {
  automatic(ThemeMode.system, 'Automatic'),
  light(ThemeMode.light, 'Light'),
  dark(ThemeMode.dark, 'Dark');

  const AppearanceChoice(this.mode, this.label);
  final ThemeMode mode;
  final String label;
}

@immutable
class DisplayPrefs {
  const DisplayPrefs({this.textSize = TextSizeChoice.standard, this.appearance = AppearanceChoice.automatic});

  final TextSizeChoice textSize;
  final AppearanceChoice appearance;

  DisplayPrefs copyWith({TextSizeChoice? textSize, AppearanceChoice? appearance}) =>
      DisplayPrefs(textSize: textSize ?? this.textSize, appearance: appearance ?? this.appearance);
}

/// The member's text size and appearance, kept on this phone.
class DisplaySettings {
  DisplaySettings._();

  static const _textSizeKey = 'display_text_size';
  static const _appearanceKey = 'display_appearance';

  static final ValueNotifier<DisplayPrefs> current = ValueNotifier(const DisplayPrefs());

  /// How many [LightOnly] screens are open. While any is, the app stays light.
  static final ValueNotifier<int> lightOnlyScreens = ValueNotifier(0);

  /// The theme mode to show right now.
  static ThemeMode get themeMode =>
      lightOnlyScreens.value > 0 ? ThemeMode.light : current.value.appearance.mode;

  /// Reads what was saved. Call before the app starts, so the first frame is right.
  static Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      current.value = DisplayPrefs(
        textSize: TextSizeChoice.values.asNameMap()[p.getString(_textSizeKey)] ?? TextSizeChoice.standard,
        appearance: AppearanceChoice.values.asNameMap()[p.getString(_appearanceKey)] ?? AppearanceChoice.automatic,
      );
    } catch (e) {
      debugPrint('DisplaySettings.load failed: $e');
    }
  }

  static Future<void> setTextSize(TextSizeChoice choice) async {
    current.value = current.value.copyWith(textSize: choice);
    await _save(_textSizeKey, choice.name);
  }

  static Future<void> setAppearance(AppearanceChoice choice) async {
    current.value = current.value.copyWith(appearance: choice);
    await _save(_appearanceKey, choice.name);
  }

  static Future<void> _save(String key, String value) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(key, value);
    } catch (e) {
      debugPrint('DisplaySettings: could not save $key: $e');
    }
  }
}

/// Keeps the app light while [child] is showing — for the in-app admin tools,
/// which have their own colours and aren't drawn for dark.
class LightOnly extends StatefulWidget {
  const LightOnly({super.key, required this.child});

  final Widget child;

  @override
  State<LightOnly> createState() => _LightOnlyState();
}

class _LightOnlyState extends State<LightOnly> {
  @override
  void initState() {
    super.initState();
    // Not during build: the app's theme is above this widget.
    WidgetsBinding.instance.addPostFrameCallback((_) => DisplaySettings.lightOnlyScreens.value++);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.addPostFrameCallback((_) => DisplaySettings.lightOnlyScreens.value--);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Sits just under the app's theme: shows the palette the theme is in, and
/// scales text by the member's choice on top of the phone's own size.
///
/// The colour tokens aren't inherited widgets, so after a switch every
/// widget is asked to build again (keeping its state) to pick them up.
class DisplayScope extends StatelessWidget {
  const DisplayScope({super.key, required this.child});

  final Widget child;

  /// Text never grows past this, however the two settings combine.
  static const double maxScale = 2.0;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    if (ChurchColors.use(dark ? ChurchPalette.dark : ChurchPalette.light)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _rebuildEverything());
    }
    final factor = DisplaySettings.current.value.textSize.factor;
    final media = MediaQuery.of(context);
    final scale = math.min(media.textScaler.scale(16) / 16 * factor, maxScale);
    return MediaQuery(
      data: media.copyWith(textScaler: TextScaler.linear(scale)),
      child: child,
    );
  }

  static void _rebuildEverything() {
    void mark(Element element) {
      element.markNeedsBuild();
      element.visitChildren(mark);
    }

    WidgetsBinding.instance.rootElement?.visitChildren(mark);
  }
}
