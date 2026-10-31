import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/member_events.dart';
import '../theme/church_colors.dart';
import '../theme/church_type.dart';
import '../widgets/cached_image.dart';
import '../widgets/church_buttons.dart';
import '../widgets/dashboard_label_title.dart';
import '../widgets/event_actions.dart' show openExternal;

/// The next service, with the church, how to get there, and a way to put it
/// in the calendar or send it to someone. The date comes from the events
/// feed when the service is on it, otherwise from the church's usual time.
class WorshipWithUsCard extends StatelessWidget {
  const WorshipWithUsCard({super.key, required this.data, this.events = const [], this.onNeedRide});

  /// `name`, `address`, `serviceTimes` (e.g. "10:00 AM"), `mapPreviewUrl`.
  final Map<String, dynamic> data;

  /// Upcoming events the member can see; the first service among them wins.
  final List<Map<String, dynamic>> events;

  /// Opens "Rides to church"; the link is left out when null.
  final VoidCallback? onNeedRide;

  String get _name => data['name'] as String? ?? 'Rejoice Greatly';
  String get _address => data['address'] as String? ?? '';
  String get _times => data['serviceTimes'] as String? ?? '';

  /// The next service as an event: the feed's own when it has one (so "Add
  /// to calendar" uses the real occurrence), else the next Sunday at the
  /// church's usual time.
  @visibleForTesting
  static Map<String, dynamic> nextService({
    required List<Map<String, dynamic>> events,
    required String usualTime,
    required String churchName,
    required String address,
    required DateTime now,
  }) {
    for (final e in events) {
      final title = (e['title'] as String? ?? '').toLowerCase();
      final start = MemberEvents.startOf(e);
      if (title.contains('service') && start != null && start.add(const Duration(hours: 2)).isAfter(now)) {
        return e;
      }
    }
    final time = _parseTime(usualTime);
    var day = DateTime(now.year, now.month, now.day);
    while (day.weekday != DateTime.sunday) {
      day = day.add(const Duration(days: 1));
    }
    // Today's has finished: next week's.
    final startsToday = DateTime(day.year, day.month, day.day, time?.$1 ?? 23, time?.$2 ?? 59);
    if (startsToday.add(const Duration(hours: 2)).isBefore(now)) {
      day = day.add(const Duration(days: 7));
    }
    return {
      'title': 'Sunday service at $churchName',
      'date': DateFormat('yyyy-MM-dd').format(day),
      if (time != null) 'startTime': '${time.$1.toString().padLeft(2, '0')}:${time.$2.toString().padLeft(2, '0')}:00',
      'location': address,
    };
  }

  /// "10:00 AM" (or the first of "9:00 AM & 11:00 AM") as hour and minute.
  static (int, int)? _parseTime(String text) {
    final m = RegExp(r'(\d{1,2}):(\d{2})\s*([AaPp][Mm])?').firstMatch(text);
    if (m == null) return null;
    var hour = int.parse(m.group(1)!);
    final minute = int.parse(m.group(2)!);
    final ampm = m.group(3)?.toLowerCase();
    if (ampm == 'pm' && hour < 12) hour += 12;
    if (ampm == 'am' && hour == 12) hour = 0;
    return (hour, minute);
  }

  /// "Happening now", "Starts in 40 minutes", "Today at 10:00 AM", "Tomorrow at 10:00 AM", "In 3 days".
  @visibleForTesting
  static String whenLabel(DateTime start, bool hasTime, DateTime now) {
    final time = DateFormat('h:mm a').format(start);
    if (hasTime && !now.isBefore(start) && now.isBefore(start.add(const Duration(hours: 2)))) {
      return 'Happening now';
    }
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(start.year, start.month, start.day);
    final days = day.difference(today).inDays;
    if (days == 0) {
      final until = start.difference(now);
      if (hasTime && until.inMinutes < 60) return 'Starts in ${until.inMinutes.clamp(1, 59)} minutes';
      if (hasTime && until.inHours < 3) return 'Starts in ${until.inHours} hour${until.inHours == 1 ? '' : 's'}';
      return hasTime ? 'Today at $time' : 'Today';
    }
    if (days == 1) return hasTime ? 'Tomorrow at $time' : 'Tomorrow';
    return 'In $days days';
  }

