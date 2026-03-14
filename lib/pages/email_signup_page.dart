import 'package:church_app/pages/email_login_page.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:church_app/pages/login_page.dart';

class EmailSignupPage extends StatefulWidget {
  const EmailSignupPage({super.key});

  @override
  State<EmailSignupPage> createState() => _EmailLoginPageState();
}

class _EmailLoginPageState extends State<EmailSignupPage> {
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

  void _submit() {
    if (!_termsAccepted || !_privacyAccepted) {
      setState(() {
        _error = "You must accept all policies and terms to continue.";
      });
      return;
    }
    if (_formKey.currentState!.validate()) {
      // TODO: handle submission
      print("Name: ${_nameController.text}");
      print("Email: ${_emailController.text}");
      print("Password: ${_passwordController.text}");
    }
  }

  void _googleSignUp() {}

  void _appleSignUp() {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        // title: const Text("Sign Up", style: TextStyle(color: Colors.black)),
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.white,
        child: ListView(
          padding: const EdgeInsets.all(20),
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
                fontSize: 12,
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
                      if (v == null || v.isEmpty) {
                        return "Please enter your email";
                      }
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
                    "Atleast 8 characters, 1 uppercas, 1 number & 1 symbol",
                    textAlign: TextAlign.left,
                    style: TextStyle(color: Colors.black, fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CheckboxListTile(
                        title: const Text(
                          "By Signing up, you agree to the Terms of Service and Privacy Policy",
                          style: TextStyle(color: Colors.black, fontSize: 12),
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
                          style: TextStyle(color: Colors.black, fontSize: 12),
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

                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),

                        child: SizedBox(
                          width: 56,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _googleSignUp,
                            style: ElevatedButton.styleFrom(
                              side: const BorderSide(
                                color: Color.fromARGB(179, 234, 231, 231),
                                width: 1,
                              ),

                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(49),
                              ),
                              elevation: 2,
                              padding: EdgeInsets.zero,
                            ),
                            child: const Center(
                              child: FaIcon(
                                FontAwesomeIcons.google,
                                size: 24,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          width: 56,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _appleSignUp,
                            style: ElevatedButton.styleFrom(
                              side: const BorderSide(
                                color: Color.fromARGB(179, 234, 231, 231),
                                width: 1,
                              ),

                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(52),
                              ),
                              elevation: 2,
                              padding: EdgeInsets.zero,
                            ),
                            child: const Center(
                              child: FaIcon(
                                FontAwesomeIcons.apple,
                                size: 24,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 16,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Already have an account?",
                          style: TextStyle(color: Colors.black, fontSize: 12),
                        ),
                        SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const EmailLoginPage(),
                            ),
                          ),
                          child: Text(
                            "Login",
                            style: TextStyle(
                              color: Color(0xFF5286FF),
                              fontSize: 12,
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
