import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class VideoHandler {
  CameraController? _controller;
  bool _isCameraReady = false;
  bool _isFrontCamera = true;
  List<CameraDescription>? _cameras;
  final String viewId = 'camera-mobile-view'; // Not used on mobile but needed for interface

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
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
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

  bool get isCameraReady => _isCameraReady;

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