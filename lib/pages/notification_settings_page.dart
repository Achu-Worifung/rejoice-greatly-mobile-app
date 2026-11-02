import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

import '../services/church_api.dart';
import '../services/user_facing_error.dart';
import '../theme/church_colors.dart';
import '../theme/church_type.dart';

/// One kind of notification and whether it buzzes this member's phone.
class NotificationSetting {
  const NotificationSetting({
    required this.type,
    required this.label,
    required this.description,
    required this.enabled,
  });

  factory NotificationSetting.fromJson(Map<String, dynamic> j) => NotificationSetting(
        type: '${j['type']}',
        label: j['label'] as String? ?? '${j['type']}',
        description: j['description'] as String? ?? '',
        enabled: j['enabled'] != false,
      );

  final String type;
  final String label;
  final String description;
  final bool enabled;

  NotificationSetting copyWith({bool? enabled}) => NotificationSetting(
        type: type,
        label: label,
        description: description,
        enabled: enabled ?? this.enabled,
      );

  static List<NotificationSetting> listFrom(Map<String, dynamic> data) => [
        for (final s in (data['settings'] as List? ?? const []))
          if (s is Map) NotificationSetting.fromJson(Map<String, dynamic>.from(s)),
      ];
}

/// Which notifications buzz this phone. Everything starts on; turning one off
/// keeps it in the inbox, just without the buzz.
class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key, this.load, this.update, this.phoneAllows});

  /// Stand-ins for the API and the phone's permission, for tests.
  final Future<List<NotificationSetting>> Function()? load;
  final Future<List<NotificationSetting>> Function(String type, bool enabled)? update;
  final Future<bool> Function()? phoneAllows;

  @override
  State<NotificationSettingsPage> createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  List<NotificationSetting>? _settings;
  String? _error;
  bool _phoneAllows = true;

  @override
  void initState() {
    super.initState();
    _load();
    _checkPhone();
  }

  Future<List<NotificationSetting>> _fetch() async =>
      NotificationSetting.listFrom(await ChurchApi.memberNotificationSettings(''));

  Future<List<NotificationSetting>> _save(String type, bool enabled) async => NotificationSetting.listFrom(
      await ChurchApi.memberNotificationSettings('update', {'type': type, 'enabled': enabled}));

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final settings = await (widget.load ?? _fetch)();
      if (mounted) setState(() => _settings = settings);
    } catch (e) {
      if (mounted) setState(() => _error = userFacingError(e));
    }
  }

  Future<void> _checkPhone() async {
    try {
      final allows = await (widget.phoneAllows ?? () async => OneSignal.Notifications.permission)();
      if (mounted) setState(() => _phoneAllows = allows);
    } catch (_) {
      // No notification plugin here (tests, web): say nothing about it.
    }
  }

  Future<void> _turnOnForPhone() async {
    try {
      // Opens the phone's settings when the member said no before.
      await OneSignal.Notifications.requestPermission(true);
    } catch (_) {}
    await _checkPhone();
  }

  Future<void> _toggle(NotificationSetting setting, bool enabled) async {
    final before = _settings;
    setState(() => _settings = [
          for (final s in before ?? const <NotificationSetting>[]) s.type == setting.type ? s.copyWith(enabled: enabled) : s,
        ]);
    try {
      final saved = await (widget.update ?? _save)(setting.type, enabled);
      if (mounted) setState(() => _settings = saved);
    } catch (e) {
      if (!mounted) return;
      setState(() => _settings = before);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Couldn’t save that. ${userFacingError(e)}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = _settings;
    return Scaffold(
      backgroundColor: ChurchColors.background,
      appBar: AppBar(title: Text('Notifications', style: ChurchType.headline)),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
          children: [
            Text(
              'Choose what buzzes your phone. Anything you turn off still shows up in your inbox, just without the buzz.',
              style: ChurchType.label,
            ),
            const SizedBox(height: 20),
            if (!_phoneAllows) ...[
              _PhoneOffNotice(onTurnOn: _turnOnForPhone),
              const SizedBox(height: 20),
            ],
            if (settings == null && _error == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (settings == null)
              Column(
                children: [
                  Text(_error!, textAlign: TextAlign.center, style: ChurchType.body),
                  const SizedBox(height: 12),
                  TextButton(onPressed: _load, child: const Text('Try again')),
                ],
              )
            else
              // A Material, not a decorated box, so the switches' ripple shows.
              Material(
                color: ChurchColors.card,
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: ChurchRadius.lgAll,
                  side: BorderSide(color: ChurchColors.divider),
                ),
                child: Column(
                  children: [
                    for (final (i, s) in settings.indexed) ...[
                      if (i > 0) Divider(height: 1, indent: 16, endIndent: 16, color: ChurchColors.divider),
                      SwitchListTile(
                        value: s.enabled,
                        onChanged: (v) => _toggle(s, v),
                        activeThumbColor: ChurchColors.buttonText,
                        activeTrackColor: ChurchColors.button,
                        // Off has to read as off, not as nothing there.
                        inactiveThumbColor: ChurchColors.muted,
                        inactiveTrackColor: ChurchColors.background,
                        trackOutlineColor: WidgetStatePropertyAll(ChurchColors.muted.withValues(alpha: 0.6)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        title: Text(s.label, style: ChurchType.title.copyWith(fontSize: 16)),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(s.description, style: ChurchType.label),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PhoneOffNotice extends StatelessWidget {
  const _PhoneOffNotice({required this.onTurnOn});

  final VoidCallback onTurnOn;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: ChurchColors.cardDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.notifications_off_outlined, color: ChurchColors.accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Notifications are off on this phone', style: ChurchType.title.copyWith(fontSize: 16)),
                const SizedBox(height: 4),
                Text(
                  'Nothing below will buzz until they’re allowed in your phone’s settings.',
                  style: ChurchType.label,
                ),
                const SizedBox(height: 8),
                TextButton(onPressed: onTurnOn, child: const Text('Turn them on')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
