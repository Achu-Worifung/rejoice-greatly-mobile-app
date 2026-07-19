import 'dart:typed_data';

/// A single preview frame handed to the face detector.
///
/// Deliberately plain data: it keeps ML Kit types out of the web camera
/// handler, which has no ML Kit plugin behind it.
class CameraFrame {
  const CameraFrame({
    required this.bytes,
    required this.width,
    required this.height,
    required this.rotationDegrees,
    required this.formatRaw,
    required this.bytesPerRow,
  });

  final Uint8List bytes;
  final int width;
  final int height;

  /// Rotation ML Kit must apply, already compensated for device orientation
  /// and lens direction.
  final int rotationDegrees;

  /// Platform-raw image format (nv21 on Android, bgra8888 on iOS).
  final int formatRaw;

  final int bytesPerRow;
}
