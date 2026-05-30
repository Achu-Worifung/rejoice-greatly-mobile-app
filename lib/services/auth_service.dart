import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'church_api.dart';
import 'user_session_store.dart';
import '../main.dart' show navigatorKey;

/// Result of syncing the Firebase user to Postgres via `POST /auth/firebase`.
class AuthSyncResult {
  const AuthSyncResult({
    required this.signupComplete,
    this.error,
  });

  final bool signupComplete;
  final String? error;

  bool get ok => error == null;
}

class AuthService {
  // Mobile only — web uses Firebase signInWithPopup (see signInWithGoogle).
  static GoogleSignIn? _mobileGoogleSignIn;

  static GoogleSignIn get _googleSignIn => _mobileGoogleSignIn ??= GoogleSignIn(
        scopes: const ['email', 'profile'],
      );

  static bool _googleSignInInProgress = false;
  static bool _appleSignInInProgress = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  static String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  static String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    return sha256.convert(bytes).toString();
  }

  // --- CURRENT USER ---
  User? get currentUser => _auth.currentUser;

  // --- EMAIL/PASSWORD ---
  Future<String?> signUpWithEmail(
    String email,
    String password,
    String name,
    BuildContext context,
  ) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _auth.currentUser?.updateDisplayName(name);
      try {
        await _auth.currentUser?.reload();
      } catch (_) {}

      final sync = await _syncWithBackend('email', name);
      if (!sync.ok) return sync.error;
      _navigateAfterAuth(sync.signupComplete);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  Future<String?> signInWithEmail(String email, String password, BuildContext context) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      final sync = await _syncWithBackend('email', null);
      if (!sync.ok) return sync.error;
      _navigateAfterAuth(sync.signupComplete);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  // --- GOOGLE ---
  Future<String?> signInWithGoogle() async {
    if (_googleSignInInProgress) {
      return 'Sign-in already in progress';
    }
    _googleSignInInProgress = true;
    try {
      if (kIsWeb) {
        await _auth.signInWithPopup(GoogleAuthProvider());
      } else {
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) return 'Cancelled';
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        await _auth.signInWithCredential(credential);
      }

      final sync = await _syncWithBackend('Google', null);
      if (!sync.ok) return sync.error;
      _navigateAfterAuth(sync.signupComplete);
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'popup-closed-by-user') return 'Cancelled';
      return e.message;
    } finally {
      _googleSignInInProgress = false;
    }
  }

  // --- APPLE ---
  Future<String?> signInWithApple() async {
    if (_appleSignInInProgress) {
      return 'Sign-in already in progress';
    }
    _appleSignInInProgress = true;
    try {
      if (kIsWeb) {
        final provider = OAuthProvider('apple.com')
          ..addScope('email')
          ..addScope('name');
        await _auth.signInWithPopup(provider);
        final sync = await _syncWithBackend(
          'Apple',
          _auth.currentUser?.displayName,
        );
        if (!sync.ok) return sync.error;
        _navigateAfterAuth(sync.signupComplete);
        return null;
      }

      if (defaultTargetPlatform != TargetPlatform.iOS &&
          defaultTargetPlatform != TargetPlatform.macOS) {
        return 'Sign in with Apple is only available on Apple devices';
      }

      final isAvailable = await SignInWithApple.isAvailable();
      if (!isAvailable) {
        return 'Sign in with Apple is not available on this device';
      }

      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      final idToken = appleCredential.identityToken;
      if (idToken == null || idToken.isEmpty) {
        return 'Apple sign-in failed: missing identity token';
      }

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: idToken,
        rawNonce: rawNonce,
      );

      final userCredential = await _auth.signInWithCredential(oauthCredential);

      final fullName =
          '${appleCredential.givenName ?? ''} ${appleCredential.familyName ?? ''}'
              .trim();
      if (fullName.isNotEmpty) {
        await userCredential.user?.updateDisplayName(fullName);
        try {
          await userCredential.user?.reload();
        } catch (_) {}
      }

      final sync = await _syncWithBackend(
        'Apple',
        fullName.isNotEmpty ? fullName : userCredential.user?.displayName,
      );
      if (!sync.ok) return sync.error;
      _navigateAfterAuth(sync.signupComplete);
      return null;
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        return 'Cancelled';
      }
      return e.message;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'popup-closed-by-user') return 'Cancelled';
      return e.message;
    } finally {
      _appleSignInInProgress = false;
    }
  }

  // --- LOGOUT ---
  Future<void> logout() async {
    try {
      OneSignal.logout();
    } catch (_) {}
    await UserSessionStore.clear();
    if (!kIsWeb) {
      await _googleSignIn.signOut();
    }
    await _auth.signOut();
  }

  /// Verifies Firebase session, upserts the user in Postgres via `/auth/firebase`.
  Future<AuthSyncResult> _syncWithBackend(String provider, String? name) async {
    final user = _auth.currentUser;
    if (user == null) {
      return const AuthSyncResult(
        signupComplete: false,
        error: 'Not signed in to Firebase',
      );
    }

    try {
      await user.reload();
    } catch (e) {
      debugPrint('AuthService: user.reload() failed (continuing): $e');
    }

    final active = _auth.currentUser ?? user;
    final displayName = name ?? active.displayName;

    String? idToken;
    try {
      idToken = await active.getIdToken(true);
    } catch (e) {
      debugPrint('AuthService: getIdToken(true) failed, retrying: $e');
      idToken = await active.getIdToken();
    }

    if (idToken == null || idToken.isEmpty) {
      return const AuthSyncResult(
        signupComplete: false,
        error: 'Could not obtain Firebase ID token',
      );
    }

    try {
      final userData = await ChurchApi.refreshAccountWithFirebaseToken(
        idToken,
        provider: provider,
        name: displayName,
      );

      final firebaseUid = userData['firebaseUid'] ?? '';
      final extractedName = userData['name'] ?? 'User';
      if ('$firebaseUid'.isNotEmpty) {
        OneSignal.login('$firebaseUid');
      }

      final persisted = await UserSessionStore.hasPersistedSession();
      debugPrint(
        'AuthService: synced $extractedName with backend (persisted=$persisted)',
      );
      if (!persisted) {
        debugPrint('WARNING: account data was not written to device storage.');
      }

      return AuthSyncResult(
        signupComplete: ChurchApi.isSignupComplete(userData),
      );
    } catch (e, st) {
      debugPrint('AuthService: backend sync failed: $e\n$st');
      return AuthSyncResult(
        signupComplete: false,
        error: 'Could not connect to the server. Please try again.',
      );
    }
  }

  void _navigateAfterAuth(bool signupComplete) {
    final route = signupComplete ? '/dashboard' : '/user-prep';
    navigatorKey.currentState?.pushNamedAndRemoveUntil(route, (r) => false);
  }
}
