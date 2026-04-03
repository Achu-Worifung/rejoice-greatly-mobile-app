import 'package:flutter/material.dart';
import '../notifications/notification_service.dart';
import '../notifications/reminder_notification_service.dart';

// ── Data models ──────────────────────────────────────────────────────────────

enum NotificationType { email, push, both }

enum RecurringFrequency { none, weekly, biweekly, monthly }

enum SendTo { all, absent, present }

class ReminderItem {
  final String id;
  String subject;
  String message;
  NotificationType type;
  DateTime? scheduledAt;
  RecurringFrequency recurring;
  SendTo sendTo;
  bool isActive;
  String? oneSignalNotificationId;

  ReminderItem({
    required this.id,
    required this.subject,
    required this.message,
    this.type = NotificationType.both,
    this.scheduledAt,
    this.recurring = RecurringFrequency.none,
    this.sendTo = SendTo.absent,
    this.isActive = true,
    this.oneSignalNotificationId,
  });
}

// ── Main widget ───────────────────────────────────────────────────────────────

class RemindersWidget extends StatefulWidget {
  const RemindersWidget({super.key});

  @override
  State<RemindersWidget> createState() => _RemindersWidgetState();
}

class _RemindersWidgetState extends State<RemindersWidget> {
  final int absentCount = 47;
  final NotificationService _notificationService = NotificationService();
  bool _isSending = false;
  bool _isInitialized = false;

