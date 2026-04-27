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
import '../services/church_api.dart';
import '../theme/church_colors.dart';

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

class _DashboardPageState extends State<DashboardPage> {
  late Future<String> _greetingFuture;
  late Future<String?> _avatarUrlFuture;
  late Future<Map<String, dynamic>> _verseFuture;
  late Future<List<dynamic>> _sermonFuture;
  late Future<List<Map<String, dynamic>>> _eventsFuture;

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

  /// Dashboard rail uses `GET /events/top4` (featured instances).
  Future<List<Map<String, dynamic>>> _fetchDashboardEventCards() async {
    final raw = await ChurchApi.getTop4Events();
    return ChurchApi.mapEventInstances(raw)
        .map(
          (e) => {
            'title': e['title'],
            'date': e['date'],
            'imageUrl': e['imageUrl'],
          },
        )
        .toList();
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
      appBar: AppBar(
        backgroundColor: ChurchColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Center(
            child: FutureBuilder<String?>(
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
        ),
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
                      fontWeight: FontWeight.bold,
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
        actions: [
          IconButton(
            icon: SvgPicture.asset(
              'assets/icons/lightning.svg',
              colorFilter: const ColorFilter.mode(ChurchColors.accent, BlendMode.srcIn),
              width: 24,
            ),
            onPressed: _showAttendanceStats,
          ),
          const SizedBox(width: 8),
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
                      return LatestSermonCard(
                        data: {
                          'title': s['title'] ?? 'Sermon',
                          'date': s['datePreached'] ?? '',
                          'imageUrl': s['imageUrl'],
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildViewMoreButton(),
                  const SizedBox(height: 32),
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: _eventsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: CircularProgressIndicator(color: ChurchColors.button),
                          ),
                        );
                      }
                      if (snapshot.hasError) {
                        return const SizedBox.shrink();
                      }
                      final data = snapshot.data;
                      if (data == null || data.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return UpcomingEventsSection(
                        events: data,
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
