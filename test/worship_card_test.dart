import 'package:church_app/components/worship_with_us.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // A Wednesday.
  final wednesday = DateTime(2026, 11, 4, 12);

  test('without a service on the feed, it’s next Sunday at the usual time', () {
    final s = WorshipWithUsCard.nextService(
        events: const [], usualTime: '10:00 AM', churchName: 'Rejoice Greatly', address: 'Main St', now: wednesday);
    expect(s['date'], '2026-11-08');
    expect(s['startTime'], '10:00:00');
    expect(s['title'], 'Sunday service at Rejoice Greatly');
  });

  test('the feed’s service wins, so the calendar gets the real one', () {
    final s = WorshipWithUsCard.nextService(events: [
      {'id': 'e1', 'title': 'Youth night', 'date': '2026-11-06', 'startTime': '19:00:00'},
      {'id': 'e2', 'title': 'Sunday Service', 'date': '2026-11-08', 'startTime': '09:30:00'},
    ], usualTime: '10:00 AM', churchName: 'RG', address: 'Main St', now: wednesday);
    expect(s['id'], 'e2');
  });

  test('on Sunday afternoon it moves on to next week', () {
    final sunday = DateTime(2026, 11, 8, 15);
    final s = WorshipWithUsCard.nextService(
        events: const [], usualTime: '10:00 AM', churchName: 'RG', address: 'Main St', now: sunday);
    expect(s['date'], '2026-11-15');
    expect(
        WorshipWithUsCard.nextService(
            events: const [], usualTime: '10:00 AM', churchName: 'RG', address: 'Main St',
            now: DateTime(2026, 11, 8, 11))['date'],
        '2026-11-08');
  });

  test('when it is, in words', () {
    final start = DateTime(2026, 11, 8, 10);
    expect(WorshipWithUsCard.whenLabel(start, true, DateTime(2026, 11, 8, 10, 30)), 'Happening now');
    expect(WorshipWithUsCard.whenLabel(start, true, DateTime(2026, 11, 8, 9, 20)), 'Starts in 40 minutes');
    expect(WorshipWithUsCard.whenLabel(start, true, DateTime(2026, 11, 8, 7)), 'Today at 10:00 AM');
    expect(WorshipWithUsCard.whenLabel(start, true, DateTime(2026, 11, 7, 18)), 'Tomorrow at 10:00 AM');
    expect(WorshipWithUsCard.whenLabel(start, true, wednesday), 'In 4 days');
  });
}
