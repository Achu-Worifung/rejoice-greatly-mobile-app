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
import '../services/church_audio_player.dart';
import '../services/church_api.dart';
import '../theme/church_colors.dart';
import 'church_app_bar.dart';
import '../widgets/dashboard_label_title.dart';


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
  String? _avatarUrl;
  late Future<Map<String, dynamic>> _verseFuture;
  late Future<List<dynamic>> _sermonFuture;
  late Future<_DashboardEventsLoad> _eventsFuture;

  @override
  void initState() {
    super.initState();
    _greetingFuture = _getGreeting();
    _verseFuture = ChurchApi.getCurrentVerse();
    _sermonFuture = _fetchSermonsNewestFirst();
    _eventsFuture = _fetchDashboardEventCards();
    _syncUserAccountAndAvatar();
  }

  Future<void> _syncUserAccountAndAvatar() async {
    final cached = await ChurchApi.getCachedAccountJson();
    if (cached != null && mounted) {
      final cachedUrl = await ChurchApi.resolveProfileImageUrl(account: cached);
      setState(() {
        _avatarUrl = cachedUrl;
        _greetingFuture = _getGreeting();
      });
    }

    final result = await ChurchApi.loadMemberProfile();
    if (!mounted) return;
    final url = await ChurchApi.resolveProfileImageUrl(account: result.profile);
    setState(() {
      _avatarUrl = url;
      _greetingFuture = _getGreeting();
    });
  }

  Future<void> _refresh() async {
    setState(() {
      _verseFuture = ChurchApi.getCurrentVerse();
      _sermonFuture = _fetchSermonsNewestFirst();
      _eventsFuture = _fetchDashboardEventCards();
    });
    await Future.wait([
      _verseFuture,
      _sermonFuture,
      _eventsFuture,
      _syncUserAccountAndAvatar(),
    ]);
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
      final list = ChurchApi.mapEventInstances(raw);
      return _DashboardEventsLoad(items: list, error: null);
    } catch (e) {
      return _DashboardEventsLoad(items: [], error: e.toString());
    }
  }

  String _formatReference(String book, int chapter, int start, int? end) {
    if (end == null || start == end) return '$book $chapter:$start';
    return '$book $chapter:$start-$end';
  }

  Future<void> _toggleDashboardSermonAudio(BuildContext context, Map<String, dynamic> sermon) async {
    final ok = await ChurchAudioPlayer.instance.toggle(sermon);
    if (!context.mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Audio is not available for this sermon.')),
      );
    }
  }

  String? _buildMapPreviewUrl(String address) {
    final custom = dotenv.env['CHURCH_MAP_PREVIEW_URL']?.trim();
    if (custom != null && custom.isNotEmpty) return custom;

    final apiKey = dotenv.env['GOOGLE_MAPS_STATIC_API_KEY']?.trim();
    if (apiKey == null || apiKey.isEmpty) return null;

    final encodedAddress = Uri.encodeComponent(address);
    return 'https://maps.googleapis.com/maps/api/staticmap'
        '?center=$encodedAddress'
        '&zoom=15'
        '&size=1200x600'
        '&maptype=roadmap'
        '&markers=color:0x2E5EA7|$encodedAddress'
        '&key=$apiKey';
  }

  Future<String> _getGreeting() async {
    final account = await ChurchApi.getCachedAccountJson();
    final name = account?['name'] as String? ??
        (await SharedPreferences.getInstance()).getString('name') ??
        'Friend';
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

  Widget _buildAvatar() {
    final url = _avatarUrl;
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
          icon: _buildAvatar(),
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
                  const SizedBox(height: 16),
                  const DashboardLabelText(label: 'VERSE OF THE WEEK'),
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
                      final chapter = v['chapter'];
                      final startVerse = v['startVerse'];
                      final endVerse = v['endVerse'];
                      return VerseOfTheWeekCard(
                        data: {
                          'text': v['content']?.toString() ?? '',
                          'version': v['version']?.toString() ?? '',
                          'reference': _formatReference(
                            v['book']?.toString() ?? '',
                            chapter is num ? chapter.toInt() : 0,
                            startVerse is num ? startVerse.toInt() : 0,
                            endVerse is num ? endVerse.toInt() : null,
                          ),
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  const DashboardLabelText(label: 'LATEST SERMON'),
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
                      final list = snapshot.data!;
                      final s0 = list.first as Map<String, dynamic>;
                      final map0 = Map<String, dynamic>.from(s0);

                      return LatestSermonCard(
                        data: map0,
                        onTapCard: () => openSermonDetailPage(context, map0),
                        onPlayTap: () => _toggleDashboardSermonAudio(context, map0),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildDashboardCtaButton(
                    label: 'VIEW MORE',
                    onPressed: widget.onViewAllSermons,
                  ),
                  const SizedBox(height: 32),
                  FutureBuilder<_DashboardEventsLoad>(
                    future: _eventsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DashboardLabelText(label: 'UPCOMING EVENTS'),
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
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          UpcomingEventsSection(events: data.items),
                          if (widget.onViewAllEvents != null) ...[
                            const SizedBox(height: 12),
                            _buildDashboardCtaButton(
                              label: 'VIEW ALL EVENTS',
                              onPressed: widget.onViewAllEvents,
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  WorshipWithUsCard(
                    data: {
                      'name': dotenv.env['CHURCH_NAME'] ?? 'REJOICE GREATLY PHX',
                      'address':
                          dotenv.env['CHURCH_ADDRESS'] ?? '2323 E Magnolia St, Phoenix, AZ 85012',
                      'serviceTimes': dotenv.env['CHURCH_SERVICE_TIMES'] ?? '10:00 AM',
                      'mapPreviewUrl': _buildMapPreviewUrl(
                        dotenv.env['CHURCH_ADDRESS'] ?? '2323 E Magnolia St, Phoenix, AZ 85012',
                      ),
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

  Widget _buildDashboardCtaButton({
    required String label,
    VoidCallback? onPressed,
  }) {
    return SizedBox(
      height: 44,
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: ChurchColors.button,
          foregroundColor: ChurchColors.buttonText,
          elevation: 0,
          padding: EdgeInsets.zero,
          minimumSize: const Size(double.infinity, 44),
          fixedSize: const Size(double.infinity, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          label,
          style: const TextStyle(
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
        const DashboardLabelText(label: 'UPCOMING EVENTS'),
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
        const DashboardLabelText(label: 'UPCOMING EVENTS'),
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
                SizedBox(
                  height: 44,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onViewAll,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ChurchColors.button,
                      foregroundColor: ChurchColors.buttonText,
                      elevation: 0,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(double.infinity, 44),
                      fixedSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'VIEW ALL EVENTS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

