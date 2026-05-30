import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/church_colors.dart';
import '../widgets/detail_page_hero.dart';

/// Full-screen event details with poster image; opened via [Navigator.push].
class EventDetailPage extends StatelessWidget {
  const EventDetailPage({super.key, required this.event});

  final Map<String, dynamic> event;

  @override
  Widget build(BuildContext context) {
    final imageUrl = event['imageUrl'] as String?;
    final title = event['title'] as String? ?? 'Event';
    final time = event['time'] as String? ?? '';
    final location = event['location'] as String? ?? '';
    final category = event['category'] as String? ?? 'General';
    final description = (event['description'] as String?)?.trim() ?? '';
    final dateStr = event['date'] as String? ?? '';

    String? formattedDate;
    if (dateStr.length >= 10) {
      try {
        formattedDate = DateFormat.yMMMMEEEEd().format(DateTime.parse(dateStr.substring(0, 10)));
      } catch (_) {
        formattedDate = dateStr;
      }
    }

    final whenLine = <String>[];
    if (formattedDate != null && formattedDate.isNotEmpty) whenLine.add(formattedDate);
    if (time.isNotEmpty) whenLine.add(time);
    final when = whenLine.join(' · ');

    return Scaffold(
      backgroundColor: ChurchColors.background,
      extendBodyBehindAppBar: true,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: DetailPageHeroHeader(
              imageUrl: imageUrl,
              placeholderIcon: Icons.event,
              onBack: () => Navigator.of(context).maybePop(),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: ChurchColors.bodyText,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                DetailCategoryChip(label: category),
                const SizedBox(height: 16),
                if (when.isNotEmpty) DetailInfoRow(icon: Icons.event_rounded, text: when),
                if (location.isNotEmpty) DetailInfoRow(icon: Icons.place_outlined, text: location),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Text(
                    'Details',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: ChurchColors.accent,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: ChurchColors.bodyText,
                    ),
                  ),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

void openEventDetailPage(BuildContext context, Map<String, dynamic> event) {
  Navigator.of(context, rootNavigator: true).push<void>(
    MaterialPageRoute<void>(
      builder: (context) => EventDetailPage(event: Map<String, dynamic>.from(event)),
    ),
  );
}
