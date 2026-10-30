import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/church_api.dart';
import '../services/user_facing_error.dart';
import '../theme/church_colors.dart';
import '../theme/church_type.dart';
import '../widgets/church_app_bar.dart';
import '../widgets/church_buttons.dart';

/// One push the member was sent, kept for 90 days or until they clear it.
class InboxNotification {
  InboxNotification.fromJson(Map<String, dynamic> json)
      : id = '${json['id']}',
        title = json['title'] as String? ?? '',
        body = json['body'] as String? ?? '',
        type = json['type'] as String? ?? 'notification',
        createdAt =
            DateTime.tryParse('${json['createdAt']}')?.toLocal() ?? DateTime.now(),
        read = json['read'] as bool? ?? false;

  final String id;
  final String title;
  final String body;
  final String type;
  final DateTime createdAt;
  final bool read;
}

/// The member's notification inbox: read, swipe one away, or clear them all.
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  /// Unread count behind the bell on the home screen.
  static final ValueNotifier<int> unread = ValueNotifier(0);

  /// Refreshes [unread]; failures leave the last count in place.
  static Future<void> refreshUnread() async {
    try {
      final map = await ChurchApi.memberNotifications('');
      unread.value = (map['unreadCount'] as num?)?.toInt() ?? 0;
    } catch (e) {
      debugPrint('NotificationsPage: unread refresh failed: $e');
    }
  }

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<InboxNotification>? _items;
  String? _error;

  @override
  void initState() {
    super.initState();
    _run('');
  }

  /// Calls `/member/notifications[/action]`; every call returns the fresh inbox.
  Future<void> _run(String action, [List<String>? ids]) async {
    try {
      final map = await ChurchApi.memberNotifications(action, ids);
      if (!mounted) return;
      final raw = map['notifications'];
      setState(() {
        _error = null;
        _items = raw is List
            ? raw
                .whereType<Map>()
                .map((e) => InboxNotification.fromJson(Map<String, dynamic>.from(e)))
                .toList()
            : [];
      });
      NotificationsPage.unread.value = (map['unreadCount'] as num?)?.toInt() ?? 0;
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = userFacingError(e));
    }
  }

  Future<void> _clearAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          decoration: ChurchColors.cardDecoration(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Clear all notifications?',
                  textAlign: TextAlign.center, style: ChurchType.headline),
              const SizedBox(height: 12),
              const Text(
                'They will be removed from this inbox for good.',
                textAlign: TextAlign.center,
                style: TextStyle(color: ChurchColors.muted, height: 1.45, fontSize: 14),
              ),
              const SizedBox(height: 24),
              ChurchDangerButton(
                label: 'Clear all',
                onPressed: () => Navigator.pop(ctx, true),
              ),
              const SizedBox(height: 10),
              ChurchSecondaryButton(
                label: 'Keep them',
                onPressed: () => Navigator.pop(ctx, false),
              ),
            ],
          ),
        ),
      ),
    );
    if (confirm == true) await _run('clear');
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    final hasUnread = items?.any((n) => !n.read) ?? false;
    return Scaffold(
      backgroundColor: ChurchColors.background,
      appBar: ChurchAppBar.pageTitle(
        'Notifications',
        actions: [
          if (items != null && items.isNotEmpty)
            PopupMenuButton<String>(
              tooltip: 'More',
              icon: const Icon(Icons.more_horiz_rounded),
              onSelected: (v) => v == 'read' ? _run('read') : _clearAll(),
              itemBuilder: (_) => [
                if (hasUnread)
                  const PopupMenuItem(value: 'read', child: Text('Mark all as read')),
                const PopupMenuItem(value: 'clear', child: Text('Clear all')),
              ],
            ),
        ],
      ),
      body: RefreshIndicator(
        color: ChurchColors.button,
        onRefresh: () => _run(''),
        child: _body(items),
      ),
    );
  }

  Widget _body(List<InboxNotification>? items) {
    if (items == null && _error == null) {
      return const Center(child: CircularProgressIndicator(color: ChurchColors.button));
    }
    if (items == null || items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(32, 120, 32, 32),
        children: [
          Icon(Icons.notifications_none_rounded,
              size: 48, color: ChurchColors.muted.withValues(alpha: 0.6)),
          const SizedBox(height: 16),
          Text(
            _error ?? 'You’re all caught up.',
            textAlign: TextAlign.center,
            style: ChurchType.title,
          ),
          const SizedBox(height: 6),
          Text(
            _error == null
                ? 'Reminders, check-ins and prayer replies will stay here for 90 days.'
                : 'Pull down to try again.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: ChurchColors.muted, height: 1.45, fontSize: 14),
          ),
        ],
      );
    }
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final n = items[i];
        return Dismissible(
          key: ValueKey(n.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: ChurchColors.muted.withValues(alpha: 0.12),
              borderRadius: ChurchColors.borderRadiusCard,
            ),
            child: const Icon(Icons.delete_outline_rounded, color: ChurchColors.muted),
          ),
          onDismissed: (_) {
            setState(() => items.removeAt(i));
            _run('clear', [n.id]);
          },
          child: _NotificationTile(
            item: n,
            onTap: n.read ? null : () => _run('read', [n.id]),
          ),
        );
      },
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item, this.onTap});

  final InboxNotification item;
  final VoidCallback? onTap;

  static String _when(DateTime t) {
    final age = DateTime.now().difference(t);
    if (age.inMinutes < 1) return 'Just now';
    if (age.inHours < 1) return '${age.inMinutes}m ago';
    if (age.inDays < 1) return '${age.inHours}h ago';
    if (age.inDays < 7) return DateFormat('EEE h:mm a').format(t);
    return DateFormat('MMM d').format(t);
  }

  @override
  Widget build(BuildContext context) {
    final icon = switch (item.type) {
      'attendance' => Icons.check_circle_outline_rounded,
      'prayer' => Icons.volunteer_activism_outlined,
      'event' => Icons.event_outlined,
      'birthday' => Icons.cake_outlined,
      _ => Icons.notifications_none_rounded,
    };
    return Container(
      decoration: ChurchColors.cardDecoration(
        color: item.read ? ChurchColors.background : ChurchColors.card,
        shadow: const [],
      ).copyWith(border: Border.fromBorderSide(ChurchRules.hairline)),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: ChurchColors.borderRadiusCard,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: ChurchColors.accent, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: item.read ? FontWeight.w500 : FontWeight.w700,
                                color: ChurchColors.bodyText,
                              ),
                            ),
                          ),
                          if (!item.read)
                            Semantics(
                              label: 'Unread',
                              child: Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(left: 8),
                                decoration: const BoxDecoration(
                                  color: ChurchColors.accent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (item.body.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          item.body,
                          style: const TextStyle(
                              fontSize: 13.5, color: ChurchColors.bodyText, height: 1.4),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Text(_when(item.createdAt),
                          style: const TextStyle(fontSize: 12, color: ChurchColors.muted)),
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
