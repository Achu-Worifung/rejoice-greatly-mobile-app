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

  final FirebaseAuth _auth = FirebaseAuth.instance;

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
    try {
      if (kIsWeb) {
        final provider = OAuthProvider("apple.com")
          ..addScope('email')
          ..addScope('name');
        await _auth.signInWithPopup(provider);
        await _sendUserToBackend("Apple", _auth.currentUser?.displayName);
        return null;
      }
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      String fullName =
          "${credential.givenName ?? ''} ${credential.familyName ?? ''}".trim();
      await FirebaseAuth.instance.currentUser?.updateDisplayName(fullName);

      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: credential.identityToken,
        accessToken: credential.authorizationCode,
      );

      await _auth.signInWithCredential(oauthCredential);
      await _sendUserToBackend("Apple", fullName.isNotEmpty ? fullName : null);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
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
