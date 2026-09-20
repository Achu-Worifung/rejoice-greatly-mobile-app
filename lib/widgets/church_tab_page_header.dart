import 'package:flutter/material.dart';

import '../theme/church_colors.dart';
import '../theme/church_type.dart';

/// Shared title + search block for the Sermons & Events tab pages.
///
/// Both pages render this identical widget as the app bar `title`, at the same
/// [height], so the page title sits at the exact same distance from the top on
/// every tab. Each page's distinct control (Sermons' tab bar, Events' filter
/// chips) goes in the app bar `bottom` slot, below this shared header.
///
/// The block is the register's page hero in miniature: a mono eyebrow, one
/// serif headline, then a ruled search field.
class ChurchTabPageHeader extends StatelessWidget {
  const ChurchTabPageHeader({
    super.key,
    required this.title,
    required this.controller,
    required this.hintText,
    required this.onChanged,
    this.eyebrow = 'Rejoice Greatly',
  });

  final String title;
  final String eyebrow;
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;

  static const EdgeInsets kTitlePadding = EdgeInsets.fromLTRB(16, 8, 16, 8);

  // The two text lines scale with the user's font size; the field and the
  // gaps do not.
  static const double _textHeight =
      12 * 1.2 /* eyebrow */ + 26 * 1.15 /* title */;
  static const double _fixedHeight =
      16 /* padding */ + 2 + 10 /* gaps */ + 44 /* search */ + 6 /* slack */;

  /// Toolbar height that fits eyebrow + title + search field with
  /// [kTitlePadding] at the current text scale. Shared by both pages so the
  /// title never shifts between tabs — and never overflows at large text.
  static double heightOf(BuildContext context) {
    final scaled = MediaQuery.textScalerOf(context).scale(_textHeight);
    return _fixedHeight + scaled;
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: kTitlePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            ChurchEyebrow(eyebrow),
            const SizedBox(height: 2),
            Text(
              title,
              textAlign: TextAlign.left,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ChurchType.display.copyWith(fontSize: 26),
            ),
            const SizedBox(height: 10),
            _SearchField(
              controller: controller,
              hintText: hintText,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.hintText,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: TextField(
        // Cream on the white bar, so it reads as a field and not a rule
        // floating in space.
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        style: ChurchType.body,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: ChurchType.body.copyWith(
            color: ChurchColors.muted.withValues(alpha: 0.7),
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: ChurchColors.muted,
            size: 20,
          ),
          isDense: true,
          fillColor: ChurchColors.card,
          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        ),
      ),
    );
  }
}
