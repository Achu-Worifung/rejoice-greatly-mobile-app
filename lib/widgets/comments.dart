import 'package:flutter/material.dart';

import '../services/comments_api.dart';
import '../services/user_facing_error.dart';
import '../theme/church_colors.dart';
import '../theme/church_type.dart';
import 'dashboard_label_title.dart';
import 'member_avatar.dart';
import 'prayer_card.dart' show prayerWhen;
import 'prayer_sheets.dart' show confirmPrayerDialog, showPrayerSnack, showReportSheet;

/// The calls the comment widgets make; tests pass their own.
class CommentsBackend {
  const CommentsBackend({
    this.thread = CommentsApi.thread,
    this.add = CommentsApi.add,
    this.like = CommentsApi.like,
    this.delete = CommentsApi.delete,
    this.report = CommentsApi.report,
  });

  final Future<CommentThread> Function(CommentSubject s, String id) thread;
  final Future<CommentThread> Function(CommentSubject s, String id, String body) add;
  final Future<CommentThread> Function(String verseId, bool liked) like;
  final Future<CommentThread> Function(String commentId) delete;
  final Future<void> Function(String commentId, String? reason) report;
}

Future<void> openComments(
  BuildContext context, {
  required CommentSubject subject,
  required String id,
  required String title,
  CommentsBackend backend = const CommentsBackend(),
}) =>
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        builder: (_) => CommentsPage(subject: subject, id: id, title: title, backend: backend),
      ),
    );

/// Like and comments under the Scripture of the Week.
class VerseReactions extends StatefulWidget {
  const VerseReactions({super.key, required this.verseId, required this.reference, this.backend = const CommentsBackend()});

  final String verseId;
  final String reference;
  final CommentsBackend backend;

  @override
  State<VerseReactions> createState() => _VerseReactionsState();
}

class _VerseReactionsState extends State<VerseReactions> {
  CommentThread _thread = CommentThread.empty;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(VerseReactions old) {
    super.didUpdateWidget(old);
    if (old.verseId != widget.verseId) _load();
  }

  Future<void> _load() async {
    try {
      final t = await widget.backend.thread(CommentSubject.verse, widget.verseId);
      if (mounted) setState(() => _thread = t);
    } catch (e) {
      debugPrint('VerseReactions: $e');
    }
  }

  Future<void> _toggleLike() async {
    final before = _thread;
    setState(() => _thread = before.withLike(!before.liked));
    try {
      final t = await widget.backend.like(widget.verseId, !before.liked);
      if (mounted) setState(() => _thread = t);
    } catch (e) {
      if (!mounted) return;
      setState(() => _thread = before);
      showPrayerSnack(context, userFacingError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = _thread;
    final liked = t.liked;
    return Row(
      children: [
        TextButton.icon(
          onPressed: _toggleLike,
          style: TextButton.styleFrom(
            foregroundColor: liked ? ChurchColors.accent : ChurchColors.muted,
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
          icon: Icon(liked ? Icons.favorite_rounded : Icons.favorite_border_rounded, size: 20),
          label: Text(
            t.likes == 0 ? 'Like' : '${t.likes}',
            semanticsLabel: liked
                ? 'You like this verse${t.likes > 1 ? ', with ${t.likes - 1} others' : ''}'
                : 'Like this verse${t.likes > 0 ? ', ${t.likes} likes' : ''}',
          ),
        ),
        const SizedBox(width: 4),
        TextButton.icon(
          onPressed: () async {
            await openComments(context,
                subject: CommentSubject.verse, id: widget.verseId, title: widget.reference, backend: widget.backend);
            _load();
          },
          style: TextButton.styleFrom(
            foregroundColor: ChurchColors.muted,
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
          icon: const Icon(Icons.chat_bubble_outline_rounded, size: 19),
          label: Text(t.count == 0 ? 'Comment' : '${t.count} ${t.count == 1 ? 'comment' : 'comments'}'),
        ),
      ],
    );
  }
}

/// The comments section at the foot of a sermon: the latest couple, and the
/// way in to read and add more.
class SermonComments extends StatefulWidget {
  const SermonComments({super.key, required this.sermonId, required this.title, this.backend = const CommentsBackend()});

  final String sermonId;
  final String title;
  final CommentsBackend backend;

  @override
  State<SermonComments> createState() => _SermonCommentsState();
}

class _SermonCommentsState extends State<SermonComments> {
  CommentThread? _thread;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final t = await widget.backend.thread(CommentSubject.sermon, widget.sermonId);
      if (mounted) setState(() => _thread = t);
    } catch (e) {
      debugPrint('SermonComments: $e');
    }
  }

  Future<void> _open() async {
    await openComments(context,
        subject: CommentSubject.sermon, id: widget.sermonId, title: widget.title, backend: widget.backend);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final t = _thread;
    if (t == null) return const SizedBox.shrink();
    final latest = t.comments.length <= 2 ? t.comments : t.comments.sublist(t.comments.length - 2);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        DashboardLabelText(label: t.count == 0 ? 'Comments' : 'Comments · ${t.count}'),
        for (final c in latest) _CommentTile(comment: c, compact: true),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _open,
          icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
          label: Text(t.count == 0
              ? (t.cantComment == null ? 'Share what stood out to you' : 'No comments yet')
              : t.count > latest.length
                  ? 'Read all ${t.count} comments'
                  : (t.cantComment == null ? 'Add a comment' : 'Read comments')),
        ),
      ],
    );
  }
}

