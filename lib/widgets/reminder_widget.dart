import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../dataobject/reminder_items.dart';
import '../notifications/reminder_api_service.dart';
import '../notifications/notification_service.dart';

class RemindersWidget extends StatefulWidget {
  const RemindersWidget({super.key});

  @override
  State<RemindersWidget> createState() => _RemindersWidgetState();
}

class _RemindersWidgetState extends State<RemindersWidget> {
  final int absentCount = 47;
  final NotificationService _notificationService = NotificationService();
  final ReminderApiService _apiService = ReminderApiService();

  bool _isSending = false;
  bool _isInitialized = false;
  bool _isLoading = true;
  String? _errorMessage;

  List<ReminderItem> _reminders = [];

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _initNotifications();
    await _fetchReminders();
  }

  Future<void> _initNotifications() async {
    try {
      await _notificationService.initialize();
      if (mounted) setState(() => _isInitialized = true);
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
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

  Future<void> _fetchReminders() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final reminders = await _apiService.fetchReminders();
      if (mounted) {
        setState(() {
          _reminders = reminders;
          _isLoading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Unexpected error: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _openReminderSheet({ReminderItem? existing}) async {
    final result = await showModalBottomSheet<ReminderItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ReminderEditorSheet(existing: existing, apiService: _apiService),
    );

    if (result == null) return;

    try {
      ReminderItem saved;
      if (existing != null && existing.id != null) {
        saved = await _apiService.updateReminder(
          result.copyWith(id: existing.id),
        );
        setState(() {
          final idx = _reminders.indexWhere((r) => r.id == existing.id);
          if (idx != -1) _reminders[idx] = saved;
        });
        _showSnackBar('Reminder updated successfully', Colors.green);
      } else {
        saved = await _apiService.createReminder(result);
        setState(() => _reminders.add(saved));
        _showSnackBar('Reminder created successfully', Colors.green);
      }
    } on ApiException catch (e) {
      _showSnackBar('Error: ${e.message}', Colors.red);
    } catch (e) {
      _showSnackBar('Unexpected error: $e', Colors.red);
    }
  }

  Future<void> _deleteReminder(String id) async {
    final reminderIndex = _reminders.indexWhere((r) => r.id == id);
    if (reminderIndex == -1) return;
    final removed = _reminders[reminderIndex];
    setState(() => _reminders.removeAt(reminderIndex));

    try {
      final success = await _apiService.deleteReminder(id);
      if (success) {
        _showSnackBar('Reminder deleted', Colors.orange);
      } else {
        setState(() => _reminders.insert(reminderIndex, removed));
        _showSnackBar('Failed to delete reminder', Colors.red);
      }
    } on ApiException catch (e) {
      setState(() => _reminders.insert(reminderIndex, removed));
      _showSnackBar('Error: ${e.message}', Colors.red);
    }
  }

  Future<void> _toggleReminderActive(ReminderItem reminder, bool value) async {
    final oldValue = reminder.isActive;
    setState(() => reminder.isActive = value);
    try {
      if (reminder.id != null) {
        final updated = await _apiService.toggleActive(reminder.id!, value);
        setState(() {
          final idx = _reminders.indexWhere((r) => r.id == reminder.id);
          if (idx != -1) _reminders[idx] = updated;
        });
      }
    } on ApiException catch (e) {
      setState(() => reminder.isActive = oldValue);
      _showSnackBar('Error: ${e.message}', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeCount = _reminders.where((r) => r.isActive).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FA),
        elevation: 0,
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
            icon: const Icon(Icons.refresh, color: Colors.grey),
            onPressed: _fetchReminders,
            tooltip: 'Refresh',
          ),
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
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.red, size: 18),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style:
                            const TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 18),
                      onPressed: _fetchReminders,
                      color: Colors.red,
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
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _reminders.isEmpty
                      ? _EmptyState(onAdd: () => _openReminderSheet())
                      : RefreshIndicator(
                          onRefresh: _fetchReminders,
                          child: ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: _reminders.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, i) {
                              final r = _reminders[i];
                              return _ReminderCard(
                                reminder: r,
                                onTap: () =>
                                    _openReminderSheet(existing: r),
                                onToggle: (val) =>
                                    _toggleReminderActive(r, val),
                                onDelete: () => _deleteReminder(r.id!),
                              );
                            },
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

// ── Reminder Card ─────────────────────────────────────────────────────────────

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

  static const _dayAbbr = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

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

  String _recurringLabel() {
    if (reminder.recurringDays.isEmpty) return 'One-time';
    if (reminder.recurringDays.length == 7) return 'Every day';

    final sorted = List<int>.from(reminder.recurringDays)..sort();
    return sorted.map((d) => _dayAbbr[d]).join(', ');
  }

  String _timeLabel(DateTime? dt) {
    if (dt == null) return 'Send immediately';
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final ampm = dt.hour < 12 ? 'AM' : 'PM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '$hour:$min $ampm';
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(reminder.id ?? UniqueKey().toString()),
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
      confirmDismiss: (_) async {
        return await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Delete Reminder'),
                content: const Text(
                    'Are you sure you want to delete this reminder?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style:
                        TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            ) ??
            false;
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
                            color: reminder.isActive
                                ? Colors.black
                                : Colors.grey,
                          ),
                        ),
                        if (reminder.oneSignalNotificationId != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                Icon(Icons.schedule,
                                    size: 12, color: Colors.green[600]),
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
                    icon: Icons.access_time_rounded,
                    label: _timeLabel(reminder.scheduledAt),
                  ),
                  _MetaChip(
                    icon: Icons.repeat,
                    label: _recurringLabel(),
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

// ── Empty State ──

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

// ── Reminder Editor Bottom Sheet ──────────────────────────────────────────────

class _ReminderEditorSheet extends StatefulWidget {
  final ReminderItem? existing;
  final ReminderApiService apiService;

  const _ReminderEditorSheet({this.existing, required this.apiService});

  @override
  State<_ReminderEditorSheet> createState() => _ReminderEditorSheetState();
}

class _ReminderEditorSheetState extends State<_ReminderEditorSheet> {
  late TextEditingController _subjectCtrl;
  late TextEditingController _messageCtrl;
  late NotificationType _type;
  late SendTo _sendTo;
  DateTime _selectedTime = DateTime(2025, 1, 1, 9, 0);
  bool _timeSelected = false;
  Set<int> _selectedDays = {};

  static const _dayLabels = [
    {'short': 'M', 'full': 'Monday', 'value': 1},
    {'short': 'T', 'full': 'Tuesday', 'value': 2},
    {'short': 'W', 'full': 'Wednesday', 'value': 3},
    {'short': 'T', 'full': 'Thursday', 'value': 4},
    {'short': 'F', 'full': 'Friday', 'value': 5},
    {'short': 'S', 'full': 'Saturday', 'value': 6},
    {'short': 'S', 'full': 'Sunday', 'value': 7},
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _subjectCtrl = TextEditingController(
      text: e?.subject ?? 'We Missed You at Church This Sunday',
    );
    _messageCtrl = TextEditingController(
      text: e?.message ??
          'Hello,\n\nWe noticed you were absent at church this Sunday.\nWe hope to see you at the next gathering.\n',
    );
    _type = e?.type ?? NotificationType.both;
    _sendTo = e?.sendTo ?? SendTo.absent;

    if (e?.scheduledAt != null) {
      _selectedTime = e!.scheduledAt!;
      _timeSelected = true;
    }

    if (e?.recurringDays != null && e!.recurringDays.isNotEmpty) {
      _selectedDays = Set<int>.from(e.recurringDays);
    }
  }

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final ampm = dt.hour < 12 ? 'AM' : 'PM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '$hour:$min $ampm';
  }

  void _showCupertinoTimePicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    'Select Time',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Text(
                      'Done',
                      style: TextStyle(
                        color: Color(0xFF438FFC),
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    onPressed: () {
                      setState(() => _timeSelected = true);
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
            // Picker
            SizedBox(
              height: 260,
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                use24hFormat: false,
                initialDateTime: _selectedTime,
                onDateTimeChanged: (DateTime newTime) {
                  setState(() => _selectedTime = newTime);
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _toggleDay(int day) {
    setState(() {
      if (_selectedDays.contains(day)) {
        _selectedDays.remove(day);
      } else {
        _selectedDays.add(day);
      }
    });
  }

  String _selectedDaysSummary() {
    if (_selectedDays.isEmpty) return 'One-time';
    if (_selectedDays.length == 7) return 'Every day';

    final weekdays = {1, 2, 3, 4, 5};
    final weekend = {6, 7};
    if (_selectedDays.containsAll(weekdays) && _selectedDays.length == 5) {
      return 'Weekdays';
    }
    if (_selectedDays.containsAll(weekend) && _selectedDays.length == 2) {
      return 'Weekends';
    }

    final sorted = _selectedDays.toList()..sort();
    const abbr = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return sorted.map((d) => abbr[d]).join(', ');
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

    if (!_timeSelected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a send time'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final result = ReminderItem(
      id: widget.existing?.id,
      subject: _subjectCtrl.text.trim(),
      message: _messageCtrl.text.trim(),
      type: _type,
      scheduledAt: _selectedTime,
      recurring: _selectedDays.isNotEmpty
          ? RecurringFrequency.custom
          : RecurringFrequency.none,
      recurringDays: _selectedDays.toList()..sort(),
      sendTo: _sendTo,
      isActive: widget.existing?.isActive ?? true,
      churchId: widget.existing?.churchId,
    );

    //saving to one signal

    //updating or saving the service to our databse
    widget.existing != null ? widget.apiService.updateReminder(result) : widget.apiService.createReminder(result);

    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
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
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // ── Send via ──
            const _SectionLabel(text: 'Send via'),
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
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: EdgeInsets.only(
                        right: t != NotificationType.both ? 8 : 0,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFFEAF3FF)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected
                              ? const Color(0xFF438FFC)
                              : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(icon,
                              size: 20,
                              color: selected
                                  ? const Color(0xFF438FFC)
                                  : Colors.grey),
                          const SizedBox(height: 4),
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
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
            const SizedBox(height: 24),

            // ── Send to ──
            const _SectionLabel(text: 'Send to'),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
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
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color:
                              selected ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(9),
                          boxShadow: selected
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : [],
                        ),
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.normal,
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
            const SizedBox(height: 24),

            // ── Subject ──
            const _SectionLabel(text: 'Subject'),
            const SizedBox(height: 8),
            TextField(
              controller: _subjectCtrl,
              decoration: _inputDecoration('Email subject line'),
            ),
            const SizedBox(height: 20),

            // ── Message ──
            const _SectionLabel(text: 'Message'),
            const SizedBox(height: 8),
            TextField(
              controller: _messageCtrl,
              maxLines: 5,
              decoration: _inputDecoration(
                'Use [First Name], [Service Date], [Church Name] as placeholders',
              ),
            ),
            const SizedBox(height: 24),

            // ── Time Picker ──
            const _SectionLabel(text: 'Send Time'),
            const SizedBox(height: 4),
            const Text(
              'Choose what time to send reminders',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _showCupertinoTimePicker,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  gradient: _timeSelected
                      ? const LinearGradient(
                          colors: [Color(0xFFEAF3FF), Color(0xFFF0F4FF)],
                        )
                      : null,
                  color: _timeSelected ? null : Colors.grey[100],
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _timeSelected
                        ? const Color(0xFF438FFC).withOpacity(0.3)
                        : Colors.grey[300]!,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _timeSelected
                            ? const Color(0xFF438FFC).withOpacity(0.1)
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.access_time_rounded,
                        size: 22,
                        color: _timeSelected
                            ? const Color(0xFF438FFC)
                            : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _timeSelected
                                ? _formatTime(_selectedTime)
                                : 'Tap to select time',
                            style: TextStyle(
                              fontSize: _timeSelected ? 20 : 15,
                              fontWeight: _timeSelected
                                  ? FontWeight.bold
                                  : FontWeight.w400,
                              color: _timeSelected
                                  ? Colors.black87
                                  : Colors.grey,
                              letterSpacing:
                                  _timeSelected ? 1.0 : 0,
                            ),
                          ),
                          if (_timeSelected)
                            const Text(
                              'Tap to change',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Icon(
                      CupertinoIcons.chevron_right,
                      size: 18,
                      color: Colors.grey[400],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Recurring Days ──
            const _SectionLabel(text: 'Repeat On'),
            const SizedBox(height: 4),
            Text(
              _selectedDays.isEmpty
                  ? 'Select days to repeat, or leave empty for one-time'
                  : _selectedDaysSummary(),
              style: TextStyle(
                fontSize: 12,
                color: _selectedDays.isNotEmpty
                    ? const Color(0xFF438FFC)
                    : Colors.grey,
                fontWeight: _selectedDays.isNotEmpty
                    ? FontWeight.w500
                    : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _dayLabels.map((day) {
                final value = day['value'] as int;
                final short = day['short'] as String;
                final isSelected = _selectedDays.contains(value);

                return GestureDetector(
                  onTap: () => _toggleDay(value),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF438FFC),
                                Color(0xFF5B9FFF),
                              ],
                            )
                          : null,
                      color: isSelected ? null : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? Colors.transparent
                            : Colors.grey[300]!,
                        width: 1.5,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(0xFF438FFC)
                                    .withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : [],
                    ),
                    child: Center(
                      child: Text(
                        short,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color:
                              isSelected ? Colors.white : Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            // Quick select buttons
            Row(
              children: [
                _QuickSelectChip(
                  label: 'Weekdays',
                  isSelected: _selectedDays.containsAll({1, 2, 3, 4, 5}) &&
                      _selectedDays.length == 5,
                  onTap: () {
                    setState(() {
                      if (_selectedDays.containsAll({1, 2, 3, 4, 5}) &&
                          _selectedDays.length == 5) {
                        _selectedDays.clear();
                      } else {
                        _selectedDays = {1, 2, 3, 4, 5};
                      }
                    });
                  },
                ),
                const SizedBox(width: 8),
                _QuickSelectChip(
                  label: 'Weekends',
                  isSelected: _selectedDays.containsAll({6, 7}) &&
                      _selectedDays.length == 2,
                  onTap: () {
                    setState(() {
                      if (_selectedDays.containsAll({6, 7}) &&
                          _selectedDays.length == 2) {
                        _selectedDays.clear();
                      } else {
                        _selectedDays = {6, 7};
                      }
                    });
                  },
                ),
                const SizedBox(width: 8),
                _QuickSelectChip(
                  label: 'Every day',
                  isSelected: _selectedDays.length == 7,
                  onTap: () {
                    setState(() {
                      if (_selectedDays.length == 7) {
                        _selectedDays.clear();
                      } else {
                        _selectedDays = {1, 2, 3, 4, 5, 6, 7};
                      }
                    });
                  },
                ),
              ],
            ),

            const SizedBox(height: 32),

            // ── Save Button ──
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF438FFC),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  isEditing ? 'Save Changes' : 'Create Reminder',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFDDE3F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFDDE3F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            const BorderSide(color: Color(0xFF438FFC), width: 1.5),
      ),
    );
  }
}

// ── Reusable Widgets ──

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Colors.black54,
        letterSpacing: 0.3,
      ),
    );
  }
}

class _QuickSelectChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _QuickSelectChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF438FFC).withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF438FFC).withOpacity(0.4)
                : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? const Color(0xFF438FFC) : Colors.grey[600],
          ),
        ),
      ),
    );
  }
}