import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../util/video_handler_web.dart'
    if (dart.library.io) '../util/video_handler_mobile.dart';

class CompleteSignup extends StatefulWidget {
  const CompleteSignup({super.key});

  @override
  State<CompleteSignup> createState() => _CompleteSignupState();
}

class _CompleteSignupState extends State<CompleteSignup> {
  late VideoHandler _handler;
  Uint8List? _capturedBytes;
  bool _isLoading = false;
  String? _error;
  bool _isCameraReady = false;

  @override
  void initState() {
    super.initState();
    _handler = VideoHandler();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      await _handler.initCamera(front: true);
      if (mounted) {
        setState(() {
          _isCameraReady = true;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "Camera access denied. Please allow permissions.";
          _isCameraReady = false;
        });
      }
    }
  }

  Future<void> _capturePhoto() async {
    try {
      final bytes = await _handler.capturePhoto();
      if (bytes != null && mounted) {
        setState(() {
          _capturedBytes = bytes;
          _error = null;
        });
      }
    } catch (e) {
      setState(() => _error = "Failed to capture photo");
    }
  }

  void _retake() {
    setState(() {
      _capturedBytes = null;
      _error = null;
    });
  }

  Future<void> _flipCamera() async {
    setState(() => _isCameraReady = false);
    try {
      await _handler.flipCamera();
      if (mounted) {
        setState(() => _isCameraReady = true);
      }
    } catch (e) {
      setState(() => _error = "Failed to switch camera");
    }
  }

  Future<void> _submitSignup() async {
    if (_capturedBytes == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => _error = "Not authenticated");
        return;
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse("http://localhost:8080/profile/picture-upload"),
      );

      request.fields['firebaseUid'] = user.uid;
      request.files.add(
        http.MultipartFile.fromBytes(
          'Image',
          _capturedBytes!,
          filename: 'profile.jpg',
        ),
      );

      final response = await request.send();

      if (response.statusCode == 200 || response.statusCode == 201) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool("signupComplete", true);

        final isAdmin = prefs.getBool("admin") ?? false;

        if (mounted) {
          Navigator.pushReplacementNamed(
            context,
            isAdmin ? '/admin' : '/dashboard',
          );
        }
      } else {
        setState(() => _error = "Upload failed: ${response.statusCode}");
      }
    } catch (e) {
      setState(() => _error = "Network error. Please try again.");
      print("Upload error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _handler.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _capturedBytes != null ? _buildPreview() : _buildCamera(),
    );
  }

  Widget _buildCamera() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Use the handler's buildCameraView method - works for both web and mobile
        _handler.buildCameraView(),

        if (!_isCameraReady)
          const ColoredBox(
            color: Colors.black,
            child: Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ),

        _gradientOverlay(fromTop: true),
        _gradientOverlay(fromTop: false),

        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _circleButton(Icons.arrow_back, () => Navigator.pop(context)),
                    const Text(
                      "TAKE A SELFIE",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 1,
                      ),
                    ),
                    _circleButton(Icons.flip_camera_ios, _flipCamera),
                  ],
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  _errorBanner(),
                ],
                const Spacer(),
                const Text(
                  "Center your face",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Position your face inside the frame and\nlook directly at the camera",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 32),
                _shutterButton(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreview() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.memory(_capturedBytes!, fit: BoxFit.cover),
        _gradientOverlay(fromTop: true),
        _gradientOverlay(fromTop: false),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _circleButton(Icons.close, _retake),
                    const Text(
                      "USE THIS PHOTO?",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(width: 44),
                  ],
                ),
                const Spacer(),
                if (_error != null) ...[
                  _errorBanner(),
                  const SizedBox(height: 16),
                ],
                Row(
                  children: [
                    Expanded(
                      child: _bottomButton(
                        label: "Retake",
                        onTap: _retake,
                        color: Colors.white.withOpacity(0.15),
                        border: Colors.white30,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: _bottomButton(
                        label: _isLoading ? "Uploading..." : "Use This Photo",
                        onTap: _isLoading ? null : _submitSignup,
                        color: const Color(0xFF5286FF),
                        isLoading: _isLoading,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _gradientOverlay({required bool fromTop}) {
    return Positioned(
      top: fromTop ? 0 : null,
      bottom: fromTop ? null : 0,
      left: 0,
      right: 0,
      height: 200,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: fromTop ? Alignment.topCenter : Alignment.bottomCenter,
            end: fromTop ? Alignment.bottomCenter : Alignment.topCenter,
            colors: [Colors.black.withOpacity(0.65), Colors.transparent],
          ),
        ),
      ),
    );
  }

  Widget _shutterButton() {
    return GestureDetector(
      onTap: _capturePhoto,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
          color: Colors.white.withOpacity(0.2),
        ),
        child: Center(
          child: Container(
            width: 62,
            height: 62,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _circleButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withOpacity(0.35),
          border: Border.all(color: Colors.white24),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }

  Widget _bottomButton({
    required String label,
    required VoidCallback? onTap,
    required Color color,
    Color? border,
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          border: border != null ? Border.all(color: border) : null,
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _errorBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.85),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _error!,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}