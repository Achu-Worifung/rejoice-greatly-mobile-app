import 'dart:async';
import 'dart:html' as html;
import 'dart:ui_web' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';

import 'camera_frame.dart';

class VideoHandler {
  late html.VideoElement _videoElement;
  html.MediaStream? _mediaStream;
  bool _isCameraReady = false;
  bool _isFrontCamera = true;
  bool _isStarting = false;
  final String viewId = 'camera-view-${DateTime.now().millisecondsSinceEpoch}';

  VideoHandler() {
    _setupVideoElement();
    _registerView();
  }

  void _setupVideoElement() {
    _videoElement = html.VideoElement()
      ..autoplay = true
      ..muted = true
      ..setAttribute('playsinline', 'true')
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.objectFit = 'cover';
  }

  void _registerView() {
    ui.platformViewRegistry.registerViewFactory(
      viewId,
      (int id) => _videoElement,
    );
  }

  Future<void> initCamera({bool front = true}) async {
    if (_isStarting) return;
    _isStarting = true;

    try {
      if (_mediaStream != null) {
        _mediaStream!.getTracks().forEach((track) => track.stop());
        _mediaStream = null;
      }

      final mediaDevices = html.window.navigator.mediaDevices;
      if (mediaDevices == null) {
        // Surfaces as the "camera access denied" message instead of crashing
        // in browsers/webviews without getUserMedia support.
        throw StateError('Camera is not supported in this browser');
      }
      final stream = await mediaDevices.getUserMedia({
        'video': {
          'facingMode': front ? 'user' : 'environment',
          'width': {'ideal': 1280},
          'height': {'ideal': 720},
        },
        'audio': false,
      });

      _mediaStream = stream;
      _videoElement.srcObject = stream;
      _videoElement.style.transform = front ? 'scaleX(-1)' : 'scaleX(1)';
      _isFrontCamera = front;

      await _videoElement.play();

      // Wait until the stream has real dimensions (avoids frozen/blank preview).
      if (_videoElement.readyState < html.MediaElement.HAVE_CURRENT_DATA) {
        try {
          await _videoElement.onLoadedData.first.timeout(const Duration(seconds: 8));
        } on TimeoutException {
          // Continue; play() below may still succeed.
        }
      }
      await _videoElement.play();

      _isCameraReady = _videoElement.videoWidth > 0 && _videoElement.videoHeight > 0;
      if (!_isCameraReady) {
        throw StateError('Camera stream did not start');
      }
    } catch (e) {
      print("Camera Error: $e");
      _isCameraReady = false;
      rethrow;
    } finally {
      _isStarting = false;
    }
  }

  /// Restart live preview after retake (web pauses video when preview is hidden).
  Future<void> restartPreview() async {
    if (_mediaStream != null) {
      try {
        _videoElement.srcObject = _mediaStream;
        _videoElement.style.transform = _isFrontCamera ? 'scaleX(-1)' : 'scaleX(1)';
        await _videoElement.play();
        if (_videoElement.videoWidth > 0 && _videoElement.videoHeight > 0) {
          _isCameraReady = true;
          return;
        }
      } catch (e) {
        print('restartPreview play failed: $e');
      }
    }
    await initCamera(front: _isFrontCamera);
  }

  Future<Uint8List?> capturePhoto() async {
    if (!_isCameraReady) return null;

    final w = _videoElement.videoWidth;
    final h = _videoElement.videoHeight;
    if (w == 0 || h == 0) return null;

    final canvas = html.CanvasElement(
      width: w,
      height: h,
    );
    final ctx = canvas.context2D;

    if (_isFrontCamera) {
      ctx.translate(w.toDouble(), 0);
      ctx.scale(-1, 1);
    }

    ctx.drawImage(_videoElement, 0, 0);

    final blob = await canvas.toBlob('image/jpeg', 0.9);
    final reader = html.FileReader();
    reader.readAsArrayBuffer(blob);

    await reader.onLoad.first;
    return reader.result as Uint8List?;
  }

  Future<void> flipCamera() async {
    await initCamera(front: !_isFrontCamera);
  }

  bool get isCameraReady => _isCameraReady;

  bool get isFrontCamera => _isFrontCamera;

  /// ML Kit has no web implementation, so live face detection is mobile-only.
  bool get supportsFrameStream => false;

  Future<void> startFrameStream(void Function(CameraFrame frame) onFrame) async {}

  Future<void> stopFrameStream() async {}

  // Returns the camera preview widget for web
  Widget buildCameraView() {
    return HtmlElementView(viewType: viewId);
  }

  void dispose() {
    _mediaStream?.getTracks().forEach((track) => track.stop());
    _videoElement.srcObject = null;
  }
}