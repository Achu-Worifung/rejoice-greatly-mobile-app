import 'package:flutter/material.dart';
import 'pages/login_page.dart';
import 'pages/email_login_page.dart';
import 'pages/email_signup_page.dart';
import 'pages/privacy_page.dart';
import 'pages/terms_page.dart';
import 'pages/admin_page.dart';
import 'pages/complete_signup.dart';
import 'pages/dashboard.dart';
import 'pages/user_prep.dart';

class AppRoutes {
  static const String login = '/login';
  static const String emailLogin = '/email-login';
  static const String emailSignup = '/email-signup';
  static const String privacy = '/privacy';
  static const String terms = '/terms';
  static const String admin = '/admin';
  static const String completeSignup = '/complete-signup';
  static const String dashboard = '/dashboard';
  static const String userPrep = '/user-prep';


  static Map<String, WidgetBuilder> getRoutes() {
    return {
      login: (context) => const LoginPage(),
      emailLogin: (context) => const EmailLoginPage(),
      emailSignup: (context) => const EmailSignupPage(),
      privacy: (context) => const PrivacyPage(),
      terms: (context) => const TermsPage(),
      admin: (context) => const AdminDashboard(),
      completeSignup: (context) => const CompleteSignup(),
      dashboard: (context) => const Dashboard(),
      userPrep: (context) => const UserPrepPage(),
    };
  }
}
