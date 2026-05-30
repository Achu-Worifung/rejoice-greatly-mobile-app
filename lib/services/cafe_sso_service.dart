import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';

import 'church_api.dart';

/// Passes the native app's Firebase session into the Mood Changing Cafe WebView.
class CafeSsoService {
  CafeSsoService._();

  static String get cafeBaseUrl =>
      dotenv.env['CAFE_WEB_URL'] ?? 'https://moodchangingcafe.vercel.app';

  static Uri get cafeUri {
    final base = cafeBaseUrl.endsWith('/')
        ? cafeBaseUrl.substring(0, cafeBaseUrl.length - 1)
        : cafeBaseUrl;
    return Uri.parse('$base/');
  }

  static Future<String?> fetchCustomToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    String? idToken;
    try {
      idToken = await user.getIdToken(true);
    } catch (e) {
      debugPrint('CafeSso: getIdToken failed: $e');
      idToken = await user.getIdToken();
    }
    if (idToken == null || idToken.isEmpty) return null;

    final uri = Uri.parse('${ChurchApi.baseUrl}/auth/custom-token');
    final r = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'idToken': idToken}),
        )
        .timeout(const Duration(seconds: 30));

    if (r.statusCode != 200) {
      throw Exception('auth/custom-token failed: ${r.statusCode} ${r.body}');
    }
    final map = json.decode(r.body) as Map<String, dynamic>;
    return map['customToken'] as String?;
  }

  /// Injects cafe SSO into the loaded page (same origin as moodchangingcafe.vercel.app).
  static Future<void> applyToWebView(
    WebViewController controller, {
    required String? customToken,
  }) async {
    if (kIsWeb) return;

    final tokenJson = json.encode(customToken);
    final script = customToken != null
        ? _signInScript(tokenJson)
        : _signOutScript();

    try {
      await controller.runJavaScript(script);
    } catch (e, st) {
      debugPrint('CafeSso: runJavaScript failed: $e\n$st');
    }
  }

  static String _signInScript(String tokenJson) => '''
(function() {
  try {
    var token = $tokenJson;
    if (!token) return;
    localStorage.setItem('rejoice_native_custom_token', token);
    localStorage.setItem('rejoice_native_auth_pending', '1');
    window.dispatchEvent(new CustomEvent('rejoice-native-auth', { detail: { customToken: token } }));
    if (typeof firebase !== 'undefined' && firebase.auth) {
      firebase.auth().signInWithCustomToken(token).then(function() {
        localStorage.removeItem('rejoice_native_custom_token');
        localStorage.removeItem('rejoice_native_auth_pending');
        console.log('[Rejoice] Cafe SSO complete');
      }).catch(function(err) {
        console.warn('[Rejoice] firebase.auth signIn failed', err);
      });
    }
  } catch (e) {
    console.warn('[Rejoice] native auth inject error', e);
  }
})();
''';

  static String _signOutScript() => '''
(function() {
  try {
    localStorage.removeItem('rejoice_native_custom_token');
    localStorage.removeItem('rejoice_native_auth_pending');
    if (typeof firebase !== 'undefined' && firebase.auth) {
      firebase.auth().signOut();
    }
  } catch (e) {}
})();
''';
}
