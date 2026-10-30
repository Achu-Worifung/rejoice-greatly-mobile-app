import 'package:flutter/material.dart';

import '../theme/church_colors.dart';
import '../theme/church_type.dart';
import '../theme/display_settings.dart';
import 'dashboard_label_title.dart';

/// Text size and light/dark, on the profile. Changes show straight away.
class DisplaySection extends StatelessWidget {
  const DisplaySection({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<DisplayPrefs>(
      valueListenable: DisplaySettings.current,
      builder: (context, prefs, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const DashboardLabelText(label: 'Display'),
          Text('Text size', style: ChurchType.bodyStrong.copyWith(fontSize: 15)),
          const SizedBox(height: 8),
          _Choices<TextSizeChoice>(
            values: TextSizeChoice.values,
            selected: prefs.textSize,
            label: (c) => c.label,
            onSelected: DisplaySettings.setTextSize,
          ),
          const SizedBox(height: 6),
          Text(
            'Makes the app’s text bigger on top of your phone’s own setting.',
            style: ChurchType.caption,
          ),
          const SizedBox(height: 16),
          Text('Appearance', style: ChurchType.bodyStrong.copyWith(fontSize: 15)),
          const SizedBox(height: 8),
          _Choices<AppearanceChoice>(
            values: AppearanceChoice.values,
            selected: prefs.appearance,
            label: (c) => c.label,
            onSelected: DisplaySettings.setAppearance,
          ),
          const SizedBox(height: 6),
          Text(
            prefs.appearance == AppearanceChoice.automatic
                ? 'Follows your phone: light by day, dark when your phone is.'
                : 'Stays ${prefs.appearance.label.toLowerCase()} whatever your phone is set to.',
            style: ChurchType.caption,
          ),
        ],
      ),
    );
  }
}

class _Choices<T> extends StatelessWidget {
  const _Choices({
    required this.values,
    required this.selected,
    required this.label,
    required this.onSelected,
  });

  final List<T> values;
  final T selected;
  final String Function(T) label;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<T>(
      segments: [for (final v in values) ButtonSegment<T>(value: v, label: Text(label(v)))],
      selected: {selected},
      showSelectedIcon: false,
      onSelectionChanged: (s) => onSelected(s.first),
      style: SegmentedButton.styleFrom(
        backgroundColor: ChurchColors.background,
        foregroundColor: ChurchColors.bodyText,
        selectedBackgroundColor: ChurchColors.button,
        selectedForegroundColor: ChurchColors.buttonText,
        side: BorderSide(color: ChurchColors.divider),
        textStyle: ChurchType.button.copyWith(fontSize: 14),
      ),
    );
  }
}