  Uri get _mapsUri => defaultTargetPlatform == TargetPlatform.iOS
      ? Uri.parse('https://maps.apple.com/?daddr=${Uri.encodeComponent(_address)}')
      : Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(_address)}');

  Future<void> _directions(BuildContext context) async {
    if (_address.isEmpty) return;
    try {
      await launchUrl(_mapsUri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Couldn’t open maps.')));
      }
    }
  }

  Future<void> _share(BuildContext context, DateTime? start, bool hasTime) async {
    final when = start == null
        ? _times
        : '${DateFormat('EEEE, MMMM d').format(start)}${hasTime ? ' at ${DateFormat('h:mm a').format(start)}' : ''}';
    final text = [
      'Come to church with me at $_name!',
      if (when.isNotEmpty) when,
      if (_address.isNotEmpty) _address,
      if (_address.isNotEmpty) 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(_address)}',
    ].join('\n');
    try {
      await Share.share(text, subject: 'Church at $_name');
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Couldn’t open sharing.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = nextService(
      events: events,
      usualTime: _times,
      churchName: _name,
      address: _address,
      now: DateTime.now(),
    );
    final start = MemberEvents.startOf(service);
    final hasTime = (service['startTime'] as String?)?.isNotEmpty == true;
    final calendar = MemberEvents.calendarUri(service);
    final label = start == null ? null : whenLabel(start, hasTime, DateTime.now());
    final live = label == 'Happening now';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const DashboardLabelText(label: 'Worship with us'),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: ChurchColors.cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _MapPreview(
                staticMapUrl: data['mapPreviewUrl'] as String?,
                onTap: () => _directions(context),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ChurchEyebrow('Next service', color: ChurchColors.accent),
                    const SizedBox(height: 6),
                    if (start != null) ...[
                      Text(DateFormat('EEEE, MMMM d').format(start), style: ChurchType.headline),
                      const SizedBox(height: 2),
                      Text(
                        // "Today at 10:00 AM" already says the time.
                        label != null && hasTime && label.contains(DateFormat('h:mm a').format(start))
                            ? label
                            : [if (hasTime) DateFormat('h:mm a').format(start), ?label].join(' · '),
                        style: ChurchType.body.copyWith(
                          color: live ? ChurchColors.accent : ChurchColors.muted,
                          fontWeight: live ? FontWeight.w600 : null,
                        ),
                      ),
                    ] else
                      Text(_times.isEmpty ? 'Sundays' : 'Sundays · $_times', style: ChurchType.headline),
                    const SizedBox(height: 14),
                    Divider(height: 1, color: ChurchColors.divider),
                    const SizedBox(height: 14),
                    Text(_name, style: ChurchType.bodyStrong),
                    if (_address.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(_address, style: ChurchType.label),
                    ],
                    if (_times.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text('Every Sunday · $_times', style: ChurchType.label),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ChurchPrimaryButton(
                label: 'Directions',
                icon: Icons.directions_outlined,
                height: 48,
                onPressed: _address.isEmpty ? null : () => _directions(context),
              ),
            ),
            if (calendar != null) ...[
              const SizedBox(width: 8),
              Expanded(
                child: ChurchSecondaryButton(
                  label: 'Add to calendar',
                  icon: Icons.event_available_outlined,
                  height: 48,
                  onPressed: () => openExternal(context, calendar),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Wrap(
          alignment: WrapAlignment.center,
          children: [
            TextButton.icon(
              onPressed: () => _share(context, start, hasTime),
              icon: const Icon(Icons.ios_share_rounded, size: 18),
              label: const Text('Invite someone to come with you'),
            ),
            if (onNeedRide != null)
              TextButton.icon(
                onPressed: onNeedRide,
                icon: const Icon(Icons.directions_car_outlined, size: 18),
                label: const Text('Need a ride?'),
              ),
          ],
        ),
      ],
    );
  }
}

/// The map at the top of the card: the church's map image when one is set,
/// else a quiet drawn map. Tapping opens directions.
class _MapPreview extends StatelessWidget {
  const _MapPreview({this.staticMapUrl, required this.onTap});

  final String? staticMapUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final url = staticMapUrl?.trim();
    return Semantics(
      button: true,
      label: 'Open directions',
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 140,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (url != null && url.isNotEmpty)
                Image(
                  image: cachedImage(url),
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const _DrawnMap(),
                )
              else
                const _DrawnMap(),
              Positioned(
                right: 10,
                bottom: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: ChurchColors.background,
                    borderRadius: ChurchRadius.mdAll,
                    border: Border.all(color: ChurchColors.divider),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_on_outlined, size: 16, color: ChurchColors.accent),
                      const SizedBox(width: 4),
                      Text('Open in Maps', style: ChurchType.caption.copyWith(color: ChurchColors.accent)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawnMap extends StatelessWidget {
  const _DrawnMap();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ChurchColors.card,
      child: CustomPaint(
        painter: _MapGridPainter(ChurchColors.button),
        child: Center(child: Icon(Icons.church_outlined, size: 36, color: ChurchColors.accent)),
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  _MapGridPainter(this.ink);

  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = ink.withValues(alpha: 0.08)
      ..strokeWidth = 1;
    const step = 24.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final road = Paint()
      ..color = ink.withValues(alpha: 0.15)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(size.width * 0.2, 0), Offset(size.width * 0.35, size.height), road);
    canvas.drawLine(Offset(0, size.height * 0.45), Offset(size.width, size.height * 0.6), road);
    canvas.drawLine(Offset(size.width * 0.6, 0), Offset(size.width * 0.7, size.height), road);
  }

  @override
  bool shouldRepaint(covariant _MapGridPainter old) => old.ink != ink;
}
