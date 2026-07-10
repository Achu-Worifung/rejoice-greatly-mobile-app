import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../notifications/notification_service.dart';
import 'api_envelope.dart';
import 'user_facing_error.dart';
import 'user_session_store.dart';

/// Thrown by [ChurchApi.nfcCheckin] when the server responds with a non-200
/// status. Unlike the generic exceptions [ChurchApi.postJson] throws, this
/// preserves the HTTP status and the envelope's `errorCode`/`message` so the
/// caller can distinguish 401 (re-login) from 404 (unrecognized tag) etc.
class ChurchApiException implements Exception {
  const ChurchApiException(
    this.statusCode, {
    this.errorCode,
    this.serverMessage,
  });

  final int statusCode;
  final String? errorCode;
  final String? serverMessage;

  @override
  String toString() =>
      'ChurchApiException($statusCode, errorCode: $errorCode, message: $serverMessage)';
}

/// Thrown when the signed-in account can no longer authenticate because it has
/// been deleted or disabled server-side — e.g. the church team actioned an
/// account-deletion request and removed the member's Firebase user.
///
/// Distinct from a transient network failure: callers should sign the member
/// out (routing them to login) rather than fall back to cached data, since the
/// account no longer exists.
class SessionInvalidException implements Exception {
  const SessionInvalidException(this.reason);

  /// A short machine-readable cause, e.g. `firebase:user-not-found` or
  /// `auth/firebase:404`, for logs.
  final String reason;

  @override
  String toString() => 'SessionInvalidException($reason)';
}

/// Result of restoring session on cold start.
class SessionRestoreResult {
  const SessionRestoreResult({
    required this.loggedIn,
    this.signupComplete = false,
    this.account,
    this.syncedFromServer = false,
    this.sessionInvalid = false,
  });

  final bool loggedIn;
  final bool signupComplete;
  final Map<String, dynamic>? account;
  final bool syncedFromServer;

  /// True when the restore failed because the account was deleted/disabled
  /// (a [SessionInvalidException]), as opposed to being offline. The caller
  /// should complete a full sign-out.
  final bool sessionInvalid;
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
    this.cachedAt,
  });

  final Map<String, dynamic>? profile;
  final bool hasProfile;
  final Map<String, dynamic>? stats;
  final List<Map<String, dynamic>> activities;
  final bool profileSynced;
  final bool statsSynced;
  final bool attendanceSynced;
  final String? error;

  /// Non-null when the result was served from the local cache rather than the
  /// server. Indicates when the data was last fetched from the server.
  final DateTime? cachedAt;
}

class ChurchApi {
  ChurchApi._();

  /// One client for every backend call, so requests reuse a kept-alive
  /// connection. The top-level `http.get`/`http.post` helpers open and close a
  /// fresh client each time, which on a phone means a new TCP + TLS handshake
  /// in front of every request.
  static final http.Client httpClient = http.Client();

  /// Backend origin from `.env`. Debug builds fall back to a LAN dev server so
  /// `flutter run` works without a `.env`; release builds must be configured
  /// (CI writes `.env` from secrets) and fail loudly rather than silently
  /// talking to a machine on someone's home network.
  static String get baseUrl {
    final configured = dotenv.env['BASE_URL'];
    if (configured != null && configured.isNotEmpty) return configured;
    if (kDebugMode) return 'http://192.168.0.166:8080';
    throw StateError(
      'BASE_URL is not set. Release builds require it in the bundled .env.',
    );
  }

  static bool isSignupComplete(Map<String, dynamic>? account) =>
      UserSessionStore.isSignupComplete(account);

  /// Whether this member is under 18. Minors never enrol a face: they check in
  /// with an NFC tag, cannot upload a photo, and wear an initials avatar.
  static bool isMinorAccount(Map<String, dynamic>? account) =>
      UserSessionStore.isMinor(account);

  /// Whether a date of birth is already on the account. Once it is, the age
  /// gate has been answered — a member who provided it and then deferred face
  /// setup should not be re-onboarded through the birthday screen on every cold
  /// start.
  static bool accountHasDateOfBirth(Map<String, dynamic>? account) {
    final dob = account?['dateOfBirth'];
    return dob is String && dob.trim().isNotEmpty;
  }

