import 'package:flutter/material.dart';

import '../services/prayer_wall_api.dart';
import '../services/user_facing_error.dart';
import '../theme/church_colors.dart';
import '../theme/church_type.dart';
import '../widgets/church_app_bar.dart';
import '../widgets/church_buttons.dart';
import '../widgets/member_avatar.dart';
import '../widgets/prayer_card.dart';
import '../widgets/prayer_sheets.dart';

/// Opens a request's thread. Resolves to how the request ended up — so the
/// wall behind it can update — or null if nothing changed.
Future<PrayerActionResult?> openPrayerThread(
  BuildContext context,
  String prayerId, {
  PrayerRequestItem? initial,
}) {
  return Navigator.of(context, rootNavigator: true).push<PrayerActionResult>(
    MaterialPageRoute(builder: (_) => PrayerThreadPage(prayerId: prayerId, initial: initial)),
  );
}

/// One prayer request with its words of encouragement, and room to add one.
class PrayerThreadPage extends StatefulWidget {
  const PrayerThreadPage({super.key, required this.prayerId, this.initial});

  final String prayerId;

  /// What the wall already knew, shown while the thread loads.
  final PrayerRequestItem? initial;

  @override
  State<PrayerThreadPage> createState() => _PrayerThreadPageState();
}

class _PrayerThreadPageState extends State<PrayerThreadPage> {
  final _reply = TextEditingController();
  final _scroll = ScrollController();
  PrayerRequestItem? _prayer;
  List<PrayerReply>? _replies;
  bool _canReply = false;
  bool _sending = false;
  bool _changed = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _prayer = widget.initial;
    _reply.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _reply.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _apply(PrayerThread thread) {
    setState(() {
      _prayer = thread.prayer;
      _replies = thread.replies;
      _canReply = thread.canReply;
      _error = null;
    });
  }

  Future<void> _load() async {
    try {
      final thread = await PrayerWallApi.thread(widget.prayerId);
      if (mounted) _apply(thread);
    } catch (e) {
      if (mounted) setState(() => _error = userFacingError(e));
    }
  }

  void _close([PrayerActionResult? result]) {
    final prayer = _prayer;
    Navigator.of(context).pop(
      result ?? (_changed && prayer != null ? PrayerActionResult.updated(prayer) : null),
    );
  }