/// All the comments on a verse or sermon, with a box to add one.
class CommentsPage extends StatefulWidget {
  const CommentsPage({
    super.key,
    required this.subject,
    required this.id,
    required this.title,
    this.backend = const CommentsBackend(),
  });

  final CommentSubject subject;
  final String id;
  final String title;
  final CommentsBackend backend;

  @override
  State<CommentsPage> createState() => _CommentsPageState();
}

class _CommentsPageState extends State<CommentsPage> {
  CommentThread? _thread;
  String? _error;
  bool _sending = false;
  final _text = TextEditingController();
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _text.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final t = await widget.backend.thread(widget.subject, widget.id);
      if (mounted) setState(() => _thread = t);
    } catch (e) {
      if (mounted) setState(() => _error = userFacingError(e));
    }
  }

  Future<void> _send() async {
    final body = _text.text.trim();
    if (body.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final t = await widget.backend.add(widget.subject, widget.id, body);
      if (!mounted) return;
      _text.clear();
      FocusScope.of(context).unfocus();
      setState(() => _thread = t);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.animateTo(_scroll.position.maxScrollExtent,
              duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
        }
      });
    } catch (e) {
      if (mounted) showPrayerSnack(context, userFacingError(e));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _delete(ContentComment c) async {
    final ok = await confirmPrayerDialog(
      context,
      title: 'Delete your comment?',
      message: 'It will be gone for everyone.',
      confirmLabel: 'Delete',
    );
    if (!ok) return;
    try {
      final t = await widget.backend.delete(c.id);
      if (mounted) setState(() => _thread = t);
    } catch (e) {
      if (mounted) showPrayerSnack(context, userFacingError(e));
    }
  }

  Future<void> _report(ContentComment c) async {
    final reason = await showReportSheet(context, what: 'comment');
    if (reason == null) return;
    try {
      await widget.backend.report(c.id, reason);
      if (!mounted) return;
      setState(() => _thread = _thread?.without(c.id));
      showPrayerSnack(context, 'Thank you. We’ve hidden it for you and a pastor will take a look.');
    } catch (e) {
      if (mounted) showPrayerSnack(context, userFacingError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = _thread;
    return Scaffold(
      backgroundColor: ChurchColors.background,
      appBar: AppBar(
        title: Column(
          children: [
            Text('Comments', style: ChurchType.headline),
            Text(widget.title, style: ChurchType.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: t == null
                ? Center(
                    child: _error == null
                        ? const CircularProgressIndicator()
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_error!, style: ChurchType.body, textAlign: TextAlign.center),
                              TextButton(onPressed: _load, child: const Text('Try again')),
                            ],
                          ),
                  )
                : RefreshIndicator(
                    onRefresh: _load,
                    child: t.comments.isEmpty
                        ? ListView(
                            padding: const EdgeInsets.fromLTRB(32, 80, 32, 32),
                            children: [
                              Icon(Icons.chat_bubble_outline_rounded,
                                  size: 40, color: ChurchColors.muted.withValues(alpha: 0.5)),
                              const SizedBox(height: 12),
                              Text('No comments yet', style: ChurchType.title, textAlign: TextAlign.center),
                              const SizedBox(height: 4),
                              Text(
                                t.cantComment == null
                                    ? 'Share what stood out to you, or how it spoke to you this week.'
                                    : 'When people share what stood out to them, it shows up here.',
                                style: ChurchType.label,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          )
                        : ListView.builder(
                            controller: _scroll,
                            padding: const EdgeInsets.fromLTRB(20, 4, 12, 16),
                            itemCount: t.comments.length + (t.count > t.comments.length ? 1 : 0),
                            itemBuilder: (context, i) {
                              if (t.count > t.comments.length && i == 0) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Text('Showing the latest ${t.comments.length} of ${t.count}.',
                                      style: ChurchType.caption, textAlign: TextAlign.center),
                                );
                              }
                              final c = t.comments[i - (t.count > t.comments.length ? 1 : 0)];
                              return _CommentTile(comment: c, onDelete: () => _delete(c), onReport: () => _report(c));
                            },
                          ),
                  ),
          ),
          if (t != null) _composer(t),
        ],
      ),
    );
  }

  Widget _composer(CommentThread t) {
    return Material(
      color: ChurchColors.card,
      child: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(border: Border(top: ChurchRules.hairline)),
          padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
          child: t.cantComment != null
              ? Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(t.cantComment!, style: ChurchType.label, textAlign: TextAlign.center),
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _text,
                        minLines: 1,
                        maxLines: 4,
                        maxLength: 1000,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          hintText: 'Add a comment…',
                          counterText: '',
                          isDense: true,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      tooltip: 'Post comment',
                      onPressed: _sending || _text.text.trim().isEmpty ? null : _send,
                      icon: _sending
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : Icon(Icons.send_rounded, color: ChurchColors.accent),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({required this.comment, this.onDelete, this.onReport, this.compact = false});

  final ContentComment comment;
  final VoidCallback? onDelete;
  final VoidCallback? onReport;

  /// A preview: no menu, body cut short.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = comment;
    return Container(
      padding: const EdgeInsets.only(top: 14, bottom: 10),
      decoration: BoxDecoration(border: Border(bottom: ChurchRules.hairline)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MemberAvatar(name: c.authorName, size: 32, radius: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  children: [
                    Text(c.mine ? 'You' : c.authorName, style: ChurchType.bodyStrong.copyWith(fontSize: 14)),
                    if (c.fromTeam) ChurchEyebrow('Church team', color: ChurchColors.accent),
                    Text(prayerWhen(c.createdAt), style: ChurchType.caption),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  c.body,
                  style: ChurchType.body,
                  maxLines: compact ? 3 : null,
                  overflow: compact ? TextOverflow.ellipsis : null,
                ),
              ],
            ),
          ),
          if (!compact)
            PopupMenuButton<String>(
              tooltip: 'More options',
              icon: Icon(Icons.more_horiz_rounded, color: ChurchColors.muted, size: 20),
              onSelected: (v) => v == 'delete' ? onDelete?.call() : onReport?.call(),
              itemBuilder: (_) => [
                if (c.mine)
                  const PopupMenuItem(value: 'delete', child: Text('Delete comment'))
                else
                  const PopupMenuItem(value: 'report', child: Text('Report')),
              ],
            ),
        ],
      ),
    );
  }
}
