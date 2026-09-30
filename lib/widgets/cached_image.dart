import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';

/// Disk-cache key for an image URL.
///
/// Our Azure blob URLs carry a read signature (`sig=…`) that the backend
/// re-issues daily, while the blob behind it never changes: every upload gets a
/// fresh, unique name. Keying on the URL minus its query keeps a cached photo
/// valid across those re-signings. Any other URL (e.g. a Google static map,
/// whose query *is* the image) is keyed as-is.
String imageCacheKey(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null || !uri.queryParameters.containsKey('sig')) return url;
  return url.split('?').first;
}

/// An image provider backed by the on-device disk cache, so images load
/// instantly on later visits and app launches instead of re-downloading.
///
/// [cacheWidth] decodes at that pixel width (keeping aspect ratio) rather than
/// at the image's full size — pass it for thumbnails and avatars.
ImageProvider cachedImage(String url, {int? cacheWidth}) {
  return ResizeImage.resizeIfNeeded(
    cacheWidth,
    null,
    CachedNetworkImageProvider(url, cacheKey: imageCacheKey(url)),
  );
}
