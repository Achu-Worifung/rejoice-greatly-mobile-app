import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:church_app/pages/login_page.dart';
import 'package:church_app/main.dart';

class RootPage extends StatelessWidget {
  const RootPage({super.key});

  Future<bool> _checkIfSignupComplete() async {
    final prefs = await SharedPreferences.getInstance();
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

      final bool isComplete = completeSnapshot.data ?? false;

     
      WidgetsBinding.instance.addPostFrameCallback((_) {
        print('postFrameCallback firing...');
        print('navigatorKey.currentState in callback: ${navigatorKey.currentState}');
        
        if (isComplete) {
          navigatorKey.currentState?.pushReplacementNamed('/dashboard');
        } else {
          navigatorKey.currentState?.pushReplacementNamed('/complete-signup');
        }
      });

      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    },
  );
}

        return const LoginPage();
      },
    );
  }
}