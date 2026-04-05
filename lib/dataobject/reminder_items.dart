enum NotificationType { email, push, both }

enum RecurringFrequency { none, custom }

enum SendTo { all, absent, present }

class ReminderItem {
  final String? id;
  String subject;
  String message;
  NotificationType type;
  DateTime? scheduledAt;
  RecurringFrequency recurring;
  List<int> recurringDays;
  SendTo sendTo;
  bool isActive;
  String? oneSignalNotificationId; // read-only from backend
  String? churchId;
  String? createdBy;
  DateTime? createdAt;
  DateTime? updatedAt;

  ReminderItem({
    this.id,
    required this.subject,
    required this.message,
    this.type = NotificationType.both,
    this.scheduledAt,
    this.recurring = RecurringFrequency.none,
    this.recurringDays = const [],
    this.sendTo = SendTo.absent,
    this.isActive = true,
    this.oneSignalNotificationId,
    this.churchId,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  factory ReminderItem.fromJson(Map<String, dynamic> json) {
    return ReminderItem(
      id: json['id']?.toString(),
      subject: json['subject'] ?? '',
      message: json['message'] ?? '',
      type: _parseNotificationType(
        json['sendPush'] ?? true,
        json['sendEmail'] ?? true,
      ),
      scheduledAt: json['scheduledAt'] != null
          ? DateTime.parse(json['scheduledAt']).toLocal()
          : null,
      recurring: (json['recurringDays'] != null &&
              (json['recurringDays'] as List).isNotEmpty)
          ? RecurringFrequency.custom
          : RecurringFrequency.none,
      recurringDays: json['recurringDays'] != null
          ? List<int>.from(json['recurringDays'])
          : [],
      sendTo: _parseSendTo(json['sendTo']),
      isActive: json['isActive'] ?? true,
      oneSignalNotificationId: json['oneSignalId']?.toString(),
      churchId: json['churchId']?.toString(),
      createdBy: json['createdBy']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt']).toLocal()
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt']).toLocal()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'subject': subject,
      'message': message,
      'sendPush':
          type == NotificationType.push || type == NotificationType.both,
      'sendEmail':
          type == NotificationType.email || type == NotificationType.both,
      'scheduledAt': scheduledAt?.toUtc().toIso8601String(),
      'timezone': 'UTC',
      'recurringDays': recurringDays,
      'sendTo': _sendToToString(sendTo),
      'isActive': isActive,
      // Don't send oneSignalNotificationId — backend manages it
      if (churchId != null) 'churchId': churchId,
    };
  }

  static NotificationType _parseNotificationType(bool push, bool email) {
    if (push && email) return NotificationType.both;
    if (push) return NotificationType.push;
    if (email) return NotificationType.email;
    return NotificationType.both;
  }

  static SendTo _parseSendTo(String? value) {
    switch ((value ?? '').toUpperCase()) {
      case 'ALL':
        return SendTo.all;
      case 'PRESENT':
        return SendTo.present;
      case 'ABSENT':
      default:
        return SendTo.absent;
    }
  }

  static String _sendToToString(SendTo sendTo) {
    switch (sendTo) {
      case SendTo.all:
        return 'ALL';
      case SendTo.present:
        return 'PRESENT';
      case SendTo.absent:
        return 'ABSENT';
    }
  }

  ReminderItem copyWith({
    String? id,
    String? subject,
    String? message,
    NotificationType? type,
    DateTime? scheduledAt,
    RecurringFrequency? recurring,
    List<int>? recurringDays,
    SendTo? sendTo,
    bool? isActive,
    String? oneSignalNotificationId,
    String? churchId,
  }) {
    return ReminderItem(
      id: id ?? this.id,
      subject: subject ?? this.subject,
      message: message ?? this.message,
      type: type ?? this.type,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      recurring: recurring ?? this.recurring,
      recurringDays: recurringDays ?? this.recurringDays,
      sendTo: sendTo ?? this.sendTo,
      isActive: isActive ?? this.isActive,
      oneSignalNotificationId:
          oneSignalNotificationId ?? this.oneSignalNotificationId,
      churchId: churchId ?? this.churchId,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}