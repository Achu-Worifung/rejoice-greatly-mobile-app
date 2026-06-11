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
      id: json['accountId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      date: json['date']?.toString(),
      imgURL: json['imgURL']?.toString(),
      isPresent: json['isPresent'] == true,
    );
  }
}