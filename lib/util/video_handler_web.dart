import 'dart:html' as html;
import 'dart:ui_web' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';

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

      final stream = await html.window.navigator.mediaDevices!.getUserMedia({
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
      _isCameraReady = true;
    } catch (e) {
      print("Camera Error: $e");
      _isCameraReady = false;
      rethrow;
    } finally {
      _isStarting = false;
    }
  }

  Future<Uint8List?> capturePhoto() async {
    if (!_isCameraReady) return null;

    final canvas = html.CanvasElement(
      width: _videoElement.videoWidth,
      height: _videoElement.videoHeight,
    );
    final ctx = canvas.context2D;

    if (_isFrontCamera) {
      ctx.translate(_videoElement.videoWidth.toDouble(), 0);
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

  // Returns the camera preview widget for web
  Widget buildCameraView() {
    return HtmlElementView(viewType: viewId);
  }

  void dispose() {
    _mediaStream?.getTracks().forEach((track) => track.stop());
    _videoElement.srcObject = null;
  }
}