enum NotificationType { email, push, both }

enum RecurringFrequency { none, weekly, biweekly, monthly }

enum SendTo { all, absent, present }

class ReminderItem {
  final String? id;
  String subject;
  String message;
  NotificationType type;
  DateTime? scheduledAt;
  RecurringFrequency recurring;
  SendTo sendTo;
  bool isActive;
  String? oneSignalNotificationId;
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
    this.sendTo = SendTo.absent,
    this.isActive = true,
    this.oneSignalNotificationId,
    this.churchId,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  // ── From Spring backend JSON ──
  factory ReminderItem.fromJson(Map<String, dynamic> json) {
    return ReminderItem(
      id: json['id'],
      subject: json['subject'] ?? '',
      message: json['message'] ?? '',
      type: _parseNotificationType(
        json['sendPush'] ?? true,
        json['sendEmail'] ?? true,
      ),
      scheduledAt: json['scheduledAt'] != null
          ? DateTime.parse(json['scheduledAt'])
          : null,
      recurring: _parseRecurring(json['recurring']),
      sendTo: _parseSendTo(json['sendTo']),
      isActive: json['isActive'] ?? true,
      oneSignalNotificationId: json['oneSignalId'],
      churchId: json['churchId'],
      createdBy: json['createdBy'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  // ── To Spring backend JSON ──
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'subject': subject,
      'message': message,
      'sendPush': type == NotificationType.push || type == NotificationType.both,
      'sendEmail': type == NotificationType.email || type == NotificationType.both,
      'scheduledAt': scheduledAt?.toUtc().toIso8601String(),
      'timezone': 'UTC',
      'recurring': _recurringToString(recurring),
      'sendTo': _sendToToString(sendTo),
      'isActive': isActive,
      if (oneSignalNotificationId != null) 'oneSignalId': oneSignalNotificationId,
      if (churchId != null) 'churchId': churchId,
    };
  }

  // ── Parsing helpers ──

  static NotificationType _parseNotificationType(bool push, bool email) {
    if (push && email) return NotificationType.both;
    if (push) return NotificationType.push;
    if (email) return NotificationType.email;
    return NotificationType.both;
  }

  static RecurringFrequency _parseRecurring(String? value) {
    switch (value?.toUpperCase()) {
      case 'WEEKLY':
        return RecurringFrequency.weekly;
      case 'BIWEEKLY':
        return RecurringFrequency.biweekly;
      case 'MONTHLY':
        return RecurringFrequency.monthly;
      case 'ONCE':
      default:
        return RecurringFrequency.none;
    }
  }

  static SendTo _parseSendTo(String? value) {
    switch (value?.toUpperCase()) {
      case 'ALL':
        return SendTo.all;
      case 'PRESENT':
        return SendTo.present;
      case 'ABSENT':
      default:
        return SendTo.absent;
    }
  }

  static String _recurringToString(RecurringFrequency freq) {
    switch (freq) {
      case RecurringFrequency.weekly:
        return 'WEEKLY';
      case RecurringFrequency.biweekly:
        return 'BIWEEKLY';
      case RecurringFrequency.monthly:
        return 'MONTHLY';
      case RecurringFrequency.none:
        return 'ONCE';
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