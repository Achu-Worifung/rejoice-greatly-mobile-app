import 'dart:typed_data';

abstract class VideoHandler {
  Future<void> initCamera({bool front = true});
  Future<Uint8List?> capturePhoto();
  Future<void> flipCamera();
  void dispose();
  bool get isCameraReady;
}