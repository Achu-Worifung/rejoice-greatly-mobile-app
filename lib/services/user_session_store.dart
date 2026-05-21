import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local persistence for logged-in member data (survives app restarts).
class UserSessionStore {
  UserSessionStore._();

  static const String accountJsonKey = 'account_json';
  static const String firebaseUidKey = 'firebaseUid';
  static const String nameKey = 'name';
  static const String emailKey = 'email';
  static const String imgUrlKey = 'imgURL';
  static const String authProviderKey = 'authProvider';
  static const String signupCompleteKey = 'signupComplete';
  static const String isAdminKey = 'isAdmin';

  static SharedPreferences? _prefs;

  /// Call once from [main] before [runApp].
  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _prefs!.reload();
    if (kDebugMode) {
      final hasAccount = _prefs!.containsKey(accountJsonKey);
      final name = _prefs!.getString(nameKey);
      debugPrint(
        'UserSessionStore: init (account_json=$hasAccount, name=${name ?? "null"})',
      );
    }
  }

  static Future<SharedPreferences> _p() async {
    if (_prefs != null) {
      await _prefs!.reload();
      return _prefs!;
    }
    _prefs = await SharedPreferences.getInstance();
    await _prefs!.reload();
    return _prefs!;
  }

  static bool asBool(dynamic v) {
    if (v is bool) return v;
    if (v is num) return v != 0;
    final s = v?.toString().toLowerCase();
    return s == 'true' || s == '1';
  }

  static int asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? 0;
  }

  static bool isSignupComplete(Map<String, dynamic>? account) {
    if (account != null && account.containsKey(signupCompleteKey)) {
      return asBool(account[signupCompleteKey]);
    }
    return false;
  }

  /// Normalizes API maps so [json.encode] never fails and keys are consistent.
  static Map<String, dynamic> sanitizeAccount(Map<String, dynamic> raw) {
    String? str(dynamic v) {
      if (v == null) return null;
      final s = v.toString().trim();
      return s.isEmpty ? null : s;
    }

    return {
      if (str(raw['firebaseUid']) != null) 'firebaseUid': str(raw['firebaseUid']),
      if (str(raw['name']) != null) 'name': str(raw['name']),
      if (str(raw['email']) != null) 'email': str(raw['email']),
      if (str(raw['imgURL']) != null) 'imgURL': str(raw['imgURL']),
      'admin': asBool(raw['admin']),
      'signupComplete': asBool(raw['signupComplete']),
      'currentStreak': asInt(raw['currentStreak']),
      'longestStreak': asInt(raw['longestStreak']),
      'totalAttendance': asInt(raw['totalAttendance']),
      'totalAbsences': asInt(raw['totalAbsences']),
      'absenceStreak': asInt(raw['absenceStreak']),
    };
  }

  static Map<String, dynamic> mergeAccounts(
    Map<String, dynamic>? existing,
    Map<String, dynamic> incoming,
  ) {
    final out = existing != null
        ? Map<String, dynamic>.from(existing)
        : <String, dynamic>{};
    final clean = sanitizeAccount(incoming);
    for (final e in clean.entries) {
      out[e.key] = e.value;
    }
    return out;
  }

  /// Writes account JSON + individual fields. Merges with existing cache when present.
  static Future<void> saveAccount(
    Map<String, dynamic> account, {
    String? provider,
    bool mergeWithExisting = true,
  }) async {
    final existing = mergeWithExisting ? await loadAccount() : null;
    final merged = mergeWithExisting
        ? mergeAccounts(existing, account)
        : sanitizeAccount(account);

    final encoded = json.encode(merged);
    final p = await _p();

    await p.setString(accountJsonKey, encoded);
    if (merged['firebaseUid'] != null) {
      await p.setString(firebaseUidKey, '${merged['firebaseUid']}');
    }
    if (merged['name'] != null) {
      await p.setString(nameKey, '${merged['name']}');
    }
    if (merged['email'] != null) {
      await p.setString(emailKey, '${merged['email']}');
    }
    if (merged['imgURL'] != null) {
      await p.setString(imgUrlKey, '${merged['imgURL']}');
    }
    if (provider != null && provider.isNotEmpty) {
      await p.setString(authProviderKey, provider);
    }
    await p.setBool(isAdminKey, asBool(merged['admin']));
    await p.setBool(signupCompleteKey, isSignupComplete(merged));
    await p.setInt('currentStreak', asInt(merged['currentStreak']));
    await p.setInt('longestStreak', asInt(merged['longestStreak']));
    await p.setInt('totalAttendance', asInt(merged['totalAttendance']));
    await p.setInt('totalAbsences', asInt(merged['totalAbsences']));
    await p.setInt('absenceStreak', asInt(merged['absenceStreak']));

    await p.reload();

    if (kDebugMode) {
      final ok = await hasPersistedSession();
      debugPrint('UserSessionStore.saveAccount: persisted=$ok bytes=${encoded.length}');
    }
  }

  static Future<Map<String, dynamic>?> loadAccount() async {
    final p = await _p();
    final s = p.getString(accountJsonKey);
    if (s != null && s.isNotEmpty) {
      try {
        return Map<String, dynamic>.from(json.decode(s) as Map);
      } catch (e) {
        debugPrint('UserSessionStore: corrupt account_json: $e');
      }
    }
    return buildAccountFromFields();
  }

  /// Rebuild account from per-field prefs when JSON blob is missing.
  static Future<Map<String, dynamic>?> buildAccountFromFields() async {
    final p = await _p();
    final name = p.getString(nameKey);
    final email = p.getString(emailKey);
    final uid = p.getString(firebaseUidKey);
    if ((name == null || name.isEmpty) &&
        (email == null || email.isEmpty) &&
        (uid == null || uid.isEmpty)) {
      return null;
    }

    final user = FirebaseAuth.instance.currentUser;
    return {
      if (uid != null && uid.isNotEmpty) 'firebaseUid': uid,
      'name': (name != null && name.isNotEmpty)
          ? name
          : (user?.displayName?.isNotEmpty == true ? user!.displayName! : 'Member'),
      'email': (email != null && email.isNotEmpty) ? email : (user?.email ?? ''),
      if (p.getString(imgUrlKey) != null) 'imgURL': p.getString(imgUrlKey),
      'signupComplete': p.getBool(signupCompleteKey) ?? false,
      'admin': p.getBool(isAdminKey) ?? false,
      'currentStreak': p.getInt('currentStreak') ?? 0,
      'longestStreak': p.getInt('longestStreak') ?? 0,
      'totalAttendance': p.getInt('totalAttendance') ?? 0,
      'totalAbsences': p.getInt('totalAbsences') ?? 0,
      'absenceStreak': p.getInt('absenceStreak') ?? 0,
    };
  }

  static Future<bool> hasPersistedSession() async {
    final account = await loadAccount();
    if (account != null && (account['name'] != null || account['email'] != null)) {
      return true;
    }
    final p = await _p();
    return (p.getString(nameKey)?.isNotEmpty ?? false) ||
        (p.getString(firebaseUidKey)?.isNotEmpty ?? false);
  }

  static Future<bool> readSignupComplete() async {
    final p = await _p();
    final fromFlag = p.getBool(signupCompleteKey) ?? false;
    if (fromFlag) return true;
    final account = await loadAccount();
    return isSignupComplete(account);
  }

  static Future<String?> readProfileImageUrl({Map<String, dynamic>? account}) async {
    final img = account?['imgURL'];
    if (img is String && img.trim().isNotEmpty) return img.trim();

    final loaded = account ?? await loadAccount();
    final fromAccount = loaded?['imgURL'];
    if (fromAccount is String && fromAccount.toString().trim().isNotEmpty) {
      return fromAccount.toString().trim();
    }

    final p = await _p();
    final fromPrefs = p.getString(imgUrlKey);
    if (fromPrefs != null && fromPrefs.isNotEmpty) return fromPrefs;

    return FirebaseAuth.instance.currentUser?.photoURL;
  }

  static Future<void> clear() async {
    final p = await _p();
    await p.remove(accountJsonKey);
    await p.remove(firebaseUidKey);
    await p.remove(nameKey);
    await p.remove(emailKey);
    await p.remove(imgUrlKey);
    await p.remove(authProviderKey);
    await p.remove(signupCompleteKey);
    await p.remove(isAdminKey);
    await p.remove('currentStreak');
    await p.remove('longestStreak');
    await p.remove('totalAttendance');
    await p.remove('totalAbsences');
    await p.remove('absenceStreak');
    await p.reload();
    debugPrint('UserSessionStore: cleared');
  }
}
