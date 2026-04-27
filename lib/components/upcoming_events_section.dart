import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:intl/intl.dart';

import '../theme/church_colors.dart';

class UpcomingEventsSection extends StatelessWidget {
  const UpcomingEventsSection({
    super.key,
    required this.events,
    this.onViewAll,
  });

  final List<Map<String, dynamic>> events;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              const Expanded(
                child: AutoSizeText(
                  'UPCOMING EVENTS',
                  minFontSize: 12,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: ChurchColors.accent,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              TextButton(
                onPressed: onViewAll,
                style: TextButton.styleFrom(
                  foregroundColor: ChurchColors.accent,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: const Text(
                  'VIEW ALL',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    decoration: TextDecoration.underline,
                    decorationColor: ChurchColors.accent,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          // Poster (3:4 @ 168w) + gap + date line; fixed height prevents overflow.
          height: 276,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(bottom: 4),
            itemCount: events.length,
            separatorBuilder: (context, _) => const SizedBox(width: 14),
            itemBuilder: (context, i) {
              return _EventStripCard(event: events[i]);
            },
          ),
        ),
      ],
    );
  }
}

class _EventStripCard extends StatelessWidget {
  const _EventStripCard({required this.event});

  final Map<String, dynamic> event;

  @override
  Widget build(BuildContext context) {
    final title = (event['title'] as String?) ?? 'Event';
    final rawDate = event['date'] as String? ?? '';
    String dateLine = rawDate;
    if (rawDate.length >= 10) {
      try {
        final d = DateTime.parse(rawDate.substring(0, 10));
        dateLine = DateFormat('MMM d, y').format(d);
      } catch (_) {}
    }

    return SizedBox(
      width: 168,
      child: Material(
        color: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(ChurchColors.cardRadius),
              child: AspectRatio(
                aspectRatio: 3 / 4,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      event['imageUrl'] as String? ?? '',
                      fit: BoxFit.cover,
                      errorBuilder: (BuildContext c, Object e, StackTrace? s) => Container(
                        color: ChurchColors.card,
                        alignment: Alignment.center,
                        child: const Icon(Icons.event, size: 40, color: ChurchColors.muted),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.55),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 10,
                      right: 10,
                      bottom: 10,
                      child: Text(
                        title.toUpperCase(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              dateLine,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: ChurchColors.accent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
