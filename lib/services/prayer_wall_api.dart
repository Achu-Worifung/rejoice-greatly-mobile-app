import 'package:flutter/foundation.dart';

import 'church_api.dart';

/// Where a prayer request is shared.
enum PrayerVisibility {
  /// On the wall for the whole church.
  church,

  /// Only the pastoral team sees it.
  pastors;

  String get wire => name.toUpperCase();

  static PrayerVisibility parse(Object? value) =>
      '$value'.toUpperCase() == 'PASTORS' ? pastors : church;
}

/// Which slice of the wall to show.
enum PrayerFilter {
  wall('All requests'),
  answered('Answered'),
  mine('My requests');

  const PrayerFilter(this.label);
  final String label;
}

/// One prayer request, as the backend shapes it for the signed-in member.
@immutable
class PrayerRequestItem {
  const PrayerRequestItem({
    required this.id,
    required this.body,
    required this.authorName,
    required this.anonymous,
    required this.mine,
    required this.visibility,
    required this.createdAt,
    required this.answeredAt,
    required this.answeredNote,
    required this.prayerCount,
    required this.prayedByMe,
    required this.commentCount,
    required this.hidden,
    this.askedToRenew = false,
    this.archived = false,
    this.shareAtService = false,
  });

  factory PrayerRequestItem.fromJson(Map<String, dynamic> json) {
    return PrayerRequestItem(
      id: '${json['id']}',
      body: json['body'] as String? ?? '',
      authorName: json['authorName'] as String? ?? 'A church member',
      anonymous: json['anonymous'] as bool? ?? false,
      mine: json['mine'] as bool? ?? false,
      visibility: PrayerVisibility.parse(json['visibility']),
      createdAt: _date(json['createdAt']) ?? DateTime.now(),
      answeredAt: _date(json['answeredAt']),
      answeredNote: json['answeredNote'] as String?,
      prayerCount: (json['prayerCount'] as num?)?.toInt() ?? 0,
      prayedByMe: json['prayedByMe'] as bool? ?? false,
      commentCount: (json['commentCount'] as num?)?.toInt() ?? 0,
      hidden: json['hidden'] as bool? ?? false,
      askedToRenew: json['askedToRenew'] as bool? ?? false,
      archived: json['archived'] as bool? ?? false,
      shareAtService: json['shareAtService'] as bool? ?? false,
    );
  }

  final String id;
  final String body;
  final String authorName;
  final bool anonymous;
  final bool mine;
  final PrayerVisibility visibility;
  final DateTime createdAt;
  final DateTime? answeredAt;
  final String? answeredNote;
  final int prayerCount;
  final bool prayedByMe;
  final int commentCount;

  /// Paused by a moderator. Only ever true on the member's own requests.
  final bool hidden;

  /// A month on, the church asked "still need prayer?" and they haven't said.
  /// Only ever true on the member's own requests.
  final bool askedToRenew;

  /// Came off the wall when it ran its course; only its author still sees it.
  final bool archived;

  /// They agreed to the answer being shared at Sunday service.
  final bool shareAtService;

  bool get answered => answeredAt != null;

  /// The optimistic state after tapping "Pray" — the server's reply replaces it.
  PrayerRequestItem withPrayed(bool prayed) {
    if (prayed == prayedByMe) return this;
    return PrayerRequestItem(
      id: id,
      body: body,
      authorName: authorName,
      anonymous: anonymous,
      mine: mine,
      visibility: visibility,
      createdAt: createdAt,
      answeredAt: answeredAt,
      answeredNote: answeredNote,
      prayerCount: (prayerCount + (prayed ? 1 : -1)).clamp(0, 1 << 30),
      prayedByMe: prayed,
      commentCount: commentCount,
      hidden: hidden,
      askedToRenew: askedToRenew,
      archived: archived,
      shareAtService: shareAtService,
    );
  }
}

/// A word of encouragement on a request.
@immutable
class PrayerReply {
  const PrayerReply({
    required this.id,
    required this.body,
    required this.authorName,
    required this.mine,
    required this.fromTeam,
    required this.anonymous,
    required this.createdAt,
  });

  factory PrayerReply.fromJson(Map<String, dynamic> json) {
    return PrayerReply(
      id: '${json['id']}',
      body: json['body'] as String? ?? '',
      authorName: json['authorName'] as String? ?? 'A church member',
      mine: json['mine'] as bool? ?? false,
      fromTeam: json['fromTeam'] as bool? ?? false,
      anonymous: json['anonymous'] as bool? ?? false,
      createdAt: _date(json['createdAt']) ?? DateTime.now(),
    );
  }

