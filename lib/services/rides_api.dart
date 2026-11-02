import 'package:flutter/material.dart' show DateUtils, immutable;
import 'package:intl/intl.dart';

import 'church_api.dart';

DateTime? _date(Object? v) => v == null ? null : DateTime.tryParse('$v');

String _iso(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

/// "Sunday, Nov 1"; "This Sunday" when it's the coming one.
String rideDayLabel(DateTime day, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final diff = DateTime(day.year, day.month, day.day).difference(today).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Tomorrow';
  if (diff > 1 && diff < 7 && day.weekday == DateTime.sunday) return 'This Sunday';
  return DateFormat('EEEE, MMM d').format(day);
}

/// The driver picking a member up.
@immutable
class RideDriver {
  const RideDriver({required this.name, this.car, this.phone});

  factory RideDriver.fromJson(Map<String, dynamic> j) => RideDriver(
        name: j['name'] as String? ?? 'Your driver',
        car: j['car'] as String?,
        phone: j['phone'] as String?,
      );

  final String name;
  final String? car;
  final String? phone;
}

/// A ride the member asked for.
@immutable
class MyRide {
  const MyRide({
    required this.id,
    required this.date,
    required this.label,
    required this.seats,
    required this.status,
    this.driver,
  });

  factory MyRide.fromJson(Map<String, dynamic> j) => MyRide(
        id: '${j['id']}',
        date: _date(j['date']) ?? DateTime.now(),
        label: j['label'] as String? ?? 'Sunday service',
        seats: (j['seats'] as num?)?.toInt() ?? 1,
        status: j['status'] as String? ?? 'OPEN',
        driver: j['driver'] is Map ? RideDriver.fromJson(Map<String, dynamic>.from(j['driver'] as Map)) : null,
      );

  final String id;
  final DateTime date;
  final String label;
  final int seats;

  /// OPEN while the transport team finds a driver; ASSIGNED once they have.
  final String status;
  final RideDriver? driver;

  bool get arranged => status == 'ASSIGNED' && driver != null;
}

/// The member's rides, and the Sundays they can ask for.
@immutable
class RidesOverview {
  const RidesOverview(this.rides, this.sundays);

  factory RidesOverview.fromJson(Map<String, dynamic> j) => RidesOverview(
        [
          for (final r in (j['rides'] as List? ?? const []))
            if (r is Map) MyRide.fromJson(Map<String, dynamic>.from(r)),
        ],
        [for (final d in (j['sundays'] as List? ?? const [])) ?_date(d)],
      );

  final List<MyRide> rides;
  final List<DateTime> sundays;

  /// Sundays without a ride asked for yet.
  List<DateTime> get openSundays => [
        for (final d in sundays)
          if (!rides.any((r) => DateUtils.isSameDay(r.date, d))) d,
      ];
}

/// Someone a driver is picking up.
@immutable
class RideRider {
  const RideRider({
    required this.requestId,
    required this.date,
    required this.label,
    required this.name,
    required this.seats,
    this.note,
    this.address,
    this.lat,
    this.lng,
    this.phone,
  });

  factory RideRider.fromJson(Map<String, dynamic> j) => RideRider(
        requestId: '${j['requestId']}',
        date: _date(j['date']) ?? DateTime.now(),
        label: j['label'] as String? ?? 'Sunday service',
        name: j['name'] as String? ?? 'A member',
        seats: (j['seats'] as num?)?.toInt() ?? 1,
        note: j['note'] as String?,
        address: j['address'] as String?,
        lat: (j['lat'] as num?)?.toDouble(),
        lng: (j['lng'] as num?)?.toDouble(),
        phone: j['phone'] as String?,
      );

  final String requestId;
  final DateTime date;
  final String label;
  final String name;
  final int seats;
  final String? note;
  final String? address;
  final double? lat;
  final double? lng;
  final String? phone;

  /// Directions to the pickup in the phone's maps app.
  Uri? get directions {
    final destination = lat != null && lng != null ? '$lat,$lng' : address;
    if (destination == null || destination.isEmpty) return null;
    return Uri.https('www.google.com', '/maps/dir/', {'api': '1', 'destination': destination});
  }
}

/// A driver's own view: their details, the Sundays they can drive, and who
/// they're picking up. [approved] is false for everyone else.
@immutable
class Driving {
  const Driving({
    required this.approved,
    required this.seats,
    this.car,
    this.phone,
    this.address,
    required this.located,
    required this.availableOn,
    required this.riders,
    required this.sundays,
  });

  factory Driving.fromJson(Map<String, dynamic> body) {
    final j = body['driving'] is Map ? Map<String, dynamic>.from(body['driving'] as Map) : const <String, dynamic>{};
    return Driving(
      approved: j['approved'] == true,
      seats: (j['seats'] as num?)?.toInt() ?? 3,
      car: j['car'] as String?,
      phone: j['phone'] as String?,
      address: j['address'] as String?,
      located: j['located'] == true,
      availableOn: [for (final d in (j['availableOn'] as List? ?? const [])) ?_date(d)],
      riders: [
        for (final r in (j['riders'] as List? ?? const []))
          if (r is Map) RideRider.fromJson(Map<String, dynamic>.from(r)),
      ],
      sundays: [for (final d in (body['sundays'] as List? ?? const [])) ?_date(d)],
    );
  }

  static const Driving none = Driving(
    approved: false,
    seats: 3,
    located: false,
    availableOn: [],
    riders: [],
    sundays: [],
  );

  final bool approved;
  final int seats;
  final String? car;
  final String? phone;

  /// Where they usually start from.
  final String? address;

  /// The start point was found on the map, so they can be suggested.
  final bool located;
  final List<DateTime> availableOn;
  final List<RideRider> riders;
  final List<DateTime> sundays;

  bool canDriveOn(DateTime day) => availableOn.any((d) => DateUtils.isSameDay(d, day));

  /// Set up enough to be suggested: a start point and a phone.
  bool get ready => located && (phone ?? '').isNotEmpty;
}

/// Pickup point details, as the backend seals them.
@immutable
class RidePlace {
  const RidePlace({required this.address, required this.phone, this.lat, this.lng});

  final String address;
  final String phone;
  final double? lat;
  final double? lng;

  Map<String, dynamic> toJson() => {
        'address': address.trim(),
        'phone': phone.trim(),
        'lat': ?lat,
        'lng': ?lng,
      };
}

/// `/member/rides`: asking for a ride to church, and driving for those who
/// were asked to. Addresses go only to the transport coordinator and the
/// driver assigned, and are deleted the day after the ride.
class RidesApi {
  RidesApi._();

  static Future<RidesOverview> mine() async => RidesOverview.fromJson(await ChurchApi.memberRides(''));

  static Future<MyRide> request({
    required DateTime date,
    required int seats,
    required RidePlace pickup,
    String? note,
  }) async {
    final map = await ChurchApi.memberRides('request', {
      'date': _iso(date),
      'seats': seats,
      if ((note ?? '').trim().isNotEmpty) 'note': note!.trim(),
      ...pickup.toJson(),
    });
    return MyRide.fromJson(map);
  }

  static Future<void> cancel(String id) => ChurchApi.memberRides('${Uri.encodeComponent(id)}/cancel');

  static Future<Driving> driving() async => Driving.fromJson(await ChurchApi.memberRides('driving'));

  static Future<Driving> updateDriving({required int seats, String? car, required RidePlace start}) async =>
      Driving.fromJson(await ChurchApi.memberRides('driving/update', {
        'seats': seats,
        if ((car ?? '').trim().isNotEmpty) 'car': car!.trim(),
        ...start.toJson(),
      }));

  static Future<Driving> setAvailable(DateTime date, bool available) async =>
      Driving.fromJson(await ChurchApi.memberRides('driving/available', {
        'date': _iso(date),
        'available': available,
      }));
}