  /// Whether the member may set a profile photo. Minors may not — no photo of
  /// an under-18 member is collected (the backend refuses the upload too).
  static bool canUploadPhoto(Map<String, dynamic>? account) {
    if (account != null && account.containsKey('canUploadPhoto')) {
      return UserSessionStore.asBool(account['canUploadPhoto']);
    }
    return !isMinorAccount(account);
  }

  static bool hasMemberProfile(Map<String, dynamic>? profile) {
    if (profile == null) return false;
    if (profile.containsKey('hasProfile') &&
        UserSessionStore.asBool(profile['hasProfile'])) {
      return true;
    }
    // A stale/clobbered `hasProfile: false` must not hide a finished profile,
    // so fall back to deriving it from the fields that define one. A minor has
    // no photo to define it with — for them finishing the age gate is the whole
    // of onboarding, so signup being complete is enough.
    if (!isSignupComplete(profile)) return false;
    if (isMinorAccount(profile)) return true;
    final img = profile['imgURL'];
    return img is String && img.trim().isNotEmpty;
  }

  static Future<void> persistAccountFromServer(
    Map<String, dynamic> account, {
    String? provider,
  }) => UserSessionStore.saveAccount(account, provider: provider);

  /// Marks onboarding finished on-device without a facial scan — used when an
  /// age-gated minor or a member who chose "no thanks" skips face setup.
  ///
  /// The backend only records `signupComplete` after a photo commit, so this
  /// flag lives on-device; [restoreUserSession] keeps it sticky across cold
  /// starts. The member can still add a photo later from their profile.
  static Future<void> markSignupCompleteLocally() =>
      persistAccountFromServer(const {'signupComplete': true});

  /// `POST /member/date-of-birth` — records the date of birth collected at the
  /// onboarding gate and returns the refreshed profile.
  ///
  /// For a member under 18 the server also marks signup complete: they never
  /// enrol a face, so there is no photo commit later to do it. The response
  /// (`minor`, `signupComplete`, `hasProfile`, `canUploadPhoto`) is cached, so
  /// the rest of the app can branch on it without another round trip.
  static Future<Map<String, dynamic>> saveDateOfBirth(DateTime dob) async {
    final iso = DateFormat('yyyy-MM-dd').format(dob);
    final map = await _postMember('date-of-birth', {'dateOfBirth': iso});
    await _mergeIntoCachedAccount(map);
    return map;
  }

  /// The date of birth already on file, or null before the gate is passed.
  static Future<DateTime?> cachedDateOfBirth() =>
      UserSessionStore.readDateOfBirth();

