import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';

class UpcomingEventsSection extends StatelessWidget {
  final List<dynamic> events;

  const UpcomingEventsSection({super.key, required this.events});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween, // Pushes items to opposite ends
            children: [
              const Expanded(
                // Allows the title to take available space and scale
                child: AutoSizeText(
                  'UPCOMING EVENTS',
                  minFontSize: 12,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
                    'View All',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFD27E09),
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Horizontal Scroll Implementation
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(left: 16, bottom: 20),
          child: Row(
            children: events.map((event) => _buildEventCard(event)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    return Container(
      width: 160, // Fixed width for horizontal items
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Slightly Vertical Image
          Container(
            height: 200, // Makes it taller than wide
            decoration: BoxDecoration(
              borderRadius: BorderRadius.zero, // Keep square look
              image: DecorationImage(
                image: NetworkImage(event['imageUrl']),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // 2. Event Title
          Text(
            event['title'].toUpperCase(),
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

          // 3. Event Date
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
