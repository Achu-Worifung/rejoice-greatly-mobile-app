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

/// Result of loading the profile — includes whether `POST /auth/firebase` succeeded.
class ProfileLoadResult {
  const ProfileLoadResult({
    this.account,
    this.syncedFromServer = false,
    this.error,
  });

  final Map<String, dynamic>? account;
  final bool syncedFromServer;
  final String? error;
}

/// Spring Boot API (`/events`, `/sermons`, `/weekly-verse`, etc.) — one place for base URL and calls.
class ChurchApi {
  ChurchApi._();

  static String get baseUrl => dotenv.env['BASE_URL'] ?? 'http://localhost:8080';

  static Future<void> cacheAccountJson(Map<String, dynamic> account) =>
      UserSessionStore.saveAccount(account);

  static bool isSignupComplete(Map<String, dynamic>? account) =>
      UserSessionStore.isSignupComplete(account);

  static Future<void> persistAccountFromServer(
    Map<String, dynamic> account, {
    String? provider,
  }) =>
      UserSessionStore.saveAccount(account, provider: provider);

  /// On app launch: restore Firebase session and sync Postgres when needed.
  ///
  /// Users who still need signup (or have no cached server account) must be
  /// upserted via `POST /auth/firebase` before profile upload — otherwise
  /// `/auth/picture-upload` returns "account not found".
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
    final needsServerAccount =
        !signupComplete || cached == null || cached['firebaseUid'] == null;

    if (needsServerAccount) {
      try {
        final account = await syncCurrentUserAccount();
        final prefs = await SharedPreferences.getInstance();
        final provider = prefs.getString(UserSessionStore.authProviderKey) ??
            inferAuthProvider(user);
        await persistAccountFromServer(account, provider: provider);
        return SessionRestoreResult(
          loggedIn: true,
          signupComplete: isSignupComplete(account),
          account: account,
          syncedFromServer: true,
        );
      } catch (e, st) {
        debugPrint('ChurchApi restoreUserSession sync failed: $e\n$st');
      }
    } else {
      unawaited(_syncSessionInBackground(user));
    }

