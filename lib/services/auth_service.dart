import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AuthService {
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
          Navigator.pushReplacementNamed(context, '/complete-signup');
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
          Navigator.pushReplacementNamed(context, '/complete-signup');
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
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn(
        clientId:
            '556556905292-n17ddaeaa0uuef5h7f5tnjl8rthe8d3l.apps.googleusercontent.com',
      ).signIn();
      if (googleUser == null) return 'Cancelled';
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);
      await _sendUserToBackend("Google", null);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  // --- APPLE ---
  Future<String?> signInWithApple() async {
    try {
      if (kIsWeb) {
        // Apple sign-in via Firebase on web
        final provider = OAuthProvider("apple.com")
          ..addScope('email')
          ..addScope('name');
        await FirebaseAuth.instance.signInWithPopup(provider);

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
      _sendUserToBackend("Apple", null);
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
  Future<bool> _sendUserToBackend(String provider, String? name) async {
    try {
      String? idToken = await _auth.currentUser?.getIdToken();

      // Use the name passed in, or fallback to the Firebase display name
      String? get_name = name ?? await _auth.currentUser?.displayName;

      final res = await http.post(
        Uri.parse("http://localhost:8080/auth/firebase"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "provider": provider,
          "idToken": idToken,
          "name": get_name, // Use the resolved name
        }),
      );

      // CRITICAL FIX: Changed from != 200 to == 200
      if (res.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        final Map<String, dynamic> userData = jsonDecode(res.body);

        // Extract fields from response
        String firebaseUid = userData['firebaseUid'] ?? "";
        String email = userData['email'] ?? "";
        String extractedName = userData['name'] ?? "User";
        bool isAdmin = userData['admin'] ?? false;
        bool signupComplete = userData['signupComplete'] ?? false;

        // Save to SharedPreferences
        await prefs.setString("firebaseUid", firebaseUid);
        await prefs.setString("email", email);
        await prefs.setString("name", extractedName);
        await prefs.setBool("isAdmin", isAdmin);
        await prefs.setBool("signupComplete", signupComplete);

        print("Backend success: User $extractedName saved locally.");
        return signupComplete;
      } else {
        print("Backend error: ${res.statusCode} - ${res.body}");
        return false;
      }
    } catch (e) {
      print("Backend connection error: $e");
      return false;
    }
  }
}
