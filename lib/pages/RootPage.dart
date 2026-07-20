import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:church_app/pages/login_page.dart';
import 'package:church_app/pages/user_prep.dart';
import 'package:church_app/pages/dashboard.dart';
import 'package:church_app/services/church_api.dart';
import 'package:church_app/widgets/branded_loader.dart';

/// App entry: auth check, session restore, then shows login / signup / dashboard.
class RootPage extends StatefulWidget {
  const RootPage({super.key});

  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  Future<SessionRestoreResult>? _sessionFuture;
  String? _restoredUid;

  // The same "Warm Welcome" surface the splash settles into, so a slow auth /
  // session-restore keeps the user in one continuous moment instead of a bare
  // white spinner after the branded splash.
  Widget _loading() => const BrandedLoader();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return _loading();
        }

        if (!authSnapshot.hasData) {
          _sessionFuture = null;
          _restoredUid = null;
          return const LoginPage();
        }

        final uid = authSnapshot.data!.uid;
        if (_restoredUid != uid) {
          _sessionFuture = null;
          _restoredUid = uid;
        }

        _sessionFuture ??= ChurchApi.restoreUserSession();

        return FutureBuilder<SessionRestoreResult>(
          future: _sessionFuture,
          builder: (context, sessionSnapshot) {
            if (sessionSnapshot.connectionState != ConnectionState.done) {
              return _loading();
            }

            if (sessionSnapshot.hasError) {
              debugPrint('RootPage session error: ${sessionSnapshot.error}');
              return const LoginPage();
            }

            final session = sessionSnapshot.data;
            if (session == null || !session.loggedIn) {
              return const LoginPage();
            }

            if (session.signupComplete) {
              return const Dashboard();
            }
            // Same onboarding entry as a fresh sign-in (camera screen is
            // pushed from here, so its back button works in both flows).
            return const UserPrepPage();
          },
        );
      },
    );
  }
}
