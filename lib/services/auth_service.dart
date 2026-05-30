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
    context,
  ) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      //login no need to send to backend
      String? idToken = await _auth.currentUser?.getIdToken();
      await FirebaseAuth.instance.currentUser?.updateDisplayName(name);

      if (idToken != null) {
        bool signupComplete = await _sendUserToBackend("email", name);
        if (signupComplete)
        {
          Navigator.pushReplacementNamed(context, '/dashboard');
        }else 
        {
          Navigator.pushReplacementNamed(context, '/user-prep');
        }
      }
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  Future<String?> signInWithEmail(String email, String password, context) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      String? idToken = await _auth.currentUser?.getIdToken();
      if (idToken != null) {
        bool signupComplete = await _sendUserToBackend("email", null);
        if (signupComplete)
        {
          Navigator.pushReplacementNamed(context, '/dashboard');
        }else 
        {
          Navigator.pushReplacementNamed(context, '/user-prep');
        }
      }
      else {
        return "Failed to sign in. Please try again.";
      }

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
        // google_sign_in.signIn() on web is deprecated, lacks idToken, and
        // requires the People API. Firebase popup is the supported path.
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

      await _sendUserToBackend("Google", null);
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
        await _sendUserToBackend('Apple', _auth.currentUser?.displayName);
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
      }

      await _sendUserToBackend(
        'Apple',
        fullName.isNotEmpty ? fullName : userCredential.user?.displayName,
      );
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
    await UserSessionStore.clear();
    if (!kIsWeb) {
      await _googleSignIn.signOut();
    }
    await _auth.signOut();
  }

  // --- OPTIONAL: send user info to your backend ---
  Future<bool> _sendUserToBackend(String provider, String? name) async {
    try {
      final idToken = await _auth.currentUser?.getIdToken(true);
      if (idToken == null || idToken.isEmpty) {
        print('Backend error: missing Firebase id token');
        return false;
      }
      final getName = name ?? await _auth.currentUser?.displayName;

      final userData = await ChurchApi.refreshAccountWithFirebaseToken(
        idToken,
        provider: provider,
        name: getName,
      );

      final firebaseUid = userData['firebaseUid'] ?? '';
      final extractedName = userData['name'] ?? 'User';
      OneSignal.login('$firebaseUid');

      final persisted = await UserSessionStore.hasPersistedSession();
      print('Backend success: User $extractedName saved locally (persisted=$persisted).');
      if (!persisted) {
        print('WARNING: account data was not written to device storage.');
      }
      return ChurchApi.isSignupComplete(userData);
    } catch (e, st) {
      print('Backend connection error: $e\n$st');
      return false;
    }
  }
}
