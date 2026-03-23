import 'package:flutter/material.dart';
import 'pages/login_page.dart';
import 'pages/email_login_page.dart';
import 'pages/email_signup_page.dart';
import 'pages/privacy_page.dart';
import 'pages/terms_page.dart';
import 'pages/admin_page.dart';

class AppRoutes {
  static const String login = '/login';
  static const String emailLogin = '/email-login';
  static const String emailSignup = '/email-signup';
  static const String privacy = '/privacy';
  static const String terms = '/terms';
  static const String admin = '/admin';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      login: (context) => const LoginPage(),
      emailLogin: (context) => const EmailLoginPage(),
      emailSignup: (context) => const EmailSignupPage(),
      privacy: (context) => const PrivacyPage(),
      terms: (context) => const TermsPage(),
      admin: (context) => const BottomNavigationBarExample(),
    };
  }
}
