import 'package:auto_size_text/auto_size_text.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../components/sermon_card.dart';
import '../components/show_streak.dart';
import '../components/upcoming_events_section.dart';
import '../components/worship_with_us.dart';
import '../pages/sermon_detail_page.dart';
import '../services/church_api.dart';
import '../theme/church_colors.dart';
import 'church_app_bar.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({
    super.key,
    this.onViewAllSermons,
    this.onViewAllEvents,
  });

  final VoidCallback? onViewAllSermons;
  final VoidCallback? onViewAllEvents;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardEventsLoad {
  _DashboardEventsLoad({required this.items, this.error});
  final List<Map<String, dynamic>> items;
  final String? error;
}

class _DashboardPageState extends State<DashboardPage> {
  late Future<String> _greetingFuture;
  late Future<String?> _avatarUrlFuture;
  late Future<Map<String, dynamic>> _verseFuture;
  late Future<List<dynamic>> _sermonFuture;
  late Future<_DashboardEventsLoad> _eventsFuture;

  @override
  void initState() {
    super.initState();
    _greetingFuture = _getGreeting();
    _avatarUrlFuture = _loadProfilePhotoUrl();
    _verseFuture = ChurchApi.getCurrentVerse();
    _sermonFuture = _fetchSermonsNewestFirst();
    _eventsFuture = _fetchDashboardEventCards();
  }

  Future<String?> _loadProfilePhotoUrl() async {
    final p = await SharedPreferences.getInstance();
    final fromBackend = p.getString('imgURL');
    if (fromBackend != null && fromBackend.isNotEmpty) {
      return fromBackend;
    }
    return FirebaseAuth.instance.currentUser?.photoURL;
  }

  Future<void> _refresh() async {
    setState(() {
      _greetingFuture = _getGreeting();
      _avatarUrlFuture = _loadProfilePhotoUrl();
      _verseFuture = ChurchApi.getCurrentVerse();
      _sermonFuture = _fetchSermonsNewestFirst();
      _eventsFuture = _fetchDashboardEventCards();
    });
    await Future.wait([_verseFuture, _sermonFuture, _eventsFuture]);
  }

  Future<List<dynamic>> _fetchSermonsNewestFirst() async {
    final list = await ChurchApi.getSermons();
    final copy = List<dynamic>.from(list);
    copy.sort((a, b) {
      final da = (a as Map<String, dynamic>)['datePreached'] as String? ?? '';
      final db = (b as Map<String, dynamic>)['datePreached'] as String? ?? '';
      return db.compareTo(da);
    });
    return copy;
  }

  /// `top4` when available, else first 4 of `upcoming` (see [ChurchApi.getDashboardEventInstances]).
  Future<_DashboardEventsLoad> _fetchDashboardEventCards() async {
    try {
      final raw = await ChurchApi.getDashboardEventInstances();
      final list = ChurchApi.mapEventInstances(raw)
          .map(
            (e) => {
              'title': e['title'],
              'date': e['date'],
              'imageUrl': e['imageUrl'],
            },
          )
          .toList();
      return _DashboardEventsLoad(items: list, error: null);
    } catch (e) {
      return _DashboardEventsLoad(items: [], error: e.toString());
    }
  }

  String _formatReference(String book, int chapter, int start, int? end) {
    if (end == null || start == end) return '$book $chapter:$start';
    return '$book $chapter:$start-$end';
  }

  Future<String> _getGreeting() async {
    final pref = await SharedPreferences.getInstance();
    final name = pref.getString('name') ?? 'Friend';
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning, $name!';
    if (hour < 18) return 'Good afternoon, $name!';
    return 'Good evening, $name!';
  }

