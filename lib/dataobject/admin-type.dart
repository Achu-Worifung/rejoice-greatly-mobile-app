class AdminType {
  final String id;
  final String name;
  final String? date;
  final String? imgURL;
  final bool isPresent; // ← add this

  AdminType({
    required this.id,
    required this.name,
    this.date,
    this.imgURL,
    required this.isPresent,
  });

  factory AdminType.fromJson(Map<String, dynamic> json) {
    return AdminType(
      id: json['accountId'],
      name: json['name'],
      date: json['date'] as String?,
      imgURL: json['imgURL'] as String?,
      isPresent: json['isPresent'] ?? false,
    );
  }
}