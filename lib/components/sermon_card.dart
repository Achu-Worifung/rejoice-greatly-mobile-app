import 'package:flutter/material.dart';

import '../theme/church_colors.dart';
import '../widgets/sermon_play_icon.dart';

class LatestSermonCard extends StatelessWidget {
  const LatestSermonCard({
    super.key,
    required this.data,
    this.onTapCard,
    this.onPlayTap,
  });

  final Map<String, dynamic> data;
  final VoidCallback? onTapCard;
  final Future<void> Function()? onPlayTap;

  @override
  Widget build(BuildContext context) {
    final imageUrl = data['imageUrl'] as String?;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: ChurchColors.cardDecoration(),
      child: Row(
        children: [
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTapCard,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
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
                                  errorBuilder:
                                      (BuildContext c, Object e, StackTrace? s) =>
                                          _placeholder(),
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
                              _formatDate(data['datePreached'] ?? data['date']),
                              style: const TextStyle(
                                fontSize: 13,
                                color: ChurchColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 48,
            height: 48,
            child: IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 48, height: 48),
              visualDensity: VisualDensity.compact,
              onPressed: onPlayTap == null
                  ? null
                  : () {
                      onPlayTap!();
                    },
              icon: ClipRect(
                child: Align(
                  alignment: Alignment.center,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: ChurchColors.button.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: SermonPlayIcon(sermon: data),
                  ),
                ),
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
