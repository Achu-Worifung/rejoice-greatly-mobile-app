import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'sermon_detail_page.dart';
import '../services/church_api.dart';
import '../services/church_audio_player.dart';
import '../theme/church_colors.dart';
import '../widgets/church_app_bar.dart';
import '../widgets/church_tab_page_header.dart';
import '../widgets/sermon_play_icon.dart';

class SermonsPage extends StatefulWidget {
  const SermonsPage({super.key});

  @override
  State<SermonsPage> createState() => _SermonsPageState();
}

class _SermonsPageState extends State<SermonsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _sermons = [];
  String _search = '';
  bool _loading = true;
  String? _error;
  Set<String> _savedIds = {};
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSaved();
    _fetchSermons();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _toggleSermonAudio(Map<String, dynamic> m) async {
    final ok = await ChurchAudioPlayer.instance.toggle(m);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Audio is not available for this sermon.')),
      );
    }
  }

  Future<void> _loadSaved() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString('saved_sermon_ids');
    if (raw != null) {
      try {
        final list = json.decode(raw) as List<dynamic>;
        setState(() {
          _savedIds = list.map((e) => e.toString()).toSet();
        });
      } catch (_) {}
    }
  }

  Future<void> _persistSaved() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('saved_sermon_ids', json.encode(_savedIds.toList()));
  }

  String _idOf(Map<String, dynamic> s) {
    final id = s['id'];
    if (id == null) return s['title']?.toString() ?? '';
    return id.toString();
  }

  Future<void> _fetchSermons() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await ChurchApi.getSermons();
      final items = <Map<String, dynamic>>[];
      for (final e in list) {
        if (e is Map) {
          items.add(Map<String, dynamic>.from(e));
        }
      }
      items.sort((a, b) {
        final da = a['datePreached'] as String? ?? '';
        final db = b['datePreached'] as String? ?? '';
        return db.compareTo(da);
      });
      if (!mounted) return;
      setState(() {
        _sermons = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _sermons = [];
        _loading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _search.toLowerCase();
    return _sermons.where((s) {
      final t = (s['title'] as String? ?? '').toLowerCase();
      final sp = (s['speaker'] as String? ?? '').toLowerCase();
      final c = (s['category'] as String? ?? '').toLowerCase();
      return q.isEmpty || t.contains(q) || sp.contains(q) || c.contains(q);
    }).toList();
  }

  List<Map<String, dynamic>> get _savedSermons {
    return _filtered.where((s) => _savedIds.contains(_idOf(s))).toList();
  }

  void _toggleSave(Map<String, dynamic> s) {
    final id = _idOf(s);
    setState(() {
      if (_savedIds.contains(id)) {
        _savedIds.remove(id);
      } else {
        _savedIds.add(id);
      }
    });
    _persistSaved();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ChurchColors.background,
      appBar: ChurchAppBar.of(
        automaticallyImplyLeading: false,
        toolbarHeight: 138,
        centerTitle: true,
        title: _buildHeader(),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: ChurchColors.button,
          indicatorWeight: 3,
          labelColor: ChurchColors.accent,
          unselectedLabelColor: ChurchColors.muted,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 12,
            letterSpacing: 0.6,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          tabs: const [
            Tab(text: 'ALL'),
            Tab(text: 'SAVED'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSermonList(onlySaved: false),
          _buildSermonList(onlySaved: true),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    // Pin to the top of the toolbar so kTitlePadding controls the top gap
    // (AppBar otherwise vertically centers the title, which differs per page).
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: ChurchTabPageHeader.kTitlePadding,
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Gradient Title with Sparkle Accents
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon(
              //   Icons.auto_awesome_rounded,
              //   size: 16,
              //   color: ChurchColors.accent.withValues(alpha: 0.6),
              // ),
              // const SizedBox(width: 10),
              Flexible(
                child: ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [
                      ChurchColors.accent,
                      ChurchColors.button,
                      ChurchColors.accent,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ).createShader(bounds),
                  child: const Text.rich(
                    TextSpan(
                      text: 'SERMONS',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 19,
                        letterSpacing: 1.6,
                        height: 1.1,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              // const SizedBox(width: 10),
              // Icon(
              //   Icons.auto_awesome_rounded,
              //   size: 16,
              //   color: ChurchColors.accent.withValues(alpha: 0.6),
              // ),
            ],
          ),
          const SizedBox(height: 6),
          // Soft Gradient Divider
          Container(
            height: 2,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(1),
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  ChurchColors.accent.withValues(alpha: 0.5),
                  ChurchColors.button,
                  ChurchColors.accent.withValues(alpha: 0.5),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Elevated Search Field
          Container(
            decoration: BoxDecoration(
              color: ChurchColors.card,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Search sermons...',
                hintStyle: TextStyle(
                  color: ChurchColors.muted.withValues(alpha: 0.6),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: ChurchColors.muted,
                  size: 20,
                ),
                filled: true,
                fillColor: Colors.transparent,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 11,
                  horizontal: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: ChurchColors.divider.withValues(alpha: 0.25),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: ChurchColors.button.withValues(alpha: 0.7),
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
          ],
        ),
      ),
    );
  }

  Widget _buildSermonList({required bool onlySaved}) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: ChurchColors.button));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_outlined, size: 48, color: ChurchColors.muted),
              const SizedBox(height: 12),
              const Text(
                "Couldn't load sermons",
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: ChurchColors.bodyText,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: ChurchColors.muted, fontSize: 13),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _fetchSermons,
                style: FilledButton.styleFrom(
                  backgroundColor: ChurchColors.button,
                  foregroundColor: ChurchColors.buttonText,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    final list = onlySaved ? _savedSermons : _filtered;
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            onlySaved
                ? 'Save sermons with the bookmark to see them here.'
                : 'No sermons match your search.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: ChurchColors.muted,
              fontSize: 15,
              height: 1.4,
            ),
          ),
        ),
      );
    }
    return RefreshIndicator(
      color: ChurchColors.button,
      onRefresh: _fetchSermons,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        itemCount: list.length,
        separatorBuilder: (context, _) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final row = list[i];
          return _SermonRow(
            data: row,
            isSaved: _savedIds.contains(_idOf(row)),
            onSave: () => _toggleSave(row),
            onOpen: () => _openSermon(row),
            onPlayTap: () => _toggleSermonAudio(row),
          );
        },
      ),
    );
  }

  void _openSermon(Map<String, dynamic> s) {
    openSermonDetailPage(context, Map<String, dynamic>.from(s));
  }
}

