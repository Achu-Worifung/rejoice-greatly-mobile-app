import 'package:church_app/services/sermon_downloads.dart';
import 'package:church_app/services/sermon_progress.dart';
import 'package:church_app/widgets/sermon_listen_controls.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _sermon = {'id': 7, 'title': 'Faith that moves mountains', 'speaker': 'Pastor Grace', 'secret': 'x'};
const _hour = Duration(minutes: 60);

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SermonProgress.clear();
  });

  test('picks up where they left off, but not from the first few seconds', () async {
    await SermonProgress.record('7', _sermon, const Duration(seconds: 20), _hour);
    expect(SermonProgress.resumeAt('7'), isNull);

    await SermonProgress.record('7', _sermon, const Duration(minutes: 23), _hour);
    expect(SermonProgress.resumeAt('7'), const Duration(minutes: 23));
    expect(SermonProgress.inProgress.single.remaining, const Duration(minutes: 37));
    // Only what the list needs is kept.
    expect(SermonProgress.inProgress.single.sermon.containsKey('secret'), isFalse);
  });

  test('finishing a sermon takes it off "Continue listening"', () async {
    await SermonProgress.record('7', _sermon, const Duration(minutes: 23), _hour);
    await SermonProgress.record('7', _sermon, _hour - const Duration(seconds: 20), _hour);
    expect(SermonProgress.resumeAt('7'), isNull);
    expect(SermonProgress.inProgress, isEmpty);
  });

  test('the most recently listened comes first, and it survives a restart', () async {
    await SermonProgress.record('7', _sermon, const Duration(minutes: 5), _hour);
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await SermonProgress.record('8', {..._sermon, 'id': 8}, const Duration(minutes: 9), _hour);
    expect(SermonProgress.inProgress.map((l) => l.sermon['id']), [8, 7]);

    final saved = (await SharedPreferences.getInstance()).getString('sermon_progress');
    expect(saved, contains('"p":540000'));
  });

  test('labels read naturally', () {
    expect(formatListenTime(const Duration(minutes: 23, seconds: 4)), '23:04');
    expect(formatListenTime(const Duration(hours: 1, minutes: 2, seconds: 15)), '1:02:15');
    expect(speedLabel(1.0), '1×');
    expect(speedLabel(1.25), '1.25×');
    expect(SermonDownloads.sizeLabel(48 * 1024 * 1024), '48 MB');
  });
}
