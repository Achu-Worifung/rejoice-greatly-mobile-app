import 'package:flutter/material.dart';

import '../theme/church_colors.dart';

class LatestSermonCard extends StatelessWidget {
  const LatestSermonCard({super.key, required this.data, this.onPlay});

  final Map<String, dynamic> data;
  final VoidCallback? onPlay;

  @override
  Widget build(BuildContext context) {
    final imageUrl = data['imageUrl'] as String?;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: ChurchColors.cardDecoration(),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 72,
              height: 72,
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (BuildContext c, Object e, StackTrace? s) => _placeholder(),
                    )
                  : _placeholder(),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  data['title'] as String? ?? 'Sermon',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: ChurchColors.bodyText,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _formatDate(data['date']),
                  style: const TextStyle(fontSize: 13, color: ChurchColors.muted),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onPlay,
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: ChurchColors.button.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: ChurchColors.button,
                size: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(Object? d) {
    if (d == null) return '';
    final s = d.toString();
    if (s.length < 10) return s;
    try {
      final parsed = DateTime.parse(s.substring(0, 10));
      return '${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return s;
    }
  }

  Widget _placeholder() {
    return Container(
      color: ChurchColors.button.withValues(alpha: 0.08),
      child: const Icon(Icons.mic, color: ChurchColors.accent, size: 32),
    );
  }
}
