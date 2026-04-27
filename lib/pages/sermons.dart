import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/church_api.dart';
import '../theme/church_colors.dart';

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
      appBar: AppBar(
        toolbarHeight: 118,
        backgroundColor: ChurchColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Column(
          children: [
            const Text(
              'SERMONS',
              style: TextStyle(
                color: ChurchColors.accent,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.3,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Search title, speaker, or topic...',
                prefixIcon: const Icon(Icons.search, color: ChurchColors.muted, size: 22),
                filled: true,
                fillColor: ChurchColors.card,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: ChurchColors.divider.withValues(alpha: 0.5)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: ChurchColors.divider.withValues(alpha: 0.5)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: ChurchColors.button, width: 1.2),
                ),
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: ChurchColors.button,
          indicatorWeight: 3,
          labelColor: ChurchColors.accent,
          unselectedLabelColor: ChurchColors.muted,
          labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 0.6),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
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
                style: TextStyle(fontWeight: FontWeight.w800, color: ChurchColors.bodyText, fontSize: 16),
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
          return _SermonRow(
            data: list[i],
            isSaved: _savedIds.contains(_idOf(list[i])),
            onSave: () => _toggleSave(list[i]),
            onOpen: () => _openSermon(list[i]),
          );
        },
      ),
    );
  }

  Future<void> _openSermon(Map<String, dynamic> s) async {
    final id = s['id'];
    if (id == null) {
      _showSermonPanel(s, null);
      return;
    }
    try {
      final detail = await ChurchApi.getSermonById(id);
      if (!mounted) return;
      _showSermonPanel(s, detail);
      return;
    } catch (_) {
      // fall through to show base payload only
    }
    if (!mounted) return;
    _showSermonPanel(s, null);
  }

  void _showSermonPanel(Map<String, dynamic> base, Map<String, dynamic>? detail) {
    final merged = <String, dynamic>{...base, if (detail != null) ...detail};
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.55,
          minChildSize: 0.4,
          maxChildSize: 0.92,
          expand: false,
          builder: (context, scroll) {
            return Container(
              decoration: const BoxDecoration(
                color: ChurchColors.card,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: ListView(
                controller: scroll,
                padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: ChurchColors.divider,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: _sermonImage(merged['imageUrl'] as String?),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    merged['title'] as String? ?? 'Sermon',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: ChurchColors.bodyText,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    [
                      merged['speaker'],
                      if (merged['datePreached'] != null)
                        _formatDate(merged['datePreached'] as String?),
                      if ((merged['duration'] as String?)?.isNotEmpty == true) merged['duration'],
                    ].whereType<String>().where((e) => e.isNotEmpty).join(' · '),
                    style: const TextStyle(
                      color: ChurchColors.muted,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if ((merged['category'] as String?)?.isNotEmpty == true) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: ChurchColors.button.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        (merged['category'] as String).toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: ChurchColors.accent,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                  if ((merged['description'] as String?)?.isNotEmpty == true) ...[
                    const SizedBox(height: 16),
                    Text(
                      merged['description'] as String,
                      style: const TextStyle(
                        color: ChurchColors.bodyText,
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _formatDate(String? s) {
    if (s == null || s.length < 10) return s ?? '';
    try {
      return DateFormat.yMMMd().format(DateTime.parse(s.substring(0, 10)));
    } catch (_) {
      return s;
    }
  }

  Widget _sermonImage(String? url) {
    if (url == null || url.isEmpty) {
      return Container(
        color: ChurchColors.button.withValues(alpha: 0.1),
        child: const Center(
          child: Icon(Icons.mic, size: 48, color: ChurchColors.accent),
        ),
      );
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (BuildContext c, Object e, StackTrace? s) => Container(
        color: ChurchColors.button.withValues(alpha: 0.1),
        child: const Center(child: Icon(Icons.mic, size: 48, color: ChurchColors.accent)),
      ),
    );
  }
}

class _SermonRow extends StatelessWidget {
  const _SermonRow({
    required this.data,
    required this.isSaved,
    required this.onSave,
    required this.onOpen,
  });

  final Map<String, dynamic> data;
  final bool isSaved;
  final VoidCallback onSave;
  final VoidCallback onOpen;

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
                IconButton(
                  onPressed: onSave,
                  icon: Icon(
                    isSaved ? Icons.bookmark : Icons.bookmark_border,
                    color: ChurchColors.button,
                    size: 26,
                  ),
                ),
                const Icon(Icons.chevron_right, color: ChurchColors.muted),
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
