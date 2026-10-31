import 'package:flutter/material.dart';

import '../services/prayer_wall_api.dart';
import '../services/user_facing_error.dart';
import '../theme/church_colors.dart';
import '../theme/church_type.dart';
import '../widgets/church_buttons.dart';
import '../widgets/prayer_card.dart';
import '../widgets/prayer_sheets.dart';
import '../widgets/skeletons.dart';
import 'cafe.dart';
import 'prayer_thread_page.dart';

/// The Community tab: the prayer wall, with the café a tap away.
class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key, this.isActive = true});

  /// The tab sits in an IndexedStack; nothing loads until it's first shown.
  final bool isActive;

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  static const _pageSize = 20;

  final _scroll = ScrollController();
  PrayerFilter _filter = PrayerFilter.wall;
  List<PrayerRequestItem>? _items;
  String? _error;
  int _page = 0;
  bool _hasMore = false;
  bool _loadingMore = false;
  bool _started = false;

  /// False while a pastor has paused this member's posting.
  bool _canPost = true;

  /// Bumped on every fresh load, so a slow response for an old filter can't
  /// overwrite the list the member is now looking at.
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_maybeLoadMore);
    if (widget.isActive) _start();
  }

  @override
  void didUpdateWidget(CommunityPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !_started) _start();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _start() {
    _started = true;
    _load();
  }

  Future<void> _load() async {
    final generation = ++_generation;
    try {
      final page = await PrayerWallApi.list(filter: _filter, size: _pageSize);
      if (!mounted || generation != _generation) return;
      setState(() {
        _items = page.items;
        _hasMore = page.hasMore;
        _canPost = page.canPost;
        _page = 0;
        _error = null;
      });
    } catch (e) {
      if (!mounted || generation != _generation) return;
      setState(() => _error = userFacingError(e));
    }
  }

  void _maybeLoadMore() {
    if (!_hasMore || _loadingMore || !_scroll.hasClients) return;
    if (_scroll.position.extentAfter < 600) _loadMore();
  }

  Future<void> _loadMore() async {
    final generation = _generation;
    setState(() => _loadingMore = true);
    try {
      final page = await PrayerWallApi.list(filter: _filter, page: _page + 1, size: _pageSize);
      if (!mounted || generation != _generation) return;
      final seen = {for (final p in _items ?? const <PrayerRequestItem>[]) p.id};
      setState(() {
        _items = [...?_items, ...page.items.where((p) => !seen.contains(p.id))];
        _hasMore = page.hasMore;
        _page += 1;
      });
    } catch (e) {
      if (mounted) showPrayerSnack(context, userFacingError(e));
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  void _setFilter(PrayerFilter filter) {
    if (filter == _filter) return;
    setState(() {
      _filter = filter;
      _items = null;
      _error = null;
      _hasMore = false;
    });
    _load();
  }

  void _replace(PrayerRequestItem updated) {
    final items = _items;
    if (items == null) return;
    setState(() {
      _items = [for (final p in items) p.id == updated.id ? updated : p];
    });
  }

  void _remove(String id) {
    final items = _items;
    if (items == null) return;
    setState(() => _items = items.where((p) => p.id != id).toList());
  }

  Future<void> _setPrayed(PrayerRequestItem prayer, bool prayed) async {
    _replace(prayer.withPrayed(prayed));
    try {
      _replace(await PrayerWallApi.setPrayed(prayer.id, prayed));
    } catch (e) {
      _replace(prayer);
      if (mounted) showPrayerSnack(context, userFacingError(e));
    }
  }

  Future<void> _onAction(PrayerRequestItem prayer, PrayerAction action) async {
    _apply(prayer, await runPrayerAction(context, prayer, action));
  }

  Future<void> _open(PrayerRequestItem prayer) async {
    _apply(prayer, await openPrayerThread(context, prayer.id, initial: prayer));
  }

  void _apply(PrayerRequestItem prayer, PrayerActionResult? result) {
    if (result == null) return;
    final updated = result.updated;
    // Taken off the wall: it only belongs under My requests now.
    if (result.removed || (updated!.archived && _filter != PrayerFilter.mine)) {
      _remove(prayer.id);
    } else {
      _replace(updated);
    }
  }

  Future<void> _share() async {
    final created = await showPrayerComposer(context);
    if (created == null || !mounted) return;
    showPrayerSnack(
      context,
      created.visibility == PrayerVisibility.pastors
          ? 'Shared with the pastors. They’ll be praying with you.'
          : 'Shared. Your church family is praying with you.',
    );
    final showsHere = _filter == PrayerFilter.mine ||
        (_filter == PrayerFilter.wall && created.visibility == PrayerVisibility.church);
    if (showsHere) {
      setState(() => _items = [created, ...?_items]);
    }
  }

  void _openCafe() {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const Cafe()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ChurchColors.background,
      floatingActionButton: _canPost
          ? FloatingActionButton.extended(
              onPressed: _share,
              backgroundColor: ChurchColors.button,
              foregroundColor: ChurchColors.buttonText,
              elevation: 1,
              shape: const RoundedRectangleBorder(borderRadius: ChurchRadius.mdAll),
              icon: const Icon(Icons.edit_outlined),
              label: Text('Share a request', style: ChurchType.button),
            )
          : null,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: ChurchColors.button,
          onRefresh: _load,
          child: ListView(
            controller: _scroll,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 96),
            children: [
              ChurchPageHero(
                eyebrow: 'Community',
                title: 'Prayer wall',
                description: 'Share what’s on your heart, and pray for one another.',
                trailing: _CafeButton(onPressed: _openCafe),
              ),
              _FilterBar(selected: _filter, onSelected: _setFilter),
              if (!_canPost) const _PostingPaused(),
              ..._content(),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _content() {
    final items = _items;
    if (items == null && _error == null) {
      return const [
        SkeletonList(count: 4, thumbSize: 36, padding: EdgeInsets.fromLTRB(16, 4, 16, 16)),
      ];
    }
    if (items == null) {
      return [
        _Message(
          icon: Icons.cloud_off_outlined,
          title: 'Couldn’t load the prayer wall',
          body: _error!,
          action: SizedBox(
            width: 160,
            child: ChurchPrimaryButton(label: 'Try again', onPressed: _load),
          ),
        ),
      ];
    }
    if (items.isEmpty) {
      final (title, body) = switch (_filter) {
        PrayerFilter.wall => (
            'The wall is quiet right now',
            'Be the first to share. Your church family is ready to pray with you.',
          ),
        PrayerFilter.answered => (
            'No answered prayers yet',
            'When a request is answered, it will be celebrated here.',
          ),
        PrayerFilter.mine => (
            'You haven’t shared a request yet',
            'Whatever you’re carrying, you don’t have to carry it alone.',
          ),
      };
      return [_Message(icon: Icons.volunteer_activism_outlined, title: title, body: body)];
    }
    return [
      for (final prayer in items)
        Padding(
          key: ValueKey(prayer.id),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: PrayerCard(
            prayer: prayer,
            onPrayed: (prayed) => _setPrayed(prayer, prayed),
            onAction: (action) => _onAction(prayer, action),
            onOpen: () => _open(prayer),
          ),
        ),
      if (_loadingMore)
        Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator(color: ChurchColors.button)),
        ),
    ];
  }
}

class _CafeButton extends StatelessWidget {
  const _CafeButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: ChurchColors.accent,
        side: ChurchRules.hairline,
        shape: const RoundedRectangleBorder(borderRadius: ChurchRadius.mdAll),
        minimumSize: const Size(48, 44),
      ),
      icon: const Icon(Icons.local_cafe_outlined, size: 18),
      label: Text('Café', style: ChurchType.label.copyWith(color: ChurchColors.accent, fontWeight: FontWeight.w600)),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.selected, required this.onSelected});

  final PrayerFilter selected;
  final ValueChanged<PrayerFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Row(
        children: [
          for (final filter in PrayerFilter.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                showCheckmark: false,
                elevation: 0,
                pressElevation: 0,
                label: Text(
                  filter.label,
                  style: ChurchType.label.copyWith(
                    fontWeight: FontWeight.w600,
                    color: filter == selected ? ChurchColors.buttonText : ChurchColors.bodyText,
                  ),
                ),
                selected: filter == selected,
                onSelected: (_) => onSelected(filter),
                backgroundColor: ChurchColors.background,
                selectedColor: ChurchColors.button,
                side: BorderSide(color: filter == selected ? ChurchColors.button : ChurchColors.divider),
                shape: const RoundedRectangleBorder(borderRadius: ChurchRadius.smAll),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
            ),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.title, required this.body, this.action});

  final IconData icon;
  final String title;
  final String body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 48, 32, 32),
      child: Column(
        children: [
          Icon(icon, size: 48, color: ChurchColors.muted.withValues(alpha: 0.6)),
          const SizedBox(height: 16),
          Text(title, textAlign: TextAlign.center, style: ChurchType.title),
          const SizedBox(height: 6),
          Text(body, textAlign: TextAlign.center, style: ChurchType.body.copyWith(color: ChurchColors.muted)),
          if (action != null) ...[const SizedBox(height: 16), action!],
        ],
      ),
    );
  }
}

/// Shown in place of "Share a request" while a pastor has paused this
/// member's posting. Quiet, and says what they can still do.
class _PostingPaused extends StatelessWidget {
  const _PostingPaused();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.pause_circle_outline_rounded, size: 18, color: ChurchColors.muted),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'You can’t post on the prayer wall right now, but you can still pray for others. '
              'If you think that’s a mistake, please talk to one of the pastors.',
              style: ChurchType.label,
            ),
          ),
        ],
      ),
    );
  }
}
