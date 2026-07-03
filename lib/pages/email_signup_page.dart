import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/gestures.dart';
import 'package:church_app/services/auth_service.dart';
import 'package:church_app/theme/church_colors.dart';
import 'package:church_app/widgets/church_app_bar.dart';
import 'package:church_app/widgets/auth_ui.dart';

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
        _error = "Please accept the terms and consent to continue.";
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
            const Text("Let's get started", style: kAuthTitleStyle),
            const SizedBox(height: 6),
            const Text("Create your account", style: kAuthSubtitleStyle),
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
                    controller: _nameController,
                    style: const TextStyle(color: ChurchColors.bodyText),
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    decoration: authInputDecoration(
                      label: "Name",
                      icon: Icons.person_outline,
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? "Please enter your name"
                        : null,
                  ),
                  const SizedBox(height: 16),
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
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 14,
                        color: ChurchColors.muted,
                      ),
                      const SizedBox(width: 6),
                      const Expanded(
                        child: Text(
                          "At least 8 characters, with an uppercase letter, a number, and a symbol.",
                          style: TextStyle(
                            color: ChurchColors.muted,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _consentTile(
                    value: _termsAccepted,
                    onChanged: (val) => setState(() => _termsAccepted = val),
                    title: Text.rich(
                      TextSpan(
                        style: _consentTextStyle,
                        children: [
                          const TextSpan(text: 'I agree to the '),
                          _linkSpan('Terms of Service', '/terms'),
                          const TextSpan(text: ' and '),
                          _linkSpan('Privacy Policy', '/privacy'),
                          const TextSpan(text: '.'),
                        ],
                      ),
                    ),
                  ),
                  _consentTile(
                    value: _privacyAccepted,
                    onChanged: (val) => setState(() => _privacyAccepted = val),
                    title: const Text(
                      'I consent to biometric and/or Bluetooth technology being used to record my church attendance.',
                      style: _consentTextStyle,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ChurchPrimaryButton(
                    label: "Create Account",
                    loading: _busy == 'email',
                    onPressed: busy ? null : _submit,
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
                    onPressed: _handleGoogle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ChurchSocialButton(
                    label: "Apple",
                    icon: FontAwesomeIcons.apple,
                    loading: _busy == 'apple',
                    enabled: !busy,
                    onPressed: _handleApple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Already have an account?",
                  style: TextStyle(color: ChurchColors.bodyText, fontSize: 15),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () =>
                      Navigator.pushReplacementNamed(context, '/email-login'),
                  behavior: HitTestBehavior.opaque,
                  child: const Text(
                    "Login",
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

  static const TextStyle _consentTextStyle = TextStyle(
    color: ChurchColors.bodyText,
    fontSize: 13.5,
    height: 1.4,
  );

  TextSpan _linkSpan(String text, String route) {
    return TextSpan(
      text: text,
      style: const TextStyle(
        color: ChurchColors.button,
        fontWeight: FontWeight.w600,
        decoration: TextDecoration.underline,
      ),
      recognizer: TapGestureRecognizer()
        ..onTap = () => Navigator.pushNamed(context, route),
    );
  }

  Widget _consentTile({
    required bool value,
    required ValueChanged<bool> onChanged,
    required Widget title,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: value,
                onChanged: (v) => onChanged(v ?? false),
                activeColor: ChurchColors.button,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: title,
              ),
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
