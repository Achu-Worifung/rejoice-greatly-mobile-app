import 'dart:convert';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../components/sermon_card.dart';
import '../components/show_streak.dart';
import '../components/upcoming_events_section.dart';
import '../components/worship_with_us.dart';
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
  late Future<Map<String, dynamic>> _verseFuture;
  late Future<List<dynamic>> _sermonFuture;
  late Future<List<dynamic>> _eventsFuture;

  @override
  void initState() {
    super.initState();
    _greetingFuture = _getGreeting();
    _verseFuture = _fetchCurrentVerse();
    _sermonFuture = _fetchSermons();
    _eventsFuture = _fetchUpcomingEvents();
  }

  String get _ipAddress => dotenv.env['IP_ADDRESS'] ?? 'localhost';

  String get _apiBase => 'http://$_ipAddress:8080';

  Future<void> _refresh() async {
    setState(() {
      _greetingFuture = _getGreeting();
      _verseFuture = _fetchCurrentVerse();
      _sermonFuture = _fetchSermons();
      _eventsFuture = _fetchUpcomingEvents();
    });
    await Future.wait([_verseFuture, _sermonFuture, _eventsFuture]);
  }

  Future<Map<String, dynamic>> _fetchCurrentVerse() async {
    final response = await http.get(Uri.parse('$_apiBase/weekly-verse/current'));
    if (response.statusCode == 200) return json.decode(response.body) as Map<String, dynamic>;
    throw Exception('Failed to load verse');
  }

  Future<List<dynamic>> _fetchUpcomingEvents() async {
    final response = await http.get(Uri.parse('$_apiBase/events/upcoming'));
    if (response.statusCode == 200) {
      return json.decode(response.body) as List<dynamic>;
    }
    throw Exception('Failed to load events');
  }

  Future<List<dynamic>> _fetchSermons() async {
    final response = await http.get(Uri.parse('$_apiBase/sermons'));
    if (response.statusCode == 200) {
      return json.decode(response.body) as List<dynamic>;
    }
    throw Exception('Failed to load sermons');
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
      builder: (context) => AttendanceSheet(data: const {}),
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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcST4JjHURtaso7i__VnumOCn8QoUHn-WXURHQ&s',
                height: 40,
                width: 40,
                fit: BoxFit.cover,
                errorBuilder: (BuildContext c, Object e, StackTrace? s) => Container(
                  height: 40,
                  width: 40,
                  color: ChurchColors.card,
                  child: const Icon(Icons.person, color: ChurchColors.accent),
                ),
              ),
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
              const Text(
                'Rejoice Greatly - PHX',
                style: TextStyle(color: ChurchColors.muted, fontSize: 13),
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
                      final s = snapshot.data!.last as Map<String, dynamic>;
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
                  FutureBuilder<List<dynamic>>(
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
                      final formattedEvents = data.map((e) {
                        final m = e as Map<String, dynamic>;
                        final template = m['template'] as Map<String, dynamic>? ?? {};
                        return {
                          'title': template['title'] ?? 'Church Event',
                          'date': m['date'] ?? '',
                          'imageUrl': template['posterUrl'] ?? 'https://via.placeholder.com/150',
                        };
                      }).toList();
                      return UpcomingEventsSection(
                        events: formattedEvents,
                        onViewAll: widget.onViewAllEvents,
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  WorshipWithUsCard(
                    data: {
                      'name': 'REJOICE GREATLY PHX',
                      'address': '2323 E Magnolia St, Phoenix, AZ 85012',
                      'serviceTimes': '10:00 AM',
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
