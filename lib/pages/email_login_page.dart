import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../services/auth_service.dart';
import '../theme/church_colors.dart';
import '../widgets/church_app_bar.dart';
import '../widgets/auth_ui.dart';

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

  void _forgotPassword() {
    Navigator.pushNamed(context, '/forgot-password');
  }

  @override
  Widget build(BuildContext context) {
    final busy = _busy != null;

    return Scaffold(
      backgroundColor: ChurchColors.background,
      appBar: ChurchAppBar.of(
        toolbarHeight: 56,
        title: const SizedBox.shrink(),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: ChurchColors.accent),
          onPressed: _goBack,
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            const Text("Welcome back", style: kAuthTitleStyle),
            const SizedBox(height: 6),
            const Text("Sign in to your account", style: kAuthSubtitleStyle),
            const SizedBox(height: 24),
            if (_error != null) ...[
              AuthErrorCallout(_error!),
              const SizedBox(height: 16),
            ],
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _emailController,
                    style: const TextStyle(color: ChurchColors.bodyText),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: authInputDecoration(
                      label: "Email",
                      icon: Icons.email_outlined,
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return "Please enter your email";
                      if (!v.contains("@")) return "Please enter a valid email";
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: const TextStyle(color: ChurchColors.bodyText),
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _emailLogin(),
                    decoration: authInputDecoration(
                      label: "Password",
                      icon: Icons.lock_outline,
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
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: _forgotPassword,
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          "Forgot password?",
                          style: TextStyle(
                            color: ChurchColors.accent,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ChurchPrimaryButton(
                    label: "Sign In",
                    loading: _isLoading,
                    onPressed: busy ? null : _emailLogin,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _orDivider(),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ChurchSocialButton(
                    label: "Google",
                    icon: FontAwesomeIcons.google,
                    loading: _busy == 'google',
                    enabled: !busy,
                    onPressed: _googleSignUp,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ChurchSocialButton(
                    label: "Apple",
                    icon: FontAwesomeIcons.apple,
                    loading: _busy == 'apple',
                    enabled: !busy,
                    onPressed: _appleSignUp,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Don't have an account?",
                  style: TextStyle(color: ChurchColors.bodyText, fontSize: 15),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () =>
                      Navigator.pushReplacementNamed(context, '/email-signup'),
                  behavior: HitTestBehavior.opaque,
                  child: const Text(
                    "Sign up",
                    style: TextStyle(
                      color: ChurchColors.button,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _orDivider() {
    return Row(
      children: [
        const Expanded(child: Divider(color: ChurchColors.divider, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'OR',
            style: TextStyle(
              color: ChurchColors.muted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const Expanded(child: Divider(color: ChurchColors.divider, thickness: 1)),
      ],
    );
  }
}
