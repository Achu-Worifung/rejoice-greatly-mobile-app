import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/church_colors.dart';
import '../widgets/church_app_bar.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _sending = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    final email = _emailController.text.trim();
    final msg = await AuthService().sendPasswordReset(email);
    if (!mounted) return;
    if (msg != null) {
      setState(() {
        _error = msg;
        _sending = false;
      });
      return;
    }
    setState(() {
      _sent = true;
      _sending = false;
    });
  }

  void _goBack() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacementNamed(context, '/email-login');
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
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            const SizedBox(height: 12),
            const Text(
              'Reset your password',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: ChurchColors.bodyText,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Enter your email and we'll send you a link to reset your password.",
              style: TextStyle(
                fontSize: 14,
                color: ChurchColors.muted,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 32),
            if (_sent) _buildSuccessState() else _buildForm(),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_error != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1EE),
              border: Border.all(color: const Color(0xFFE1B0A9)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              _error!,
              style: const TextStyle(
                color: Color(0xFF8A2C1F),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        Form(
          key: _formKey,
          child: TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autofocus: true,
            style: const TextStyle(color: ChurchColors.bodyText),
            decoration: InputDecoration(
              labelText: 'Email',
              labelStyle: const TextStyle(color: ChurchColors.muted),
              prefixIcon: const Icon(Icons.email_outlined, color: ChurchColors.muted),
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
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Please enter your email';
              if (!v.contains('@')) return 'Please enter a valid email';
              return null;
            },
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _sending ? null : _send,
            style: ElevatedButton.styleFrom(
              backgroundColor: ChurchColors.button,
              disabledBackgroundColor: ChurchColors.button,
              foregroundColor: ChurchColors.buttonText,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _sending
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: ChurchColors.buttonText,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Send reset link',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: GestureDetector(
            onTap: _goBack,
            child: const Text(
              'Back to sign in',
              style: TextStyle(
                color: ChurchColors.accent,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessState() {
    final email = _emailController.text.trim();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: ChurchColors.cardDecoration(),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ChurchColors.button.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.mark_email_read_outlined,
              color: ChurchColors.button,
              size: 32,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Check your inbox',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: ChurchColors.bodyText,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'A password reset link has been sent to\n$email',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: ChurchColors.muted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "If it doesn't arrive within a few minutes, check your spam folder.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: ChurchColors.muted,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _goBack,
              style: ElevatedButton.styleFrom(
                backgroundColor: ChurchColors.button,
                foregroundColor: ChurchColors.buttonText,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Back to sign in',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
