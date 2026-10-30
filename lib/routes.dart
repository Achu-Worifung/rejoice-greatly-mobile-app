import 'package:flutter/material.dart';
import 'pages/login_page.dart';
import 'pages/email_login_page.dart';
import 'pages/email_signup_page.dart';
import 'pages/biometric_notice_page.dart';
import 'pages/privacy_page.dart';
import 'pages/terms_page.dart';
import 'pages/dashboard.dart';
import 'pages/complete_signup.dart';
import 'pages/user_prep.dart';
import 'pages/date_of_birth_page.dart';
import 'pages/admin_dashboard.dart' as admin_page;
import 'pages/me_page.dart';
import 'pages/forgot_password_page.dart';
import 'pages/notifications_page.dart';
import 'theme/display_settings.dart';

class AppRoutes {
  static const String login = '/login';
  static const String emailLogin = '/email-login';
  static const String emailSignup = '/email-signup';
  static const String forgotPassword = '/forgot-password';
  static const String privacy = '/privacy';
  static const String terms = '/terms';
  static const String biometricNotice = '/biometric-notice';
  static const String admin = '/admin';
  static const String completeSignup = '/complete-signup';
  static const String dashboard = '/dashboard';
  static const String userPrep = '/user-prep';
  static const String dob = '/date-of-birth';
  static const String profile = '/profile';
  static const String notifications = '/notifications';


  static Map<String, WidgetBuilder> getRoutes() {
    return {
      profile: (context) => const MePage(),
      notifications: (context) => const NotificationsPage(),
      dob: (context) => const DobPage(),
      login: (context) => const LoginPage(),
      emailLogin: (context) => const EmailLoginPage(),
      emailSignup: (context) => const EmailSignupPage(),
      privacy: (context) => const PrivacyPage(),
      terms: (context) => const TermsPage(),
      biometricNotice: (context) => const BiometricNoticePage(),
      // The admin tools have their own colours, drawn for light only.
      admin: (context) => const LightOnly(child: admin_page.AdminDashboard()),
      completeSignup: (context) => const CompleteSignup(),
      dashboard: (context) => const Dashboard(),
      userPrep: (context) => const UserPrepPage(),
      forgotPassword: (context) => const ForgotPasswordPage(),
    };
  }
}