import 'package:church_app/widgets/cached_image.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a signed blob URL is keyed by its path, so re-signing keeps the cache', () {
    const monday =
        'https://acct.blob.core.windows.net/c/profile/a/b.jpg?sv=2024&se=2026-10-07&sig=abc';
    const tuesday =
        'https://acct.blob.core.windows.net/c/profile/a/b.jpg?sv=2024&se=2026-10-08&sig=xyz';

    expect(imageCacheKey(monday), imageCacheKey(tuesday));
    expect(
      imageCacheKey(monday),
      'https://acct.blob.core.windows.net/c/profile/a/b.jpg',
    );
  });

  test('an unsigned URL keeps its query, which may be the whole image', () {
    const map =
        'https://maps.googleapis.com/maps/api/staticmap?center=1,2&zoom=15';

    expect(imageCacheKey(map), map);
  });
}
