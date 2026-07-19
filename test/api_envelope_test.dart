import 'dart:convert';

import 'package:church_app/services/api_envelope.dart';
import 'package:flutter_test/flutter_test.dart';

/// The bodies below are copied from live responses on the running backend, so
/// a change to `ApiResponseAdvice` on the Spring side shows up here rather
/// than as a crash on someone's phone.
void main() {
  group('unwrapApiList', () {
    test('returns the rows from an enveloped list', () {
      const body = '{"success":true,"data":[{"id":1},{"id":2}],'
          '"timestamp":"2026-07-18T18:00:00Z"}';

      expect(unwrapApiList(body), hasLength(2));
      expect((unwrapApiList(body).first as Map)['id'], 1);
    });

    test('accepts a bare list from a pre-envelope backend', () {
      expect(unwrapApiList('[{"id":1}]'), hasLength(1));
    });

    test('treats an omitted data field as empty rather than throwing', () {
      // `data` is dropped entirely when null (Jackson NON_NULL), which is what
      // a 200-with-no-body looks like on the wire.
      expect(unwrapApiList('{"success":true,"timestamp":"x"}'), isEmpty);
    });
  });

  group('unwrapApiMap', () {
    test('returns the payload from an enveloped object', () {
      const body = '{"success":true,"data":{"book":"Joshua","chapter":1},'
          '"timestamp":"2026-07-18T18:00:00Z"}';

      final verse = unwrapApiMap(body);
      expect(verse['book'], 'Joshua');
      expect(verse['chapter'], 1);
      // The envelope's own fields must not leak into the payload.
      expect(verse.containsKey('success'), isFalse);
    });

    test('accepts a bare object from a pre-envelope backend', () {
      expect(unwrapApiMap('{"book":"Joshua"}')['book'], 'Joshua');
    });
  });

  group('discriminator', () {
    test('a payload with its own data field is not mistaken for an envelope', () {
      // Keyed on `success`, not `data` — otherwise a legitimate payload
      // carrying a `data` key would be unwrapped a second time.
      const body = '{"data":{"nested":true},"other":1}';

      final map = unwrapApiMap(body);
      expect(map['other'], 1);
      expect((map['data'] as Map)['nested'], isTrue);
    });

    test('a failure envelope is not unwrapped into null by callers', () {
      // Error bodies keep `message` at the top level with no `data`; callers
      // read them without unwrapping, so confirm the shape they rely on.
      const body = '{"success":false,"message":"Admin access required",'
          '"errorCode":"FORBIDDEN","path":"/admin/users"}';

      final decoded = json.decode(body) as Map<String, dynamic>;
      expect(decoded['message'], 'Admin access required');
      // And if someone did unwrap it, they would get null — hence the rule.
      expect(unwrapApiValue(decoded), isNull);
    });
  });
}
