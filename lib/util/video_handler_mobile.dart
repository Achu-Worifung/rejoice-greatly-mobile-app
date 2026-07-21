import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'camera_frame.dart';

class VideoHandler {
  CameraController? _controller;
  bool _isCameraReady = false;
  bool _isFrontCamera = true;
  bool _isStreaming = false;
  List<CameraDescription>? _cameras;
  final String viewId = 'camera-mobile-view'; // Not used on mobile but needed for interface

  static const _orientationDegrees = <DeviceOrientation, int>{
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  Future<void> initCamera({bool front = true}) async {
    try {
      _cameras ??= await availableCameras();

      if (_cameras == null || _cameras!.isEmpty) {
        throw Exception('No cameras available');
      }

      final camera = _cameras!.firstWhere(
        (cam) => front
            ? cam.lensDirection == CameraLensDirection.front
            : cam.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first,
      );

      await _controller?.dispose();

      _controller = CameraController(
        camera,
        // Medium keeps the live NV21/bgra8888 stream light enough for ML Kit
        // on slower/mid-range chips (this preset drives both the preview
        // stream and takePicture() output; the face-recognition backend
        // doesn't need full-res stills, and this stream ran at ResolutionPreset.high
        // before, which was heavy enough to freeze devices like the S10e).
        ResolutionPreset.medium,
        enableAudio: false,
        // ML Kit only accepts nv21/bgra8888 stream frames. takePicture() still
        // returns JPEG regardless, so the upload path is unaffected.
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );

      await _controller!.initialize();
      _isCameraReady = true;
      _isFrontCamera = front;
    } catch (e) {
      print("Mobile Camera Error: $e");
      _isCameraReady = false;
      rethrow;
    }
  }

  Future<Uint8List?> capturePhoto() async {
    if (!_isCameraReady || _controller == null) return null;

    try {
      final image = await _controller!.takePicture();
      return await image.readAsBytes();
    } catch (e) {
      print("Capture error: $e");
      return null;
    }
  }

  Future<void> flipCamera() async {
    await initCamera(front: !_isFrontCamera);
  }

  /// Resume or re-open the camera after retake (preview can pause after capture).
  Future<void> restartPreview() async {
    if (_controller != null && _controller!.value.isInitialized) {
      try {
        await _controller!.resumePreview();
        _isCameraReady = true;
        return;
      } catch (e) {
        print('resumePreview failed: $e');
      }
    }
    await initCamera(front: _isFrontCamera);
  }

  bool get isCameraReady => _isCameraReady;

  bool get isFrontCamera => _isFrontCamera;

  bool get supportsFrameStream => true;

  /// Streams preview frames for face detection. Safe to call repeatedly; a
  /// second call replaces nothing and is ignored while already streaming.
  Future<void> startFrameStream(void Function(CameraFrame frame) onFrame) async {
    final controller = _controller;
    if (!_isCameraReady || controller == null || _isStreaming) return;

    _isStreaming = true;
    await controller.startImageStream((CameraImage image) {
      // ML Kit requires a single-plane frame; nv21/bgra8888 both satisfy this.
      if (image.planes.length != 1) return;
      final plane = image.planes.first;
      final rotation = _rotationDegrees(controller);
      if (rotation == null) return;

      onFrame(CameraFrame(
        bytes: plane.bytes,
        width: image.width,
        height: image.height,
        rotationDegrees: rotation,
        formatRaw: image.format.raw is int ? image.format.raw as int : 0,
        bytesPerRow: plane.bytesPerRow,
      ));
    });
  }

  Future<void> stopFrameStream() async {
    if (!_isStreaming) return;
    _isStreaming = false;
    try {
      await _controller?.stopImageStream();
    } catch (e) {
      print('stopImageStream failed: $e');
    }
  }

  /// Rotation ML Kit must apply, compensating for device orientation and for
  /// the front lens mirroring on Android.
  int? _rotationDegrees(CameraController controller) {
    final sensorOrientation = controller.description.sensorOrientation;
    if (Platform.isIOS) return sensorOrientation;

    final deviceRotation =
        _orientationDegrees[controller.value.deviceOrientation];
    if (deviceRotation == null) return null;

    return controller.description.lensDirection == CameraLensDirection.front
        ? (sensorOrientation + deviceRotation) % 360
        : (sensorOrientation - deviceRotation + 360) % 360;
  }

  // Returns the camera preview widget for mobile
  Widget buildCameraView() {
    if (_controller != null && _controller!.value.isInitialized) {
      return CameraPreview(_controller!);
    }
    return Container(color: Colors.black);
  }

  void dispose() {
    _controller?.dispose();
  }
}