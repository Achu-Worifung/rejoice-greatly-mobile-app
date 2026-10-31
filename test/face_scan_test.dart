import 'package:church_app/services/biometric_consent.dart';
import 'package:church_app/services/profile_picture_upload.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() => dotenv.loadFromString(envString: 'BASE_URL=https://api.example.org'));
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('photo uses match what the backend expects', () {
    // POST /auth/picture-upload/commit `purpose`.
    expect(PictureUse.values.map((u) => u.wire), ['PROFILE', 'FACE_SCAN', 'BOTH']);
    expect(PictureUse.faceScan.showsAsProfile, isFalse);
    expect(PictureUse.profile.showsAsProfile, isTrue);
    expect(PictureUse.both.showsAsProfile, isTrue);
  });

  test('consent can’t be claimed on the server without agreeing on this phone', () async {
    expect(await BiometricConsent.isCurrent(), isFalse);
    await expectLater(BiometricConsent.sendToServer(), throwsStateError);
  });
}
