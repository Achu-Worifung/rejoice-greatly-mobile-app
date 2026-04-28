import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'event_detail_page.dart';
import '../services/church_api.dart';
import '../theme/church_colors.dart';
import '../widgets/church_app_bar.dart';
import '../widgets/church_tab_page_header.dart';

class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  String _searchQuery = '';
  String _selectedFilter = 'All';

  List<Map<String, dynamic>> _rawEvents = [];
  Map<String, List<Map<String, dynamic>>> _grouped = {};
  bool _loading = true;
  String? _error;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await ChurchApi.getUpcomingEvents();
      final out = ChurchApi.mapEventInstances(list);
      if (!mounted) return;
      setState(() {
        _rawEvents = out;
        _applyFilters();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
        _rawEvents = [];
        _grouped = {};
      });
    }
  }

  List<String> get _categories {
    final s = <String>{'All'};
    for (final e in _rawEvents) {
      s.add(e['category'] as String? ?? 'General');
    }
    return s.toList()..sort();
  }

  void _applyFilters() {
    var filtered = _rawEvents.where((event) {
      final title = (event['title'] as String? ?? '').toLowerCase();
      final loc = (event['location'] as String? ?? '').toLowerCase();
      final q = _searchQuery.toLowerCase();
      final matchesSearch = q.isEmpty || title.contains(q) || loc.contains(q);
      final cat = event['category'] as String? ?? 'General';
      final matchesFilter = _selectedFilter == 'All' || cat == _selectedFilter;
      return matchesSearch && matchesFilter;
    }).toList();

    filtered.sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));

    final temp = <String, List<Map<String, dynamic>>>{};
    for (final event in filtered) {
      final date = event['date'] as String;
      temp.putIfAbsent(date, () => []);
      temp[date]!.add(event);
    }
    _grouped = temp;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ChurchColors.background,
      appBar: ChurchAppBar.of(
       toolbarHeight: 138,
        centerTitle: true,
        title: _buildHeader(),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
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
              const Icon(Icons.cloud_off_outlined, size: 48, color: ChurchColors.muted),
              const SizedBox(height: 12),
              Text(
                "Couldn't load events",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: ChurchColors.bodyText,
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
                onPressed: _load,
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
    if (_grouped.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.event_available_outlined, size: 56, color: ChurchColors.muted.withValues(alpha: 0.6)),
              const SizedBox(height: 16),
              const Text(
                'No upcoming events match your filters',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: ChurchColors.bodyText,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Try another category or clear search.',
                textAlign: TextAlign.center,
                style: TextStyle(color: ChurchColors.muted, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      color: ChurchColors.button,
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 24),
        itemCount: _grouped.length,
        itemBuilder: (context, index) {
          final key = _grouped.keys.elementAt(index);
          return _buildDateSection(key, _grouped[key]!);
        },
      ),
    );
  }

  // ✨ PREMIUM HEADER
  Widget _buildHeader() {
    return Padding(
      padding: ChurchTabPageHeader.kTitlePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Gradient Title with Accents
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon(Icons.auto_awesome_rounded, size: 16, color: ChurchColors.accent.withValues(alpha: 0.6)),
              // const SizedBox(width: 10),
              Flexible(
                child: ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [ChurchColors.accent, ChurchColors.button, ChurchColors.accent],
                    stops: const [0.0, 0.5, 1.0],
                  ).createShader(bounds),
                  child: const Text(
                    'UPCOMING EVENTS',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 19,
                      letterSpacing: 1.6,
                      height: 1.1,
                      color: Colors.white, // Required for ShaderMask gradient
                    ),
                  ),
                ),
              ),
              // const SizedBox(width: 10),
              // Icon(Icons.auto_awesome_rounded, size: 16, color: ChurchColors.accent.withValues(alpha: 0.6)),
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
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                  _applyFilters();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search events...',
                hintStyle: TextStyle(
                  color: ChurchColors.muted.withValues(alpha: 0.6),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                prefixIcon: Icon(Icons.search_rounded, color: ChurchColors.muted, size: 20),
                filled: true,
                fillColor: Colors.transparent,
                contentPadding: const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: ChurchColors.divider.withValues(alpha: 0.25)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: ChurchColors.button.withValues(alpha: 0.7), width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Premium Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Row(
              children: _categories.map((cat) {
                final isSel = _selectedFilter == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    showCheckmark: false,
                    elevation: isSel ? 2.5 : 0,
                    shadowColor: ChurchColors.button.withValues(alpha: 0.2),
                    label: Text(
                      cat,
                      style: TextStyle(
                        fontWeight: isSel ? FontWeight.w700 : FontWeight.w600,
                        color: isSel ? ChurchColors.buttonText : ChurchColors.accent.withValues(alpha: 0.85),
                        fontSize: 12,
                        letterSpacing: 0.2,
                      ),
                    ),
                    selected: isSel,
                    onSelected: (val) {
                      setState(() {
                        if (val) {
                          _selectedFilter = cat;
                          _applyFilters();
                        }
                      });
                    },
                    backgroundColor: ChurchColors.card,
                    selectedColor: ChurchColors.button,
                    side: BorderSide(
                      color: isSel ? Colors.transparent : ChurchColors.divider.withValues(alpha: 0.35),
                      width: 1,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSection(String date, List<Map<String, dynamic>> events) {
    final dt = DateTime.parse(date);
    final header = DateFormat('EEEE, MMM d, y').format(dt).toUpperCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
          child: Text(
            header,
            style: const TextStyle(
              color: ChurchColors.accent,
              fontWeight: FontWeight.w800,
              fontSize: 11,
              letterSpacing: 0.6,
            ),
          ),
        ),
        ...events.map(_buildEventCard),
      ],
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Material(
        color: ChurchColors.card,
        elevation: 0,
        borderRadius: BorderRadius.circular(ChurchColors.cardRadius),
        child: InkWell(
          onTap: () => _openEvent(event),
          borderRadius: BorderRadius.circular(ChurchColors.cardRadius),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(ChurchColors.cardRadius),
              border: Border.all(color: ChurchColors.divider.withValues(alpha: 0.45)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 86,
                      height: 86,
                      child: Image.network(
                        event['imageUrl'] as String? ?? '',
                        fit: BoxFit.cover,
                        errorBuilder: (BuildContext c, Object e, StackTrace? s) => Container(
                          color: ChurchColors.button.withValues(alpha: 0.08),
                          child: const Icon(Icons.event, color: ChurchColors.accent, size: 32),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event['title'] as String? ?? '',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: ChurchColors.bodyText,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.schedule, size: 15, color: ChurchColors.muted),
                            const SizedBox(width: 4),
                            Text(
                              event['time'] as String? ?? 'Time TBA',
                              style: const TextStyle(
                                color: ChurchColors.muted,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        if ((event['location'] as String? ?? '').isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 2),
                                child: Icon(Icons.place_outlined, size: 15, color: ChurchColors.muted),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  event['location'] as String,
                                  style: const TextStyle(
                                    color: ChurchColors.muted,
                                    fontSize: 12,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: ChurchColors.button.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              (event['category'] as String? ?? 'General').toUpperCase(),
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: ChurchColors.accent,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: ChurchColors.muted),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openEvent(Map<String, dynamic> event) {
    openEventDetailPage(context, event);
  }
}