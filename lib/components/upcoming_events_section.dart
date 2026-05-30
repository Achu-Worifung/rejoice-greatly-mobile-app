import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../pages/event_detail_page.dart';
import '../theme/church_colors.dart';
import '../widgets/dashboard_label_title.dart';

class UpcomingEventsSection extends StatelessWidget {
  const UpcomingEventsSection({
    super.key,
    required this.events,
  });

  final List<Map<String, dynamic>> events;



  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: DashboardLabelText(label: 'UPCOMING EVENTS'),
        ),
        SizedBox(
          // Poster (3:4 @ 168w) + title + date; fixed height prevents overflow.
          height: 300,
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
        child: InkWell(
          onTap: () => openEventDetailPage(context, event),
          borderRadius: BorderRadius.circular(ChurchColors.cardRadius),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(ChurchColors.cardRadius),
                child: AspectRatio(
                  aspectRatio: 3 / 4,
                  child: ColoredBox(
                    color: ChurchColors.card,
                    child: _PosterImage(url: event['imageUrl'] as String?),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: ChurchColors.bodyText,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
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
      ),
    );
  }
}

class _PosterImage extends StatelessWidget {
  const _PosterImage({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return const Center(
        child: Icon(Icons.event, size: 40, color: ChurchColors.muted),
      );
    }
    return Image.network(
      url!,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.contain,
      alignment: Alignment.center,
      errorBuilder: (c, e, s) => const Center(
        child: Icon(Icons.event, size: 40, color: ChurchColors.muted),
      ),
    );
  }
}

