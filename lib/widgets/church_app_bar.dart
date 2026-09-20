import 'package:flutter/material.dart';

import '../theme/church_colors.dart';
import '../theme/church_type.dart';

/// Shared app bar look: white bar, no elevation, brown icons, serif title.
class ChurchAppBar {
  ChurchAppBar._();

  static const TextStyle titleStyle = ChurchType.headline;

  /// The mono micro-label above or beside a title.
  static const TextStyle kickerStyle = ChurchType.eyebrow;

  static AppBar of({
    required Widget title,
    bool centerTitle = true,
    double titleSpacing = 0,
    double? toolbarHeight,
    Widget? leading,
    List<Widget>? actions,
    PreferredSizeWidget? bottom,
    bool automaticallyImplyLeading = true,
  }) {
    return AppBar(
      backgroundColor: ChurchColors.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      shadowColor: Colors.transparent,
      toolbarHeight: toolbarHeight,
      centerTitle: centerTitle,
      titleSpacing: titleSpacing,
      title: title,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      actions: actions,
      bottom: bottom,
      iconTheme: const IconThemeData(color: ChurchColors.accent, size: 24),
    );
  }

  static AppBar pageTitle(
    String text, {
    bool centerTitle = true,
    Widget? leading,
    List<Widget>? actions,
    PreferredSizeWidget? bottom,
    double? toolbarHeight,
    bool automaticallyImplyLeading = true,
  }) {
    return of(
      title: Text(text, style: titleStyle),
      centerTitle: centerTitle,
      leading: leading,
      actions: actions,
      bottom: bottom,
      toolbarHeight: toolbarHeight,
      automaticallyImplyLeading: automaticallyImplyLeading,
    );
  }
}
