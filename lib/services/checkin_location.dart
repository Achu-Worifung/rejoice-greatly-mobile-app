import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Where the phone is, for a check-in at a tag that has a place. Sent once,
/// with that check-in; the server keeps only how far it was from the tag.
class CheckinPosition {
  const CheckinPosition(this.latitude, this.longitude, this.accuracyMeters);

  final double latitude;
  final double longitude;

  /// The phone's own estimate of how far off it may be.
  final double? accuracyMeters;

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        if (accuracyMeters != null) 'accuracyMeters': accuracyMeters,
      };
}

/// Whether the app may read the phone's location right now.
enum LocationAccess {
  granted,

  /// Not decided yet: the system will ask.
  canAsk,

  /// Turned down for good: only the Settings app can change it.
  blocked,

  /// Location is switched off for the whole phone.
  off,
}

/// Reads the phone's location for check-in. Only touched when a tag needs
/// it — tags without a place never ask. Tests stand in their own subclass.
class CheckinLocation {
  const CheckinLocation();

  /// How long to wait for a fresh fix. Indoors this can take a few seconds.
  static const Duration _fixTimeout = Duration(seconds: 12);

  /// A recent fix the phone already has is good enough if it's this fresh —
  /// older, and it may be from before they arrived.
  static const Duration _maxFixAge = Duration(minutes: 2);

  Future<LocationAccess> access() async {
    if (kIsWeb) return LocationAccess.off;
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return LocationAccess.off;
      return _accessFor(await Geolocator.checkPermission());
    } catch (e) {
      debugPrint('CheckinLocation.access failed: $e');
      return LocationAccess.off;
    }
  }

  /// Shows the system's own location prompt (while using the app only).
  Future<LocationAccess> request() async {
    try {
      return _accessFor(await Geolocator.requestPermission());
    } catch (e) {
      debugPrint('CheckinLocation.request failed: $e');
      return LocationAccess.blocked;
    }
  }

  /// Where the phone is now, or null if it can't tell in time.
  Future<CheckinPosition?> current() async {
    try {
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: _fixTimeout,
        ),
      );
      return CheckinPosition(p.latitude, p.longitude, p.accuracy);
    } on TimeoutException {
      try {
        final last = await Geolocator.getLastKnownPosition();
        if (last != null && DateTime.now().difference(last.timestamp) < _maxFixAge) {
          return CheckinPosition(last.latitude, last.longitude, last.accuracy);
        }
      } catch (_) {}
      return null;
    } catch (e) {
      debugPrint('CheckinLocation.current failed: $e');
      return null;
    }
  }

  /// Where the member can turn location back on.
  Future<void> openSettings(LocationAccess access) async {
    try {
      if (access == LocationAccess.off) {
        await Geolocator.openLocationSettings();
      } else {
        await Geolocator.openAppSettings();
      }
    } catch (e) {
      debugPrint('CheckinLocation.openSettings failed: $e');
    }
  }

  static LocationAccess _accessFor(LocationPermission permission) {
    switch (permission) {
      case LocationPermission.always:
      case LocationPermission.whileInUse:
        return LocationAccess.granted;
      case LocationPermission.denied:
        return LocationAccess.canAsk;
      case LocationPermission.deniedForever:
      case LocationPermission.unableToDetermine:
        return LocationAccess.blocked;
    }
  }
}
