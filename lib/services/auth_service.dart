import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../firebase_options.dart';
import '../notifications/notification_service.dart';
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

  /// Web OAuth client (type 3) from Firebase/Google Cloud. Required on iOS so
  /// Google returns an ID token Firebase Auth will accept.
  static const _googleServerClientId =
      '1053433403648-6h8u89n0ts8ijrmv13qm5dj57j6v7pgd.apps.googleusercontent.com';

  static GoogleSignIn get _googleSignIn => _mobileGoogleSignIn ??= GoogleSignIn(
        scopes: const ['email', 'profile'],
        clientId: DefaultFirebaseOptions.ios.iosClientId,
        serverClientId: _googleServerClientId,
      );

  static bool _googleSignInInProgress = false;
  static bool _appleSignInInProgress = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  static String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  /// Firebase exception messages can be null or developer-speak; map the
  /// common sign-in failures to something a user (or tester) can act on.
  static String _authErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'popup-closed-by-user':
      case 'canceled':
      case 'web-context-canceled':
      case 'user-cancelled':
        return 'Cancelled';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled for the app yet. '
            'Enable the provider in the Firebase console.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with this email using a different '
            'sign-in method. Try that method instead.';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      default:
        return e.message ?? 'Sign-in failed (${e.code}). Please try again.';
    }
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
      return _authErrorMessage(e);
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
      return _authErrorMessage(e);
    }
  }

  /// Sends a password-reset email. Returns an error message, or null on success.
  Future<String?> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return null;
    } on FirebaseAuthException catch (e) {
      return _authErrorMessage(e);
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
        if (googleAuth.idToken == null || googleAuth.idToken!.isEmpty) {
          return 'Google sign-in did not return an ID token. Check that the '
              'iOS OAuth client is for com.rejoicegreatly.app.';
        }

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
      return _authErrorMessage(e);
    } catch (e) {
      debugPrint('AuthService: signInWithGoogle unexpected error: $e');
      return 'Sign-in failed. Please try again.';
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
      String? name;
      debugPrint('AuthService: Apple sign-in started '
          '(platform=${defaultTargetPlatform.name}, web=$kIsWeb)');

      if (kIsWeb) {
        final provider = OAuthProvider('apple.com')
          ..addScope('email')
          ..addScope('name');
        await _auth.signInWithPopup(provider);
        name = _auth.currentUser?.displayName;
      } else if (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS) {
        name = await _signInWithAppleNative();
      } else {
        // Android (and anything else): Firebase runs Apple's OAuth flow in a
        // browser tab — previously this branch just refused to sign in.
        final provider = OAuthProvider('apple.com')
          ..addScope('email')
          ..addScope('name');
        await _auth.signInWithProvider(provider);
        name = _auth.currentUser?.displayName;
      }

      debugPrint('AuthService: Apple Firebase auth OK, syncing backend…');
      final sync = await _syncWithBackend('Apple', name);
      if (!sync.ok) {
        debugPrint('AuthService: Apple backend sync failed: ${sync.error}');
        return sync.error;
      }
      _navigateAfterAuth(sync.signupComplete);
      return null;
    } on SignInWithAppleAuthorizationException catch (e) {
      debugPrint(
        'AuthService: Apple authorization failed '
        '(code=${e.code}, message=${e.message})',
      );
      if (e.code == AuthorizationErrorCode.canceled) {
        return 'Cancelled';
      }
      return e.message.isNotEmpty
          ? e.message
          : 'Apple sign-in failed (${e.code.name}).';
    } on FirebaseAuthException catch (e) {
      debugPrint(
        'AuthService: Apple FirebaseAuthException '
        '(code=${e.code}, message=${e.message})',
      );
      return _authErrorMessage(e);
    } catch (e, st) {
      debugPrint('AuthService: Apple unexpected error: $e\n$st');
      return 'Apple sign-in failed: $e';
    } finally {
      _appleSignInInProgress = false;
    }
  }

  /// Native Apple sheet on iOS/macOS. Returns the user's display name (Apple
  /// only provides it on the first authorization, so it is persisted then).
  Future<String?> _signInWithAppleNative() async {
    final isAvailable = await SignInWithApple.isAvailable();
    debugPrint('AuthService: SignInWithApple.isAvailable=$isAvailable');
    if (!isAvailable) {
      // Old iOS (<13): fall back to the Firebase-managed web flow.
      final provider = OAuthProvider('apple.com')
        ..addScope('email')
        ..addScope('name');
      await _auth.signInWithProvider(provider);
      return _auth.currentUser?.displayName;
    }

    final rawNonce = _generateNonce();
    final nonce = _sha256ofString(rawNonce);

    debugPrint('AuthService: requesting Apple ID credential…');
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: nonce,
    );

    final idToken = appleCredential.identityToken;
    debugPrint(
      'AuthService: Apple credential received '
      '(hasIdToken=${idToken != null && idToken.isNotEmpty}, '
      'userIdentifier=${appleCredential.userIdentifier}, '
      'email=${appleCredential.email})',
    );
    if (idToken == null || idToken.isEmpty) {
      throw FirebaseAuthException(
        code: 'missing-identity-token',
        message: 'Apple sign-in failed: missing identity token',
      );
    }

    final oauthCredential = OAuthProvider('apple.com').credential(
      idToken: idToken,
      rawNonce: rawNonce,
      accessToken: appleCredential.authorizationCode,
    );

    debugPrint('AuthService: exchanging Apple credential with Firebase…');
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

    return fullName.isNotEmpty ? fullName : userCredential.user?.displayName;
  }

  /// Sign-in succeeded on Firebase but the church backend rejected/failed the
  /// sync: drop the Firebase session so the user is not stuck half signed in
  /// (the UI shows an error and stays on the login screen).
  Future<AuthSyncResult> _failSync(AuthSyncResult sync) async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('AuthService: sign-out after failed sync failed: $e');
    }
    return sync;
  }

  // --- LOGOUT ---
  Future<void> logout() async {
    await NotificationService().logout();
    await UserSessionStore.clear();
    // Home data (verse, sermons, events) is a global in-memory cache, not tied
    // to the session store — drop it so the next account never sees stale data.
    ChurchApi.invalidateHomeCache();
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
      return _failSync(const AuthSyncResult(
        signupComplete: false,
        error: 'Could not obtain Firebase ID token',
      ));
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
        // Fire-and-forget: push registration must not block or fail sign-in.
        NotificationService().login('$firebaseUid', email: active.email);
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
      return _failSync(const AuthSyncResult(
        signupComplete: false,
        error: 'Could not connect to the server. Please try again.',
      ));
    }
  }

  void _navigateAfterAuth(bool signupComplete) {
    // Not-yet-complete members start onboarding at the date-of-birth gate,
    // which routes 18+ into the facial-recognition flow and under-18s straight
    // to the dashboard.
    final route = signupComplete ? '/dashboard' : '/date-of-birth';
    navigatorKey.currentState?.pushNamedAndRemoveUntil(route, (r) => false);
  }
}
