import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'sermon_detail_page.dart';
import '../services/church_api.dart';
import '../services/church_audio_player.dart';
import '../services/sermon_downloads.dart';
import '../services/sermon_progress.dart';
import '../theme/church_colors.dart';
import '../theme/church_type.dart';
import '../widgets/church_app_bar.dart';
import '../widgets/church_tab_page_header.dart';
import '../widgets/church_buttons.dart';
import '../widgets/skeletons.dart';
import '../widgets/sermon_play_icon.dart';
import '../services/user_facing_error.dart';
import '../widgets/cached_image.dart';

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
    _tabController = TabController(length: 4, vsync: this);
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
      debugPrint('SermonsPage: load failed: $e');
      if (!mounted) return;
      setState(() {
        _error = userFacingError(e);
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
        toolbarHeight: ChurchTabPageHeader.heightOf(context),
        centerTitle: true,
        title: ChurchTabPageHeader(
          title: 'Sermons',
          controller: _searchController,
          hintText: 'Search sermons...',
          onChanged: (v) => setState(() => _search = v),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorWeight: 2,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Series'),
            Tab(text: 'Saved'),
            Tab(text: 'Downloads'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSermonList(onlySaved: false),
          _buildSeries(),
          _buildSermonList(onlySaved: true),
          _buildDownloads(),
        ],
      ),
    );
  }

  Widget _buildSermonList({required bool onlySaved}) {
    if (_loading) {
      return const SkeletonList(count: 6, thumbSize: 76);
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off_outlined, size: 48, color: ChurchColors.muted),
              const SizedBox(height: 12),
              Text(
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
                style: TextStyle(color: ChurchColors.muted, fontSize: 13),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: 160,
                child: ChurchPrimaryButton(
                  label: 'Try again',
                  onPressed: _fetchSermons,
                ),
              ),
              if (SermonDownloads.all.value.isNotEmpty) ...[
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () => _tabController.animateTo(3),
                  icon: const Icon(Icons.download_done_rounded),
                  label: const Text('Your downloads still play'),
                ),
              ],
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
            style: TextStyle(
              color: ChurchColors.muted,
              fontSize: 15,
              height: 1.4,
            ),
          ),
        ),
      );
    }
    final showContinue = !onlySaved && _search.isEmpty;
    return RefreshIndicator(
      color: ChurchColors.button,
      onRefresh: _fetchSermons,
      child: ValueListenableBuilder<Map<String, SermonListen>>(
        valueListenable: SermonProgress.all,
        builder: (context, _, _) {
          final resume = showContinue ? SermonProgress.inProgress : const <SermonListen>[];
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              if (resume.isNotEmpty) ...[
                _ContinueListening(items: resume, onOpen: _openSermon),
                const SizedBox(height: 16),
              ],
              for (final row in list) ...[
                _row(row),
                const SizedBox(height: 12),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _row(Map<String, dynamic> row) => _SermonRow(
        data: row,
        isSaved: _savedIds.contains(_idOf(row)),
        onSave: () => _toggleSave(row),
        onOpen: () => _openSermon(row),
        onPlayTap: () => _toggleSermonAudio(row),
      );

  /// Sermons grouped by series, newest series first.
  Widget _buildSeries() {
    if (_loading) return const SkeletonList(count: 4, thumbSize: 76);
    final groups = <String, List<Map<String, dynamic>>>{};
    for (final s in _sermons) {
      final name = (s['series'] as String?)?.trim();
      if (name != null && name.isNotEmpty) groups.putIfAbsent(name, () => []).add(s);
    }
    if (groups.isEmpty) {
      return _quiet('When sermons are preached as a series, they’ll be gathered here.');
    }
    // _sermons is newest first, so each group's first sermon is its latest.
    final names = groups.keys.toList()
      ..sort((a, b) => '${groups[b]!.first['datePreached']}'.compareTo('${groups[a]!.first['datePreached']}'));
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      itemCount: names.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final name = names[i];
        final parts = groups[name]!.reversed.toList(); // oldest first: the order they were preached
        return _SeriesCard(
          name: name,
          parts: parts,
          onOpen: () => Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => _SeriesPage(name: name, parts: parts, rowBuilder: _row),
          )),
        );
      },
    );
  }

  /// What's on this phone, from the copy kept with each download, so it
  /// works with no connection at all.
  Widget _buildDownloads() {
    return ValueListenableBuilder<Map<String, SermonDownload>>(
      valueListenable: SermonDownloads.all,
      builder: (context, downloads, _) {
        if (downloads.isEmpty) {
          return _quiet('Download a sermon from its page to listen without a connection.');
        }
        final rows = downloads.values.map((d) => d.sermon).toList()
          ..sort((a, b) => '${b['datePreached']}'.compareTo('${a['datePreached']}'));
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          itemCount: rows.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, i) => _row(rows[i]),
        );
      },
    );
  }

  Widget _quiet(String text) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(color: ChurchColors.muted, fontSize: 15, height: 1.4),
          ),
        ),
      );

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
      borderRadius: ChurchRadius.lgAll,
      child: InkWell(
        onTap: onOpen,
        borderRadius: ChurchRadius.lgAll,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: ChurchRadius.lgAll,
            border: Border.all(color: ChurchColors.divider),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: ChurchRadius.mdAll,
                  child: SizedBox(
                    width: 76,
                    height: 76,
                    child: imageUrl != null && imageUrl.isNotEmpty
                        ? Image(
                            image: cachedImage(
                              imageUrl,
                              cacheWidth: (76 * MediaQuery.devicePixelRatioOf(context) * 2).round(),
                            ),
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
                        style: ChurchType.title,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        [
                          if ((data['speaker'] as String?)?.isNotEmpty == true) data['speaker'],
                          dateLine,
                        ].whereType<String>().join(' · '),
                        style: ChurchType.dataSmall,
                      ),
                      _RowListenState(sermon: data),
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
                Icon(Icons.chevron_right, size: 22, color: ChurchColors.muted),
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
      child: Icon(Icons.mic, color: ChurchColors.accent, size: 28),
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

/// How far they got (a thin bar) and whether it's downloaded, under a row's title.
class _RowListenState extends StatelessWidget {
  const _RowListenState({required this.sermon});

  final Map<String, dynamic> sermon;

  @override
  Widget build(BuildContext context) {
    final key = ChurchAudioPlayer.sermonKey(sermon);
    if (key == null) return const SizedBox.shrink();
    return ListenableBuilder(
      listenable: Listenable.merge([SermonProgress.all, SermonDownloads.all]),
      builder: (context, _) {
        final listen = SermonProgress.all.value[key];
        final downloaded = SermonDownloads.all.value.containsKey(key);
        if (listen == null && !downloaded) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            children: [
              if (listen != null)
                Expanded(
                  child: ClipRRect(
                    borderRadius: ChurchRadius.smAll,
                    child: LinearProgressIndicator(
                      value: listen.fraction,
                      minHeight: 3,
                      color: ChurchColors.accent,
                      backgroundColor: ChurchColors.divider,
                    ),
                  ),
                )
              else
                const Spacer(),
              if (downloaded) ...[
                const SizedBox(width: 8),
                Icon(Icons.download_done_rounded, size: 16, color: ChurchColors.muted, semanticLabel: 'Downloaded'),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// "Continue listening": sermons they started, most recent first.
class _ContinueListening extends StatelessWidget {
  const _ContinueListening({required this.items, required this.onOpen});

  final List<SermonListen> items;
  final ValueChanged<Map<String, dynamic>> onOpen;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ChurchEyebrow('Continue listening'),
        const SizedBox(height: 10),
        SizedBox(
          height: 112,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final listen = items[i];
              final s = listen.sermon;
              return SizedBox(
                width: 220,
                child: Material(
                  color: ChurchColors.card,
                  shape: RoundedRectangleBorder(
                    borderRadius: ChurchRadius.lgAll,
                    side: BorderSide(color: ChurchColors.divider),
                  ),
                  child: InkWell(
                    borderRadius: ChurchRadius.lgAll,
                    onTap: () => onOpen(s),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s['title'] as String? ?? 'Sermon',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: ChurchType.bodyStrong.copyWith(fontSize: 15),
                          ),
                          const Spacer(),
                          Text('${listen.remaining.inMinutes} min left', style: ChurchType.dataSmall),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: ChurchRadius.smAll,
                            child: LinearProgressIndicator(
                              value: listen.fraction,
                              minHeight: 3,
                              color: ChurchColors.accent,
                              backgroundColor: ChurchColors.divider,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// One series on the Series tab: its name, how many parts, and when.
class _SeriesCard extends StatelessWidget {
  const _SeriesCard({required this.name, required this.parts, required this.onOpen});

  final String name;

  /// Oldest first.
  final List<Map<String, dynamic>> parts;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final cover = parts.reversed
        .map((p) => p['imageUrl'] as String?)
        .firstWhere((u) => u != null && u.isNotEmpty, orElse: () => null);
    return Material(
      color: ChurchColors.card,
      shape: RoundedRectangleBorder(borderRadius: ChurchRadius.lgAll, side: BorderSide(color: ChurchColors.divider)),
      child: InkWell(
        borderRadius: ChurchRadius.lgAll,
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: ChurchRadius.mdAll,
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: cover != null
                      ? Image(image: cachedImage(cover, cacheWidth: 256), fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _seriesPlaceholder())
                      : _seriesPlaceholder(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, maxLines: 2, overflow: TextOverflow.ellipsis, style: ChurchType.title),
                    const SizedBox(height: 4),
                    Text('${parts.length} sermon${parts.length == 1 ? '' : 's'}', style: ChurchType.dataSmall),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, size: 22, color: ChurchColors.muted),
            ],
          ),
        ),
      ),
    );
  }

  Widget _seriesPlaceholder() => Container(
        color: ChurchColors.button.withValues(alpha: 0.1),
        child: Icon(Icons.collections_bookmark_outlined, color: ChurchColors.accent),
      );
}

/// A series' sermons in the order they were preached.
class _SeriesPage extends StatelessWidget {
  const _SeriesPage({required this.name, required this.parts, required this.rowBuilder});

  final String name;
  final List<Map<String, dynamic>> parts;
  final Widget Function(Map<String, dynamic>) rowBuilder;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ChurchColors.background,
      appBar: AppBar(title: Text(name, style: ChurchType.headline)),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        itemCount: parts.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, i) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 6, left: 2),
              child: ChurchEyebrow('Part ${i + 1}'),
            ),
            rowBuilder(parts[i]),
          ],
        ),
      ),
    );
  }
}
