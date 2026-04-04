import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/gestures.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:church_app/services/auth_service.dart';
import 'package:auto_size_text/auto_size_text.dart';

class EmailSignupPage extends StatefulWidget {
  const EmailSignupPage({super.key});

  @override
  State<EmailSignupPage> createState() => _EmailSignupPageState();
}

class _EmailSignupPageState extends State<EmailSignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _error;

  bool _obscurePassword = true;
  bool _termsAccepted = false;
  bool _privacyAccepted = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_termsAccepted || !_privacyAccepted) {
      setState(() {
        _error = "You must accept all policies and terms to continue.";
      });
      return;
    }

    if (_formKey.currentState!.validate()) {
      setState(() => _error = null);

      // FIX: Changed from signInWithEmail to signUpWithEmail
      // Also added _nameController.text
      final msg = await AuthService().signUpWithEmail(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _nameController.text.trim(),
        context,
      );

      if (msg != null) {
        setState(() => _error = msg);
        return;
      }
    }
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pushNamed(context, '/login'),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.white,
        child: ListView(
          padding: const EdgeInsets.all(10),
          children: [
            const Text(
              "Let's Get Started!",
              style: TextStyle(
                color: Colors.black,
                fontSize: 28,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              "Create your account",
              style: TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.w400,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 22),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  // Name
                  TextFormField(
                    controller: _nameController,
                    style: const TextStyle(color: Colors.black),
                    decoration: _inputDecoration(
                      label: "Name",
                      icon: Icons.person_3_outlined,
                    ),
                    validator: (v) => v == null || v.isEmpty
                        ? "Please enter your name"
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // Email
                  TextFormField(
                    controller: _emailController,
                    style: const TextStyle(color: Colors.black),
                    keyboardType: TextInputType.emailAddress,
                    decoration: _inputDecoration(
                      label: "Email",
                      icon: Icons.email_outlined,
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty)
                        return "Please enter your email";
                      if (!v.contains("@")) return "Please enter a valid email";
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: const TextStyle(color: Colors.black),
                    decoration:
                        _inputDecoration(
                          label: "Password",
                          icon: Icons.lock_outline,
                        ).copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: Colors.black,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                        ),
                    validator: (v) {
                      if (v == null || v.isEmpty)
                        return "Please enter your password";
                      if (v.length < 6)
                        return "Password must be at least 6 characters";
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "At least 8 characters, 1 uppercase, 1 number & 1 symbol",
                    textAlign: TextAlign.left,
                    style: TextStyle(color: Colors.black, fontSize: 12),
                  ),
                  const SizedBox(height: 10),

                  // Terms, Privacy, and Consent checkboxes
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CheckboxListTile(
                        title: RichText(
                          text: TextSpan(
                            style: const TextStyle(color: Colors.black),
                            children: [
                              const TextSpan(
                                text: "By signing up, you agree to the ",
                                style: TextStyle(fontSize: 16),
                              ),
                              TextSpan(
                                text: "Terms of Service",
                                style: const TextStyle(
                                  color: Color(0xFF5286FF),
                                  decoration: TextDecoration.underline,
                                  fontSize: 16,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    Navigator.pushNamed(context, '/terms');
                                  },
                              ),
                              const TextSpan(text: " and "),
                              TextSpan(
                                text: "Privacy Policy",
                                style: const TextStyle(
                                  color: Color(0xFF5286FF),
                                  decoration: TextDecoration.underline,
                                  fontSize: 16,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    Navigator.pushNamed(context, '/privacy');
                                  },
                              ),
                            ],
                          ),
                        ),
                        value: _termsAccepted,
                        onChanged: (val) =>
                            setState(() => _termsAccepted = val!),
                        activeColor: const Color(0xFF5286FF),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                      CheckboxListTile(
                        title: const Text(
                          "I consent to the use of biometric and/or Bluetooth technology to record my church attendance",
                          style: TextStyle(color: Colors.black, fontSize: 16),
                        ),
                        value: _privacyAccepted,
                        onChanged: (val) =>
                            setState(() => _privacyAccepted = val!),
                        activeColor: const Color(0xFF5286FF),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                      if (_error != null)
                        SizedBox(
                          width: double.infinity,
                          child: Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: Colors.grey.shade400,
                          thickness: 1,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: Text(
                          'OR',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: Colors.grey.shade400,
                          thickness: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 1. First Button (Google)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(
                            4.0,
                          ), // Reduced padding to save space
                          child: SizedBox(
                            height:
                                50, // Slightly shorter height helps on small screens
                            child: ElevatedButton(
                              onPressed: _handleGoogle,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                elevation: 2,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ), // Minimal internal padding
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const FaIcon(
                                    FontAwesomeIcons.google,
                                    size: 18,
                                  ), // Smaller icon
                                  const SizedBox(width: 4),
                                  Flexible(
                                    // Use Flexible to allow the text to shrink aggressively
                                    child: AutoSizeText(
                                      "Sign in with Google", // Shortened text also helps
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      minFontSize:
                                          8, // Dropped min size to 8 to prevent overflow
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // 2. Second Button (Apple)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: SizedBox(
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _handleApple,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                elevation: 2,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const FaIcon(
                                    FontAwesomeIcons.apple,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: AutoSizeText(
                                      "Sign in with Apple",
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      minFontSize: 8,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Login link
                  SizedBox(
                    height: 24,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Already have an account?",
                          style: TextStyle(color: Colors.black, fontSize: 16),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () =>
                              Navigator.pushNamed(context, '/email-login'),
                          child: const Text(
                            "Login",
                            style: TextStyle(
                              color: Color(0xFF5286FF),
                              fontSize: 16,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5286FF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: const Text(
                        "Create Account",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.black),
      prefixIcon: Icon(icon, color: Colors.black),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.black),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF5286FF)),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }
}
