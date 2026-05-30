import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'user_session_store.dart';

/// Result of restoring session on cold start.
class SessionRestoreResult {
  const SessionRestoreResult({
    required this.loggedIn,
    this.signupComplete = false,
    this.account,
    this.syncedFromServer = false,
  });

  final bool loggedIn;
  final bool signupComplete;
  final Map<String, dynamic>? account;
  final bool syncedFromServer;
}

/// Church profile from `POST /member/profile` (not auth).
class ProfileLoadResult {
  const ProfileLoadResult({
    this.profile,
    this.syncedFromServer = false,
    this.error,
    this.hasProfile = false,
  });

  final Map<String, dynamic>? profile;
  final bool syncedFromServer;
  final String? error;
  final bool hasProfile;
}

/// Stats from `POST /member/stats`.
class MemberStatsResult {
  const MemberStatsResult({
    this.stats,
    this.syncedFromServer = false,
    this.error,
  });

  final Map<String, dynamic>? stats;
  final bool syncedFromServer;
  final String? error;
}

/// Attendance history from `POST /member/attendance/history`.
class MemberAttendanceResult {
  const MemberAttendanceResult({
    this.activities = const [],
    this.syncedFromServer = false,
    this.error,
  });

  final List<Map<String, dynamic>> activities;
  final bool syncedFromServer;
  final String? error;
}

/// My profile page: profile + optional stats/history when [hasProfile].
class MePageLoadResult {
  const MePageLoadResult({
    this.profile,
    this.hasProfile = false,
    this.stats,
    this.activities = const [],
    this.profileSynced = false,
    this.statsSynced = false,
    this.attendanceSynced = false,
    this.error,
  });

  final Map<String, dynamic>? profile;
  final bool hasProfile;
  final Map<String, dynamic>? stats;
  final List<Map<String, dynamic>> activities;
  final bool profileSynced;
  final bool statsSynced;
  final bool attendanceSynced;
  final String? error;
}

class ChurchApi {
  ChurchApi._();

  static String get baseUrl => dotenv.env['BASE_URL'] ?? 'http://localhost:8080';

  static bool isSignupComplete(Map<String, dynamic>? account) =>
      UserSessionStore.isSignupComplete(account);

  static bool hasMemberProfile(Map<String, dynamic>? profile) {
    if (profile == null) return false;
    if (profile.containsKey('hasProfile')) {
      return UserSessionStore.asBool(profile['hasProfile']);
    }
    final img = profile['imgURL'];
    return isSignupComplete(profile) &&
        img is String &&
        img.trim().isNotEmpty;
  }

  static Future<void> persistAccountFromServer(
    Map<String, dynamic> account, {
    String? provider,
  }) =>
      UserSessionStore.saveAccount(account, provider: provider);

  static Future<SessionRestoreResult> restoreUserSession() async {
    final user = await waitForSignedInUser(
      timeout: const Duration(seconds: 5),
    );
    if (user == null) {
      return const SessionRestoreResult(loggedIn: false);
    }

    final cached = await getCachedAccountJson();
    final local = cached ?? await accountFromLocalPrefs(user);
    final signupComplete = await UserSessionStore.readSignupComplete();

    try {
      final auth = await syncAuthAccount();
      final prefs = await SharedPreferences.getInstance();
      final provider = prefs.getString(UserSessionStore.authProviderKey) ??
          inferAuthProvider(user);
      await persistAccountFromServer(auth, provider: provider);
      return SessionRestoreResult(
        loggedIn: true,
        signupComplete: isSignupComplete(auth),
        account: auth,
        syncedFromServer: true,
      );
    } catch (e, st) {
      debugPrint('ChurchApi restoreUserSession auth sync failed: $e\n$st');
    }

    return SessionRestoreResult(
      loggedIn: true,
      signupComplete: signupComplete,
      account: local,
      syncedFromServer: false,
    );
  }

  static Future<Map<String, dynamic>> ensurePostgresAccount() =>
      syncAuthAccount();

  static String? profileImageUrlFromAccount(Map<String, dynamic>? account) {
    if (account == null) return null;
    final img = account['imgURL'];
    if (img is String && img.trim().isNotEmpty) return img.trim();
    return null;
  }

  static Future<String?> resolveProfileImageUrl({Map<String, dynamic>? account}) =>
      UserSessionStore.readProfileImageUrl(account: account);

  static Future<Map<String, dynamic>?> getCachedAccountJson() =>
      UserSessionStore.loadAccount();