  void _showAttendanceStats() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const AttendanceStatsLoader(),
    );
  }

  Widget _avatarPlaceholder() {
    return Container(
      height: 40,
      width: 40,
      decoration: BoxDecoration(
        color: ChurchColors.card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Icon(Icons.person, color: ChurchColors.accent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ChurchColors.background,
      appBar: ChurchAppBar.of(
        centerTitle: false,
        titleSpacing: 12,
        title: GestureDetector(
          onTap: () {
            Navigator.pushNamed(context, '/profile');
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              FutureBuilder<String>(
                future: _greetingFuture,
                builder: (context, snapshot) {
                  final displayGreeting = snapshot.hasData ? snapshot.data! : 'Hello!';
                  return AutoSizeText(
                    displayGreeting,
                    maxLines: 1,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: ChurchColors.accent,
                    ),
                  );
                },
              ),
              Text(
                dotenv.env['CHURCH_SUBTITLE'] ?? 'Rejoice Greatly - PHX',
                style: const TextStyle(color: ChurchColors.muted, fontSize: 13),
              ),
            ],
          ),
        ),
        leading: IconButton(
          onPressed: () {
            Navigator.pushNamed(context, '/profile');
          },
          padding: const EdgeInsets.only(left: 8),
          icon: FutureBuilder<String?>(
            future: _avatarUrlFuture,
            builder: (context, snap) {
              final url = snap.data;
              if (url == null || url.isEmpty) {
                return _avatarPlaceholder();
              }
              return ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  url,
                  height: 40,
                  width: 40,
                  fit: BoxFit.cover,
                  errorBuilder: (BuildContext c, Object e, StackTrace? s) => _avatarPlaceholder(),
                ),
              );
            },
          ),
        ),
        actions: [
          IconButton(
            icon: SvgPicture.asset(
              'assets/icons/lightning.svg',
              colorFilter: const ColorFilter.mode(ChurchColors.accent, BlendMode.srcIn),
              width: 24,
            ),
            onPressed: _showAttendanceStats,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: ChurchColors.button,
          onRefresh: _refresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FutureBuilder<Map<String, dynamic>>(
                    future: _verseFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const LoadingPlaceholder();
                      }
                      if (snapshot.hasError) {
                        return _ErrorCard(
                          message: "We couldn't load this week's verse.",
                          onRetry: _refresh,
                        );
                      }
                      final v = snapshot.data!;
                      return VerseOfTheWeekCard(
                        data: {
                          'text': v['content'],
                          'version': v['version'],
                          'reference': _formatReference(
                            v['book'] as String,
                            (v['chapter'] as num).toInt(),
                            (v['startVerse'] as num).toInt(),
                            v['endVerse'] == null ? null : (v['endVerse'] as num).toInt(),
                          ),
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  const SectionHeader(title: 'LATEST SERMON'),
                  FutureBuilder<List<dynamic>>(
                    future: _sermonFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const LoadingPlaceholder();
                      }
                      if (snapshot.hasError ||
                          snapshot.data == null ||
                          snapshot.data!.isEmpty) {
                        return const _EmptyInlineCard(
                          message: 'No sermons available yet.',
                        );
                      }
                      final s = snapshot.data!.first as Map<String, dynamic>;
                      final map = Map<String, dynamic>.from(s);
                      return LatestSermonCard(
                        data: map,
                        onPlay: () => openSermonDetailPage(context, map),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildViewMoreButton(),
                  const SizedBox(height: 32),
                  FutureBuilder<_DashboardEventsLoad>(
                    future: _eventsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SectionHeader(title: 'UPCOMING EVENTS'),
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Center(
                                child: CircularProgressIndicator(color: ChurchColors.button),
                              ),
                            ),
                          ],
                        );
                      }
                      if (snapshot.hasError) {
                        return _DashboardEventsError(
                          message: snapshot.error.toString(),
                          onRetry: _refresh,
                          onViewAll: widget.onViewAllEvents,
                        );
                      }
                      final data = snapshot.data;
                      if (data == null) {
                        return const SizedBox.shrink();
                      }
                      if (data.error != null) {
                        return _DashboardEventsError(
                          message: data.error!,
                          onRetry: _refresh,
                          onViewAll: widget.onViewAllEvents,
                        );
                      }
                      if (data.items.isEmpty) {
                        return _DashboardEventsEmpty(onViewAll: widget.onViewAllEvents);
                      }
                      return UpcomingEventsSection(
                        events: data.items,
                        onViewAll: widget.onViewAllEvents,
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  WorshipWithUsCard(
                    data: {
                      'name': dotenv.env['CHURCH_NAME'] ?? 'REJOICE GREATLY PHX',
                      'address': dotenv.env['CHURCH_ADDRESS'] ?? '2323 E Magnolia St, Phoenix, AZ 85012',
                      'serviceTimes': dotenv.env['CHURCH_SERVICE_TIMES'] ?? '10:00 AM',
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildViewMoreButton() {
    return SizedBox(
      height: 44,
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: ChurchColors.button,
          foregroundColor: ChurchColors.buttonText,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: widget.onViewAllSermons,
        child: const Text(
          'VIEW MORE',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}

// --- DASHBOARD COMPONENTS ---

class VerseOfTheWeekCard extends StatelessWidget {
  const VerseOfTheWeekCard({super.key, required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: ChurchColors.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: ChurchColors.button.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'VERSE OF THE WEEK',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: ChurchColors.accent,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            data['text'] ?? '',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w500,
              color: ChurchColors.bodyText,
              height: 1.65,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  data['reference'] ?? '',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: ChurchColors.accent,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                data['version'] ?? '',
                style: const TextStyle(fontSize: 12, color: ChurchColors.muted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: ChurchColors.accent,
          letterSpacing: 1.3,
        ),
      ),
    );
  }
}

class LoadingPlaceholder extends StatelessWidget {
  const LoadingPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: CircularProgressIndicator(color: ChurchColors.button),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: ChurchColors.cardDecoration(),
      child: Column(
        children: [
          Text(message, textAlign: TextAlign.center, style: const TextStyle(color: ChurchColors.muted)),
          TextButton(
            onPressed: () => onRetry(),
            child: const Text('Try again', style: TextStyle(color: ChurchColors.accent, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _EmptyInlineCard extends StatelessWidget {
  const _EmptyInlineCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: ChurchColors.cardDecoration(),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(color: ChurchColors.muted, fontSize: 14),
        ),
      ),
    );
  }
}

class _DashboardEventsError extends StatelessWidget {
  const _DashboardEventsError({
    required this.message,
    required this.onRetry,
    this.onViewAll,
  });

  final String message;
  final Future<void> Function() onRetry;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'UPCOMING EVENTS'),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: ChurchColors.cardDecoration(),
          child: Column(
            children: [
              const Icon(Icons.wifi_tethering_error_outlined, color: ChurchColors.muted, size: 32),
              const SizedBox(height: 8),
              const Text(
                "Couldn't load events",
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: ChurchColors.bodyText,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: ChurchColors.muted),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () => onRetry(),
                    child: const Text('Retry', style: TextStyle(fontWeight: FontWeight.w700, color: ChurchColors.accent)),
                  ),
                  if (onViewAll != null) ...[
                    const Text('|', style: TextStyle(color: ChurchColors.muted)),
                    TextButton(
                      onPressed: onViewAll,
                      child: const Text('Open Events tab', style: TextStyle(fontWeight: FontWeight.w700, color: ChurchColors.accent)),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DashboardEventsEmpty extends StatelessWidget {
  const _DashboardEventsEmpty({this.onViewAll});

  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'UPCOMING EVENTS'),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: ChurchColors.cardDecoration(),
          child: Column(
            children: [
              const Icon(Icons.event_busy_outlined, size: 36, color: ChurchColors.muted),
              const SizedBox(height: 10),
              const Text(
                'No upcoming events right now',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: ChurchColors.bodyText,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'When your church adds events, they will show up here. Check the Events tab for the full schedule.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: ChurchColors.muted, height: 1.35),
              ),
              if (onViewAll != null) ...[
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: onViewAll,
                  style: FilledButton.styleFrom(
                    backgroundColor: ChurchColors.button,
                    foregroundColor: ChurchColors.buttonText,
                    minimumSize: const Size.fromHeight(40),
                  ),
                  child: const Text('VIEW ALL EVENTS'),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
