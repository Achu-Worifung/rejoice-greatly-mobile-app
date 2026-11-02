import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../services/user_facing_error.dart';
import '../services/year_review.dart';
import '../theme/church_type.dart';
import '../widgets/milestone_widgets.dart';

// The review keeps its own colours, light or dark mode alike: the logo's gold
// on the church's night, cocoa and cream.
const _night = Color(0xFF1C140C);
const _cocoa = Color(0xFF633A02);
const _gold = Color(0xFFE9B949);
const _cream = Color(0xFFFFF7EB);
const _ink = Color(0xFF2A1D10);

/// One page of the review: its colours and what it says.
class YearSlide {
  const YearSlide({
    required this.background,
    required this.foreground,
    required this.accent,
    this.eyebrow,
    this.count,
    required this.title,
    this.lines = const [],
    this.milestones = false,
    this.closing = false,
  });

  final Color background;
  final Color foreground;
  final Color accent;
  final String? eyebrow;

  /// The big number, when the page is about one.
  final int? count;
  final String title;
  final List<String> lines;
  final bool milestones;
  final bool closing;
}

/// The pages for [r], leaving out anything they didn't do — the review only
/// tells back what happened, never what didn't.
List<YearSlide> yearSlides(YearReview r) {
  String plural(int n, String one, String many) => n == 1 ? one : many;
  final prayedOthers = r.prayedForOthers;
  return [
    YearSlide(
      background: _night,
      foreground: _cream,
      accent: _gold,
      eyebrow: '${r.year}',
      title: 'Your year at Rejoice Greatly',
      lines: const ['A few things worth remembering. Tap to go on.'],
    ),
    if (r.sundays > 0)
      YearSlide(
        background: _cocoa,
        foreground: _cream,
        accent: _gold,
        count: r.sundays,
        title: plural(r.sundays, 'Sunday together', 'Sundays together'),
        lines: [
          if (r.firstYear) 'Your first year with us. Welcome home.',
          if (r.fullestMonth != null) 'You were with us most in ${r.fullestMonth}.',
        ],
      ),
    if (r.bacentaMeetings > 0)
      YearSlide(
        background: _gold,
        foreground: _ink,
        accent: _cocoa,
        count: r.bacentaMeetings,
        title: plural(r.bacentaMeetings, 'bacenta meeting', 'bacenta meetings'),
        lines: const ['Church is closer in a small circle.'],
      ),
    if (r.sermonsHeard > 0)
      YearSlide(
        background: _night,
        foreground: _cream,
        accent: _gold,
        count: r.sermonsHeard,
        title: plural(r.sermonsHeard, 'sermon heard to the end', 'sermons heard to the end'),
        lines: [if (r.favouriteSeries != null) 'Most of all from “${r.favouriteSeries}”.'],
      ),
    if (prayedOthers > 0 || r.prayersForThem > 0)
      YearSlide(
        background: _cocoa,
        foreground: _cream,
        accent: _gold,
        count: prayedOthers > 0 ? prayedOthers : r.prayersForThem,
        title: prayedOthers > 0
            ? plural(prayedOthers, 'time you prayed for someone', 'times you prayed for someone')
            : plural(r.prayersForThem, 'time your church prayed for you', 'times your church prayed for you'),
        lines: [
          if (prayedOthers > 0 && r.prayersForThem > 0)
            'And your church prayed for you ${r.prayersForThem} ${plural(r.prayersForThem, 'time', 'times')}.',
          if (r.requestsAnswered > 0)
            '${r.requestsAnswered} of your requests ${plural(r.requestsAnswered, 'was', 'were')} answered.',
        ],
      ),
    if (r.milestones.isNotEmpty)
      const YearSlide(
        background: _gold,
        foreground: _ink,
        accent: _cocoa,
        title: 'Milestones this year',
        milestones: true,
      ),
    const YearSlide(
      background: _night,
      foreground: _cream,
      accent: _gold,
      title: 'Thank you for a beautiful year.',
      lines: ['“You crown the year with your goodness.” Psalm 65:11'],
      closing: true,
    ),
  ];
}

/// "Your year at Rejoice Greatly": a few pages, one thing each, swiped or
/// tapped through like a story. Loads the review itself unless given one.
class YearReviewPage extends StatefulWidget {
  const YearReviewPage({super.key, this.review, this.load});

  final YearReview? review;

  /// Stand-in for the API, for tests.
  final Future<YearReview> Function()? load;