  static Future<User?> waitForSignedInUser({
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final existing = FirebaseAuth.instance.currentUser;
    if (existing != null) return existing;
    try {
      return await FirebaseAuth.instance
          .authStateChanges()
          .firstWhere((u) => u != null)
          .timeout(timeout);
    } on TimeoutException {
      return FirebaseAuth.instance.currentUser;
    }
  }

  /// Auth only — `POST /auth/firebase`.
  static Future<Map<String, dynamic>> syncAuthAccount() async {
    final tokenBundle = await _requireIdToken();
    final prefs = await SharedPreferences.getInstance();
    final provider = prefs.getString(UserSessionStore.authProviderKey) ??
        inferAuthProvider(tokenBundle.user);

    debugPrint('ChurchApi: POST /auth/firebase (provider=$provider)');
    return refreshAccountWithFirebaseToken(
      tokenBundle.token,
      provider: provider,
      name: tokenBundle.user.displayName,
    );
  }

  /// `POST /member/profile` — profile fields only.
  static Future<Map<String, dynamic>> fetchMemberProfile() async {
    final map = await _postMember('profile', const {});
    await _mergeIntoCachedAccount(map);
    return map;
  }

  /// `POST /member/stats` — attendance aggregates.
  static Future<Map<String, dynamic>> fetchMemberStats() async {
    final map = await _postMember('stats', const {});
    await _mergeIntoCachedAccount(map);
    return map;
  }

  /// `POST /member/attendance/history` — check-in dates.
  static Future<List<Map<String, dynamic>>> fetchMemberAttendanceHistory() async {
    final map = await _postMember('attendance/history', const {});
    final raw = map['recentAttendance'];
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  static Future<ProfileLoadResult> loadMemberProfile() async {
    final user = await waitForSignedInUser();
    if (user == null) {
      return const ProfileLoadResult(
        error: 'Not signed in',
        syncedFromServer: false,
      );
    }

    try {
      await syncAuthAccount();
      final profile = await fetchMemberProfile();
      return ProfileLoadResult(
        profile: profile,
        hasProfile: hasMemberProfile(profile),
        syncedFromServer: true,
      );
    } catch (e, st) {
      debugPrint('ChurchApi.loadMemberProfile failed: $e\n$st');
      final cached = await getCachedAccountJson();
      return ProfileLoadResult(
        profile: cached,
        hasProfile: hasMemberProfile(cached),
        syncedFromServer: false,
        error: e.toString(),
      );
    }
  }

  static Future<MemberStatsResult> loadMemberStats() async {
    try {
      final stats = await fetchMemberStats();
      return MemberStatsResult(stats: stats, syncedFromServer: true);
    } catch (e, st) {
      debugPrint('ChurchApi.loadMemberStats failed: $e\n$st');
      final cached = await getCachedAccountJson();
      if (cached != null && cached.containsKey('currentStreak')) {
        return MemberStatsResult(
          stats: _statsFromAccountMap(cached),
          syncedFromServer: false,
          error: e.toString(),
        );
      }
      return MemberStatsResult(syncedFromServer: false, error: e.toString());
    }
  }

  static Future<MePageLoadResult> loadMePage() async {
    final user = await waitForSignedInUser();
    if (user == null) {
      return const MePageLoadResult(error: 'Not signed in');
    }

    try {
      await syncAuthAccount();
    } catch (e, st) {
      debugPrint('ChurchApi.loadMePage auth failed: $e\n$st');
      final cached = await getCachedAccountJson();
      return MePageLoadResult(
        profile: cached,
        hasProfile: hasMemberProfile(cached),
        error: e.toString(),
      );
    }

    try {
      final profile = await fetchMemberProfile();
      final hasProfile = hasMemberProfile(profile);

      if (!hasProfile) {
        return MePageLoadResult(
          profile: profile,
          hasProfile: false,
          profileSynced: true,
        );
      }

      Map<String, dynamic>? stats;
      List<Map<String, dynamic>> activities = [];
      var statsSynced = false;
      var attendanceSynced = false;
      String? partialError;

      try {
        stats = await fetchMemberStats();
        statsSynced = true;
      } catch (e, st) {
        debugPrint('ChurchApi.loadMePage stats failed: $e\n$st');
        partialError = e.toString();
        final cached = await getCachedAccountJson();
        if (cached != null) stats = _statsFromAccountMap(cached);
      }

      try {
        activities = await fetchMemberAttendanceHistory();
        attendanceSynced = true;
      } catch (e, st) {
        debugPrint('ChurchApi.loadMePage attendance failed: $e\n$st');
        partialError ??= e.toString();
      }

      return MePageLoadResult(
        profile: profile,
        hasProfile: true,
        stats: stats,
        activities: activities,
        profileSynced: true,
        statsSynced: statsSynced,
        attendanceSynced: attendanceSynced,
        error: partialError,
      );
    } catch (e, st) {
      debugPrint('ChurchApi.loadMePage profile failed: $e\n$st');
      final cached = await getCachedAccountJson();
      return MePageLoadResult(
        profile: cached,
        hasProfile: hasMemberProfile(cached),
        error: e.toString(),
      );
    }
  }

  @Deprecated('Use syncAuthAccount or loadMemberProfile')
  static Future<Map<String, dynamic>> syncCurrentUserAccount() =>
      syncAuthAccount();

  @Deprecated('Use loadMemberProfile')
  static Future<ProfileLoadResult> loadProfileAccount() => loadMemberProfile();

  static Future<Map<String, dynamic>?> accountFromLocalPrefs(User? user) async {
    final cached = await UserSessionStore.loadAccount();
    if (cached != null) return cached;
    if (user == null) return null;
    return UserSessionStore.buildAccountFromFields();
  }

  static String inferAuthProvider(User user) {
    for (final info in user.providerData) {
      if (info.providerId == 'google.com') return 'Google';
      if (info.providerId == 'apple.com') return 'Apple';
    }
    return 'email';
  }

  static Future<Map<String, dynamic>> refreshAccountWithFirebaseToken(
    String idToken, {
    String provider = 'email',
    String? name,
  }) async {
    final body = <String, dynamic>{
      'idToken': idToken,
      'provider': provider,
    };
    if (name != null) body['name'] = name;

    final map = await _postJson('/auth/firebase', body);
    await _mergeIntoCachedAccount(map);
    return map;
  }

  static Future<void> _mergeIntoCachedAccount(Map<String, dynamic> incoming) async {
    final cached = await getCachedAccountJson();
    final merged = <String, dynamic>{
      if (cached != null) ...cached,
      ...incoming,
    };
    final prefs = await SharedPreferences.getInstance();
    final provider = prefs.getString(UserSessionStore.authProviderKey);
    await persistAccountFromServer(merged, provider: provider);
  }

  static Future<Map<String, dynamic>> _postMember(
    String path,
    Map<String, dynamic> extra,
  ) async {
    final tokenBundle = await _requireIdToken();
    final body = <String, dynamic>{
      'idToken': tokenBundle.token,
      ...extra,
    };
    return _postJson('/member/$path', body);
  }

  static Future<Map<String, dynamic>> _postJson(
    String path,
    Map<String, dynamic> body,
  ) async {
    final uri = Uri.parse('$baseUrl$path');
    final r = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: json.encode(body),
        )
        .timeout(const Duration(seconds: 30));

    debugPrint('ChurchApi: POST ${uri.path} -> ${r.statusCode}');
    if (r.statusCode != 200) {
      throw Exception('${uri.path} failed: ${r.statusCode} ${r.body}');
    }
    return Map<String, dynamic>.from(json.decode(r.body) as Map);
  }

  static Future<({User user, String token})> _requireIdToken() async {
    final user = await waitForSignedInUser();
    if (user == null) {
      throw StateError('Not signed in to Firebase');
    }

    try {
      await user.reload();
    } catch (e) {
      debugPrint('ChurchApi: user.reload() failed (continuing): $e');
    }

    final active = FirebaseAuth.instance.currentUser ?? user;
    String? token;
    try {
      token = await active.getIdToken(true);
    } catch (e) {
      debugPrint('ChurchApi: getIdToken(true) failed, retrying: $e');
      token = await active.getIdToken();
    }
    if (token == null || token.isEmpty) {
      throw StateError('Could not obtain Firebase id token');
    }
    return (user: active, token: token);
  }

  static Map<String, dynamic> _statsFromAccountMap(Map<String, dynamic> a) {
    return {
      'currentStreak': a['currentStreak'],
      'longestStreak': a['longestStreak'],
      'totalAttendance': a['totalAttendance'],
      'totalAbsences': a['totalAbsences'],
      'absenceStreak': a['absenceStreak'],
    };
  }

  static int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? 0;
  }