  final String id;
  final String body;
  final String authorName;
  final bool mine;

  /// Written by a pastor or admin — shown with a "Church team" label.
  final bool fromTeam;

  /// Other members see "Someone from church" rather than a name.
  final bool anonymous;
  final DateTime createdAt;
}

@immutable
class PrayerPage {
  const PrayerPage(this.items, this.hasMore, {this.canPost = true});
  final List<PrayerRequestItem> items;
  final bool hasMore;

  /// False while a pastor has paused this member's posting.
  final bool canPost;
}

@immutable
class PrayerThread {
  const PrayerThread(this.prayer, this.replies, this.canReply);

  factory PrayerThread.fromJson(Map<String, dynamic> json) {
    final raw = json['comments'];
    return PrayerThread(
      PrayerRequestItem.fromJson(Map<String, dynamic>.from(json['prayer'] as Map)),
      raw is List
          ? raw
              .whereType<Map>()
              .map((e) => PrayerReply.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
      json['canComment'] as bool? ?? false,
    );
  }

  final PrayerRequestItem prayer;
  final List<PrayerReply> replies;
  final bool canReply;
}

DateTime? _date(Object? value) =>
    value == null ? null : DateTime.tryParse('$value')?.toLocal();

/// Typed calls for `/member/prayers/**`.
class PrayerWallApi {
  PrayerWallApi._();

  /// Longest request / reply the backend accepts.
  static const int maxRequestLength = 1000;
  static const int maxReplyLength = 500;

  /// A prayer request a push notification asked to open. The home screen
  /// picks it up once the member is signed in and the tabs are showing.
  /// Empty opens the prayer wall itself.
  static final ValueNotifier<String?> pendingThread = ValueNotifier(null);

  static Future<PrayerPage> list({
    PrayerFilter filter = PrayerFilter.wall,
    int page = 0,
    int size = 20,
  }) async {
    final map = await ChurchApi.memberPrayers('', {
      'filter': filter.name,
      'page': page,
      'size': size,
    });
    final raw = map['items'];
    return PrayerPage(
      raw is List
          ? raw
              .whereType<Map>()
              .map((e) => PrayerRequestItem.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
      map['hasMore'] as bool? ?? false,
      canPost: map['canPost'] as bool? ?? true,
    );
  }

  static Future<PrayerRequestItem> create({
    required String body,
    required bool anonymous,
    required PrayerVisibility visibility,
  }) async {
    final map = await ChurchApi.memberPrayers('create', {
      'body': body,
      'anonymous': anonymous,
      'visibility': visibility.wire,
    });
    return PrayerRequestItem.fromJson(map);
  }

  static Future<PrayerThread> thread(String id) async =>
      PrayerThread.fromJson(await ChurchApi.memberPrayers(id));

  static Future<PrayerRequestItem> setPrayed(String id, bool prayed) async =>
      PrayerRequestItem.fromJson(
          await ChurchApi.memberPrayers('$id/pray', {'prayed': prayed}));

  /// [shareAtService] is the member agreeing to the answer being shared at
  /// Sunday service.
  static Future<PrayerRequestItem> setAnswered(
    String id, {
    required bool answered,
    String? note,
    bool shareAtService = false,
  }) async =>
      PrayerRequestItem.fromJson(await ChurchApi.memberPrayers('$id/answered',
          {'answered': answered, 'note': ?note, 'shareAtService': shareAtService}));

  /// "Still need prayer" — open for another month, and back on the wall if archived.
  static Future<PrayerRequestItem> renew(String id) async =>
      PrayerRequestItem.fromJson(await ChurchApi.memberPrayers('$id/renew'));

  /// Off the wall, without deleting it.
  static Future<PrayerRequestItem> archive(String id) async =>
      PrayerRequestItem.fromJson(await ChurchApi.memberPrayers('$id/archive'));

  static Future<void> delete(String id) => ChurchApi.memberPrayers('$id/delete');

  static Future<PrayerThread> reply(String id, String body, {bool anonymous = false}) async =>
      PrayerThread.fromJson(await ChurchApi.memberPrayers(
          '$id/comments', {'body': body, 'anonymous': anonymous}));

  static Future<PrayerThread> deleteReply(String replyId) async =>
      PrayerThread.fromJson(
          await ChurchApi.memberPrayers('comments/$replyId/delete'));

  static Future<void> report(String id, String reason) =>
      ChurchApi.memberPrayers('$id/report', {'reason': reason});

  static Future<void> reportReply(String replyId, String reason) =>
      ChurchApi.memberPrayers('comments/$replyId/report', {'reason': reason});
}
