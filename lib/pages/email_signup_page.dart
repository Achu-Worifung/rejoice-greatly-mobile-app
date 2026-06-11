import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/gestures.dart';
import 'package:church_app/services/auth_service.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:church_app/theme/church_colors.dart';
import 'package:church_app/widgets/church_app_bar.dart';

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

  /// Which action is running: 'email', 'google', 'apple', or null when idle.
  String? _busy;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _runSignIn(String action, Future<String?> Function() run) async {
    if (_busy != null) return;
    setState(() {
      _error = null;
      _busy = action;
    });
    try {
      final msg = await run();
      if (msg != null && msg != 'Cancelled' && mounted) {
        setState(() => _error = msg);
      }
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<void> _submit() async {
    if (!_termsAccepted || !_privacyAccepted) {
      setState(() {
        _error = "You must accept all policies and terms to continue.";
      });
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    await _runSignIn(
      'email',
      () => AuthService().signUpWithEmail(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _nameController.text.trim(),
        context,
      ),
    );
  }

  Future<void> _handleGoogle() =>
      _runSignIn('google', () => AuthService().signInWithGoogle());

  Future<void> _handleApple() =>
      _runSignIn('apple', () => AuthService().signInWithApple());

  void _goBack() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ChurchColors.background,
      appBar: ChurchAppBar.of(
        title: const SizedBox.shrink(),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: ChurchColors.accent),
          onPressed: _goBack,
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: ChurchColors.background,
        child: ListView(
          padding: const EdgeInsets.all(10),
          children: [
            const Text(
              "Let's Get Started!",
              style: TextStyle(
                color: ChurchColors.bodyText,
                fontSize: 28,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              "Create your account",
              style: TextStyle(
                color: ChurchColors.muted,
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
                    style: const TextStyle(color: ChurchColors.bodyText),
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
                    style: const TextStyle(color: ChurchColors.bodyText),
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
                    style: const TextStyle(color: ChurchColors.bodyText),
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
                              color: ChurchColors.muted,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                        ),
                    validator: (v) {
                      // Keep in sync with the helper text below the field.
                      if (v == null || v.isEmpty) {
                        return "Please enter your password";
                      }
                      if (v.length < 8) {
                        return "Password must be at least 8 characters";
                      }
                      if (!v.contains(RegExp(r'[A-Z]'))) {
                        return "Password must contain an uppercase letter";
                      }
                      if (!v.contains(RegExp(r'[0-9]'))) {
                        return "Password must contain a number";
                      }
                      if (!v.contains(RegExp(r'[^A-Za-z0-9]'))) {
                        return "Password must contain a symbol";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "At least 8 characters, 1 uppercase, 1 number & 1 symbol",
                    textAlign: TextAlign.left,
                    style: TextStyle(color: ChurchColors.muted, fontSize: 12),
                  ),
                  const SizedBox(height: 10),

                  // Terms, Privacy, and Consent checkboxes
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CheckboxListTile(
                        title: RichText(
                          text: TextSpan(
                            style: const TextStyle(color: ChurchColors.bodyText),
                            children: [
                              const TextSpan(
                                text: "By signing up, you agree to the ",
                                style: TextStyle(fontSize: 16),
                              ),
                              TextSpan(
                                text: "Terms of Service",
                                style: const TextStyle(
                                  color: ChurchColors.button,
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
                                  color: ChurchColors.button,
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
                        activeColor: ChurchColors.button,
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                      CheckboxListTile(
                        title: const Text(
                          "I consent to the use of biometric and/or Bluetooth technology to record my church attendance",
                          style: TextStyle(color: ChurchColors.bodyText, fontSize: 16),
                        ),
                        value: _privacyAccepted,
                        onChanged: (val) =>
                            setState(() => _privacyAccepted = val!),
                        activeColor: ChurchColors.button,
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                      if (_error != null)
                        SizedBox(
                          width: double.infinity,
                          child: Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFF8A2C1F),
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
                          color: ChurchColors.divider,
                          thickness: 1,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: Text(
                          'OR',
                          style: TextStyle(
                            color: ChurchColors.muted,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: ChurchColors.divider,
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
                              onPressed: _busy != null ? null : _handleGoogle,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ChurchColors.card,
                                foregroundColor: ChurchColors.bodyText,
                                disabledBackgroundColor: ChurchColors.card,
                                elevation: 2,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _busy == 'google'
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: ChurchColors.bodyText,
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const FaIcon(
                                          FontAwesomeIcons.google,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: AutoSizeText(
                                            "Sign in with Google",
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

                      // 2. Second Button (Apple)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: SizedBox(
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _busy != null ? null : _handleApple,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ChurchColors.card,
                                foregroundColor: ChurchColors.bodyText,
                                disabledBackgroundColor: ChurchColors.card,
                                elevation: 2,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _busy == 'apple'
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: ChurchColors.bodyText,
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
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
                          style: TextStyle(color: ChurchColors.bodyText, fontSize: 16),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => Navigator.pushReplacementNamed(
                              context, '/email-login'),
                          child: const Text(
                            "Login",
                            style: TextStyle(
                              color: ChurchColors.button,
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
                      onPressed: _busy != null ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ChurchColors.button,
                        disabledBackgroundColor: ChurchColors.button,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: _busy == 'email'
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: ChurchColors.buttonText,
                              ),
                            )
                          : const Text(
                              "Create Account",
                              style: TextStyle(
                                color: ChurchColors.buttonText,
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
      labelStyle: const TextStyle(color: ChurchColors.muted),
      prefixIcon: Icon(icon, color: ChurchColors.muted),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: ChurchColors.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: ChurchColors.button),
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
