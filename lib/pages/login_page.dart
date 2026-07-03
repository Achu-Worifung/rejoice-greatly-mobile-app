import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../services/auth_service.dart';
import '../theme/church_colors.dart';
import '../widgets/auth_ui.dart';
import '../main.dart' show navigatorKey;

/// The app's front door. A Roasted Cocoa surface that flows straight out of the
/// splash — cream welcome copy and three sign-in choices.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  /// Which provider's sign-in is currently running ('google' / 'apple'),
  /// or null when idle. While set, all buttons are disabled and the active
  /// one shows a spinner.
  String? _busy;

  void _showError(String msg) {
    if (msg == 'Cancelled') return;
    // Fall back to the root navigator's context when this widget has been
    // unmounted (e.g. Firebase auth state fired before the backend sync
    // finished, causing RootPage to replace LoginPage mid-flight).
    final ctx = mounted ? context : navigatorKey.currentContext;
    if (ctx == null) return;
    ScaffoldMessenger.maybeOf(ctx)
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _signIn(String provider, Future<String?> Function() run) async {
    if (_busy != null) return;
    setState(() => _busy = provider);
    try {
      final msg = await run();
      if (msg != null) _showError(msg);
    } catch (e) {
      _showError('Sign-in failed. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<void> _handleGoogle() =>
      _signIn('google', () => AuthService().signInWithGoogle());

  Future<void> _handleApple() =>
      _signIn('apple', () => AuthService().signInWithApple());

  void _handleEmail() {
    if (_busy != null) return;
    Navigator.pushNamed(context, '/email-login');
  }

  @override
  Widget build(BuildContext context) {
    final cream = ChurchColors.card;
    final busy = _busy != null;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: ChurchColors.button,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const Spacer(flex: 2),
                Text(
                  'Welcome to\nRejoice Greatly',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: cream,
                    fontSize: 32,
                    height: 1.15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Secure, seamless check-ins for every service.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: cream.withValues(alpha: 0.85),
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
                const Spacer(flex: 3),
                ChurchSocialButton(
                  label: 'Continue with Google',
                  icon: FontAwesomeIcons.google,
                  loading: _busy == 'google',
                  enabled: !busy,
                  onPressed: _handleGoogle,
                ),
                const SizedBox(height: 12),
                ChurchSocialButton(
                  label: 'Continue with Apple',
                  icon: FontAwesomeIcons.apple,
                  loading: _busy == 'apple',
                  enabled: !busy,
                  onPressed: _handleApple,
                ),
                const SizedBox(height: 12),
                ChurchSocialButton.ghost(
                  label: 'Continue with Email',
                  icon: Icons.email_outlined,
                  enabled: !busy,
                  onPressed: _handleEmail,
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.lock_outline_rounded,
                      size: 15,
                      color: cream.withValues(alpha: 0.75),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Automatic attendance, powered by secure facial recognition.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: cream.withValues(alpha: 0.8),
                          fontSize: 12.5,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
