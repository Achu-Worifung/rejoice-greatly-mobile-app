import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/auth_service.dart';
import '../theme/church_colors.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  Future<void> _handleGoogle() async {
    final msg = await AuthService().signInWithGoogle();
    if (msg != null) {
        print(msg);
        return;
      }
  }

  Future<void> _handleApple() async {
    final msg = await AuthService().signInWithApple();
    if (msg != null) {
        print(msg);
        return;
      }
  }

  void _handleEmail(BuildContext context) {
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
            Positioned(
              left: 0,
              bottom: 0,
              child: SvgPicture.asset(
                'assets/icons/background.svg',
                width: 180,
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()..scale(-1.0, 1.0, 1.0),
                child: SvgPicture.asset(
                  'assets/icons/background.svg',
                  width: 180,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 125),
                const Text(
                  "WELCOME TO REJOICE GREATLY",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
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
      onPressed: () => _handleGoogle(),
    );
  }

  Widget _appleButton(BuildContext context) {
    return _socialButton(
      text: "Sign in with Apple",
      icon: FontAwesomeIcons.apple,
      isFa: true,
      bg: ChurchColors.card,
      fg: ChurchColors.bodyText,
      onPressed: () => _handleApple(),
    );
  }

  Widget _emailButton(BuildContext context) {
    return _socialButton(
      text: "Sign in with Email",
      icon: Icons.email_outlined,
      isFa: false,
      bg: ChurchColors.button,
      fg: ChurchColors.buttonText,
      onPressed: () => _handleEmail(context),
    );
  }

  Widget _socialButton({
    required String text,
    required dynamic icon,
    required bool isFa,
    required Color bg,
    required Color fg,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          side: BorderSide(color: ChurchColors.divider.withValues(alpha: 0.6)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          elevation: 2,
        ),
        child: Row(
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