class _SermonRow extends StatelessWidget {
  const _SermonRow({
    required this.data,
    required this.isSaved,
    required this.onSave,
    required this.onOpen,
    required this.onPlayTap,
  });

  final Map<String, dynamic> data;
  final bool isSaved;
  final VoidCallback onSave;
  final VoidCallback onOpen;
  final VoidCallback onPlayTap;

  @override
  Widget build(BuildContext context) {
    final imageUrl = data['imageUrl'] as String?;
    final dateLine = _dateLine(data['datePreached']);

    return Material(
      color: ChurchColors.card,
      borderRadius: BorderRadius.circular(ChurchColors.cardRadius),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(ChurchColors.cardRadius),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(ChurchColors.cardRadius),
            border: Border.all(color: ChurchColors.divider.withValues(alpha: 0.45)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 76,
                    height: 76,
                    child: imageUrl != null && imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (BuildContext c, Object e, StackTrace? s) => _ph(),
                          )
                        : _ph(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['title'] as String? ?? 'Sermon',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: ChurchColors.bodyText,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        [
                          if ((data['speaker'] as String?)?.isNotEmpty == true) data['speaker'],
                          dateLine,
                        ].whereType<String>().join(' · '),
                        style: const TextStyle(
                          fontSize: 13,
                          color: ChurchColors.muted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 44,
                  height: 44,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(width: 44, height: 44),
                    visualDensity: VisualDensity.compact,
                    onPressed: onPlayTap,
                    icon: ClipRect(
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: ChurchColors.button.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: SermonPlayIcon(
                          sermon: data,
                          iconSize: 24,
                          spinnerSize: 24,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 40,
                  height: 44,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(width: 40, height: 44),
                    visualDensity: VisualDensity.compact,
                    onPressed: onSave,
                    icon: Icon(
                      isSaved ? Icons.bookmark : Icons.bookmark_border,
                      color: ChurchColors.button,
                      size: 24,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, size: 22, color: ChurchColors.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _ph() {
    return Container(
      color: ChurchColors.button.withValues(alpha: 0.1),
      child: const Icon(Icons.mic, color: ChurchColors.accent, size: 28),
    );
  }

  String? _dateLine(Object? d) {
    if (d == null) return null;
    final s = d.toString();
    if (s.length < 10) return s;
    try {
      return DateFormat.MMMd().add_y().format(DateTime.parse(s.substring(0, 10)));
    } catch (_) {
      return s;
    }
  }
}