import 'dart:async';

import 'package:flutter/material.dart';
import '../services/church_api.dart';
import '../services/profile_picture_upload.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../util/video_handler_web.dart'
    if (dart.library.io) '../util/video_handler_mobile.dart';
import '../util/camera_frame.dart';
import '../util/frame_to_jpeg.dart';
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
  bool _isRegisteringAccount = true;
  String? _error;
  bool _isCameraReady = false;
  bool _canuseImg = true;
  Key _cameraViewKey = UniqueKey();

  // create a FaceDetector instance with desired options
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: false,
      enableClassification: false,
      enableLandmarks: false,
      enableTracking: false,
      performanceMode: FaceDetectorMode.fast,
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

  /// Still below [_turnThreshold]: ML Kit under-reports downward pitch and loses
  /// the face as the chin occludes the eyes, so we can't demand a full turn's
  /// worth of tilt — but we ask for a clear, deliberate chin-down and grab the
  /// shot immediately the first frame we see it (see [_recordHeadAngles]).
  /// Chin-*up* is unreliable in the other direction, so it is deliberately
  /// never requested.
  static const double _pitchDownThreshold = 14;

  /// Guards against re-entering detection while a frame is still processing.
  bool _isDetecting = false;

  /// Most recent preview frame, kept so a capture can be encoded straight
  /// from the buffer instead of stopping the stream to call takePicture().
  CameraFrame? _lastFrame;

  /// Throttles ML Kit calls so a slow/mid-range chip isn't fed a detection
  /// request on every single preview frame (source of jank on devices like
  /// the Galaxy S10e). Adaptive: poll quickly while hunting for a face, then
  /// back off once one is being tracked — ~5Hz is plenty to follow a head
  /// turning slowly, and most detection work on a "found" frame is spent
  /// waiting on the next capture anyway.
  DateTime? _lastDetectionAt;
  bool _faceTracked = false;
  static const _searchingDetectionGap = Duration(milliseconds: 80);
  static const _trackingDetectionGap = Duration(milliseconds: 200);
  Duration get _minDetectionGap =>
      _faceTracked ? _trackingDetectionGap : _searchingDetectionGap;

  // --- Multi-shot enrolment -------------------------------------------------

  /// Several angles of the same face are captured so the recognition backend
  /// can store multiple "mugs" per member — more embeddings, more robust
  /// matching. Each shot is uploaded as its own picture.
  final List<Uint8List> _shots = [];

  /// The head angle each captured shot belongs to, kept parallel to [_shots]
  /// so the per-angle cap ([_maxShotsPerSide]) can spread the batch across
  /// sides instead of letting one long sweep consume it.
  final List<_ShotBucket> _shotBuckets = [];

  /// Pose of the last captured shot, so the next capture only fires once the
  /// head has moved a meaningful amount — that is what spreads the shots
  /// across angles instead of grabbing near-identical frames.
  double? _lastShotYaw;
  double? _lastShotPitch;

  /// True while a still is being taken (the frame stream is paused for it).
  bool _isCapturing = false;

  /// Which screen the flow is on: auto-capturing, uploading, or the final
  /// "all done" page. Capture is fully automatic — there is no manual shutter
  /// on mobile and no review/retake step.
  _SignupPhase _phase = _SignupPhase.capturing;

  /// The frontal shot chosen as the profile picture (the most squarely centred
  /// face): its index in [_shots] and its score (lower = more frontal), so a
  /// better one can take over as capture continues. [_capturedBytes] mirrors
  /// the current pick for the later screens to display.
  int? _frontalIndex;
  double _frontalScore = double.infinity;

  /// Once enough shots exist, finish shortly after capture stalls, so the flow
  /// never hangs waiting on the (unreliable) chin-down or a capped angle.
  Timer? _settleTimer;
  static const _settleAfter = Duration(seconds: 3);

  /// Progress text shown while the batch uploads.
  String? _uploadStatus;

  /// Enough distinct shots to enrol; keep capturing up to [_maxShots].
  static const int _minShots = 10;
  static const int _maxShots = 15;

  /// Most shots kept for any single angle (centre / left / right / chin-down),
  /// so a long sweep to one side can't eat the whole batch and starve the
  /// others. Four angles × this cap comfortably covers [_maxShots]. Tunable.
  static const int _maxShotsPerSide = 4;

  /// Degrees of yaw/pitch change from the last shot before another is taken.
  static const double _poseDelta = 8;

  bool get _hasEnoughShots => _shots.length >= _minShots;

  /// Nothing left to nudge for: every angle we ask about (centre, left, right,
  /// chin-down) has been covered, or we've simply hit the hard shot cap. Used
  /// for the heading/guidance/arrow only — the Continue button unlocks earlier,
  /// at [_hasEnoughShots], so the member is never blocked if ML Kit fails to
  /// register the (deliberately shallow, unreliable) chin-down.
  ///
  /// Note this deliberately does *not* short-circuit on [_hasEnoughShots]: the
  /// left/right sweep alone usually reaches 10 shots before the chin-down step,
  /// and gating on the count there meant the chin-down cue never appeared.
  bool get _coverageComplete =>
      _shots.length >= _maxShots || (_hasEnoughShots && _seenDown);

  String get _headingText {
    if (!_handler.supportsFrameStream) return "Center your face";
    if (_coverageComplete) return "That's everything — thank you";
    return "Turn your head slowly";
  }

  /// Nudges the member to keep rotating so shots span several angles. Chin-up
  /// is intentionally never requested — ML Kit reports it unreliably.
  String get _guidanceText {
    if (!_handler.supportsFrameStream) {
      return "Position your face inside the frame and\nlook directly at the camera";
    }
    if (_coverageComplete) {
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

  /// The head movement currently being requested, so the preview can show a
  /// matching directional cue alongside the text nudge. Null while the member
  /// is still centring, or once every angle is covered.
  _GuidanceDirection? get _currentDirection {
    if (!_handler.supportsFrameStream || _coverageComplete || !_seenCentre) {
      return null;
    }
    if (!_seenLeft) return _GuidanceDirection.left;
    if (!_seenRight) return _GuidanceDirection.right;
    if (!_seenDown) return _GuidanceDirection.down;
    return null;
  }

  void _resetCoverage() {
    _seenCentre = false;
    _seenLeft = false;
    _seenRight = false;
    _seenDown = false;
    _faceTracked = false;
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
    if (!mounted) return;
    // Always kept fresh, independent of the detection throttle below, so a
    // capture can grab the most recent frame rather than a stale one.
    _lastFrame = frame;
    if (_isDetecting) return;

    final now = DateTime.now();
    if (_lastDetectionAt != null &&
        now.difference(_lastDetectionAt!) < _minDetectionGap) {
      return;
    }
    _lastDetectionAt = now;
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
    _faceTracked = faces.length == 1;
    // Losing the face entirely is the usual failure when the chin drops.
    if (faces.length != 1) return;

    final face = faces.first;
    final yaw = face.headEulerAngleY; // negative = user's right
    final pitch = face.headEulerAngleX; // positive = chin up
    if (yaw == null || pitch == null) return;

    if (yaw.abs() < 10 && pitch.abs() < 10) _seenCentre = true;
    if (yaw > _turnThreshold) _seenLeft = true;
    if (yaw < -_turnThreshold) _seenRight = true;

    // Chin-down is unreliable: ML Kit both under-reports negative pitch and
    // loses the face as the chin occludes the eyes. So the first frame we do
    // see it, grab a shot immediately rather than waiting for the usual
    // pose-change gate — that window may not come again. (Chin-up is left out
    // entirely; it is unreliable in the other direction.)
    final chinDownNow = pitch < -_pitchDownThreshold;
    final firstChinDown = chinDownNow && !_seenDown;
    if (chinDownNow) _seenDown = true;

    _maybeCaptureShot(yaw, pitch, force: firstChinDown);
  }

  /// Fires a capture on the first face seen, on the first chin-down frame
  /// ([force]), and otherwise each time the head has moved [_poseDelta] degrees
  /// from the last shot — until [_maxShots] are collected, and never more than
  /// [_maxShotsPerSide] for any one angle.
  void _maybeCaptureShot(double yaw, double pitch, {bool force = false}) {
    // Ignore frames still arriving after we've left the capture phase, so a
    // late shot can't mutate _shots while the upload loop is iterating it.
    if (_phase != _SignupPhase.capturing) return;
    if (_isCapturing || _shots.length >= _maxShots) return;

    // Per-angle cap so one long sweep can't consume the whole batch.
    final bucket = _bucketFor(yaw, pitch);
    if (_countForBucket(bucket) >= _maxShotsPerSide) return;

    if (!force) {
      final movedEnough = _lastShotYaw == null ||
          (yaw - _lastShotYaw!).abs() >= _poseDelta ||
          (pitch - _lastShotPitch!).abs() >= _poseDelta;
      if (!movedEnough) return;
    }

    // Fire-and-forget: _isCapturing and the guard above serialise captures.
    unawaited(_captureShot(yaw, pitch));
  }

  /// Classifies a pose into the angle "bucket" it counts against. Chin-down
  /// wins over yaw so a downward shot isn't miscounted as centre/left/right.
  _ShotBucket _bucketFor(double yaw, double pitch) {
    if (pitch < -_pitchDownThreshold) return _ShotBucket.down;
    if (yaw > _turnThreshold) return _ShotBucket.left;
    if (yaw < -_turnThreshold) return _ShotBucket.right;
    return _ShotBucket.centre;
  }

  int _countForBucket(_ShotBucket bucket) {
    var n = 0;
    for (final b in _shotBuckets) {
      if (b == bucket) n++;
    }
    return n;
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

  /// Takes one still for the current pose. Where a live frame stream exists
  /// (mobile), the shot is decoded straight from the most recently buffered
  /// preview frame — the stream is never stopped, so there is no
  /// takePicture()/stream-toggle to contend with or hang (that toggle was
  /// the source of freezes on some Android devices). Platforms without a
  /// stream (web) fall back to the handler's own still-capture call.
  Future<void> _captureShot(double yaw, double pitch) async {
    if (_isCapturing || _shots.length >= _maxShots) return;
    _isCapturing = true;
    try {
      final bytes = _handler.supportsFrameStream
          ? await _captureFromBufferedFrame()
          : await _captureFromHandler();

      if (bytes == null) {
        if (mounted) {
          setState(() {
            _error = "That shot didn't come through. Keep turning slowly.";
          });
        }
      } else {
        final bucket = _bucketFor(yaw, pitch);
        _shots.add(bytes);
        _shotBuckets.add(bucket);
        _lastShotYaw = yaw;
        _lastShotPitch = pitch;
        _registerFrontalCandidate(_shots.length - 1, bucket, yaw, pitch, bytes);
        if (mounted) setState(() => _error = null);
      }
    } catch (e) {
      debugPrint('Auto-capture failed: $e');
    } finally {
      _isCapturing = false;
      if (mounted) _afterCapture();
    }
  }

  /// Chooses the profile picture as capture goes: the most frontal (centre)
  /// shot — smallest combined yaw+pitch, i.e. looking most squarely at the
  /// camera. Non-centre shots seed [_capturedBytes] only as a fallback so the
  /// later screens always have an image to show.
  void _registerFrontalCandidate(
      int index, _ShotBucket bucket, double yaw, double pitch, Uint8List bytes) {
    if (bucket != _ShotBucket.centre) {
      _capturedBytes ??= bytes;
      return;
    }
    final score = yaw.abs() + pitch.abs();
    if (score < _frontalScore) {
      _frontalScore = score;
      _frontalIndex = index;
      _capturedBytes = bytes;
    }
  }

  /// Runs after each shot lands (mobile only — web finishes via the manual
  /// shutter). Finishes immediately once every angle is covered, otherwise —
  /// once we have enough — finishes after a short lull so the flow can't stall
  /// on the unreliable chin-down or a side that's hit its cap.
  void _afterCapture() {
    if (_phase != _SignupPhase.capturing) return;
    if (_coverageComplete) {
      unawaited(_finishCapturing());
    } else if (_hasEnoughShots) {
      _scheduleSettle();
    }
  }

  void _scheduleSettle() {
    _settleTimer?.cancel();
    _settleTimer = Timer(_settleAfter, () {
      if (mounted && _phase == _SignupPhase.capturing && _hasEnoughShots) {
        unawaited(_finishCapturing());
      }
    });
  }

  /// Encodes the most recently buffered preview frame to JPEG on a worker
  /// isolate. Doesn't touch the camera at all, so it can't race or hang the
  /// capture pipeline the way stopping/restarting the stream around
  /// takePicture() could on some devices (notably Samsung/Exynos).
  Future<Uint8List?> _captureFromBufferedFrame() async {
    final frame = _lastFrame;
    if (frame == null) return null;

    final format = InputImageFormatValue.fromRawValue(frame.formatRaw);
    if (format == null) return null;

    final request = FrameJpegRequest(
      bytes: Uint8List.fromList(frame.bytes),
      width: frame.width,
      height: frame.height,
      bytesPerRow: frame.bytesPerRow,
      rotationDegrees: frame.rotationDegrees,
      isNv21: format == InputImageFormat.nv21,
    );

    try {
      return await compute(encodeFrameToJpeg, request)
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('Frame-to-JPEG encode failed: $e');
      return null;
    }
  }

  /// Fallback for platforms without a live frame stream (web): use the
  /// handler's own still-capture call.
  Future<Uint8List?> _captureFromHandler() async {
    try {
      return await _handler.capturePhoto().timeout(
            const Duration(seconds: 5),
            onTimeout: () => null,
          );
    } catch (e) {
      debugPrint('capturePhoto failed: $e');
      return null;
    }
  }

  /// All the shots we need are in — stop the camera and upload straight away.
  /// There is no review step: on success the flow lands on the "all done" page.
  Future<void> _finishCapturing() async {
    if (_phase != _SignupPhase.capturing) return;
    _settleTimer?.cancel();
    setState(() => _phase = _SignupPhase.submitting);
    await _handler.stopFrameStream();
    if (!mounted) return;
    await _submitSignup();
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

  /// Clears the batch and returns to the camera to start capture over. Only
  /// reached from the upload screen when every frame was rejected — there is no
  /// per-shot retake in the automatic flow.
  Future<void> _restartCapture() async {
    setState(() {
      _shots.clear();
      _shotBuckets.clear();
      _frontalIndex = null;
      _frontalScore = double.infinity;
      _capturedBytes = null;
      _lastShotYaw = null;
      _lastShotPitch = null;
      _resetCoverage();
      _error = null;
      _canuseImg = true;
      _uploadStatus = null;
      _phase = _SignupPhase.capturing;
      _isCameraReady = false;
      _cameraViewKey = UniqueKey();
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

  /// Uploads the profile picture first — the one image sign-up actually needs —
  /// then marks the account complete and shows the done page. The remaining
  /// shots are extra recognition "mugs"; those upload in the background so the
  /// member isn't kept waiting on all fifteen. The backend associates each
  /// upload with the account server-side, so we don't need their URLs here.
  Future<void> _submitSignup() async {
    if (_shots.isEmpty) return;

    setState(() {
      _error = null;
      _uploadStatus = 'Finishing up…';
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

      // Upload the frontal shot for the profile first; if that one frame is
      // rejected, fall back through the others until one lands. Only this
      // upload is awaited — it's all sign-up needs to complete.
      final order = <int>[
        ?_frontalIndex,
        for (var i = 0; i < _shots.length; i++)
          if (i != _frontalIndex) i,
      ];
      String? profileUrl;
      var profileIndex = -1;
      PictureUploadException? faceRejection;
      for (final i in order) {
        try {
          profileUrl = await ProfilePictureUpload.upload(_shots[i]);
          profileIndex = i;
          break;
        } on PictureUploadException catch (e) {
          // A rejected *face* just means that frame is unusable — try the next.
          // A network/session failure is fatal to the batch — rethrow it.
          if (_isFaceRejection(e.kind)) {
            faceRejection = e;
            continue;
          }
          rethrow;
        }
      }

      if (profileUrl == null) {
        if (!mounted) return;
        setState(() {
          _error = faceRejection?.message ??
              'None of your photos worked. Please try again.';
          _canuseImg = false;
        });
        return;
      }

      final cached = await ChurchApi.getCachedAccountJson();
      final merged = <String, dynamic>{
        if (cached != null) ...cached,
        'imgURL': profileUrl,
        'signupComplete': true,
      };
      await ChurchApi.persistAccountFromServer(merged);
      if (!mounted) return;
      setState(() => _phase = _SignupPhase.done);

      // Enrich recognition with the other angles without blocking the member —
      // fire-and-forget, it keeps running even after they move to the dashboard.
      final mugs = [
        for (var i = 0; i < _shots.length; i++)
          if (i != profileIndex) _shots[i],
      ];
      if (mugs.isNotEmpty) unawaited(_uploadMugsInBackground(mugs));
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
      if (mounted) setState(() => _uploadStatus = null);
    }
  }

  /// Best-effort background upload of the extra mugs, a few at a time so a
  /// mobile connection isn't hit with all of them at once. Fire-and-forget:
  /// failures are logged, not surfaced, and it never touches the widget, so it
  /// is safe to keep running after the member has moved on to the dashboard.
  Future<void> _uploadMugsInBackground(List<Uint8List> mugs) async {
    const maxConcurrent = 3;
    var next = 0;
    Future<void> worker() async {
      while (next < mugs.length) {
        final bytes = mugs[next++];
        try {
          await ProfilePictureUpload.upload(bytes);
        } catch (e) {
          debugPrint('Background mug upload failed: $e');
        }
      }
    }

    await Future.wait([for (var i = 0; i < maxConcurrent; i++) worker()]);
  }

  @override
  void dispose() {
    _settleTimer?.cancel();
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
      body: switch (_phase) {
        _SignupPhase.capturing => _buildCapturing(),
        _SignupPhase.submitting => _buildProcessing(),
        _SignupPhase.done => _buildComplete(),
      },
    );
  }

  Widget _buildCapturing() {
    return Stack(
      fit: StackFit.expand,
      children: [
        _buildCamera(),
        if (_error != null && _error!.contains('register your account'))
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

        // Animated arrow over the face, bobbing the way the member should move
        // their head next (turn left/right, or tilt the chin down) — a visual
        // companion to the text nudge below.
        if (_isCameraReady && _currentDirection != null)
          Align(
            alignment: const Alignment(0, 0.2),
            child: _DirectionCue(direction: _currentDirection!),
          ),

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
                _captureFooter(),
                const SizedBox(height: 40),
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

  /// Footer under the guidance text. Capture is fully automatic on mobile, so
  /// there is no shutter — just a progress bar that fills as shots come in and
  /// hands off to the upload screen on its own. Web has no live detection, so
  /// it keeps a single manual shutter.
  Widget _captureFooter() {
    if (!_handler.supportsFrameStream) return _manualShutter();

    final progress = (_shots.length / _maxShots).clamp(0.0, 1.0);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "${_shots.length} / $_maxShots captured",
          style: TextStyle(
            color: ChurchColors.buttonText.withValues(alpha: 0.9),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            width: 220,
            height: 6,
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: ChurchColors.buttonText.withValues(alpha: 0.2),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(ChurchColors.button),
            ),
          ),
        ),
      ],
    );
  }

  /// Web-only single manual shutter: grab one shot and go straight to upload.
  Widget _manualShutter() {
    final ready = _shots.isEmpty && _isCameraReady;
    return GestureDetector(
      onTap: ready ? _captureManualShot : null,
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

  Future<void> _captureManualShot() async {
    await _captureShot(0, 0);
    if (!mounted || _shots.isEmpty) return;
    await _finishCapturing();
  }

  /// Upload screen: a spinner with progress while the batch uploads, or an
  /// error with the appropriate recovery (retry the upload for a transient
  /// failure, or re-capture if every frame was rejected).
  Widget _buildProcessing() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _profileAvatar(120),
              const SizedBox(height: 28),
              if (_error == null) ...[
                const CircularProgressIndicator(color: ChurchColors.button),
                const SizedBox(height: 20),
                Text(
                  _uploadStatus ?? 'Finishing up…',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: ChurchColors.buttonText,
                    fontSize: 15,
                  ),
                ),
              ] else ...[
                _errorBanner(),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: _bottomButton(
                    label: _canuseImg ? 'Try Again' : 'Retake photos',
                    onTap: _canuseImg ? _submitSignup : _restartCapture,
                    color: ChurchColors.button,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Final screen: confirms enrolment is done and offers the way in.
  Widget _buildComplete() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            const Spacer(),
            _profileAvatar(150),
            const SizedBox(height: 32),
            const Icon(Icons.check_circle,
                color: ChurchColors.card, size: 40),
            const SizedBox(height: 16),
            const Text(
              "You're all set!",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ChurchColors.buttonText,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Your profile is ready. Welcome to Rejoice Greatly — we're\nglad you're here.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ChurchColors.buttonText.withValues(alpha: 0.75),
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: _bottomButton(
                label: 'Go to Dashboard',
                onTap: _goToDashboard,
                color: ChurchColors.button,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  /// Circular avatar of the chosen frontal (profile) shot, shown on the upload
  /// and completion screens.
  Widget _profileAvatar(double size) {
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ChurchColors.card,
        border: Border.all(color: ChurchColors.button, width: 3),
      ),
      child: _capturedBytes != null
          ? Image.memory(_capturedBytes!, fit: BoxFit.cover)
          : const Icon(Icons.person, color: ChurchColors.button, size: 64),
    );
  }

  void _goToDashboard() {
    Navigator.pushReplacementNamed(context, '/dashboard');
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

/// Which screen the sign-up flow is showing.
enum _SignupPhase { capturing, submitting, done }

/// Head movement the capture flow is currently asking for.
enum _GuidanceDirection { left, right, down }

/// The angle a captured shot is counted against for the per-side cap.
enum _ShotBucket { centre, left, right, down }

/// A soft, repeating arrow that bobs in the direction the member should move
/// their head — a visual companion to the text nudge during capture. Kept
/// deliberately gentle (slow, semi-transparent) to match the app's unhurried,
/// "greeted, not processed" feel.
class _DirectionCue extends StatefulWidget {
  const _DirectionCue({required this.direction});

  final _GuidanceDirection direction;

  @override
  State<_DirectionCue> createState() => _DirectionCueState();
}

class _DirectionCueState extends State<_DirectionCue>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 950),
  )..repeat(reverse: true);

  IconData get _icon {
    switch (widget.direction) {
      case _GuidanceDirection.left:
        return Icons.keyboard_arrow_left;
      case _GuidanceDirection.right:
        return Icons.keyboard_arrow_right;
      case _GuidanceDirection.down:
        return Icons.keyboard_arrow_down;
    }
  }

  /// Unit direction the arrow drifts as it bobs.
  Offset get _motion {
    switch (widget.direction) {
      case _GuidanceDirection.left:
        return const Offset(-1, 0);
      case _GuidanceDirection.right:
        return const Offset(1, 0);
      case _GuidanceDirection.down:
        return const Offset(0, 1);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_controller.value);
        return Opacity(
          opacity: 0.5 + 0.5 * t,
          child: Transform.translate(
            offset: _motion * (10 * t),
            child: child,
          ),
        );
      },
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: ChurchColors.bodyText.withValues(alpha: 0.35),
        ),
        child: Icon(_icon, color: ChurchColors.buttonText, size: 40),
      ),
    );
  }
}