  static Map<String, dynamic> statsToAttendanceSheetData(Map<String, dynamic> stats) {
    return {
      'attendanceStreak': {
        'streakLabel': 'Current streak',
        'currentStreak': _asInt(stats['currentStreak']),
        'totalLabel': 'Total attendances',
        'totalAttendance': _asInt(stats['totalAttendance']),
        'bestLabel': 'Longest streak',
        'bestStreak': _asInt(stats['longestStreak']),
        'absences': _asInt(stats['totalAbsences']),
        'absenceStreak': _asInt(stats['absenceStreak']),
      },
    };
  }

  @Deprecated('Use statsToAttendanceSheetData')
  static Map<String, dynamic> accountToAttendanceSheetData(Map<String, dynamic> a) =>
      statsToAttendanceSheetData(a);

  static Future<Map<String, dynamic>> getCurrentVerse() async {
    final r = await http.get(Uri.parse('$baseUrl/weekly-verse/current'));
    if (r.statusCode != 200) {
      throw Exception('weekly-verse/current failed: ${r.statusCode}');
    }
    return json.decode(r.body) as Map<String, dynamic>;
  }

  static Future<List<dynamic>> getTop4Events() async {
    final r = await http.get(Uri.parse('$baseUrl/events/top4'));
    if (r.statusCode != 200) {
      throw Exception('events/top4 failed: ${r.statusCode}');
    }
    return json.decode(r.body) as List<dynamic>;
  }

