import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Everything needed to turn one buffered preview frame into a JPEG,
/// bundled so it can cross the isolate boundary via [compute].
class FrameJpegRequest {
  const FrameJpegRequest({
    required this.bytes,
    required this.width,
    required this.height,
    required this.bytesPerRow,
    required this.rotationDegrees,
    required this.isNv21,
  });

  /// Raw NV21 (Android) or BGRA8888 (iOS) frame bytes.
  final Uint8List bytes;
  final int width;
  final int height;
  final int bytesPerRow;
  final int rotationDegrees;

  /// False means bgra8888 (iOS); the only two formats the camera stream
  /// produces (see camera_frame.dart).
  final bool isNv21;
}

/// Decodes a buffered preview frame straight to JPEG bytes, skipping the
/// camera's still-capture pipeline entirely. Runs on a worker isolate via
/// [compute] — pure-Dart pixel conversion is too slow to do on the UI
/// isolate without dropping frames.
Uint8List encodeFrameToJpeg(FrameJpegRequest req) {
  var image = req.isNv21 ? _decodeNv21(req) : _decodeBgra8888(req);
  if (req.rotationDegrees != 0) {
    image = img.copyRotate(image, angle: req.rotationDegrees);
  }
  return Uint8List.fromList(img.encodeJpg(image, quality: 85));
}

/// Standard NV21 (Y plane followed by interleaved VU) to RGB conversion.
/// Assumes the chroma plane shares the luma row stride, which matches the
/// single merged buffer the `camera` plugin hands back for
/// ImageFormatGroup.nv21 (see camera_frame.dart).
img.Image _decodeNv21(FrameJpegRequest req) {
  final bytes = req.bytes;
  final width = req.width;
  final height = req.height;
  final stride = req.bytesPerRow;
  final image = img.Image(width: width, height: height);
  final frameSize = stride * height;

  for (var j = 0; j < height; j++) {
    final rowStart = j * stride;
    final uvRowStart = frameSize + (j >> 1) * stride;
    for (var i = 0; i < width; i++) {
      final y = (0xff & bytes[rowStart + i]) - 16;
      final uvCol = (i >> 1) * 2;
      final v = (0xff & bytes[uvRowStart + uvCol]) - 128;
      final u = (0xff & bytes[uvRowStart + uvCol + 1]) - 128;

      final y1192 = 1192 * (y < 0 ? 0 : y);
      var r = (y1192 + 1634 * v);
      var g = (y1192 - 833 * v - 400 * u);
      var b = (y1192 + 2066 * u);
      r = (r < 0 ? 0 : (r > 262143 ? 262143 : r)) >> 10;
      g = (g < 0 ? 0 : (g > 262143 ? 262143 : g)) >> 10;
      b = (b < 0 ? 0 : (b > 262143 ? 262143 : b)) >> 10;

      image.setPixelRgb(i, j, r, g, b);
    }
  }
  return image;
}

/// BGRA8888 (iOS) to RGB conversion — a direct channel reorder, no chroma
/// subsampling to unpack.
img.Image _decodeBgra8888(FrameJpegRequest req) {
  final bytes = req.bytes;
  final width = req.width;
  final height = req.height;
  final stride = req.bytesPerRow;
  final image = img.Image(width: width, height: height);

  for (var j = 0; j < height; j++) {
    final rowStart = j * stride;
    for (var i = 0; i < width; i++) {
      final idx = rowStart + i * 4;
      final b = bytes[idx];
      final g = bytes[idx + 1];
      final r = bytes[idx + 2];
      image.setPixelRgb(i, j, r, g, b);
    }
  }
  return image;
}
