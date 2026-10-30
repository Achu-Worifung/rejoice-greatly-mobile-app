import 'package:flutter/foundation.dart';

import 'checkin_location.dart';
import 'church_api.dart';

/// A child a member brings to church and checks in alongside themselves.
@immutable
class HouseholdChild {
  const HouseholdChild({
    required this.id,
    required this.name,
    this.dateOfBirth,
    this.presentToday = false,
  });

  factory HouseholdChild.fromJson(Map<String, dynamic> json) => HouseholdChild(
        id: '${json['accountId']}',
        name: json['name'] as String? ?? 'Your child',
        dateOfBirth: DateTime.tryParse('${json['dateOfBirth']}'),
        presentToday: json['presentToday'] as bool? ?? false,
      );

  final String id;
  final String name;
  final DateTime? dateOfBirth;

  /// Already checked in today.
  final bool presentToday;

  /// First name, for "You and Kofi are checked in".
  String get firstName => name.trim().split(RegExp(r'\s+')).first;
}

List<HouseholdChild> parseHousehold(Object? raw) => raw is List
    ? raw
        .whereType<Map>()
        .map((e) => HouseholdChild.fromJson(Map<String, dynamic>.from(e)))
        .toList()
    : const [];

/// Typed calls for `/member/household/**`.
class HouseholdApi {
  HouseholdApi._();

  static Future<List<HouseholdChild>> children() async =>
      parseHousehold(await ChurchApi.memberHousehold(''));

  static Future<HouseholdChild> addChild(String name, DateTime dateOfBirth) async {
    final raw = await ChurchApi.memberHousehold('children', {
      'name': name,
      'dateOfBirth': _isoDate(dateOfBirth),
    });
    return HouseholdChild.fromJson(Map<String, dynamic>.from(raw as Map));
  }

  static Future<void> removeChild(String id) => ChurchApi.memberHousehold('children/$id/remove');

  /// Checks in [childIds] at the tag the member just tapped. Returns the
  /// household as it now stands.
  static Future<List<HouseholdChild>> checkIn(
    String tagId,
    List<String> childIds, {
    CheckinPosition? position,
  }) async {
    final map = await ChurchApi.nfcCheckinChildren(tagId, childIds, location: position?.toJson());
    return parseHousehold(map['household']);
  }

  static String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
