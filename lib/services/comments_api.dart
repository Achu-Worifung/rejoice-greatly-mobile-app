import 'package:flutter/foundation.dart';

import 'church_api.dart';

/// What a comment is on.
enum CommentSubject {
  verse,
  sermon;

  String get path => name;
}

/// One member's comment.
@immutable
class ContentComment {
  const ContentComment({
    required this.id,
    required this.body,
    required this.authorName,
    required this.mine,
    required this.fromTeam,
    required this.createdAt,
  });

  factory ContentComment.fromJson(Map<String, dynamic> j) => ContentComment(
        id: '${j['id']}',
        body: j['body'] as String? ?? '',
        authorName: j['authorName'] as String? ?? 'A church member',
        mine: j['mine'] == true,
        fromTeam: j['fromTeam'] == true,
        createdAt: DateTime.tryParse('${j['createdAt']}')?.toLocal() ?? DateTime.now(),
      );

  final String id;
  final String body;
  final String authorName;
  final bool mine;

  /// Written by a pastor or admin, labelled "Church team".
  final bool fromTeam;
  final DateTime createdAt;
}

/// Comments on one verse or sermon, oldest first, and the verse's likes.
@immutable
class CommentThread {
  const CommentThread({
    required this.likable,
    required this.likes,
    required this.liked,
    required this.count,
    this.cantComment,
    required this.comments,
  });

  factory CommentThread.fromJson(Map<String, dynamic> j) => CommentThread(
        likable: j['likable'] == true,
        likes: (j['likes'] as num?)?.toInt() ?? 0,
        liked: j['liked'] == true,
        count: (j['count'] as num?)?.toInt() ?? 0,
        cantComment: j['cantComment'] as String?,
        comments: [
          for (final c in (j['comments'] as List? ?? const []))
            if (c is Map) ContentComment.fromJson(Map<String, dynamic>.from(c)),
        ],
      );

  static const empty = CommentThread(likable: false, likes: 0, liked: false, count: 0, comments: []);

  /// Only the Scripture of the Week takes likes.
  final bool likable;
  final int likes;
  final bool liked;

  /// Comments in all; [comments] holds the newest 200.
  final int count;

  /// Why this member can't comment (under 18, or muted); null when they can.
  final String? cantComment;
  final List<ContentComment> comments;

  CommentThread withLike(bool on) => CommentThread(
        likable: likable,
        likes: (likes + (on == liked ? 0 : (on ? 1 : -1))).clamp(0, 1 << 30),
        liked: on,
        count: count,
        cantComment: cantComment,
        comments: comments,
      );

  CommentThread without(String commentId) => CommentThread(
        likable: likable,
        likes: likes,
        liked: liked,
        count: comments.any((c) => c.id == commentId) ? count - 1 : count,
        cantComment: cantComment,
        comments: [for (final c in comments) if (c.id != commentId) c],
      );
}

/// `/member/comments`: comments on the Scripture of the Week and sermons,
/// and likes on the verse.
class CommentsApi {
  CommentsApi._();

  static String _key(CommentSubject s, String id) => '${s.path}/${Uri.encodeComponent(id)}';

  static Future<CommentThread> thread(CommentSubject s, String id) async =>
      CommentThread.fromJson(await ChurchApi.memberComments(_key(s, id)));

  static Future<CommentThread> add(CommentSubject s, String id, String body) async =>
      CommentThread.fromJson(await ChurchApi.memberComments('${_key(s, id)}/add', {'body': body.trim()}));

  static Future<CommentThread> like(String verseId, bool liked) async => CommentThread.fromJson(
      await ChurchApi.memberComments('verse/${Uri.encodeComponent(verseId)}/like', {'liked': liked}));

  static Future<CommentThread> delete(String commentId) async => CommentThread.fromJson(
      await ChurchApi.memberComments('comment/${Uri.encodeComponent(commentId)}/delete'));

  static Future<void> report(String commentId, String? reason) => ChurchApi.memberComments(
      'comment/${Uri.encodeComponent(commentId)}/report', {if ((reason ?? '').trim().isNotEmpty) 'reason': reason!.trim()});
}
