import 'package:flutter/material.dart';
import '../theme/church_colors.dart';
import '../widgets/church_app_bar.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class Cafe extends StatefulWidget {
  const Cafe({super.key});

  @override
  State<Cafe> createState() => _CafeState();
}

class _CafeState extends State<Cafe> {
  late final WebViewController _controller;

  @override
  @override
  void initState() {
    super.initState();
    
    // Initialize the controller
    _controller = WebViewController();

    // 2. The fix for the UnimplementedError on Chrome
    if (!kIsWeb) {
      _controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    }

    // Load the URL
    _controller.loadRequest(Uri.parse('https://moodchangingcafe.vercel.app/'));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent the app from exiting the page immediately
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // If the website has history, go back in the webview
        if (await _controller.canGoBack()) {
          await _controller.goBack();
        } else {
          // Otherwise, allow the app to go back to the previous screen
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: ChurchColors.background,
        appBar: ChurchAppBar.pageTitle(
          'Mood Changing Cafe',
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: ChurchColors.accent),
            onPressed: () async {
              if (await _controller.canGoBack()) {
                _controller.goBack();
              } else {
                Navigator.of(context).pop();
              }
            },
          ),
        ),
        body: WebViewWidget(controller: _controller),
      ),
    );
  }
}