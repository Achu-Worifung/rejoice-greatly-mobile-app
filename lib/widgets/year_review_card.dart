import 'package:flutter/material.dart';

import '../pages/year_review_page.dart';
import '../services/year_review.dart';
import '../theme/church_type.dart';

/// On Home in December and January, until they've looked: their year is
/// ready. Shows nothing otherwise, or when there's no year to tell.
class YearReviewCard extends StatefulWidget {
  const YearReviewCard({super.key, this.now, this.load});

  /// Stand-ins for the clock and the API, for tests.
  final DateTime? now;
  final Future<YearReview> Function()? load;

  @override
  State<YearReviewCard> createState() => _YearReviewCardState();
}

class _YearReviewCardState extends State<YearReviewCard> {
  YearReview? _review;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!YearReviews.inSeason(widget.now ?? DateTime.now())) return;
    try {
      final review = await (widget.load ?? () => YearReviews.load())();
      if (!review.available || !review.hasContent || await YearReviews.seen(review.year)) return;
      if (mounted) setState(() => _review = review);
    } catch (_) {
      // A nicety: not being able to load it shouldn't get in the way of Home.
    }
  }

  @override
  Widget build(BuildContext context) {
    final review = _review;
    if (review == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Material(
        color: const Color(0xFF1C140C),
        clipBehavior: Clip.antiAlias,
        // A gold rule so it stands apart on a dark Home too.
        shape: RoundedRectangleBorder(
          borderRadius: ChurchRadius.lgAll,
          side: BorderSide(color: const Color(0xFFE9B949).withValues(alpha: 0.4)),
        ),
        child: InkWell(
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => YearReviewPage(review: review)),
            );
            if (mounted) setState(() => _review = null);
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 12, 16),
            child: Row(
              children: [
                Text('${review.year}',
                    style: ChurchType.display.copyWith(color: const Color(0xFFE9B949), fontSize: 30)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Your year at Rejoice Greatly',
                          style: ChurchType.title.copyWith(color: const Color(0xFFFFF7EB))),
                      Text('A few things worth remembering.',
                          style: ChurchType.label.copyWith(color: const Color(0xFFE8DCC8))),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Color(0xFFE8DCC8)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
