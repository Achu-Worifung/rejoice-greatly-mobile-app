import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'email_signup_page.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  void _handleGoogle(BuildContext context) {
    // TODO: implement Google sign in
    print("Google pressed");
  }

  void _handleApple(BuildContext context) {
    // TODO: implement Apple sign in
    print("Apple pressed");
  }

  void _handleEmail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EmailSignupPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF000000), Color(0xFF00174B)],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 125),
            const Text(
              "WELCOME TO AMC PHOENIX",
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
            _googleButton(context),
            const SizedBox(height: 10),
            _appleButton(context),
            const SizedBox(height: 10),
            _emailButton(context),
            const SizedBox(height: 20),
            const Text(
              "Automatic attendance powered by\nsecure facial recognition",
              style: TextStyle(color: Colors.white, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 15),
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
      bg: Colors.white,
      fg: Colors.black,
      onPressed: () => _handleGoogle(context),
    );
  }

  Widget _appleButton(BuildContext context) {
    return _socialButton(
      text: "Sign in with Apple",
      icon: FontAwesomeIcons.apple,
      isFa: true,
      bg: Colors.white,
      fg: Colors.black,
      onPressed: () => _handleApple(context),
    );
  }

  Widget _emailButton(BuildContext context) {
    return _socialButton(
      text: "Sign in with Email",
      icon: Icons.email_outlined,
      isFa: false,
      bg: const Color(0xFF5286FF),
      fg: Colors.white,
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
      width: 344,
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
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