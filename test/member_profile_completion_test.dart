import 'package:church_app/services/church_api.dart';
import 'package:church_app/widgets/member_avatar.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('hasMemberProfile', () {
    test('a minor is complete once signup is, with no photo', () {
      expect(
        ChurchApi.hasMemberProfile(const {
          'signupComplete': true,
          'minor': true,
        }),
        isTrue,
      );
    });

    test('an adult who skipped the face scan is not complete', () {
      expect(
        ChurchApi.hasMemberProfile(const {
          'signupComplete': true,
          'minor': false,
        }),
        isFalse,
      );
    });

    test('an adult with a photo is complete', () {
      expect(
        ChurchApi.hasMemberProfile(const {
          'signupComplete': true,
          'imgURL': 'https://blob/x.jpg',
        }),
        isTrue,
      );
    });

    test('an unfinished signup is never complete', () {
      expect(
        ChurchApi.hasMemberProfile(const {
          'signupComplete': false,
          'minor': true,
        }),
        isFalse,
      );
    });

    test("the server's hasProfile wins when it says yes", () {
      expect(ChurchApi.hasMemberProfile(const {'hasProfile': true}), isTrue);
    });
  });

  group('canUploadPhoto', () {
    test('is false for a minor', () {
      expect(ChurchApi.canUploadPhoto(const {'minor': true}), isFalse);
    });

    test('follows the server flag when present', () {
      expect(ChurchApi.canUploadPhoto(const {'canUploadPhoto': false}), isFalse);
    });

    test('is true for an ordinary account', () {
      expect(ChurchApi.canUploadPhoto(const {'minor': false}), isTrue);
    });
  });

  group('MemberAvatar.initialsOf', () {
    test('takes the first and last name', () {
      expect(MemberAvatar.initialsOf('Clinton Achu'), 'CA');
      expect(MemberAvatar.initialsOf('Ada Grace Obi'), 'AO');
    });

    test('takes one letter from a single name', () {
      expect(MemberAvatar.initialsOf('Ada'), 'A');
    });

    test('tolerates stray spacing and casing', () {
      expect(MemberAvatar.initialsOf('  ada   obi '), 'AO');
    });

    test('is empty for an empty name, so the avatar can fall back', () {
      expect(MemberAvatar.initialsOf('   '), '');
    });
  });
}