  static Future<List<dynamic>> getDashboardEventInstances() async {
    try {
      final top = await getTop4Events();
      if (top.isNotEmpty) return top;
    } catch (_) {}
    final upcoming = await getUpcomingEvents();
    if (upcoming.isEmpty) return [];
    final list = List<dynamic>.from(upcoming);
    list.sort((a, b) {
      String dateOf(Object? x) {
        if (x is! Map) return '';
        return x['date'] as String? ?? '';
      }
      return dateOf(a).compareTo(dateOf(b));
    });
    if (list.length <= 4) return list;
    return list.sublist(0, 4);
  }

  static Future<List<dynamic>> getUpcomingEvents() async {
    final r = await http.get(Uri.parse('$baseUrl/events/upcoming'));
    if (r.statusCode != 200) {
      throw Exception('events/upcoming failed: ${r.statusCode}');
    }
    return json.decode(r.body) as List<dynamic>;
  }

  static Future<List<dynamic>> getSermons() async {
    final r = await http.get(Uri.parse('$baseUrl/sermons'));
    if (r.statusCode != 200) {
      throw Exception('sermons failed: ${r.statusCode}');
    }
    return json.decode(r.body) as List<dynamic>;
  }

  static Future<Map<String, dynamic>> getSermonById(Object id) async {
    final r = await http.get(Uri.parse('$baseUrl/sermons/$id'));
    if (r.statusCode != 200) {
      throw Exception('sermons/$id failed: ${r.statusCode}');
    }
    return json.decode(r.body) as Map<String, dynamic>;
  }

  static List<Map<String, dynamic>> mapEventInstances(List<dynamic> list) {
    final out = <Map<String, dynamic>>[];
    for (final e in list) {
      if (e is! Map) continue;
      final m = Map<String, dynamic>.from(e);
      if (m['cancelled'] == true) continue;
      final t = m['template'] is Map
          ? Map<String, dynamic>.from(m['template'] as Map)
          : <String, dynamic>{};
      final dateStr = m['date'] as String? ?? '';
      if (dateStr.isEmpty) continue;
      out.add({
        'title': (t['title'] as String?)?.trim().isNotEmpty == true
            ? t['title'] as String
            : (m['title'] as String?) ?? 'Church event',
        'time': _formatTime(m['specificTime'] as String?, t['defaultTime'] as String?),
        'date': dateStr.length >= 10 ? dateStr.substring(0, 10) : dateStr,
        'location': t['location'] ?? '',
        'imageUrl': t['posterUrl'],
        'description': (t['description'] as String?)?.trim() ?? '',
        'category': (t['category'] as String?)?.trim().isNotEmpty == true
            ? t['category'] as String
            : 'General',
      });
    }
    return out;
  }

  static String _formatTime(String? specific, String? def) {
    final raw = specific ?? def;
    if (raw == null || raw.isEmpty) return '';
    final parts = raw.split(':');
    if (parts.length < 2) return raw;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1].split('.').first) ?? 0;
    return DateFormat.jm().format(DateTime(2000, 1, 1, h, m));
  }
}
