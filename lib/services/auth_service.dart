import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- CURRENT USER ---
  User? get currentUser => _auth.currentUser;

  // --- EMAIL/PASSWORD ---
  Future<String?> signUpWithEmail(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(email: email, password: password);
      await _sendUserToBackend(); // optional
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  Future<String?> signInWithEmail(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      await _sendUserToBackend(); // optional
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  // --- GOOGLE ---
  Future<String?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return 'Cancelled';
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);
      await _sendUserToBackend(); // optional
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  // --- APPLE ---
  Future<String?> signInWithApple() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName
        ],
      );

      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: credential.identityToken,
        accessToken: credential.authorizationCode,
      );

      await _auth.signInWithCredential(oauthCredential);
      await _sendUserToBackend(); // optional
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  // --- LOGOUT ---
  Future<void> logout() async {
    await _auth.signOut();
  }

  // --- OPTIONAL: send user info to your backend ---
  Future<void> _sendUserToBackend() async {
    final user = _auth.currentUser;
    if (user == null) return;

    await http.post(
      Uri.parse('https://your-backend.com/users'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'uid': user.uid,
        'email': user.email,
        'name': user.displayName ?? '',
      }),
    );
  }
}