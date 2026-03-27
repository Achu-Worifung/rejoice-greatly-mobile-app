import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:church_app/routes.dart'; // Ensure this matches your project name
import 'package:church_app/pages/login_page.dart'; // Import your actual Login Page

class RootPage extends StatelessWidget {
  const RootPage({super.key});

  /// Helper function to read from SharedPreferences
  /// This sits outside the build method for clarity
  Future<bool> _checkIfSignupComplete() async {
    final prefs = await SharedPreferences.getInstance();
    // Default to false if the key doesn't exist yet
    return prefs.getBool("signupComplete") ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (authSnapshot.hasData) {
          return FutureBuilder<bool>(
            future: _checkIfSignupComplete(),
            builder: (context, completeSnapshot) {
              if (completeSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              bool isComplete = completeSnapshot.data ?? false;

              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (isComplete) {
                  Navigator.pushReplacementNamed(context, '/dashboard');
                } else {
                  Navigator.pushReplacementNamed(context, '/complete-signup');
                }
              });

              return const Scaffold(body: SizedBox.shrink());
            },
          );
        }

        return const LoginPage();
      },
    );
  }
}