  Future<void> _setPrayed(bool prayed) async {
    final before = _prayer;
    if (before == null) return;
    setState(() => _prayer = before.withPrayed(prayed));
    try {
      final updated = await PrayerWallApi.setPrayed(before.id, prayed);
      if (!mounted) return;
      setState(() {
        _prayer = updated;
        _changed = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _prayer = before);
      showPrayerSnack(context, userFacingError(e));
    }
  }

  Future<void> _onAction(PrayerAction action) async {
    final prayer = _prayer;
    if (prayer == null) return;
    final result = await runPrayerAction(context, prayer, action);
    if (result == null || !mounted) return;
    if (result.removed) {
      _close(result);
    } else {
      setState(() {
        _prayer = result.updated;
        _changed = true;
      });
    }
  }

  Future<void> _send() async {
    final text = _reply.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final thread = await PrayerWallApi.reply(widget.prayerId, text);
      if (!mounted) return;
      _reply.clear();
      FocusScope.of(context).unfocus();
      _changed = true;
      _apply(thread);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.animateTo(
            _scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      if (mounted) showPrayerSnack(context, userFacingError(e));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _deleteReply(PrayerReply reply) async {
    final ok = await confirmPrayerDialog(
      context,
      title: 'Delete your reply?',
      message: 'It will be removed for everyone.',
      confirmLabel: 'Delete',
    );
    if (!ok) return;
    try {
      final thread = await PrayerWallApi.deleteReply(reply.id);
      _changed = true;
      if (mounted) _apply(thread);
    } catch (e) {
      if (mounted) showPrayerSnack(context, userFacingError(e));
    }
  }

  Future<void> _reportReply(PrayerReply reply) async {
    final reason = await showReportSheet(context, what: 'reply');
    if (reason == null) return;
    try {
      await PrayerWallApi.reportReply(reply.id, reason);
      if (!mounted) return;
      setState(() => _replies = _replies?.where((r) => r.id != reply.id).toList());
      showPrayerSnack(context, 'Thank you. We’ve hidden it for you and a pastor will take a look.');
    } catch (e) {
      if (mounted) showPrayerSnack(context, userFacingError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: Scaffold(
        backgroundColor: ChurchColors.background,
        appBar: ChurchAppBar.pageTitle(
          'Prayer request',
          leading: IconButton(
            tooltip: 'Back',
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: _close,
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                color: ChurchColors.button,
                onRefresh: _load,
                child: ListView(
                  controller: _scroll,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: _content(),
                ),
              ),
            ),
            if (_replies != null) _composer(),
          ],
        ),
      ),
    );
  }

  List<Widget> _content() {
    final prayer = _prayer;
    if (prayer == null && _error != null) {
      return [
        const SizedBox(height: 80),
        const Icon(Icons.cloud_off_outlined, size: 48, color: ChurchColors.muted),
        const SizedBox(height: 12),
        Text(_error!, textAlign: TextAlign.center, style: ChurchType.title),
        const SizedBox(height: 16),
        Center(
          child: SizedBox(width: 160, child: ChurchPrimaryButton(label: 'Try again', onPressed: _load)),
        ),
      ];
    }
    if (prayer == null) {
      return const [
        SizedBox(height: 120),
        Center(child: CircularProgressIndicator(color: ChurchColors.button)),
      ];
    }
    final replies = _replies;
    return [
      PrayerCard(prayer: prayer, expanded: true, onPrayed: _setPrayed, onAction: _onAction),
      const SizedBox(height: 24),
      const ChurchEyebrow('Words of encouragement'),
      const SizedBox(height: 4),
      const Divider(height: 1, color: ChurchColors.divider),
      if (replies == null && _error != null)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Text(_error!, textAlign: TextAlign.center, style: ChurchType.label),
        )
      else if (replies == null)
        const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator(color: ChurchColors.button)),
        )
      else if (replies.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Text(
            prayer.mine
                ? 'No replies yet. Your church family is praying with you.'
                : 'No replies yet. A few kind words can mean a lot.',
            textAlign: TextAlign.center,
            style: ChurchType.body.copyWith(color: ChurchColors.muted),
          ),
        )
      else
        for (final reply in replies)
          _ReplyTile(
            reply: reply,
            onDelete: () => _deleteReply(reply),
            onReport: () => _reportReply(reply),
          ),
    ];
  }

  Widget _composer() {
    final prayer = _prayer;
    final Widget child;
    if (!_canReply) {
      child = Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(
          prayer?.hidden == true
              ? 'Replies are paused while a pastor takes a look.'
              : 'You can pray along with this request.',
          textAlign: TextAlign.center,
          style: ChurchType.label,
        ),
      );
    } else {
      final canSend = _reply.text.trim().isNotEmpty && !_sending;
      child = Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _reply,
              minLines: 1,
              maxLines: 4,
              maxLength: PrayerWallApi.maxReplyLength,
              textCapitalization: TextCapitalization.sentences,
              style: ChurchType.body,
              decoration: InputDecoration(
                hintText: prayer?.mine == true ? 'Add an update…' : 'Write a word of encouragement…',
                counterText: '',
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            tooltip: 'Send reply',
            onPressed: canSend ? _send : null,
            style: IconButton.styleFrom(
              backgroundColor: ChurchColors.button,
              foregroundColor: ChurchColors.buttonText,
              disabledBackgroundColor: ChurchColors.divider,
              minimumSize: const Size(48, 48),
              shape: const RoundedRectangleBorder(borderRadius: ChurchRadius.mdAll),
            ),
            icon: _sending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: ChurchColors.buttonText),
                  )
                : const Icon(Icons.send_rounded),
          ),
        ],
      );
    }
    return Container(
      decoration: const BoxDecoration(
        color: ChurchColors.background,
        border: Border(top: ChurchRules.hairline),
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
      child: SafeArea(top: false, child: child),
    );
  }
}

class _ReplyTile extends StatelessWidget {
  const _ReplyTile({required this.reply, required this.onDelete, required this.onReport});

  final PrayerReply reply;
  final VoidCallback onDelete;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 14, bottom: 10),
      decoration: const BoxDecoration(border: Border(bottom: ChurchRules.hairline)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MemberAvatar(name: reply.authorName, size: 32, radius: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  children: [
                    Text(reply.mine ? 'You' : reply.authorName, style: ChurchType.bodyStrong.copyWith(fontSize: 14)),
                    if (reply.fromTeam) const ChurchEyebrow('Church team', color: ChurchColors.accent),
                    Text(prayerWhen(reply.createdAt), style: ChurchType.caption),
                  ],
                ),
                const SizedBox(height: 4),
                Text(reply.body, style: ChurchType.body),
              ],
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'More options',
            icon: const Icon(Icons.more_horiz_rounded, color: ChurchColors.muted, size: 20),
            onSelected: (v) => v == 'delete' ? onDelete() : onReport(),
            itemBuilder: (_) => [
              if (reply.mine)
                const PopupMenuItem(value: 'delete', child: Text('Delete reply'))
              else
                const PopupMenuItem(value: 'report', child: Text('Report')),
            ],
          ),
        ],
      ),
    );
  }
}
