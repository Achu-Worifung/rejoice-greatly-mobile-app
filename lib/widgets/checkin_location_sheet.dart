import 'package:flutter/material.dart';

import '../services/checkin_location.dart';
import '../services/nfc_checkin_service.dart';
import '../theme/church_colors.dart';
import '../theme/church_type.dart';
import 'church_buttons.dart';

/// Sends one check-in; [NfcCheckinService.checkInWithTagId] in the app.
typedef CheckinSubmit = Future<NfcCheckinResult> Function(String tagId, {CheckinPosition? position});

/// Checks in from a tag, and if the tag only checks people in near it, asks
/// for the phone's location and tries once more.
///
/// Tags without a place never ask. Once location is allowed, a tag that needs
/// it just takes it — the sheet only appears the first time, or when location
/// is turned off.
Future<NfcCheckinResult> checkInAtTag(
  BuildContext context,
  String tagId, {
  @visibleForTesting CheckinSubmit submit = NfcCheckinService.checkInWithTagId,
  @visibleForTesting CheckinLocation location = const CheckinLocation(),
}) async {
  final first = await submit(tagId);
  if (first.errorKind != NfcCheckinErrorKind.needsLocation) return first;

  var access = await location.access();
  if (access != LocationAccess.granted) {
    if (!context.mounted) return first;
    final choice = await _askForLocation(context, access);
    switch (choice) {
      case _Choice.share:
        access = await location.request();
      case _Choice.settings:
        await location.openSettings(access);
        return NfcCheckinResult.failure(
          NfcCheckinErrorKind.needsLocation,
          'Once location is on, tap the tag again to check in.',
        );
      case _Choice.notNow:
        return NfcCheckinResult.failure(
          NfcCheckinErrorKind.needsLocation,
          'Not checked in. You can check in at the welcome desk instead.',
        );
    }
    if (access != LocationAccess.granted) {
      return NfcCheckinResult.failure(
        NfcCheckinErrorKind.needsLocation,
        'Without your location this tag can’t check you in. You can check in at the welcome desk instead.',
      );
    }
  }

  final position = await location.current();
  if (position == null) {
    return NfcCheckinResult.failure(
      NfcCheckinErrorKind.needsLocation,
      'Your phone couldn’t find where it is. Give it a moment and tap the tag again, or check in at the welcome desk.',
    );
  }
  return submit(tagId, position: position);
}

enum _Choice { share, settings, notNow }

Future<_Choice> _askForLocation(BuildContext context, LocationAccess access) async {
  final (String note, String action) = switch (access) {
    LocationAccess.off => ('Location is switched off on this phone.', 'Turn on location'),
    LocationAccess.blocked => ('Location is turned off for Rejoice Greatly.', 'Open Settings'),
    _ => ('', 'Share my location'),
  };
  final picked = await showModalBottomSheet<_Choice>(
    context: context,
    useSafeArea: true,
    // Sized to its content, and scrolls on a short screen or with large text.
    isScrollControlled: true,
    backgroundColor: ChurchColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(ChurchRadius.lg)),
    ),
    builder: (ctx) => SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.place_outlined, color: ChurchColors.accent, size: 28),
          const SizedBox(height: 12),
          const Text('One more step', style: ChurchType.headline),
          const SizedBox(height: 8),
          const Text(
            'This tag checks people in at church, so it needs to see that your phone is here. '
            'Your location is used once, right now. We keep only how far you were from the tag.',
            style: ChurchType.body,
          ),
          if (note.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(note, style: ChurchType.bodyStrong),
          ],
          const SizedBox(height: 20),
          ChurchPrimaryButton(
            label: action,
            icon: access == LocationAccess.canAsk ? Icons.my_location_rounded : null,
            onPressed: () => Navigator.pop(
              ctx,
              access == LocationAccess.canAsk ? _Choice.share : _Choice.settings,
            ),
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: () => Navigator.pop(ctx, _Choice.notNow),
            child: const Text('Not now', style: ChurchType.button),
          ),
          const SizedBox(height: 4),
          const Text(
            'You can always check in at the welcome desk instead.',
            textAlign: TextAlign.center,
            style: ChurchType.caption,
          ),
        ],
      ),
    ),
  );
  return picked ?? _Choice.notNow;
}