  final List<ReminderItem> _reminders = [
    ReminderItem(
      id: '1',
      subject: 'We Missed You at Church This Sunday',
      message:
          'Hello [First Name],\n\nWe noticed you were absent on [Service Date].\nWe hope to see you at the next gathering.\nIf you need any support, please reach out.\n\nJane,\n[Church Name]',
      type: NotificationType.both,
      recurring: RecurringFrequency.weekly,
      sendTo: SendTo.absent,
      isActive: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    try {
      await _notificationService.initialize();
      setState(() => _isInitialized = true);
    } catch (e) {
      print('Error initializing notifications: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to initialize notifications: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _openReminderSheet({ReminderItem? existing}) async {
    final result = await showModalBottomSheet<ReminderItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ReminderEditorSheet(existing: existing),
    );
    
    if (result != null) {
      // Cancel old scheduled notification if editing
      if (existing != null && existing.oneSignalNotificationId != null) {
        await ReminderNotificationService.cancelScheduledNotification(
          existing.oneSignalNotificationId!,
        );
      }

      setState(() {
        if (existing != null) {
          final idx = _reminders.indexWhere((r) => r.id == existing.id);
          if (idx != -1) _reminders[idx] = result;
        } else {
          _reminders.add(result);
        }
      });

      // Schedule the notification if needed
      await _scheduleReminderIfNeeded(result);
    }
  }

  Future<void> _scheduleReminderIfNeeded(ReminderItem reminder) async {
    if (!reminder.isActive) return;

    final shouldSendPush = reminder.type == NotificationType.push ||
        reminder.type == NotificationType.both;
    final shouldSendEmail = reminder.type == NotificationType.email ||
        reminder.type == NotificationType.both;

    if (reminder.scheduledAt != null && shouldSendPush) {
      final notificationId = await ReminderNotificationService.scheduleReminder(
        subject: reminder.subject,
        message: reminder.message,
        scheduledAt: reminder.scheduledAt!,
        sendTo: reminder.sendTo.name,
        sendPush: shouldSendPush,
        sendEmail: shouldSendEmail,
        recurring: reminder.recurring != RecurringFrequency.none
            ? reminder.recurring.name
            : null,
      );

      if (notificationId != null) {
        setState(() {
          reminder.oneSignalNotificationId = notificationId;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Reminder scheduled successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to schedule reminder'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteReminder(String id) async {
    final reminderIndex = _reminders.indexWhere((r) => r.id == id);
    if (reminderIndex == -1) return;

    final reminder = _reminders[reminderIndex];

    // Cancel scheduled notification if exists
    if (reminder.oneSignalNotificationId != null) {
      await ReminderNotificationService.cancelScheduledNotification(
        reminder.oneSignalNotificationId!,
      );
    }

    setState(() => _reminders.removeAt(reminderIndex));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reminder deleted'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _sendAll() async {
    if (_isSending) return;

    setState(() => _isSending = true);

    final activeReminders = _reminders.where((r) => r.isActive).toList();
    int successCount = 0;
    int failCount = 0;
    int skippedCount = 0;

    for (final reminder in activeReminders) {
      final shouldSendPush = reminder.type == NotificationType.push ||
          reminder.type == NotificationType.both;
      final shouldSendEmail = reminder.type == NotificationType.email ||
          reminder.type == NotificationType.both;

      // If scheduled for future, skip (already scheduled)
      if (reminder.scheduledAt != null && 
          reminder.scheduledAt!.isAfter(DateTime.now())) {
        skippedCount++;
        continue;
      }

      // Send immediate notification
      final success = await ReminderNotificationService.sendImmediateReminder(
        subject: reminder.subject,
        message: reminder.message,
        sendTo: reminder.sendTo.name,
        sendPush: shouldSendPush,
        sendEmail: shouldSendEmail,
      );

      if (success) {
        successCount++;
      } else {
        failCount++;
      }

      // Small delay between sends to avoid rate limiting
      await Future.delayed(const Duration(milliseconds: 500));
    }

    setState(() => _isSending = false);

    if (mounted) {
      String message;
      Color backgroundColor;

      if (failCount == 0 && successCount > 0) {
        message = 'Successfully sent $successCount reminder(s) to $absentCount members';
        backgroundColor = Colors.green;
      } else if (successCount > 0 && failCount > 0) {
        message = 'Sent $successCount, failed $failCount reminder(s)';
        backgroundColor = Colors.orange;
      } else if (skippedCount > 0 && successCount == 0) {
        message = '$skippedCount reminder(s) are scheduled for later';
        backgroundColor = Colors.blue;
      } else {
        message = 'Failed to send reminders';
        backgroundColor = Colors.red;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _toggleReminderActive(ReminderItem reminder, bool value) async {
    setState(() => reminder.isActive = value);

    if (value) {
      // Turning on - schedule if needed
      await _scheduleReminderIfNeeded(reminder);
    } else {
      // Turning off - cancel scheduled notification
      if (reminder.oneSignalNotificationId != null) {
        await ReminderNotificationService.cancelScheduledNotification(
          reminder.oneSignalNotificationId!,
        );
        setState(() {
          reminder.oneSignalNotificationId = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeCount = _reminders.where((r) => r.isActive).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FA),
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: const Text(
          'Reminders',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFF438FFC), size: 28),
            onPressed: () => _openReminderSheet(),
            tooltip: 'New reminder',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Initialization status
            if (!_isInitialized)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: const Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Initializing notifications...',
                      style: TextStyle(color: Colors.orange, fontSize: 13),
                    ),
                  ],
                ),
              ),

            // Absent members banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF3FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Absent Members: $absentCount',
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      'View absentees',
                      style: TextStyle(color: Color(0xFF438FFC), fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Reminders',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                Text(
                  '$activeCount active',
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Reminder cards list
            Expanded(
              child: _reminders.isEmpty
                  ? _EmptyState(onAdd: () => _openReminderSheet())
                  : ListView.separated(
                      itemCount: _reminders.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final r = _reminders[i];
                        return _ReminderCard(
                          reminder: r,
                          onTap: () => _openReminderSheet(existing: r),
                          onToggle: (val) => _toggleReminderActive(r, val),
                          onDelete: () => _deleteReminder(r.id),
                        );
                      },
                    ),
            ),

            const SizedBox(height: 12),

            // Send button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (activeCount > 0 && !_isSending && _isInitialized)
                    ? _sendAll
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF438FFC),
                  disabledBackgroundColor: Colors.grey[300],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isSending
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        activeCount > 0
                            ? 'Send $activeCount Reminder${activeCount == 1 ? '' : 's'} to $absentCount Members'
                            : 'No active reminders',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ── Reminder card ─────────────────────────────────────────────────────────────

class _ReminderCard extends StatelessWidget {
  final ReminderItem reminder;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;

  const _ReminderCard({
    required this.reminder,
    required this.onTap,
    required this.onToggle,
    required this.onDelete,
  });

  String _typeLabel(NotificationType t) {
    switch (t) {
      case NotificationType.email:
        return 'Email';
      case NotificationType.push:
        return 'Push';
      case NotificationType.both:
        return 'Email + Push';
    }
  }

  IconData _typeIcon(NotificationType t) {
    switch (t) {
      case NotificationType.email:
        return Icons.email_outlined;
      case NotificationType.push:
        return Icons.notifications_outlined;
      case NotificationType.both:
        return Icons.send;
    }
  }

  String _recurringLabel(RecurringFrequency f) {
    switch (f) {
      case RecurringFrequency.none:
        return 'One-time';
      case RecurringFrequency.weekly:
        return 'Weekly';
      case RecurringFrequency.biweekly:
        return 'Bi-weekly';
      case RecurringFrequency.monthly:
        return 'Monthly';
    }
  }

  String _scheduleLabel(DateTime? dt) {
    if (dt == null) return 'Send immediately';
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final ampm = dt.hour < 12 ? 'AM' : 'PM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '${months[dt.month]} ${dt.day} at $hour:$min $ampm';
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(reminder.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red[400],
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Reminder'),
            content: const Text('Are you sure you want to delete this reminder?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ?? false;
      },
      onDismissed: (_) => onDelete(),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: reminder.isActive
                  ? const Color(0xFFB8D4FF)
                  : Colors.grey[200]!,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: subject + toggle
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reminder.subject,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: reminder.isActive ? Colors.black : Colors.grey,
                          ),
                        ),
                        if (reminder.oneSignalNotificationId != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.schedule,
                                  size: 12,
                                  color: Colors.green[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Scheduled',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.green[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Transform.scale(
                    scale: 0.8,
                    child: Switch(
                      value: reminder.isActive,
                      onChanged: onToggle,
                      activeColor: const Color(0xFF438FFC),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Meta chips row
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _MetaChip(
                    icon: _typeIcon(reminder.type),
                    label: _typeLabel(reminder.type),
                  ),
                  _MetaChip(
                    icon: Icons.people_outline,
                    label: reminder.sendTo == SendTo.all
                        ? 'All members'
                        : reminder.sendTo == SendTo.absent
                            ? 'Absent only'
                            : 'Present only',
                  ),
                  _MetaChip(
                    icon: Icons.schedule,
                    label: _scheduleLabel(reminder.scheduledAt),
                  ),
                  _MetaChip(
                    icon: Icons.repeat,
                    label: _recurringLabel(reminder.recurring),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4FF),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFF438FFC)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF438FFC),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications_none, size: 56, color: Colors.grey[300]),
          const SizedBox(height: 12),
          const Text(
            'No reminders yet',
            style: TextStyle(color: Colors.grey, fontSize: 15),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Create your first reminder'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF438FFC),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reminder editor bottom sheet ──────────────────────────────────────────────

class _ReminderEditorSheet extends StatefulWidget {
  final ReminderItem? existing;
  const _ReminderEditorSheet({this.existing});

  @override
  State<_ReminderEditorSheet> createState() => _ReminderEditorSheetState();
}

class _ReminderEditorSheetState extends State<_ReminderEditorSheet> {
  late TextEditingController _subjectCtrl;
  late TextEditingController _messageCtrl;
  late NotificationType _type;
  late RecurringFrequency _recurring;
  late SendTo _sendTo;
  DateTime? _scheduledAt;
  bool _scheduleEnabled = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _subjectCtrl = TextEditingController(
      text: e?.subject ?? 'We Missed You at Church This Sunday',
    );
    _messageCtrl = TextEditingController(
      text: e?.message ??
          'Hello [First Name],\n\nWe noticed you were absent on [Service Date].\nWe hope to see you at the next gathering.\n\nJane,\n[Church Name]',
    );
    _type = e?.type ?? NotificationType.both;
    _recurring = e?.recurring ?? RecurringFrequency.none;
    _sendTo = e?.sendTo ?? SendTo.absent;
    _scheduledAt = e?.scheduledAt;
    _scheduleEnabled = _scheduledAt != null;
  }

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledAt ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null) return;

    if (!mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_scheduledAt ?? now),
    );
    if (time == null) return;

    setState(() {
      _scheduledAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  String _formatDateTime(DateTime dt) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final ampm = dt.hour < 12 ? 'AM' : 'PM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '${months[dt.month]} ${dt.day}, ${dt.year}  $hour:$min $ampm';
  }

  void _save() {
    if (_subjectCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a subject'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_messageCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a message'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_scheduleEnabled && _scheduledAt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a schedule date and time'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final result = ReminderItem(
      id: widget.existing?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      subject: _subjectCtrl.text.trim(),
      message: _messageCtrl.text.trim(),
      type: _type,
      scheduledAt: _scheduleEnabled ? _scheduledAt : null,
      recurring: _recurring,
      sendTo: _sendTo,
      isActive: widget.existing?.isActive ?? true,
    );
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              isEditing ? 'Edit Reminder' : 'New Reminder',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Notification type
            const Text(
              'Send via',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: NotificationType.values.map((t) {
                final selected = _type == t;
                final label = t == NotificationType.email
                    ? 'Email'
                    : t == NotificationType.push
                        ? 'Push'
                        : 'Both';
                final icon = t == NotificationType.email
                    ? Icons.email_outlined
                    : t == NotificationType.push
                        ? Icons.notifications_outlined
                        : Icons.send;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _type = t),
                    child: Container(
                      margin: EdgeInsets.only(
                        right: t != NotificationType.both ? 8 : 0,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFFEAF3FF)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected
                              ? const Color(0xFF438FFC)
                              : Colors.transparent,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            icon,
                            size: 18,
                            color: selected
                                ? const Color(0xFF438FFC)
                                : Colors.grey,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: selected
                                  ? const Color(0xFF438FFC)
                                  : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Send to
            const Text(
              'Send to',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: SendTo.values.map((f) {
                  final selected = _sendTo == f;
                  final label = f == SendTo.all
                      ? 'All'
                      : f == SendTo.absent
                          ? 'Absent'
                          : 'Present';
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _sendTo = f),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: selected ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: selected
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.06),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ]
                              : [],
                        ),
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight:
                                selected ? FontWeight.w600 : FontWeight.normal,
                            color: selected
                                ? const Color(0xFF438FFC)
                                : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),

            // Subject
            const Text(
              'Subject',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _subjectCtrl,
              decoration: _inputDecoration('Email subject line'),
            ),
            const SizedBox(height: 16),

            // Message
            const Text(
              'Message',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _messageCtrl,
              maxLines: 6,
              decoration: _inputDecoration(
                'Use [First Name], [Service Date], [Church Name] as placeholders',
              ),
            ),
            const SizedBox(height: 20),

            // Schedule toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Schedule',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                    ),
                    Text(
                      'Send at a specific time',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                Switch(
                  value: _scheduleEnabled,
                  onChanged: (val) {
                    setState(() {
                      _scheduleEnabled = val;
                      if (val && _scheduledAt == null) {
                        _pickDateTime();
                      }
                    });
                  },
                  activeColor: const Color(0xFF438FFC),
                ),
              ],
            ),
            if (_scheduleEnabled) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickDateTime,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F4FF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFB8D4FF)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.schedule,
                        size: 16,
                        color: Color(0xFF438FFC),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _scheduledAt != null
                            ? _formatDateTime(_scheduledAt!)
                            : 'Tap to pick date & time',
                        style: TextStyle(
                          fontSize: 14,
                          color:
                              _scheduledAt != null ? Colors.black87 : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),

            // Recurring
            const Text(
              'Recurring',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: RecurringFrequency.values.map((f) {
                  final selected = _recurring == f;
                  final label = f == RecurringFrequency.none
                      ? 'Once'
                      : f == RecurringFrequency.weekly
                          ? 'Weekly'
                          : f == RecurringFrequency.biweekly
                              ? 'Bi-weekly'
                              : 'Monthly';
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _recurring = f),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: selected ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: selected
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.06),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ]
                              : [],
                        ),
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight:
                                selected ? FontWeight.w600 : FontWeight.normal,
                            color: selected
                                ? const Color(0xFF438FFC)
                                : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 28),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF438FFC),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  isEditing ? 'Save Changes' : 'Create Reminder',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFDDE3F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFDDE3F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF438FFC)),
      ),
    );
  }
}