  @override
  State<YearReviewPage> createState() => _YearReviewPageState();
}

class _YearReviewPageState extends State<YearReviewPage> {
  final _pages = PageController();
  YearReview? _review;
  String? _error;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _review = widget.review;
    if (_review == null) {
      _load();
    } else {
      YearReviews.markSeen(_review!.year);
    }
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final review = await (widget.load ?? () => YearReviews.load())();
      YearReviews.markSeen(review.year);
      if (mounted) setState(() => _review = review);
    } catch (e) {
      if (mounted) setState(() => _error = userFacingError(e));
    }
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _go(int delta, int count) {
    final next = _index + delta;
    if (next < 0) return;
    if (next >= count) {
      Navigator.of(context).maybePop();
      return;
    }
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (still) {
      _pages.jumpToPage(next);
    } else {
      _pages.animateToPage(next, duration: const Duration(milliseconds: 420), curve: Curves.easeOutCubic);
    }
  }

  @override
  Widget build(BuildContext context) {
    final review = _review;
    if (review == null) {
      return Scaffold(
        backgroundColor: _night,
        appBar: AppBar(backgroundColor: _night, foregroundColor: _cream),
        body: Center(
          child: _error == null
              ? const CircularProgressIndicator(color: _gold)
              : Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(_error!, textAlign: TextAlign.center, style: ChurchType.body.copyWith(color: _cream)),
                    const SizedBox(height: 12),
                    TextButton(onPressed: _load, child: const Text('Try again', style: TextStyle(color: _gold))),
                  ]),
                ),
        ),
      );
    }
    final slides = yearSlides(review);
    final slide = slides[_index.clamp(0, slides.length - 1)];
    return Scaffold(
      backgroundColor: slide.background,
      body: Stack(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            // A tap on the left third goes back; anywhere else goes on.
            onTapUp: (d) => _go(d.localPosition.dx < MediaQuery.sizeOf(context).width / 3 ? -1 : 1, slides.length),
            child: PageView.builder(
              controller: _pages,
              itemCount: slides.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) => _SlideView(slide: slides[i], review: review),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 8, 0),
              child: Row(
                children: [
                  for (var i = 0; i < slides.length; i++)
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 3,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: slide.foreground.withValues(alpha: i <= _index ? 0.9 : 0.25),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  IconButton(
                    tooltip: 'Close',
                    icon: Icon(Icons.close, color: slide.foreground),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide, required this.review});

  final YearSlide slide;
  final YearReview review;

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final fg = slide.foreground;
    return ColoredBox(
      color: slide.background,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 72, 28, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (slide.eyebrow != null)
                Text(slide.eyebrow!, style: ChurchType.display.copyWith(color: slide.accent, fontSize: 64, height: 1)),
              if (slide.count != null)
                _CountUp(value: slide.count!, still: still, style: ChurchType.display.copyWith(color: slide.accent, fontSize: 104, height: 1)),
              const SizedBox(height: 12),
              Text(slide.title, style: ChurchType.display.copyWith(color: fg, fontSize: 34, height: 1.15)),
              for (final line in slide.lines) ...[
                const SizedBox(height: 14),
                Text(line, style: ChurchType.body.copyWith(color: fg.withValues(alpha: 0.88), fontSize: 18, height: 1.5)),
              ],
              if (slide.milestones) ...[
                const SizedBox(height: 20),
                for (final m in review.milestones.take(6))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Row(
                      children: [
                        MilestoneSeal(milestoneKey: m.key, size: 46, color: slide.accent),
                        const SizedBox(width: 14),
                        Expanded(child: Text(m.title, style: ChurchType.title.copyWith(color: fg))),
                      ],
                    ),
                  ),
              ],
              if (slide.closing) ...[
                const SizedBox(height: 36),
                SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: _gold,
                      foregroundColor: _ink,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                    ),
                    onPressed: () => Share.share(review.shareText, subject: 'My ${review.year} at Rejoice Greatly'),
                    icon: const Icon(Icons.ios_share),
                    label: const Text('Share my year'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The big number, counting up as the page arrives (not with reduced motion).
class _CountUp extends StatelessWidget {
  const _CountUp({required this.value, required this.style, required this.still});

  final int value;
  final TextStyle style;
  final bool still;

  @override
  Widget build(BuildContext context) {
    if (still) return Text('$value', style: style);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: const Duration(milliseconds: 1300),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Text('${v.round()}', style: style),
    );
  }
}
