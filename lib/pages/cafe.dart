import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:webview_flutter/webview_flutter.dart';

import '../services/cafe_sso_service.dart';
import '../theme/church_colors.dart';
import '../util/webview_web_platform.dart';
import '../widgets/church_app_bar.dart';

class Cafe extends StatefulWidget {
  const Cafe({super.key, this.isActive = true, this.onExit});

  /// When false, the tab is off-screen (IndexedStack); skip SSO until visible.
  final bool isActive;

  /// Called when the user backs out of the cafe and the WebView has no
  /// history left (e.g. the dashboard switches back to the home tab).
  final VoidCallback? onExit;

  @override
  State<Cafe> createState() => _CafeState();
}

class _CafeState extends State<Cafe> {
  WebViewController? _controller;
  StreamSubscription<User?>? _authSub;
  bool _pageReady = false;
  bool _syncing = false;
  String? _syncedUid;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      registerWebWebViewPlatform();
    }
    _initWebView();
    _authSub = FirebaseAuth.instance.authStateChanges().listen((_) {
      if (widget.isActive) {
        _syncCafeAuth();
      } else {
        _syncedUid = null;
      }
    });
  }

  @override
  void didUpdateWidget(Cafe oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _syncCafeAuth();
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  void _initWebView() {
    final controller = WebViewController();
    if (!kIsWeb) {
      controller.setJavaScriptMode(JavaScriptMode.unrestricted);
      controller.setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            _pageReady = true;
            if (widget.isActive) {
              _syncCafeAuth();
            }
          },
        ),
      );
    }
    controller.loadRequest(CafeSsoService.cafeUri);
    _controller = controller;
  }

  Future<void> _syncCafeAuth() async {
    final controller = _controller;
    if (controller == null || !_pageReady || _syncing || kIsWeb) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (_syncedUid != null) {
        _syncedUid = null;
        await CafeSsoService.applyToWebView(controller, customToken: null);
      }
      return;
    }

    // Already signed this user into the cafe. Each fetchCustomToken() mints a
    // fresh token, so without this guard every onPageFinished would re-fetch
    // and re-inject, leaving the loading bar running forever.
    if (_syncedUid == user.uid) return;

    _setSyncing(true);
    try {
      final customToken = await CafeSsoService.fetchCustomToken();
      if (!mounted) return;
      if (customToken == null || customToken.isEmpty) return;

      await CafeSsoService.applyToWebView(controller, customToken: customToken);
      _syncedUid = user.uid;
    } catch (e, st) {
      debugPrint('Cafe tab SSO failed: $e\n$st');
    } finally {
      _setSyncing(false);
    }
  }

  void _setSyncing(bool value) {
    if (!mounted || _syncing == value) return;
    setState(() => _syncing = value);
  }

  Future<void> _handleBack(BuildContext context) async {
    final controller = _controller;
    if (controller != null && await controller.canGoBack()) {
      await controller.goBack();
      return;
    }
    if (!context.mounted) return;
    if (widget.onExit != null) {
      widget.onExit!();
    } else if (Navigator.of(context).canPop()) {
      // Never pop the root route: the cafe lives inside the dashboard tab
      // bar, so popping with no route below would blank the app.
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    if (kIsWeb) {
      return Scaffold(
        backgroundColor: ChurchColors.background,
        appBar: ChurchAppBar.pageTitle('Mood Changing Cafe'),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Open the cafe on your phone',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: ChurchColors.bodyText,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Cafe sign-in sync works in the iOS and Android app. '
                  'Or visit ${CafeSsoService.cafeBaseUrl} in your browser.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: ChurchColors.muted, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (controller == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: ChurchColors.button),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handleBack(context);
      },
      child: Scaffold(
        backgroundColor: ChurchColors.background,
        appBar: ChurchAppBar.pageTitle(
          'Mood Changing Cafe',
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: ChurchColors.accent),
            onPressed: () => _handleBack(context),
          ),
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: controller),
            if (_syncing)
              const Align(
                alignment: Alignment.topCenter,
                child: LinearProgressIndicator(
                  color: ChurchColors.button,
                  minHeight: 2,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
