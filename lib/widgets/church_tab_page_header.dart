import 'package:flutter/material.dart';

import '../theme/church_colors.dart';

/// Shared title + search block for the Sermons & Events tab pages.
///
/// Both pages render this identical widget as the app bar `title`, at the same
/// [height], so the page title sits at the exact same distance from the top on
/// every tab. Each page's distinct control (Sermons' tab bar, Events' filter
/// chips) goes in the app bar `bottom` slot, below this shared header.
class ChurchTabPageHeader extends StatelessWidget {
  const ChurchTabPageHeader({
    super.key,
    required this.title,
    required this.controller,
    required this.hintText,
    required this.onChanged,
  });

  final String title;
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;

  static const EdgeInsets kTitlePadding = EdgeInsets.fromLTRB(16, 10, 16, 6);

  /// Toolbar height that fits the title + search field with [kTitlePadding].
  /// Shared by both pages so the title never shifts between tabs.
  static const double height = 108;

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
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: ChurchColors.bodyText,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 12),
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
    return Container(
      decoration: BoxDecoration(
        color: ChurchColors.card,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: ChurchColors.muted.withValues(alpha: 0.6),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: ChurchColors.muted,
            size: 20,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                BorderSide(color: ChurchColors.divider.withValues(alpha: 0.25)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: ChurchColors.button.withValues(alpha: 0.7),
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}
