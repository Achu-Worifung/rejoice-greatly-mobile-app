import 'package:flutter/material.dart';

import 'church_colors.dart';
import 'church_type.dart';
import 'page_transitions.dart';

/// The app theme: the register look on the app's own palette.
///
/// Everything here reads from [ChurchColors], [ChurchType] and [ChurchRadius]
/// so that a widget reaching for `Theme.of(context)` lands on the same faces
/// and edges as one built from the tokens directly. The palette is unchanged
/// from before; what this sets is typography, shape and the ruled borders.
ThemeData buildChurchTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: ChurchColors.button,
    brightness: Brightness.light,
    primary: ChurchColors.button,
    onPrimary: ChurchColors.buttonText,
    surface: ChurchColors.background,
    onSurface: ChurchColors.bodyText,
    outline: ChurchColors.divider,
  );

  OutlineInputBorder inputBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: ChurchRadius.mdAll,
      borderSide: BorderSide(color: color, width: width),
    );
  }

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    fontFamily: ChurchFonts.sans,
    textTheme: ChurchType.textTheme,
    scaffoldBackgroundColor: ChurchColors.background,
    pageTransitionsTheme: kChurchPageTransitionsTheme,
    dividerColor: ChurchColors.divider,
    splashFactory: InkSparkle.splashFactory,

    appBarTheme: const AppBarTheme(
      backgroundColor: ChurchColors.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: ChurchType.headline,
      iconTheme: IconThemeData(color: ChurchColors.accent, size: 24),
    ),

    // Cards are flat, cream and ruled; the old warm shadow is gone.
    cardTheme: CardThemeData(
      color: ChurchColors.card,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: ChurchRadius.lgAll,
        side: ChurchRules.hairline,
      ),
    ),

    dividerTheme: const DividerThemeData(
      color: ChurchColors.divider,
      thickness: 1,
      space: 1,
    ),

    // Primary is flat — its colour is its elevation. Secondary surfaces are
    // ruled rather than lifted.
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: ChurchColors.button,
        foregroundColor: ChurchColors.buttonText,
        textStyle: ChurchType.button,
        minimumSize: const Size(44, 48),
        shape: const RoundedRectangleBorder(borderRadius: ChurchRadius.mdAll),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: ChurchColors.button,
        foregroundColor: ChurchColors.buttonText,
        textStyle: ChurchType.button,
        minimumSize: const Size(44, 48),
        shape: const RoundedRectangleBorder(borderRadius: ChurchRadius.mdAll),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: ChurchColors.bodyText,
        textStyle: ChurchType.button,
        minimumSize: const Size(44, 48),
        side: ChurchRules.hairline,
        shape: const RoundedRectangleBorder(borderRadius: ChurchRadius.mdAll),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: ChurchColors.accent,
        textStyle: ChurchType.button,
        minimumSize: const Size(44, 44),
        shape: const RoundedRectangleBorder(borderRadius: ChurchRadius.mdAll),
      ),
    ),

    // A field is a ruled box on white: 1px sand rule, crisp corners, and the
    // accent rule when it has focus.
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: ChurchColors.background,
      labelStyle: ChurchType.label,
      floatingLabelStyle: ChurchType.label.copyWith(color: ChurchColors.accent),
      hintStyle: ChurchType.body.copyWith(
        color: ChurchColors.muted.withValues(alpha: 0.7),
      ),
      helperStyle: ChurchType.caption,
      errorStyle: ChurchType.caption.copyWith(color: colorScheme.error),
      prefixIconColor: ChurchColors.muted,
      suffixIconColor: ChurchColors.muted,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: inputBorder(ChurchColors.divider),
      enabledBorder: inputBorder(ChurchColors.divider),
      focusedBorder: inputBorder(ChurchColors.accent, width: 1.5),
      errorBorder: inputBorder(colorScheme.error),
      focusedErrorBorder: inputBorder(colorScheme.error, width: 1.5),
    ),

    chipTheme: ChipThemeData(
      backgroundColor: ChurchColors.background,
      selectedColor: ChurchColors.card,
      side: ChurchRules.hairline,
      labelStyle: ChurchType.label.copyWith(color: ChurchColors.bodyText),
      shape: const RoundedRectangleBorder(borderRadius: ChurchRadius.smAll),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: ChurchColors.background,
      elevation: 0,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: ChurchColors.accent,
      selectedLabelStyle: TextStyle(
        fontFamily: ChurchFonts.sans,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: TextStyle(
        fontFamily: ChurchFonts.sans,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    ),

    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: ChurchColors.background,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(ChurchRadius.lg)),
      ),
    ),

    dialogTheme: DialogThemeData(
      backgroundColor: ChurchColors.background,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: ChurchType.headline,
      contentTextStyle: ChurchType.body,
      shape: RoundedRectangleBorder(
        borderRadius: ChurchRadius.lgAll,
        side: ChurchRules.hairline,
      ),
    ),

    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: ChurchColors.bodyText,
      contentTextStyle: ChurchType.body.copyWith(color: ChurchColors.background),
      shape: const RoundedRectangleBorder(borderRadius: ChurchRadius.mdAll),
    ),

    tabBarTheme: TabBarThemeData(
      labelColor: ChurchColors.accent,
      unselectedLabelColor: ChurchColors.muted,
      labelStyle: ChurchType.bodyStrong,
      unselectedLabelStyle: ChurchType.body.copyWith(fontWeight: FontWeight.w500),
      indicatorColor: ChurchColors.accent,
      indicatorSize: TabBarIndicatorSize.label,
      dividerColor: ChurchColors.divider,
    ),

    listTileTheme: const ListTileThemeData(
      titleTextStyle: ChurchType.bodyStrong,
      subtitleTextStyle: ChurchType.label,
      iconColor: ChurchColors.accent,
    ),

    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: ChurchColors.accent,
    ),
  );
}
