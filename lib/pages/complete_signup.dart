import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui;

class CompleteSignup extends StatefulWidget {
  const CompleteSignup({super.key});

  @override
  State<CompleteSignup> createState() => _CompleteSignupState();
}

class _CompleteSignupState extends State<CompleteSignup> {
  late final html.VideoElement _videoElement;
  html.MediaStream? _mediaStream;

  bool _isCameraReady = false;
  bool _isFrontCamera = true;
  bool _isStarting = false;
  Uint8List? _capturedBytes;
  bool _isLoading = false;
  String? _error;

  final String _viewId = 'camera-view-html-element';

  @override
  void initState() {
    super.initState();
    _setupVideoElement();
    _registerView();
    _startCamera();
  }

  void _setupVideoElement() {
    _videoElement = html.VideoElement()
      ..autoplay = true
      ..muted = true
      ..setAttribute('playsinline', 'true')
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.objectFit = 'cover'
      ..style.transform = 'scaleX(-1)';
  }

  void _registerView() {
    ui.platformViewRegistry.registerViewFactory(
      _viewId,
      (int id) => _videoElement,
    );
  }

  Future<void> _startCamera({bool front = true}) async {
    if (_isStarting) return;
    _isStarting = true;

    try {
      if (_mediaStream != null) {
        for (var track in _mediaStream!.getTracks()) {
          track.stop();
        }
        _mediaStream = null;
      }
      _videoElement.srcObject = null;

      final stream =
          await html.window.navigator.mediaDevices!.getUserMedia({
        'video': {
          'facingMode': front ? 'user' : 'environment',
          'width': {'ideal': 1280},
          'height': {'ideal': 720},
        },
        'audio': false,
      });

      _mediaStream = stream;
      _videoElement.srcObject = stream;
      _videoElement.style.transform =
          front ? 'scaleX(-1)' : 'scaleX(1)';

      _videoElement.onLoadedMetadata.listen((_) async {
        try {
          await _videoElement.play();
        } catch (e) {
          print("Playback error: $e");
        }
      });

      if (mounted) {
        setState(() {
          _isCameraReady = true;
          _isFrontCamera = front;
          _error = null;
        });
      }
    } catch (e) {
      print("Camera Error: $e");
      if (mounted) {
        setState(() => _error =
            "Camera access denied. Please allow permissions and use HTTPS.");
      }
    } finally {
      _isStarting = false;
    }
  }

  void _capturePhoto() {
    if (!_isCameraReady) return;

    final int width = _videoElement.videoWidth;
    final int height = _videoElement.videoHeight;

    final canvas = html.CanvasElement(width: width, height: height);
    final ctx = canvas.context2D;

    if (_isFrontCamera) {
      ctx.translate(width.toDouble(), 0);
      ctx.scale(-1, 1);
    }

    ctx.drawImage(_videoElement, 0, 0);

    canvas.toBlob('image/jpeg', 0.9).then((blob) {
      final reader = html.FileReader();
      reader.readAsArrayBuffer(blob!);
      reader.onLoad.listen((_) {
        if (mounted) {
          setState(() {
            _capturedBytes = reader.result as Uint8List;
            _error = null;
          });
        }
      });
    });
  }

void _retake() {
  setState(() {
    _capturedBytes = null;
    _error = null;
    _isCameraReady = false; // briefly show spinner
  });

  Future.delayed(const Duration(milliseconds: 100), () {
    _videoElement.style.transform =
        _isFrontCamera ? 'scaleX(-1)' : 'scaleX(1)';
    _videoElement.play().then((_) {
      if (mounted) setState(() => _isCameraReady = true);
    });
  });
}

  Future<void> _flipCamera() async {
    if (_isStarting) return;
    setState(() => _isCameraReady = false);
    await _startCamera(front: !_isFrontCamera);
  }

  Future<void> _submitSignup() async {
    if (_capturedBytes == null) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final accountId = prefs.getString("account_id") ?? "";

      if (accountId.isEmpty) {
        setState(() => _error = "Account not found. Please sign up again.");
        return;
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse("http://localhost:8080/profile/picture-upload"),
      );
      

      request.fields['account_id'] = accountId;
      request.files.add(
        http.MultipartFile.fromBytes(
          'Image',
          _capturedBytes!,
          filename: '$accountId' + 'profile.jpg',       
           ),
      );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200 || response.statusCode == 201) {
        //release camera and navigate to admin
        _mediaStream?.getTracks().forEach((t) => t.stop());
        if (mounted) Navigator.pushNamed(context, '/admin');
      } else {
        setState(
            () => _error = "Upload failed. Error: ${response.statusCode}");
        print("Failed: ${response.statusCode} - $responseBody");
      }
    } catch (e) {
      setState(() => _error = "Network error. Is your server running?");
      print("Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _mediaStream?.getTracks().forEach((t) => t.stop());
    _videoElement.srcObject = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _capturedBytes != null ? _buildPreview() : _buildCamera(),
    );
  }

  // ─── Camera Screen ────────────────────────────────────────────────────────

  Widget _buildCamera() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Always keep HtmlElementView mounted — never remove from tree
        HtmlElementView(viewType: _viewId),

        // Show black overlay + spinner while camera is starting
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              children: [
                // Top bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _circleButton(
                        Icons.arrow_back, () => Navigator.pop(context)),
                    const Text(
                      "TAKE A SELFIE FOR IDENTITY VERIFICATION",
                      style: TextStyle(
                        color: Colors.white,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        shadows: [
                          Shadow(blurRadius: 8, color: Colors.black54)
                        ],
                      ),
                    ),
                    // _circleButton(Icons.flip_camera_ios, _flipCamera),
                  ],
                ),

                if (_error != null) ...[
                  const SizedBox(height: 16),
                  _errorBanner(),
                ],

                const Spacer(),

                // Hint
                const Text(
                  "Position your face in the center",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    shadows: [Shadow(blurRadius: 8, color: Colors.black)],
                  ),
                ),
                const SizedBox(height: 32),

                // Shutter row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(width: 50),
                    _shutterButton(),
                    // _circleButton(Icons.flip_camera_ios, _flipCamera),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── Preview Screen ───────────────────────────────────────────────────────

  Widget _buildPreview() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.memory(_capturedBytes!, fit: BoxFit.cover),

        _gradientOverlay(fromTop: true),
        _gradientOverlay(fromTop: false),

        // Top bar
        SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        shadows: [Shadow(blurRadius: 8, color: Colors.black54)],
                      ),
                    ),
                    const SizedBox(width: 44),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Bottom buttons
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 48),
              child: Column(
                children: [
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
                          label: _isLoading ? "Uploading..." : "Use Photo",
                          onTap: _isLoading ? null : _submitSignup,
                          color: const Color(0xFF5286FF),
                          isLoading: _isLoading,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

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
            begin:
                fromTop ? Alignment.topCenter : Alignment.bottomCenter,
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