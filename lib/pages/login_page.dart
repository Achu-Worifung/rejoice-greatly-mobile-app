import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../services/auth_service.dart';
import '../theme/church_colors.dart';
import '../main.dart' show navigatorKey;

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

  void _handleEmail(BuildContext context) {
    if (_busy != null) return;
    Navigator.pushNamed(context, '/email-login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF000000), Color(0xFFD27E09)],
          ),
        ),
        child: Stack(
          children: [
            // Positioned(
            //   left: 0,
            //   bottom: 0,
            //   child: SvgPicture.asset(
            //     'assets/icons/background.svg',
            //     width: 180,
            //     fit: BoxFit.contain,
            //   ),
            // ),
            // Positioned(
            //   right: 0,
            //   bottom: 0,
            //   child: Transform(
            //     alignment: Alignment.center,
            //     transform: Matrix4.identity()..scale(-1.0, 1.0, 1.0),
            //     child: SvgPicture.asset(
            //       'assets/icons/background.svg',
            //       width: 180,
            //       fit: BoxFit.contain,
            //     ),
            //   ),
            // ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 80),
                // Image.asset(
                //   'assets/images/logo.png',
                //   width: 140,
                //   height: 140,
                // ),
                // const SizedBox(height: 24),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      "WELCOME TO REJOICE GREATLY",
                      maxLines: 1,
                      softWrap: false,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Secure and seamless check-ins for every service",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                ),
                const Expanded(child: SizedBox()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _googleButton(context),
                      const SizedBox(height: 10),
                      _appleButton(context),
                      const SizedBox(height: 10),
                      _emailButton(context),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Automatic attendance powered by\nsecure facial recognition",
                  style: TextStyle(color: Colors.white, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 15),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _googleButton(BuildContext context) {
    return _socialButton(
      text: "Sign in with Google",
      icon: FontAwesomeIcons.google,
      isFa: true,
      bg: ChurchColors.card,
      fg: ChurchColors.bodyText,
      loading: _busy == 'google',
      onPressed: _handleGoogle,
    );
  }

  Widget _appleButton(BuildContext context) {
    return _socialButton(
      text: "Sign in with Apple",
      icon: FontAwesomeIcons.apple,
      isFa: true,
      bg: ChurchColors.card,
      fg: ChurchColors.bodyText,
      loading: _busy == 'apple',
      onPressed: _handleApple,
    );
  }

  Widget _emailButton(BuildContext context) {
    return _socialButton(
      text: "Sign in with Email",
      icon: Icons.email_outlined,
      isFa: false,
      bg: ChurchColors.button,
      fg: ChurchColors.buttonText,
      loading: false,
      onPressed: () => _handleEmail(context),
    );
  }

  Widget _socialButton({
    required String text,
    required dynamic icon,
    required bool isFa,
    required Color bg,
    required Color fg,
    required bool loading,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _busy != null ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          disabledBackgroundColor: bg,
          disabledForegroundColor: fg.withValues(alpha: 0.6),
          side: BorderSide(color: ChurchColors.divider.withValues(alpha: 0.6)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          elevation: 2,
        ),
        child: loading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2, color: fg),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  isFa
                      ? FaIcon(icon, size: 24, color: fg)
                      : Icon(icon, size: 24, color: fg),
                  const SizedBox(width: 8),
                  Text(
                    text,
                    style: TextStyle(
                      color: fg,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}