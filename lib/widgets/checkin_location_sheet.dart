import 'package:flutter/material.dart';

import '../services/checkin_location.dart';
import '../services/church_api.dart';
import '../services/household_api.dart';
import '../services/nfc_checkin_service.dart';
import '../theme/church_colors.dart';
import '../theme/church_type.dart';
import 'church_buttons.dart';

/// Sends one check-in; [NfcCheckinService.checkInWithTagId] in the app.
typedef CheckinSubmit = Future<NfcCheckinResult> Function(String tagId, {CheckinPosition? position});

/// Checks in children; [HouseholdApi.checkIn] in the app.
typedef ChildrenSubmit = Future<List<HouseholdChild>> Function(
    String tagId, List<String> childIds, {CheckinPosition? position});

/// Checks in from a tag, asking for the phone's location only if the tag
/// needs it, then — for a parent — who of their children is with them.
///
/// Tags without a place never ask. Once location is allowed, a tag that needs
/// it just takes it — the location sheet only appears the first time, or when
/// location is turned off.
Future<NfcCheckinResult> checkInAtTag(
  BuildContext context,
  String tagId, {
  @visibleForTesting CheckinSubmit submit = NfcCheckinService.checkInWithTagId,
  @visibleForTesting ChildrenSubmit submitChildren = HouseholdApi.checkIn,
  @visibleForTesting CheckinLocation location = const CheckinLocation(),
}) async {
  final (result, position) = await _checkInSelf(context, tagId, submit, location);
  if (!result.success || !context.mounted) return result;

  final waiting = result.household.where((c) => !c.presentToday).toList();
  if (waiting.isEmpty) return result;
  final chosen = await _askWhoIsWithYou(context, waiting);
  if (chosen.isEmpty) return result;
  try {
    await submitChildren(tagId, [for (final c in chosen) c.id], position: position);
    return result.withMessage(_together(chosen), alreadyPresent: false);
  } on ChurchApiException catch (e) {
    final reason = e.serverMessage?.trim();
    return result.withMessage(
      'You’re checked in, but we couldn’t check in ${_names(chosen)}'
      '${reason == null || reason.isEmpty ? '. Try again, or ask at the welcome desk.' : ': $reason'}',
    );
  } catch (_) {
    return result.withMessage(
      'You’re checked in, but we couldn’t reach the church to check in ${_names(chosen)}. '
      'Ask at the welcome desk.',
    );
  }
}

/// "You and Kofi are checked in." / "You, Kofi and Ama are checked in."
String _together(List<HouseholdChild> children) => children.length == 1
    ? 'You and ${children.first.firstName} are checked in.'
    : 'You, ${_names(children)} are checked in.';

/// "Kofi" / "Kofi and Ama" / "Kofi, Ama and Esi".
String _names(List<HouseholdChild> children) {
  final names = [for (final c in children) c.firstName];
  if (names.length == 1) return names.first;
  return '${names.sublist(0, names.length - 1).join(', ')} and ${names.last}';
}

/// The member's own check-in, and the position it went with, if any.
Future<(NfcCheckinResult, CheckinPosition?)> _checkInSelf(
  BuildContext context,
  String tagId,
  CheckinSubmit submit,
  CheckinLocation location,
) async {
  final first = await submit(tagId);
  if (first.errorKind != NfcCheckinErrorKind.needsLocation) return (first, null);

  var access = await location.access();
  if (access != LocationAccess.granted) {
    if (!context.mounted) return (first, null);
    final choice = await _askForLocation(context, access);
    switch (choice) {
      case _Choice.share:
        access = await location.request();
      case _Choice.settings:
        await location.openSettings(access);
        return (
          NfcCheckinResult.failure(
            NfcCheckinErrorKind.needsLocation,
            'Once location is on, tap the tag again to check in.',
          ),
          null,
        );
      case _Choice.notNow:
        return (
          NfcCheckinResult.failure(
            NfcCheckinErrorKind.needsLocation,
            'Not checked in. You can check in at the welcome desk instead.',
          ),
          null,
        );
    }
    if (access != LocationAccess.granted) {
      return (
        NfcCheckinResult.failure(
          NfcCheckinErrorKind.needsLocation,
          'Without your location this tag can’t check you in. You can check in at the welcome desk instead.',
        ),
        null,
      );
    }
  }

  final position = await location.current();
  if (position == null) {
    return (
      NfcCheckinResult.failure(
        NfcCheckinErrorKind.needsLocation,
        'Your phone couldn’t find where it is. Give it a moment and tap the tag again, or check in at the welcome desk.',
      ),
      null,
    );
  }
  return (await submit(tagId, position: position), position);
}

/// "Who's with you today?" — the children not yet checked in, all ticked.
/// Returns the ones to check in; empty for "just me".
Future<List<HouseholdChild>> _askWhoIsWithYou(BuildContext context, List<HouseholdChild> children) async {
  final ticked = {for (final c in children) c.id};
  final picked = await showModalBottomSheet<List<HouseholdChild>>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: ChurchColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(ChurchRadius.lg)),
    ),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) {
        final chosen = [for (final c in children) if (ticked.contains(c.id)) c];
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('You’re checked in', style: ChurchType.headline),
              const SizedBox(height: 6),
              Text('Who’s with you today?', style: ChurchType.body),
              const SizedBox(height: 8),
              for (final child in children)
                CheckboxListTile(
                  value: ticked.contains(child.id),
                  onChanged: (v) => setState(() => v == true ? ticked.add(child.id) : ticked.remove(child.id)),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: ChurchColors.button,
                  title: Text(child.name, style: ChurchType.body),
                ),
              const SizedBox(height: 12),
              ChurchPrimaryButton(
                label: chosen.isEmpty
                    ? 'Just me today'
                    : chosen.length == 1
                        ? 'Check in ${chosen.first.firstName}'
                        : 'Check them in',
                onPressed: () => Navigator.pop(ctx, chosen),
              ),
              if (chosen.isNotEmpty) ...[
                const SizedBox(height: 4),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, const <HouseholdChild>[]),
                  child: Text('Just me today', style: ChurchType.button),
                ),
              ],
            ],
          ),
        );
      },
    ),
  );
  return picked ?? const [];
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
          Icon(Icons.place_outlined, color: ChurchColors.accent, size: 28),
          const SizedBox(height: 12),
          Text('One more step', style: ChurchType.headline),
          const SizedBox(height: 8),
          Text(
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
            child: Text('Not now', style: ChurchType.button),
          ),
          const SizedBox(height: 4),
          Text(
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
