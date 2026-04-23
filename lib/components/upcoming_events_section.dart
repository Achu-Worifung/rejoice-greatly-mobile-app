import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';

class UpcomingEventsSection extends StatelessWidget {
  final List<dynamic> events;

  const UpcomingEventsSection({super.key, required this.events});

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: AutoSizeText(
                  'UPCOMING EVENTS',
                  minFontSize: 12,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFD27E09),
                    letterSpacing: 1,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => print("View All clicked!"),
                child: Container(
                  padding: const EdgeInsets.only(bottom: 1),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFD27E09), width: 1.5),
                    ),
                  ),
                  child: const Text(
                    'vIEW ALL',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFD27E09),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(left: 16, bottom: 20),
          child: Row(
            // Use cast to ensure type safety during mapping
            children: events.map((event) => _buildEventCard(Map<String, dynamic>.from(event))).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[300], // Placeholder color while loading image
              image: DecorationImage(
                image: NetworkImage(event['imageUrl']),
                fit: BoxFit.cover,
                // Error handling for broken links
                onError: (exception, stackTrace) => const Icon(Icons.broken_image),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            (event['title'] as String).toUpperCase(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            event['date'],
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFFD27E09),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}