import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/leader_api.dart';
import '../services/user_facing_error.dart';
import '../theme/church_colors.dart';
import '../theme/church_type.dart';
import '../widgets/church_buttons.dart';
import '../widgets/dashboard_label_title.dart';

Future<void> openLeaderBacenta(BuildContext context, LedBacenta bacenta) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => LeaderBacentaPage(bacentaId: bacenta.id, title: bacenta.name)),
  );
}

/// A leader's bacenta, from their phone: take attendance, see who to check
/// in with, message the group, and add someone who isn't on the app.
class LeaderBacentaPage extends StatefulWidget {
  const LeaderBacentaPage({super.key, required this.bacentaId, required this.title});

  final String bacentaId;
  final String title;

  @override
  State<LeaderBacentaPage> createState() => _LeaderBacentaPageState();
}

class _LeaderBacentaPageState extends State<LeaderBacentaPage> {
  LeaderView? _view;
  String? _error;
  Set<String> _present = {};
  bool _saving = false;
  final _message = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      _show(await LeaderApi.view(widget.bacentaId));
    } catch (e) {
      if (mounted) setState(() => _error = userFacingError(e));
    }
  }

  void _show(LeaderView view) {
    if (!mounted) return;
    setState(() {
      _view = view;
      _error = null;
      _present = {...?view.meeting?.present};
    });
  }

  void _snack(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _save({bool cancelled = false}) async {
    final meeting = _view?.meeting;
    if (meeting == null) return;
    setState(() => _saving = true);
    try {
      _show(await LeaderApi.takeAttendance(widget.bacentaId, meeting.date, cancelled ? {} : _present,
          cancelled: cancelled));
      _snack(cancelled ? 'Marked as not meeting.' : 'Attendance saved. ${_present.length} present.');
    } catch (e) {
      _snack(userFacingError(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _addPerson() async {
    final name = await _ask(
      title: 'Add someone who isn’t on the app',
      hint: 'Their name',
      action: 'Add',
      caption: 'They’ll be in your bacenta, so you can mark them present. When they sign up, the church joins the two.',
    );
    if (name == null || name.trim().isEmpty) return;
    try {
      _show(await LeaderApi.addPerson(widget.bacentaId, name.trim()));
      _snack('${name.trim()} is in your bacenta.');
    } catch (e) {
      _snack(userFacingError(e));
    }
  }

  Future<void> _checkIn(FollowUpPerson person) async {
    final note = await _ask(
      title: 'Checked in with ${person.name.split(' ').first}',
      hint: 'A note for yourself and the pastors (optional)',
      action: 'Save',
      allowEmpty: true,
    );
    if (note == null) return;
    try {
      await LeaderApi.checkIn(person.id, note.trim().isEmpty ? null : note.trim());
      await _load();
    } catch (e) {
      _snack(userFacingError(e));
    }
  }

  Future<void> _send() async {
    final text = _message.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    try {
      final count = await LeaderApi.message(widget.bacentaId, text);
      _message.clear();
      _snack(count == 1 ? 'Sent to 1 person.' : 'Sent to $count people.');
      await _load();
    } catch (e) {
      _snack(userFacingError(e));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<String?> _ask({
    required String title,
    required String hint,
    required String action,
    String? caption,
    bool allowEmpty = false,
  }) {
    final controller = TextEditingController();
    return showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: ChurchColors.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(ChurchRadius.lg))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: ChurchType.headline),
              if (caption != null) ...[
                const SizedBox(height: 6),
                Text(caption, style: ChurchType.label),
              ],
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                maxLines: allowEmpty ? 3 : 1,
                decoration: InputDecoration(hintText: hint),
              ),
              const SizedBox(height: 16),
              ChurchPrimaryButton(label: action, onPressed: () => Navigator.pop(ctx, controller.text)),
            ],
          ),
        ),
      ),
    ).whenComplete(controller.dispose);
  }

  @override
  Widget build(BuildContext context) {
    final view = _view;
    return Scaffold(
      backgroundColor: ChurchColors.background,
      appBar: AppBar(title: Text(view?.name ?? widget.title, style: ChurchType.headline)),
      body: view == null
          ? Center(
              child: _error == null
                  ? const CircularProgressIndicator()
                  : Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Text(_error!, textAlign: TextAlign.center, style: ChurchType.body),
                        const SizedBox(height: 12),
                        TextButton(onPressed: _load, child: const Text('Try again')),
                      ]),
                    ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                children: [
                  if (view.meetingDay != null)
                    Text(
                      [
                        '${view.meetingDay}s',
                        ?view.meetingTime,
                        if (view.location != null && view.location!.isNotEmpty) view.location!,
                      ].join(' · '),
                      style: ChurchType.label,
                    ),
                  const SizedBox(height: 20),
                  ..._attendance(view),
                  const SizedBox(height: 28),
                  ..._followUps(view),
                  const SizedBox(height: 28),
                  ..._messageGroup(view),
                ],
              ),
            ),
    );
  }

  List<Widget> _attendance(LeaderView view) {
    final meeting = view.meeting;
    final widgets = <Widget>[const DashboardLabelText(label: 'Attendance')];
    if (meeting == null) {
      return [
        ...widgets,
        Text('Your bacenta has no meeting day yet. Ask a pastor to set one, then you can take attendance here.',
            style: ChurchType.body),
      ];
    }
    final today = DateUtils.dateOnly(DateTime.now());
    final date = DateUtils.dateOnly(meeting.date);
    final when = date == today
        ? 'Tonight'
        : date.isAfter(today)
            ? 'Next: ${DateFormat('EEEE, MMM d').format(date)}'
            : DateFormat('EEEE, MMM d').format(date);
    widgets.add(Text('$when${meeting.time != null ? ' · ${meeting.time}' : ''}',
        style: ChurchType.title));
    widgets.add(const SizedBox(height: 4));

    // A meeting stays open once it has happened, so the only one that can't be
    // taken yet is a future one. (A server from before that could still say a
    // past meeting is closed; the last branch covers it.)
    if (!meeting.recordable) {
      widgets.add(Text(
        date.isAfter(today)
            ? 'You can take attendance on the day.'
            : meeting.recorded
                ? (meeting.cancelled ? 'Recorded as not meeting.' : '${meeting.present.length} were there.')
                : 'Attendance for this meeting can’t be changed here right now.',
        style: ChurchType.label,
      ));
      return widgets;
    }

    widgets.add(Text(
      meeting.cancelled
          ? 'Recorded as not meeting. Tick who came to change that.'
          : 'Tick who was there. You can come back and change it any time.',
      style: ChurchType.label,
    ));
    widgets.add(const SizedBox(height: 8));
    for (final m in view.members) {
      widgets.add(CheckboxListTile(
        value: _present.contains(m.id),
        onChanged: (v) => setState(() => v == true ? _present.add(m.id) : _present.remove(m.id)),
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
        activeColor: ChurchColors.button,
        title: Text(m.name, style: ChurchType.body),
        subtitle: m.onApp ? null : Text('Not on the app', style: ChurchType.caption),
      ));
    }
    widgets.addAll([
      TextButton.icon(
        onPressed: _addPerson,
        icon: const Icon(Icons.person_add_alt_1_outlined),
        label: const Text('Add someone who isn’t on the app'),
      ),
      const SizedBox(height: 8),
      ChurchPrimaryButton(
        label: 'Save attendance · ${_present.length} here',
        loading: _saving,
        onPressed: () => _save(),
      ),
      const SizedBox(height: 4),
      TextButton(
        onPressed: _saving ? null : () => _save(cancelled: true),
        child: const Text('We didn’t meet this time'),
      ),
    ]);
    return widgets;
  }

  List<Widget> _followUps(LeaderView view) {
    final waiting = view.followUps.where((p) => !p.checked).length;
    return [
      const DashboardLabelText(label: 'Who to check in with'),
      if (view.followUps.isEmpty)
        Text('Everyone’s been around lately.', style: ChurchType.label)
      else ...[
        Text(
          waiting == 0
              ? 'You’ve checked in with everyone who’s been away.'
              : 'They’ve missed a few Sundays. A message or a call goes a long way.',
          style: ChurchType.label,
        ),
        const SizedBox(height: 8),
        for (final p in view.followUps)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
            decoration: ChurchColors.cardDecoration(shadow: const []),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.name, style: ChurchType.bodyStrong.copyWith(fontSize: 15)),
                      Text(
                        [
                          'Missed ${p.weeksMissed} Sunday${p.weeksMissed == 1 ? '' : 's'}',
                          if (p.lastAttended != null) 'last came ${DateFormat('MMM d').format(p.lastAttended!)}',
                        ].join(' · '),
                        style: ChurchType.caption,
                      ),
                      if (p.checked)
                        Text(
                          'Checked in${p.checkedBy != null ? ' by ${p.checkedBy}' : ''}'
                          '${p.note != null ? ': ${p.note}' : ''}',
                          style: ChurchType.caption.copyWith(color: ChurchColors.accent),
                        ),
                    ],
                  ),
                ),
                TextButton(onPressed: () => _checkIn(p), child: Text(p.checked ? 'Again' : 'Checked in')),
              ],
            ),
          ),
      ],
    ];
  }

  List<Widget> _messageGroup(LeaderView view) {
    return [
      const DashboardLabelText(label: 'Message the group'),
      TextField(
        controller: _message,
        minLines: 2,
        maxLines: 5,
        maxLength: 500,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(hintText: 'e.g. Bring a friend on Tuesday!'),
      ),
      ChurchSecondaryButton(
        label: _sending ? 'Sending…' : 'Send to everyone in ${view.name}',
        icon: Icons.send_rounded,
        onPressed: _sending ? null : _send,
      ),
      if (view.messages.isNotEmpty) ...[
        const SizedBox(height: 16),
        for (final m in view.messages)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(m.body, style: ChurchType.body),
                Text('Sent to ${m.recipients} · ${DateFormat('EEE, MMM d · h:mm a').format(m.sentAt)}',
                    style: ChurchType.caption),
              ],
            ),
          ),
      ],
    ];
  }
}
