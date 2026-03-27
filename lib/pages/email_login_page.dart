import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../routes.dart';
import '../services/auth_service.dart';

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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      // TODO: handle submission
      print("Email: ${_emailController.text}");
      print("Password: ${_passwordController.text}");
    }
  }

  Future<void> _emailLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _error = null);

      final msg = await AuthService().signInWithEmail(
        _emailController.text,
        _passwordController.text,
        context,
      );
      print('here is the msg: $msg');

      if (msg != null) {
        setState(() => _error = msg);
        return;
      }
    }
  }

  Future<void> _googleSignUp() async {
    final msg = await AuthService().signInWithGoogle();
    if (msg != null) {
        setState(() => _error = msg);
        return;
      }
  }

  Future<void> _appleSignUp() async{
    final msg = await AuthService().signInWithApple();
    if (msg != null) {
        setState(() => _error = msg);
        return;
      }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80, // adds space to the top
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(""),
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
              "Sign in to your account",
              style: TextStyle(
                color: Colors.black,
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
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _error!,
                  style: TextStyle(
                    color: Colors.red.shade700,
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
                  SizedBox(
                    width: double.infinity,
                    child: GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/login'),
                      child: Text(
                        "Forgot Password?",
                        textAlign: TextAlign.right,
                        style: TextStyle(color: Colors.black, fontSize: 12),
                      ),
                    ),
                  ),

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
                  const SizedBox(height: 10),

                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),

                        child: SizedBox(
                          width: 70,
                          height: 70,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
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
                      ),
                      const SizedBox(width: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          width: 70,
                          height: 70,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
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
                          "Don't have an account?",
                          style: TextStyle(color: Colors.black, fontSize: 12),
                        ),
                        SizedBox(width: 4),
                        GestureDetector(
                          onTap: () =>
                              Navigator.pushNamed(context, '/email-signup'),
                          child: Text(
                            "Sign up",
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
                      onPressed: _emailLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5286FF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: const Text(
                        "Sign In",
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
