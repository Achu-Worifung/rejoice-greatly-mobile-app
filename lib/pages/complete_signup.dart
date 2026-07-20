import 'package:flutter/material.dart';
import '../services/church_api.dart';
import '../services/profile_picture_upload_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../util/video_handler_web.dart'
    if (dart.library.io) '../util/video_handler_mobile.dart';
import '../theme/church_colors.dart';
import '../services/auth_service.dart';
import '../main.dart' show navigatorKey;

class CompleteSignup extends StatefulWidget {
  const CompleteSignup({super.key});

  @override
  State<CompleteSignup> createState() => _CompleteSignupState();
}

class _CompleteSignupState extends State<CompleteSignup> {
  late VideoHandler _handler;
  Uint8List? _capturedBytes;
  bool _isLoading = false;
  bool _isRegisteringAccount = true;
  String? _error;
  bool _isCameraReady = false;
  bool _canuseImg = true;
  Key _cameraViewKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _handler = VideoHandler();
    _initializeCamera();
    _ensurePostgresAccount();
  }

  /// Parent-app users may exist in Firebase only; upsert before photo upload.
  Future<void> _ensurePostgresAccount() async {
    setState(() {
      _isRegisteringAccount = true;
      _error = null;
    });
    try {
      await ChurchApi.ensurePostgresAccount();
      if (!mounted) return;
      setState(() => _isRegisteringAccount = false);
    } catch (e, st) {
      debugPrint('CompleteSignup: ensurePostgresAccount failed: $e\n$st');
      if (!mounted) return;
      setState(() {
        _isRegisteringAccount = false;
        _error =
            'Could not register your account on the server. Check your connection and tap Retry.';
      });
    }
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
      if (!mounted) return;
      setState(() => _error = "Failed to capture photo");
    }
  }

  /// This screen can be the root route (RootPage shows it directly when a
  /// signed-in user has not finished signup), in which case there is nothing
  /// to pop — sign out and let RootPage show the login screen instead.
  Future<void> _goBack() async {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
      return;
    }
    await AuthService().logout();
    navigatorKey.currentState?.pushNamedAndRemoveUntil('/', (route) => false);
  }

  Future<void> _retake() async {
    setState(() {
      _capturedBytes = null;
      _error = null;
      _isCameraReady = false;
      _cameraViewKey = UniqueKey();
    });

    try {
      await _handler.restartPreview();
      if (!mounted) return;
      setState(() => _isCameraReady = _handler.isCameraReady);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not restart camera. Try the flip button.';
        _isCameraReady = false;
      });
    }
  }

  Future<void> _flipCamera() async {
    setState(() {
      _isCameraReady = false;
      _cameraViewKey = UniqueKey();
    });
    try {
      await _handler.flipCamera();
      if (mounted) {
        setState(() => _isCameraReady = _handler.isCameraReady);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Failed to switch camera');
      }
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

      try {
        await ChurchApi.ensurePostgresAccount();
      } catch (e, st) {
        debugPrint('CompleteSignup: pre-upload sync failed: $e\n$st');
        if (!mounted) return;
        setState(() => _error =
            'Your account is not on the server yet. Check your connection and try again.');
        return;
      }

      // Fresh Firebase ID token: the backend authenticates the upload and the
      // commit with it (no more firebaseUid form field).
      final idToken = await user.getIdToken();
      if (idToken == null || idToken.isEmpty) {
        if (!mounted) return;
        setState(() => _error = "Not authenticated");
        return;
      }

      // Encrypt on-device and PUT straight to Azure under a short-lived SAS,
      // then commit so the backend validates the face and publishes the photo.
      final imgUrl = await ProfilePictureUploadService.upload(
        idToken: idToken,
        jpegBytes: _capturedBytes!,
      );

      final cached = await ChurchApi.getCachedAccountJson();
      final merged = <String, dynamic>{
        if (cached != null) ...cached,
        if (imgUrl.isNotEmpty) 'imgURL': imgUrl,
        'signupComplete': true,
      };
      await ChurchApi.persistAccountFromServer(merged);
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/dashboard');
    } on PictureUploadException catch (e) {
      if (!mounted) return;
      // Face-quality failures mean the shot is unusable — force a retake.
      final retake = e.code == 'NO_FACE_DETECTED' ||
          e.code == 'MULTIPLE_FACES' ||
          e.code == 'FACE_NOT_CLEAR';
      setState(() {
        if (retake) _canuseImg = false;
        _error = _messageForUploadCode(e.code, e.message);
      });
    } catch (e) {
      debugPrint("Upload error: $e");
      if (!mounted) return;
      setState(() => _error = "Network error. Please try again.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _messageForUploadCode(String code, String serverMessage) {
    switch (code) {
      case 'NO_FACE_DETECTED':
        return 'No face detected. Use a clear front-facing photo.';
      case 'MULTIPLE_FACES':
        return 'Multiple faces detected. Use a photo with only you in frame.';
      case 'FACE_NOT_CLEAR':
        return 'Facial image not clear enough.';
      case 'UPLOAD_TOKEN_EXPIRED':
        return 'Your upload session expired. Please try again.';
      case 'TOO_MANY_UPLOADS':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'UPLOAD_TOO_LARGE':
        return 'That photo is too large. Please try again.';
      default:
        return serverMessage.isNotEmpty
            ? serverMessage
            : 'Upload failed. Please try again.';
    }
  }

  @override
  void dispose() {
    _handler.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isRegisteringAccount) {
      return const Scaffold(
        backgroundColor: ChurchColors.bodyText,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: ChurchColors.button),
              SizedBox(height: 16),
              Text(
                'Setting up your account…',
                style: TextStyle(color: ChurchColors.buttonText, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: ChurchColors.bodyText,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _capturedBytes != null ? _buildPreview() : _buildCamera(),
          if (_error != null &&
              _error!.contains('register your account') &&
              _capturedBytes == null)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 80, 20, 0),
                child: Column(
                  children: [
                    _errorBanner(),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _ensurePostgresAccount,
                      child: const Text(
                        'Retry',
                        style: TextStyle(color: ChurchColors.button),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCamera() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Use the handler's buildCameraView method - works for both web and mobile
        KeyedSubtree(
          key: _cameraViewKey,
          child: _handler.buildCameraView(),
        ),

        if (!_isCameraReady)
          const ColoredBox(
            color: ChurchColors.bodyText,
            child: Center(
              child: CircularProgressIndicator(color: ChurchColors.button),
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
                    _circleButton(Icons.arrow_back, _goBack, false),
                    const Text(
                      "TAKE A SELFIE",
                      style: TextStyle(
                        color: ChurchColors.buttonText,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 1,
                      ),
                    ),
                    _circleButton(Icons.flip_camera_ios, _flipCamera, false),
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
                    color: ChurchColors.buttonText,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Position your face inside the frame and\nlook directly at the camera",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: ChurchColors.buttonText.withValues(alpha: 0.75),
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
                    _circleButton(Icons.close, _retake, !_canuseImg),
                    const Text(
                      "USE THIS PHOTO?",
                      style: TextStyle(
                        color: ChurchColors.buttonText,
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
                        color: ChurchColors.buttonText.withValues(alpha: 0.15),
                        border: ChurchColors.buttonText.withValues(alpha: 0.3),
                        textColor: ChurchColors.buttonText,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: _bottomButton(
                        label: _isLoading ? "Uploading..." : "Use This Photo",
                        onTap: _isLoading ? null : _submitSignup,
                        color: ChurchColors.button,
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
            colors: [
              ChurchColors.bodyText.withValues(alpha: 0.65),
              Colors.transparent,
            ],
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
          color: Colors.white.withValues(alpha: 0.2),
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

  Widget _circleButton(IconData icon, VoidCallback onTap, bool disabled) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Container(

        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: ChurchColors.bodyText.withValues(alpha: 0.45),
          border: Border.all(color: ChurchColors.buttonText.withValues(alpha: 0.35)),
        ),
        child: Icon(icon, color: ChurchColors.buttonText, size: 22),
      ),
    );
  }

  Widget _bottomButton({
    required String label,
    required VoidCallback? onTap,
    required Color color,
    Color? border,
    Color textColor = ChurchColors.buttonText,
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
              ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: textColor,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  label,
                  style: TextStyle(
                    color: textColor,
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