    return SessionRestoreResult(
      loggedIn: true,
      signupComplete: signupComplete,
      account: local,
      syncedFromServer: false,
    );
  }

  /// Upserts the current Firebase user into Postgres. Call before endpoints
  /// that look up [AuthAccount] by `firebaseUid` (e.g. picture upload).
  static Future<Map<String, dynamic>> ensurePostgresAccount() =>
      syncCurrentUserAccount();

  static Future<void> _syncSessionInBackground(User user) async {
    try {
      final account = await syncCurrentUserAccount();
      final prefs = await SharedPreferences.getInstance();
      final provider =
          prefs.getString(UserSessionStore.authProviderKey) ?? inferAuthProvider(user);
      await persistAccountFromServer(account, provider: provider);
    } catch (e, st) {
      debugPrint('ChurchApi background session sync: $e\n$st');
    }
  }

  /// Church profile photo from account JSON (`imgURL` from signup upload / auth sync).
  static String? profileImageUrlFromAccount(Map<String, dynamic>? account) {
    if (account == null) return null;
    final img = account['imgURL'];
    if (img is String && img.trim().isNotEmpty) return img.trim();
    return null;
  }

  /// Best available profile image: synced account, then prefs, then Firebase photo.
  static Future<String?> resolveProfileImageUrl({Map<String, dynamic>? account}) =>
      UserSessionStore.readProfileImageUrl(account: account);

  static Future<Map<String, dynamic>?> getCachedAccountJson() =>
      UserSessionStore.loadAccount();

  /// Waits briefly for Firebase to restore [currentUser] after app start.
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

  /// Always calls `POST /auth/firebase` when a Firebase user is available.
  static Future<Map<String, dynamic>> syncCurrentUserAccount() async {
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
    final prefs = await SharedPreferences.getInstance();
    final provider = prefs.getString(UserSessionStore.authProviderKey) ??
        inferAuthProvider(active);

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

    final url = '$baseUrl/auth/firebase';
    debugPrint('ChurchApi: POST $url (provider=$provider)');
    return refreshAccountWithFirebaseToken(
      token,
      provider: provider,
      name: active.displayName,
    );
  }

  /// Profile: always tries server sync first, then cache / local prefs.
  static Future<ProfileLoadResult> loadProfileAccount() async {
    final user = await waitForSignedInUser();

    Future<Map<String, dynamic>?> localFallback() async {
      final cached = await getCachedAccountJson();
      if (cached != null) return cached;
      return accountFromLocalPrefs(user);
    }

    if (user == null) {
      final local = await localFallback();
      return ProfileLoadResult(
        account: local,
        syncedFromServer: false,
        error: local == null ? 'Not signed in' : 'Not signed in — showing saved data only',
      );
    }

    try {
      final account = await syncCurrentUserAccount();
      final prefs = await SharedPreferences.getInstance();
      final provider =
          prefs.getString('authProvider') ?? inferAuthProvider(user);
      await persistAccountFromServer(account, provider: provider);
      return ProfileLoadResult(
        account: account,
        syncedFromServer: true,
      );
    } catch (e, st) {
      debugPrint('ChurchApi.loadProfileAccount sync failed: $e\n$st');
      final local = await localFallback();
      return ProfileLoadResult(
        account: local,
        syncedFromServer: false,
        error: e.toString(),
      );
    }
  }

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

    final uri = Uri.parse('$baseUrl/auth/firebase');
    final r = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: json.encode(body),
        )
        .timeout(const Duration(seconds: 30));

    debugPrint('ChurchApi: POST ${uri.path} -> ${r.statusCode}');
    if (r.statusCode != 200) {
      throw Exception('auth/firebase failed: ${r.statusCode} ${r.body}');
    }
    final map = json.decode(r.body) as Map<String, dynamic>;
    await persistAccountFromServer(map, provider: provider);
    return map;
  }

  static int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? 0;
  }

  /// Shapes [AuthAccount] JSON for [AttendanceSheet] (dashboard lightning modal).
  static Map<String, dynamic> accountToAttendanceSheetData(Map<String, dynamic> a) {
    return {
      'attendanceStreak': {
        'streakLabel': 'Current streak',
        'currentStreak': _asInt(a['currentStreak']),
        'totalLabel': 'Total attendances',
        'totalAttendance': _asInt(a['totalAttendance']),
        'bestLabel': 'Longest streak',
        'bestStreak': _asInt(a['longestStreak']),
        'absences': _asInt(a['totalAbsences']),
        'absenceStreak': _asInt(a['absenceStreak']),
      },
    };
  }

  static Future<Map<String, dynamic>> getCurrentVerse() async {
    final r = await http.get(Uri.parse('$baseUrl/weekly-verse/current'));
    if (r.statusCode != 200) {
      throw Exception('weekly-verse/current failed: ${r.statusCode}');
    }
    return json.decode(r.body) as Map<String, dynamic>;
  }

  /// Dashboard highlight rail — `GET /events/top4` (EventInstance list).
  static Future<List<dynamic>> getTop4Events() async {
    final r = await http.get(Uri.parse('$baseUrl/events/top4'));
    if (r.statusCode != 200) {
      throw Exception('events/top4 failed: ${r.statusCode}');
    }
    return json.decode(r.body) as List<dynamic>;
  }

  /// Uses **top4** when non-empty; otherwise first **4** of **upcoming** (sorted by date).
  /// This covers backends where `top4` is empty or not populated yet.
  static Future<List<dynamic>> getDashboardEventInstances() async {
    try {
      final top = await getTop4Events();
      if (top.isNotEmpty) return top;
    } catch (_) {
      // Fall through to upcoming
    }
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

  /// Full upcoming list for the Events tab — `GET /events/upcoming`.
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

  /// Normalizes [EventInstance] JSON into a row for UI lists.
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
