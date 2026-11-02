import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../pages/event_detail_page.dart';
import '../theme/church_colors.dart';
import '../theme/church_type.dart';
import 'cached_image.dart';
import 'dashboard_label_title.dart';

/// "Sat, Nov 8 · 7:00 PM" from an event in `mapEventInstances` shape.
String featuredEventWhen(Map<String, dynamic> event) {
  final date = DateTime.tryParse('${event['date'] ?? ''}');
  final time = '${event['time'] ?? ''}'.trim();
  return [
    if (date != null) DateFormat('EEE, MMM d').format(date),
    if (time.isNotEmpty) time,
  ].join(' · ');
}

/// At the top of Home: the events the church is featuring, a few at most.
/// One shows at a time; with more than one they turn over slowly on their
/// own (never with reduced motion) and can be swiped. Tapping opens the event.
/// Shows nothing when nothing is featured.
class FeaturedEventsBanner extends StatefulWidget {
  const FeaturedEventsBanner({super.key, required this.events, this.turnEvery = const Duration(seconds: 7)});

  final List<Map<String, dynamic>> events;
  final Duration turnEvery;

  @override
  State<FeaturedEventsBanner> createState() => _FeaturedEventsBannerState();
}

class _FeaturedEventsBannerState extends State<FeaturedEventsBanner> {
  final _controller = PageController();
  Timer? _timer;
  int _page = 0;
  bool _touching = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _restartTimer();
  }

  @override
  void didUpdateWidget(FeaturedEventsBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.events.length != widget.events.length) {
      _page = 0;
      _restartTimer();
    }
  }

  void _restartTimer() {
    _timer?.cancel();
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (widget.events.length < 2 || still) return;
    _timer = Timer.periodic(widget.turnEvery, (_) {
      if (_touching || !_controller.hasClients) return;
      final next = (_page + 1) % widget.events.length;
      _controller.animateToPage(next, duration: const Duration(milliseconds: 700), curve: Curves.easeOutCubic);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final events = widget.events;
    if (events.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const DashboardLabelText(label: 'Coming up'),
          Listener(
            onPointerDown: (_) => _touching = true,
            onPointerUp: (_) => _touching = false,
            onPointerCancel: (_) => _touching = false,
            child: AspectRatio(
              aspectRatio: 16 / 11,
              child: PageView.builder(
                controller: _controller,
                itemCount: events.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) => _FeaturedCard(event: events[i]),
              ),
            ),
          ),
          if (events.length > 1)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < events.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _page ? 18 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: i == _page ? ChurchColors.accent : ChurchColors.divider,
                        borderRadius: ChurchRadius.smAll,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({required this.event});

  final Map<String, dynamic> event;

  @override
  Widget build(BuildContext context) {
    final title = '${event['title'] ?? 'Event'}';
    final when = featuredEventWhen(event);
    final poster = '${event['imageUrl'] ?? ''}'.trim();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Semantics(
        button: true,
        label: '$title, $when. Opens the event.',
        excludeSemantics: true,
        child: Material(
          color: ChurchColors.card,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: ChurchRadius.lgAll,
            side: BorderSide(color: ChurchColors.divider),
          ),
          child: InkWell(
            onTap: () => openEventDetailPage(context, event),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: poster.isEmpty ? _NoPoster(title: title) : _Poster(url: poster)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: ChurchType.title),
                            if (when.isNotEmpty) Text(when, style: ChurchType.dataSmall),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: ChurchColors.muted),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The whole poster, never cropped — posters carry their own words — over a
/// soft, blurred fill of itself.
class _Poster extends StatelessWidget {
  const _Poster({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final image = cachedImage(url, cacheWidth: 900);
    return Stack(
      fit: StackFit.expand,
      children: [
        ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: Image(image: image, fit: BoxFit.cover, errorBuilder: (_, _, _) => const SizedBox()),
        ),
        ColoredBox(color: Colors.black.withValues(alpha: 0.18)),
        Image(
          image: image,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => const SizedBox(),
        ),
      ],
    );
  }
}

class _NoPoster extends StatelessWidget {
  const _NoPoster({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: ChurchColors.button,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: ChurchType.display.copyWith(color: ChurchColors.buttonText),
          ),
        ),
      ),
    );
  }
}
