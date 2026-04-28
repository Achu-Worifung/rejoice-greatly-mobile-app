import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/church_colors.dart';
import '../widgets/church_app_bar.dart';

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
      appBar: ChurchAppBar.pageTitle(
        'Event',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: ChurchColors.accent),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        children: [
          if (imageUrl != null && imageUrl.isNotEmpty)
            Image.network(
              imageUrl,
              width: double.infinity,
              height: 260,
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) => _placeholder(),
            )
          else
            _placeholder(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: ChurchColors.button.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    category.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: ChurchColors.accent,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (when.isNotEmpty) _row(Icons.event_rounded, when),
                if (location.isNotEmpty) _row(Icons.place_outlined, location),
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: double.infinity,
      height: 200,
      color: ChurchColors.card,
      child: const Center(
        child: Icon(Icons.event, size: 64, color: ChurchColors.muted),
      ),
    );
  }

  Widget _row(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: ChurchColors.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: ChurchColors.bodyText,
                fontSize: 16,
                height: 1.35,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void openEventDetailPage(BuildContext context, Map<String, dynamic> event) {
  Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (context) => EventDetailPage(event: Map<String, dynamic>.from(event)),
    ),
  );
}
