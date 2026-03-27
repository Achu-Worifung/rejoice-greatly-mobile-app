import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- CURRENT USER ---
  User? get currentUser => _auth.currentUser;

  // --- EMAIL/PASSWORD ---
  Future<String?> signUpWithEmail(String email, String password, String name) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      //login no need to send to backend
      await _sendUserToBackend("email", _auth.currentUser!.uid); 
      await FirebaseAuth.instance.currentUser?.updateDisplayName(name);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  Future<String?> signInWithEmail(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
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
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);
      await _sendUserToBackend("Google", _auth.currentUser!.uid);
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
      _sendUserToBackend("Apple", _auth.currentUser!.uid);
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
  Future<void> _sendUserToBackend(String provider, String token) async {
    try {
      final res = await http.post(
        Uri.parse("http://localhost:8080/auth/firebase"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"provider": provider}),
      );

      if (res.statusCode != 200) throw Exception("Failed to send user to backend");
      

    } catch (e) {
      print(e);
    }
  }

 
}
