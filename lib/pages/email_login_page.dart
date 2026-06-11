import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../services/auth_service.dart';
import 'package:auto_size_text/auto_size_text.dart';
import '../theme/church_colors.dart';
import '../widgets/church_app_bar.dart';

class EmailLoginPage extends StatefulWidget {
  const EmailLoginPage({super.key});

  @override
  State<EmailLoginPage> createState() => _EmailLoginPageState();
}

class _EmailLoginPageState extends State<EmailLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _error;

  /// Which action is running: 'email', 'google', 'apple', or null when idle.
  String? _busy;

  bool get _isLoading => _busy == 'email';

  @override
  void dispose() {
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

  Future<void> _emailLogin() async {
    if (!_formKey.currentState!.validate()) return;
    await _runSignIn(
      'email',
      () => AuthService().signInWithEmail(
        _emailController.text,
        _passwordController.text,
        context,
      ),
    );
  }

  Future<void> _googleSignUp() =>
      _runSignIn('google', () => AuthService().signInWithGoogle());

  Future<void> _appleSignUp() =>
      _runSignIn('apple', () => AuthService().signInWithApple());

  void _goBack() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  Future<void> _forgotPassword() async {
    if (_busy != null) return;
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() =>
          _error = 'Enter your email above, then tap "Forgot Password?".');
      return;
    }
    final msg = await AuthService().sendPasswordReset(email);
    if (!mounted) return;
    if (msg != null) {
      setState(() => _error = msg);
      return;
    }
    setState(() => _error = null);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('Password reset email sent to $email')),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ChurchColors.background,
      appBar: ChurchAppBar.of(
        toolbarHeight: 56,
        centerTitle: true,
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
              "Sign in to your account",
              style: TextStyle(
                color: ChurchColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w400,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 14),
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1EE),
                  border: Border.all(color: const Color(0xFFE1B0A9)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _error!,
                  style: TextStyle(
                    color: const Color(0xFF8A2C1F),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            if (_error != null) const SizedBox(height: 14),
            const SizedBox(height: 8),
            Form(
              key: _formKey,
              child: Column(
                children: [
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
                  SizedBox(
                    width: double.infinity,
                    child: GestureDetector(
                      onTap: _forgotPassword,
                      child: Text(
                        "Forgot Password?",
                        textAlign: TextAlign.right,
                        style: const TextStyle(color: ChurchColors.muted, fontSize: 12),
                      ),
                    ),
                  ),

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
                      if (v == null || v.isEmpty) {
                        return "Please enter your password";
                      }
                      if (v.length < 6) {
                        return "Password must be at least 6 characters";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  // const Text(
                  //   "Atleast 8 characters, 1 uppercas, 1 number & 1 symbol",
                  //   textAlign: TextAlign.left,
                  //   style: TextStyle(color: Colors.black, fontSize: 12),
                  // ),
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
                      Expanded(
                        child: SizedBox(
                          height: 60,
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: ElevatedButton(
                              onPressed: _busy != null ? null : _googleSignUp,
                              style: ElevatedButton.styleFrom(
                                side: const BorderSide(
                                  color: ChurchColors.divider,
                                  width: 1,
                                ),
                                backgroundColor: ChurchColors.card,
                                disabledBackgroundColor: ChurchColors.card,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                              ),
                              child: _busy == 'google'
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
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
                                          size: 20,
                                          color: ChurchColors.bodyText,
                                        ),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: AutoSizeText(
                                            "Sign in with Google",
                                            style: const TextStyle(
                                              color: ChurchColors.bodyText,
                                              fontSize: 16,
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
                      const SizedBox(width: 4),
                      Expanded(
                        child: SizedBox(
                          height: 60,
                          child: Padding(
                            padding: const EdgeInsets.all(
                              4.0,
                            ), // Consistent padding
                            child: ElevatedButton(
                              onPressed: _busy != null ? null : _appleSignUp,
                              style: ElevatedButton.styleFrom(
                                side: const BorderSide(
                                  color: ChurchColors.divider,
                                  width: 1,
                                ),
                                backgroundColor: ChurchColors.card,
                                disabledBackgroundColor: ChurchColors.card,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                              ),
                              child: _busy == 'apple'
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
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
                                          size: 20,
                                          color: ChurchColors.bodyText,
                                        ),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: AutoSizeText(
                                            "Sign in with Apple",
                                            style: const TextStyle(
                                              color: ChurchColors.bodyText,
                                              fontSize: 16,
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
                  SizedBox(
                    height: 24,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account?",
                          style: const TextStyle(color: ChurchColors.bodyText, fontSize: 16),
                        ),
                        SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => Navigator.pushReplacementNamed(
                              context, '/email-signup'),
                          child: Text(
                            "Sign up",
                            style: const TextStyle(
                              color: ChurchColors.button,
                              fontSize: 16,
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
                      onPressed: _busy != null ? null : _emailLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ChurchColors.button,
                        disabledBackgroundColor: ChurchColors.button,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: ChurchColors.buttonText,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              "Sign In",
                              style: TextStyle(
                                color: ChurchColors.buttonText,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
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
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: ChurchColors.button),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }
}
