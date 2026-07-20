import 'dart:async';

import 'package:flutter/material.dart';
import '../services/church_api.dart';
import '../services/profile_picture_upload.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../util/video_handler_web.dart'
    if (dart.library.io) '../util/video_handler_mobile.dart';
import '../util/camera_frame.dart';
import '../theme/church_colors.dart';
import '../services/auth_service.dart';
import '../main.dart' show navigatorKey;

import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

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

  // create a FaceDetector instance with desired options
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: true,
      enableClassification: true,
      enableLandmarks: true,
      enableTracking: true,
    ),
  );

  /// Head angles the user has covered so far, purely to nudge the guidance
  /// text — capture itself is driven by how much the pose has changed, not by
  /// these flags.
  bool _seenLeft = false;
  bool _seenRight = false;
  bool _seenDown = false;
  bool _seenCentre = false;

  /// Degrees away from centre that counts as a deliberate turn.
  static const double _turnThreshold = 20;

  /// Lower than [_turnThreshold]: ML Kit under-reports downward pitch and
  /// loses the face as the chin occludes the eyes. Chin-*up* is unreliable on
  /// ML Kit, so it is deliberately never requested.
  static const double _pitchDownThreshold = 12;

  /// Guards against re-entering detection while a frame is still processing.
  bool _isDetecting = false;

  // --- Multi-shot enrolment -------------------------------------------------

  /// Several angles of the same face are captured so the recognition backend
  /// can store multiple "mugs" per member — more embeddings, more robust
  /// matching. Each shot is uploaded as its own picture.
  final List<Uint8List> _shots = [];

  /// Pose of the last captured shot, so the next capture only fires once the
  /// head has moved a meaningful amount — that is what spreads the shots
  /// across angles instead of grabbing near-identical frames.
  double? _lastShotYaw;
  double? _lastShotPitch;

  /// True while a still is being taken (the frame stream is paused for it).
  bool _isCapturing = false;

  /// True once the member taps Continue and moves to the review/submit screen.
  bool _reviewing = false;

  /// Progress text shown while the batch uploads.
  String? _uploadStatus;

  /// Enough distinct shots to enrol; keep capturing up to [_maxShots].
  static const int _minShots = 10;
  static const int _maxShots = 15;

  /// Degrees of yaw/pitch change from the last shot before another is taken.
  static const double _poseDelta = 8;

  bool get _hasEnoughShots => _shots.length >= _minShots;

  String get _headingText {
    if (!_handler.supportsFrameStream) return "Center your face";
    if (_hasEnoughShots) return "That's everything — thank you";
    return "Turn your head slowly";
  }

  /// Nudges the member to keep rotating so shots span several angles. Chin-up
  /// is intentionally never requested — ML Kit reports it unreliably.
  String get _guidanceText {
    if (!_handler.supportsFrameStream) {
      return "Position your face inside the frame and\nlook directly at the camera";
    }
    if (_hasEnoughShots) {
      return "Great — that's plenty. Tap the button to continue.";
    }
    if (!_seenCentre) {
      return "Settle your face inside the frame and\nlook straight at the camera";
    }
    if (!_seenLeft) return "Now turn your head slowly to the left";
    if (!_seenRight) return "And now slowly to the right";
    if (!_seenDown) return "Now tilt your chin down a little";
    return "Keep turning slowly so we catch a few angles";
  }

  void _resetCoverage() {
    _seenCentre = false;
    _seenLeft = false;
    _seenRight = false;
    _seenDown = false;
  }

  @override
  void initState() {
    super.initState();
    _handler = VideoHandler();
    _ensurePostgresAccount();
    // Detection can only start once the camera reports ready.
    _initializeCamera().then((_) => _startFaceDetection());
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
  Future<void> _startFaceDetection() async {
    if (!_isCameraReady || !_handler.supportsFrameStream) return;

    try {
      await _handler.startFrameStream(_onCameraFrame);
    } catch (e) {
      // Detection is a guidance aid; capture must still work without it.
      debugPrint('Could not start face detection: $e');
    }
  }

  Future<void> _onCameraFrame(CameraFrame frame) async {
    if (_isDetecting || !mounted) return;
    _isDetecting = true;

    try {
      final format = InputImageFormatValue.fromRawValue(frame.formatRaw);
      final rotation =
          InputImageRotationValue.fromRawValue(frame.rotationDegrees);
      if (format == null || rotation == null) return;

      final inputImage = InputImage.fromBytes(
        bytes: frame.bytes,
        metadata: InputImageMetadata(
          size: Size(frame.width.toDouble(), frame.height.toDouble()),
          rotation: rotation,
          format: format,
          bytesPerRow: frame.bytesPerRow,
        ),
      );

      final faces = await _faceDetector.processImage(inputImage);
      if (!mounted) return;
      _recordHeadAngles(faces);
    } catch (e) {
      debugPrint('Face detection failed: $e');
    } finally {
      _isDetecting = false;
    }
  }

  /// Tracks head direction (for the guidance nudges) and fires a capture when
  /// the pose has moved enough. Only a single face is tracked — more than one
  /// in frame is ambiguous, so we ignore the frame.
  void _recordHeadAngles(List<Face> faces) {
    // Losing the face entirely is the usual failure when the chin drops.
    if (faces.length != 1) return;

    final face = faces.first;
    final yaw = face.headEulerAngleY; // negative = user's right
    final pitch = face.headEulerAngleX; // positive = chin up
    if (yaw == null || pitch == null) return;

    if (yaw.abs() < 10 && pitch.abs() < 10) _seenCentre = true;
    if (yaw > _turnThreshold) _seenLeft = true;
    if (yaw < -_turnThreshold) _seenRight = true;
    // Chin-down only: ML Kit both under-reports negative pitch and loses the
    // face sooner than it does looking up, so chin-up is left out entirely.
    if (pitch < -_pitchDownThreshold) _seenDown = true;

    _maybeCaptureShot(yaw, pitch);
  }

  /// Fires a capture on the first face seen, then again each time the head has
  /// moved [_poseDelta] degrees from the last shot, until [_maxShots] collected.
  void _maybeCaptureShot(double yaw, double pitch) {
    if (_isCapturing || _shots.length >= _maxShots) return;

    final movedEnough = _lastShotYaw == null ||
        (yaw - _lastShotYaw!).abs() >= _poseDelta ||
        (pitch - _lastShotPitch!).abs() >= _poseDelta;
    if (!movedEnough) return;

    // Fire-and-forget: _isCapturing and the guard above serialise captures.
    unawaited(_captureShot(yaw, pitch));
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

  /// Takes one still for the current pose. The frame stream and takePicture()
  /// contend for the camera, so the stream is paused for the shot and resumed
  /// afterwards unless we have hit [_maxShots].
  Future<void> _captureShot(double yaw, double pitch) async {
    if (_isCapturing || _shots.length >= _maxShots) return;
    _isCapturing = true;
    try {
      await _handler.stopFrameStream();
      final bytes = await _handler.capturePhoto();
      if (bytes != null) {
        _shots.add(bytes);
        _lastShotYaw = yaw;
        _lastShotPitch = pitch;
        if (mounted) {
          setState(() {
            // First shot doubles as the review thumbnail.
            _capturedBytes ??= bytes;
            _error = null;
          });
        }
      }
    } catch (e) {
      debugPrint('Auto-capture failed: $e');
    } finally {
      // Resume guidance/detection for the next angle unless we are full.
      if (mounted && _shots.length < _maxShots) {
        await _startFaceDetection();
      }
      _isCapturing = false;
    }
  }

  /// Leaves the capture screen for the review/submit screen.
  Future<void> _finishCapturing() async {
    await _handler.stopFrameStream();
    if (!mounted) return;
    setState(() => _reviewing = true);
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
      _shots.clear();
      _lastShotYaw = null;
      _lastShotPitch = null;
      _reviewing = false;
      _uploadStatus = null;
      _canuseImg = true;
      _error = null;
      _isCameraReady = false;
      _cameraViewKey = UniqueKey();
      _resetCoverage();
    });

    try {
      await _handler.restartPreview();
      if (!mounted) return;
      setState(() => _isCameraReady = _handler.isCameraReady);
      await _startFaceDetection();
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
      _resetCoverage();
    });
    try {
      await _handler.stopFrameStream();
      await _handler.flipCamera();
      if (mounted) {
        setState(() => _isCameraReady = _handler.isCameraReady);
        await _startFaceDetection();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Failed to switch camera');
      }
    }
  }

  Future<void> _submitSignup() async {
    if (_shots.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _uploadStatus = null;
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

      // Each shot is uploaded as its own encrypted picture and becomes one
      // recognition mug on the backend. A blurry frame from the burst can
      // legitimately fail face validation — skip those and keep the rest, as
      // long as at least one lands.
      String? primaryUrl;
      int uploaded = 0;
      PictureUploadException? faceRejection;

      for (var i = 0; i < _shots.length; i++) {
        if (mounted) {
          setState(() => _uploadStatus = 'Uploading ${i + 1} of ${_shots.length}…');
        }
        try {
          final url = await ProfilePictureUpload.upload(_shots[i]);
          primaryUrl ??= url;
          uploaded++;
        } on PictureUploadException catch (e) {
          // A rejected *face* just means that one frame is unusable. A network
          // or session failure is fatal to the whole batch — rethrow it.
          if (_isFaceRejection(e.kind)) {
            faceRejection = e;
            continue;
          }
          rethrow;
        }
      }

      if (uploaded == 0 || primaryUrl == null) {
        if (!mounted) return;
        setState(() {
          _error = faceRejection?.message ??
              'None of your photos worked. Please retake.';
          _canuseImg = false;
        });
        return;
      }

      final cached = await ChurchApi.getCachedAccountJson();
      final merged = <String, dynamic>{
        if (cached != null) ...cached,
        'imgURL': primaryUrl,
        'signupComplete': true,
      };
      await ChurchApi.persistAccountFromServer(merged);
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/dashboard');
    } on PictureUploadException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        // Only a rejected *face* means the shots are unusable; a network or
        // session failure should leave them retryable as-is.
        _canuseImg = !_isFaceRejection(e.kind);
      });
    } catch (e) {
      debugPrint("Upload error: $e");
      if (!mounted) return;
      setState(() => _error = "Network error. Please try again.");
    } finally {
      if (mounted) setState(() {
        _isLoading = false;
        _uploadStatus = null;
      });
    }
  }

  @override
  void dispose() {
    _handler.stopFrameStream();
    _handler.dispose();
    _faceDetector.close();
    super.dispose();
  }

  /// Whether the backend rejected the photo itself, as opposed to failing to
  /// deliver it.
  bool _isFaceRejection(PictureUploadError kind) =>
      kind == PictureUploadError.faceNotClear ||
      kind == PictureUploadError.multipleFaces ||
      kind == PictureUploadError.noFaceDetected;

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
          _reviewing ? _buildPreview() : _buildCamera(),
          if (_error != null &&
              _error!.contains('register your account') &&
              !_reviewing)
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
                Text(
                  _headingText,
                  style: const TextStyle(
                    color: ChurchColors.buttonText,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _guidanceText,
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
                    _circleButton(Icons.close, _retake, _isLoading),
                    Text(
                      _shots.length == 1
                          ? "USE THIS PHOTO?"
                          : "USE THESE ${_shots.length} PHOTOS?",
                      style: const TextStyle(
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
                        onTap: _isLoading ? null : _retake,
                        color: ChurchColors.buttonText.withValues(alpha: 0.15),
                        border: ChurchColors.buttonText.withValues(alpha: 0.3),
                        textColor: ChurchColors.buttonText,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: _bottomButton(
                        label: _isLoading
                            ? (_uploadStatus ?? "Uploading…")
                            : "Use ${_shots.length == 1 ? 'Photo' : 'Photos'}",
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
    // Capture is automatic as the head turns; this button confirms and moves
    // on. Where live detection is unavailable (web) there is no auto-capture,
    // so allow a single manual shot instead.
    final manual = !_handler.supportsFrameStream;
    final ready = manual ? _shots.isEmpty : _hasEnoughShots;
    final onTap = manual ? _captureManualShot : (ready ? _finishCapturing : null);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!manual)
          Text(
            "${_shots.length} / $_maxShots captured",
            style: TextStyle(
              color: ChurchColors.buttonText.withValues(alpha: 0.9),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: onTap,
          child: AnimatedOpacity(
            opacity: (manual || ready) ? 1 : 0.4,
            duration: const Duration(milliseconds: 250),
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                color: Colors.white.withValues(alpha: 0.2),
              ),
              child: Center(
                child: manual
                    ? Container(
                        width: 62,
                        height: 62,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        ready ? Icons.check : Icons.hourglass_bottom,
                        color: Colors.white,
                        size: 34,
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Manual single capture for platforms without a live detection stream
  /// (web): grab one shot and go straight to review.
  Future<void> _captureManualShot() async {
    await _captureShot(0, 0);
    if (!mounted || _shots.isEmpty) return;
    setState(() => _reviewing = true);
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
        color: Colors.red.withValues(alpha: 0.85),
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