  static Future<SessionRestoreResult> restoreUserSession() async {
    final user = await waitForSignedInUser(timeout: const Duration(seconds: 5));
    if (user == null) {
      return const SessionRestoreResult(loggedIn: false);
    }

    final cached = await getCachedAccountJson();
    final local = cached ?? await accountFromLocalPrefs(user);
    // Captured before the sync below, which may overwrite the on-device flag
    // with the server's copy.
    final locallyComplete = await UserSessionStore.readSignupComplete();

    try {
      final auth = await syncAuthAccount();
      final prefs = await SharedPreferences.getInstance();
      final provider =
          prefs.getString(UserSessionStore.authProviderKey) ??
          inferAuthProvider(user);
      await persistAccountFromServer(auth, provider: provider);

      final firebaseUid = auth['firebaseUid'] ?? '';
      if ('$firebaseUid'.isNotEmpty) {
        // Fire-and-forget: re-links this device's push subscription to the
        // user on every silent session restore (e.g. after a reinstall),
        // not just interactive sign-in.
        NotificationService().login('$firebaseUid', email: user.email);
      }

      // A member who finished onboarding without a facial scan (age-gated
      // minor, or an explicit "no thanks") is only marked complete on-device —
      // the backend records signupComplete after a photo commit. Keep that
      // local decision sticky so a cold start doesn't re-onboard them.
      final complete = isSignupComplete(auth) || locallyComplete;
      if (complete && !isSignupComplete(auth)) {
        await persistAccountFromServer(const {
          'signupComplete': true,
        }, provider: provider);
      }

      return SessionRestoreResult(
        loggedIn: true,
        signupComplete: complete,
        account: auth,
        syncedFromServer: true,
      );
    } on SessionInvalidException catch (e) {
      // The account was deleted/disabled server-side. Don't fall back to the
      // cached session — report it so the caller completes a full sign-out.
      debugPrint('ChurchApi restoreUserSession: account no longer valid ($e)');
      return const SessionRestoreResult(loggedIn: false, sessionInvalid: true);
    } catch (e, st) {
      // Transient (offline, server error): keep the member signed in on cache.
      debugPrint('ChurchApi restoreUserSession auth sync failed: $e\n$st');
    }

    return SessionRestoreResult(
      loggedIn: true,
      signupComplete: locallyComplete,
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

  static Future<String?> resolveProfileImageUrl({
    Map<String, dynamic>? account,
  }) => UserSessionStore.readProfileImageUrl(account: account);

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
    final tokenBundle = await requireIdToken();
    final prefs = await SharedPreferences.getInstance();
    final provider =
        prefs.getString(UserSessionStore.authProviderKey) ??
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
  static Future<List<Map<String, dynamic>>>
  fetchMemberAttendanceHistory() async {
    final map = await _postMember('attendance/history', const {});
    await _mergeIntoCachedAccount(map);
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

    // Reuse the me-page cache when it is still within the weekly TTL.
    final cachedAt = await UserSessionStore.readMePageCachedAt();
    if (cachedAt != null && _memberCacheIsFresh(cachedAt)) {
      final cached = await getCachedAccountJson();
      if (cached != null) {
        return ProfileLoadResult(
          profile: cached,
          hasProfile: hasMemberProfile(cached),
          syncedFromServer: false,
        );
      }
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
        error: userFacingError(e),
      );
    }
  }

  static Future<MemberStatsResult> loadMemberStats() async {
    // Reuse the me-page cache when it is still within the weekly TTL.
    final cachedAt = await UserSessionStore.readMePageCachedAt();
    if (cachedAt != null && _memberCacheIsFresh(cachedAt)) {
      final cached = await getCachedAccountJson();
      if (cached != null && cached.containsKey('currentStreak')) {
        return MemberStatsResult(
          stats: _statsFromAccountMap(cached),
          syncedFromServer: false,
        );
      }
    }

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
          error: userFacingError(e),
        );
      }
      return MemberStatsResult(
        syncedFromServer: false,
        error: userFacingError(e),
      );
    }
  }

  static const Duration _mePageCacheDuration = Duration(days: 7);

  /// Whether locally cached member data (profile, stats, streak) is still fresh
  /// enough to serve without a network call.
  ///
  /// Sundays always miss: attendance is taken on the service day, so the Me page
  /// and the streak/attendance display must reflect today's check-in rather than
  /// a stale weekly snapshot. Every other day the weekly TTL applies.
  static bool _memberCacheIsFresh(DateTime cachedAt) {
    if (DateTime.now().weekday == DateTime.sunday) return false;
    return DateTime.now().difference(cachedAt) < _mePageCacheDuration;
  }

  static List<Map<String, dynamic>> _activitiesFromAccount(
    Map<String, dynamic> account,
  ) {
    final raw = account['recentAttendance'];
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  /// Loads the Me page data.
  ///
  /// Returns cached data immediately when the last server sync is less than
  /// [_mePageCacheDuration] old, skipping all network calls. Sundays always
  /// refresh from the server (see [_memberCacheIsFresh]).
  /// Pass [forceRefresh] to bypass the cache (e.g. pull-to-refresh).
  static Future<MePageLoadResult> loadMePage({
    bool forceRefresh = false,
  }) async {
    final user = await waitForSignedInUser();
    if (user == null) {
      return const MePageLoadResult(error: 'Not signed in');
    }

    if (!forceRefresh) {
      final cachedAt = await UserSessionStore.readMePageCachedAt();
      if (cachedAt != null && _memberCacheIsFresh(cachedAt)) {
        final cached = await getCachedAccountJson();
        if (cached != null) {
          final hasProfile = hasMemberProfile(cached);
          return MePageLoadResult(
            profile: cached,
            hasProfile: hasProfile,
            // Stats show for NFC-only members too, so they are read from cache
            // regardless of whether the photo step is finished.
            stats: _statsFromAccountMap(cached),
            activities: _activitiesFromAccount(cached),
            cachedAt: cachedAt,
          );
        }
      }
    }

    try {
      await syncAuthAccount();
    } catch (e, st) {
      debugPrint('ChurchApi.loadMePage auth failed: $e\n$st');
      final cached = await getCachedAccountJson();
      return MePageLoadResult(
        profile: cached,
        hasProfile: hasMemberProfile(cached),
        error: userFacingError(e),
      );
    }

    try {
      final profile = await fetchMemberProfile();
      final hasProfile = hasMemberProfile(profile);

      // Stats and attendance are fetched even when the profile is unfinished:
      // an eligible member who checks in with the NFC tag (rather than enrolling
      // their face) still accrues a record, and the My Profile page shows it to
      // them alongside the "finish signup" prompt.
      Map<String, dynamic>? stats;
      List<Map<String, dynamic>> activities = [];
      var statsSynced = false;
      var attendanceSynced = false;
      String? partialError;

      // Stats and history are independent, so fetch them side by side rather
      // than paying for two sequential round-trips. Each handles its own
      // failure, so one erroring can't surface unhandled while the other runs.
      Future<void> loadStats() async {
        try {
          stats = await fetchMemberStats();
          statsSynced = true;
        } catch (e, st) {
          debugPrint('ChurchApi.loadMePage stats failed: $e\n$st');
          // A stats failure is the one reported, even if history failed first.
          partialError = userFacingError(e);
          final cached = await getCachedAccountJson();
          if (cached != null) stats = _statsFromAccountMap(cached);
        }
      }

      Future<void> loadHistory() async {
        try {
          activities = await fetchMemberAttendanceHistory();
          attendanceSynced = true;
        } catch (e, st) {
          debugPrint('ChurchApi.loadMePage attendance failed: $e\n$st');
          partialError ??= userFacingError(e);
        }
      }

      await Future.wait([loadStats(), loadHistory()]);

      await UserSessionStore.saveMePageCachedAt(DateTime.now());
      return MePageLoadResult(
        profile: profile,
        hasProfile: hasProfile,
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
        error: userFacingError(e),
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
    final body = <String, dynamic>{'idToken': idToken, 'provider': provider};
    if (name != null) body['name'] = name;

    // Not routed through [postJson] so a "no such account" status can be told
    // apart from a transient failure and surfaced as a [SessionInvalidException].
    final uri = Uri.parse('$baseUrl/auth/firebase');
    final r = await httpClient
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: json.encode(body),
        )
        .timeout(_httpTimeout);

    debugPrint('ChurchApi: POST /auth/firebase -> ${r.statusCode}');
    if (r.statusCode == 401 || r.statusCode == 403 || r.statusCode == 404) {
      throw SessionInvalidException('auth/firebase:${r.statusCode}');
    }
    if (r.statusCode != 200) {
      throw _failure(r);
    }

    final Map<String, dynamic> map;
    try {
      map = unwrapApiMap(r.body);
    } on FormatException {
      throw ChurchApiException(r.statusCode);
    }
    await _mergeIntoCachedAccount(map);
    return map;
  }

  /// Tail of the queue of pending [_mergeIntoCachedAccount] writes.
  static Future<void> _accountMergeQueue = Future.value();

  /// Merges [incoming] into the cached account. Merges are queued one after
  /// another: each is a read-modify-write of the same stored map, so two
  /// responses landing together (the Me page fetches stats and history in
  /// parallel) would otherwise each overwrite the other's fields.
  static Future<void> _mergeIntoCachedAccount(Map<String, dynamic> incoming) {
    final merge = _accountMergeQueue.then(
      (_) => _mergeIntoCachedAccountNow(incoming),
    );
    // A failed merge must not wedge every later one behind it.
    _accountMergeQueue = merge.catchError((Object _) {});
    return merge;
  }

  static Future<void> _mergeIntoCachedAccountNow(
    Map<String, dynamic> incoming,
  ) async {
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
    final tokenBundle = await requireIdToken();
    final body = <String, dynamic>{'idToken': tokenBundle.token, ...extra};
    return postJson('/member/$path', body);
  }

  static const Duration _httpTimeout = Duration(seconds: 30);

  /// `POST /attendance/nfc/checkin` — marks the signed-in member present for
  /// today from a [tagId] read off a physical NFC tag.
  ///
  /// Follows the same body-auth convention as the `/member/**` calls: the
  /// Firebase id token travels in the JSON body, not a Bearer header. Returns
  /// the unwrapped success `data` map (`message`, `name`, `attendedAt`,
  /// `alreadyPresent`). Throws [ChurchApiException] carrying the HTTP status on
  /// a non-200 response so the caller can react to 401/404 distinctly.
  static Future<Map<String, dynamic>> nfcCheckin(String tagId) async {
    final tokenBundle = await requireIdToken();
    final uri = Uri.parse('$baseUrl/attendance/nfc/checkin');
    final r = await httpClient
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'idToken': tokenBundle.token, 'tagId': tagId}),
        )
        .timeout(_httpTimeout);

    debugPrint('ChurchApi: POST ${uri.path} -> ${r.statusCode}');
    if (r.statusCode == 200) {
      try {
        return unwrapApiMap(r.body);
      } on FormatException {
        throw const ChurchApiException(
          200,
          serverMessage: 'The server returned an invalid response.',
        );
      }
    }

    throw _failure(r);
  }

  /// A non-200 response as a [ChurchApiException], keeping the status and the
  /// envelope's `message`/`errorCode` but never the URL or raw body — the
  /// exception's text can end up on screen.
  static ChurchApiException _failure(http.Response r) {
    debugPrint('ChurchApi: ${r.request?.url.path} failed ${r.statusCode}');
    // Error envelope: `message`/`errorCode` sit at the top level with a null
    // `data`, so decode the raw body rather than unwrapping it.
    String? message;
    String? errorCode;
    try {
      final decoded = json.decode(r.body);
      if (decoded is Map) {
        message = decoded['message'] as String?;
        errorCode = decoded['errorCode'] as String?;
      }
    } catch (_) {
      // Non-JSON error body; fall through with nulls.
    }
    return ChurchApiException(
      r.statusCode,
      errorCode: errorCode,
      serverMessage: message,
    );
  }

  static Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, dynamic> body,
  ) async {
    final uri = Uri.parse('$baseUrl$path');
    final r = await httpClient
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: json.encode(body),
        )
        .timeout(_httpTimeout);

    debugPrint('ChurchApi: POST ${uri.path} -> ${r.statusCode}');
    if (r.statusCode != 200) {
      throw _failure(r);
    }
    try {
      return unwrapApiMap(r.body);
    } on FormatException {
      throw ChurchApiException(r.statusCode);
    }
  }

  /// Firebase auth error codes that mean the account can no longer
  /// authenticate — it was deleted or disabled, or its sessions were revoked
  /// (which Firebase also does when a user is deleted). These map to a
  /// [SessionInvalidException] so the caller signs the member out instead of
  /// retrying or serving stale cache. `network-request-failed` and the like
  /// are deliberately excluded — those are transient.
  static const Set<String> accountGoneAuthCodes = {
    'user-disabled',
    'user-not-found',
    'user-token-expired',
    'user-token-revoked',
    'invalid-user-token',
    'user-mismatch',
  };

  /// Forces a fresh Firebase ID token, translating a "this account is gone"
  /// [FirebaseAuthException] into a [SessionInvalidException]. A non-terminal
  /// failure (e.g. offline) is retried once without the force-refresh so a
  /// still-valid cached token can be used.
  static Future<String> forceFreshIdToken(User user) async {
    try {
      final token = await user.getIdToken(true);
      if (token == null || token.isEmpty) {
        throw StateError('Could not obtain Firebase id token');
      }
      return token;
    } on FirebaseAuthException catch (e) {
      if (accountGoneAuthCodes.contains(e.code)) {
        throw SessionInvalidException('firebase:${e.code}');
      }
      debugPrint('ChurchApi: getIdToken(true) failed (${e.code}), retrying');
      final token = await user.getIdToken();
      if (token == null || token.isEmpty) {
        throw StateError('Could not obtain Firebase id token');
      }
      return token;
    }
  }

  /// How long a token from [requireIdToken] is handed out again before the
  /// next call goes back to Firebase.
  ///
  /// Each fresh token costs two Firebase round-trips (a user reload and a
  /// forced refresh) before the actual API call even starts, and one screen
  /// can make several member calls in a row — the Me page makes four. Within
  /// this window those calls share one token; the backend still verifies it
  /// (revocation included) on every request.
  static const Duration _idTokenReuseWindow = Duration(seconds: 60);

  static ({User user, String token, DateTime issuedAt})? _recentIdToken;
  static Future<({User user, String token})>? _idTokenInFlight;

  /// Public so sibling services (e.g. [ProfilePictureUpload]) can reuse the
  /// reload-and-retry behaviour rather than reimplementing it.
  static Future<({User user, String token})> requireIdToken() {
    final recent = _recentIdToken;
    final current = FirebaseAuth.instance.currentUser;
    if (recent != null &&
        current != null &&
        current.uid == recent.user.uid &&
        DateTime.now().difference(recent.issuedAt) < _idTokenReuseWindow) {
      return Future.value((user: recent.user, token: recent.token));
    }
    // Calls that start together (e.g. parallel fetches) share one refresh.
    return _idTokenInFlight ??= _requireFreshIdToken().whenComplete(() {
      _idTokenInFlight = null;
    });
  }

  static Future<({User user, String token})> _requireFreshIdToken() async {
    _recentIdToken = null;
    final user = await waitForSignedInUser();
    if (user == null) {
      throw StateError('Not signed in to Firebase');
    }

    try {
      await user.reload();
    } on FirebaseAuthException catch (e) {
      // A reload that reports the user is gone is itself a deletion signal.
      if (accountGoneAuthCodes.contains(e.code)) {
        throw SessionInvalidException('firebase:${e.code}');
      }
      debugPrint('ChurchApi: user.reload() failed (continuing): $e');
    } catch (e) {
      debugPrint('ChurchApi: user.reload() failed (continuing): $e');
    }

    final active = FirebaseAuth.instance.currentUser ?? user;
    final token = await forceFreshIdToken(active);
    _recentIdToken = (user: active, token: token, issuedAt: DateTime.now());
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

  static Map<String, dynamic> statsToAttendanceSheetData(
    Map<String, dynamic> stats,
  ) {
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
  static Map<String, dynamic> accountToAttendanceSheetData(
    Map<String, dynamic> a,
  ) => statsToAttendanceSheetData(a);

  static void invalidateHomeCache() {
    _verseCache = null;
    _verseCachedAt = null;
    _sermonsCache = null;
    _sermonsCachedAt = null;
    _latestSermonCache = null;
    _latestSermonCachedAt = null;
    _dashboardEventsCache = null;
    _dashboardEventsCachedAt = null;
  }

  // --- In-memory caches for home data (1-hour TTL) ---
  static const Duration _homeCacheDuration = Duration(hours: 1);

  static Map<String, dynamic>? _verseCache;
  static DateTime? _verseCachedAt;

  static List<dynamic>? _sermonsCache;
  static DateTime? _sermonsCachedAt;

  static List<dynamic>? _latestSermonCache;
  static DateTime? _latestSermonCachedAt;

  static List<dynamic>? _dashboardEventsCache;
  static DateTime? _dashboardEventsCachedAt;

  static Future<Map<String, dynamic>> getCurrentVerse() async {
    final cachedAt = _verseCachedAt;
    if (_verseCache != null &&
        cachedAt != null &&
        DateTime.now().difference(cachedAt) < _homeCacheDuration) {
      return _verseCache!;
    }
    final r = await httpClient
        .get(Uri.parse('$baseUrl/weekly-verse/current'))
        .timeout(_httpTimeout);
    if (r.statusCode != 200) {
      throw _failure(r);
    }
    final data = unwrapApiMap(r.body);
    _verseCache = data;
    _verseCachedAt = DateTime.now();
    return data;
  }

  static Future<List<dynamic>> getTop4Events() async {
    final r = await httpClient
        .get(Uri.parse('$baseUrl/events/top4'))
        .timeout(_httpTimeout);
    if (r.statusCode != 200) {
      throw _failure(r);
    }
    return unwrapApiList(r.body);
  }

  static Future<List<dynamic>> getDashboardEventInstances() async {
    final cachedAt = _dashboardEventsCachedAt;
    if (_dashboardEventsCache != null &&
        cachedAt != null &&
        DateTime.now().difference(cachedAt) < _homeCacheDuration) {
      return _dashboardEventsCache!;
    }
    List<dynamic> result;
    try {
      final top = await getTop4Events();
      if (top.isNotEmpty) {
        result = top;
      } else {
        result = await _fetchUpcoming4();
      }
    } catch (_) {
      result = await _fetchUpcoming4();
    }
    _dashboardEventsCache = result;
    _dashboardEventsCachedAt = DateTime.now();
    return result;
  }

  static Future<List<dynamic>> _fetchUpcoming4() async {
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
    return list.length <= 4 ? list : list.sublist(0, 4);
  }

  static Future<List<dynamic>> getUpcomingEvents() async {
    final r = await httpClient
        .get(Uri.parse('$baseUrl/events/upcoming'))
        .timeout(_httpTimeout);
    if (r.statusCode != 200) {
      throw _failure(r);
    }
    final list = unwrapApiList(r.body);
    if (list.isNotEmpty) return list;
    // Fall back to top4 when the upcoming endpoint returns nothing.
    return getTop4Events();
  }

  static Future<List<dynamic>> getSermons() async {
    final cachedAt = _sermonsCachedAt;
    if (_sermonsCache != null &&
        cachedAt != null &&
        DateTime.now().difference(cachedAt) < _homeCacheDuration) {
      return _sermonsCache!;
    }
    final r = await httpClient
        .get(Uri.parse('$baseUrl/sermons'))
        .timeout(_httpTimeout);
    if (r.statusCode != 200) {
      throw _failure(r);
    }
    final data = unwrapApiList(r.body);
    _sermonsCache = data;
    _sermonsCachedAt = DateTime.now();
    return data;
  }

  /// The newest sermon, for the dashboard card — asks the server for one
  /// (`?limit=1`) instead of downloading the whole library. Reuses the full
  /// list when the sermons page has already loaded it. A backend without the
  /// `limit` parameter returns everything, which callers sort anyway.
  static Future<List<dynamic>> getLatestSermons() async {
    final now = DateTime.now();
    final fullAt = _sermonsCachedAt;
    if (_sermonsCache != null &&
        fullAt != null &&
        now.difference(fullAt) < _homeCacheDuration) {
      return _sermonsCache!;
    }
    final latestAt = _latestSermonCachedAt;
    if (_latestSermonCache != null &&
        latestAt != null &&
        now.difference(latestAt) < _homeCacheDuration) {
      return _latestSermonCache!;
    }
    final r = await httpClient
        .get(Uri.parse('$baseUrl/sermons?limit=1'))
        .timeout(_httpTimeout);
    if (r.statusCode != 200) {
      throw _failure(r);
    }
    final data = unwrapApiList(r.body);
    _latestSermonCache = data;
    _latestSermonCachedAt = DateTime.now();
    return data;
  }

  static Future<Map<String, dynamic>> getSermonById(Object id) async {
    final r = await httpClient
        .get(Uri.parse('$baseUrl/sermons/$id'))
        .timeout(_httpTimeout);
    if (r.statusCode != 200) {
      throw _failure(r);
    }
    return unwrapApiMap(r.body);
  }

  static List<Map<String, dynamic>> mapEventInstances(List<dynamic> list) {
    final out = <Map<String, dynamic>>[];
    for (final e in list) {
      if (e is! Map) continue;
      final m = Map<String, dynamic>.from(e);
      if (m['cancelled'] == true || m['is_cancelled'] == true) continue;
      final t = m['template'] is Map
          ? Map<String, dynamic>.from(m['template'] as Map)
          : <String, dynamic>{};
      final dateStr = m['date'] as String? ?? '';
      if (dateStr.isEmpty) continue;
      out.add({
        'title': (t['title'] as String?)?.trim().isNotEmpty == true
            ? t['title'] as String
            : (m['title'] as String?) ?? 'Church event',
        'time': _formatTime(
          (m['specificTime'] ?? m['specific_time']) as String?,
          (t['defaultTime'] ?? t['default_time']) as String?,
        ),
        'date': dateStr.length >= 10 ? dateStr.substring(0, 10) : dateStr,
        'location': t['location'] ?? '',
        'imageUrl': (t['posterUrl'] ?? t['poster_url']) as String?,
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
