import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/household_api.dart';
import '../services/user_facing_error.dart';
import '../theme/church_colors.dart';
import '../theme/church_type.dart';
import 'church_buttons.dart';
import 'dashboard_label_title.dart';
import 'member_avatar.dart';

/// "Your children" on the profile: the children a parent brings, who they
/// can check in alongside themselves when they tap in at the door.
class HouseholdSection extends StatefulWidget {
  const HouseholdSection({super.key});

  @override
  State<HouseholdSection> createState() => _HouseholdSectionState();
}

class _HouseholdSectionState extends State<HouseholdSection> {
  List<HouseholdChild>? _children;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final children = await HouseholdApi.children();
      if (mounted) {
        setState(() {
          _children = children;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = userFacingError(e));
    }
  }

  Future<void> _add() async {
    final added = await showModalBottomSheet<HouseholdChild>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: ChurchColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(ChurchRadius.lg)),
      ),
      builder: (_) => const _AddChildSheet(),
    );
    if (added != null && mounted) {
      setState(() => _children = [...?_children, added]..sort((a, b) => a.name.compareTo(b.name)));
    }
  }

  Future<void> _remove(HouseholdChild child) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ChurchColors.card,
        title: Text('Remove ${child.firstName}?', style: ChurchType.title),
        content: Text(
          'You won’t be able to check them in from your phone. Their attendance so far is kept.',
          style: ChurchType.body,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Remove')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await HouseholdApi.removeChild(child.id);
      if (mounted) setState(() => _children = _children?.where((c) => c.id != child.id).toList());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(userFacingError(e))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final children = _children;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const DashboardLabelText(label: 'Your children'),
        if (children == null && _error == null)
          const SizedBox(height: 48, child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
        else if (children == null)
          Row(
            children: [
              Expanded(child: Text('Couldn’t load your children.', style: ChurchType.label)),
              TextButton(onPressed: _load, child: const Text('Try again')),
            ],
          )
        else ...[
          if (children.isEmpty)
            Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                'Bring children to church? Add them here, and you can check them in when you tap in at the door.',
                style: ChurchType.label,
              ),
            ),
          for (final child in children)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                decoration: ChurchColors.cardDecoration(shadow: const []),
                padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
                child: Row(
                  children: [
                    MemberAvatar(name: child.name, size: 36, radius: 18),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(child.name, style: ChurchType.bodyStrong.copyWith(fontSize: 15)),
                          Text(
                            child.presentToday ? 'Checked in today' : 'Checked in when you tap in',
                            style: ChurchType.caption,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Remove ${child.firstName}',
                      icon: Icon(Icons.close_rounded, color: ChurchColors.muted),
                      onPressed: () => _remove(child),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 4),
          ChurchSecondaryButton(label: 'Add a child', icon: Icons.add_rounded, onPressed: _add),
        ],
      ],
    );
  }
}

class _AddChildSheet extends StatefulWidget {
  const _AddChildSheet();

  @override
  State<_AddChildSheet> createState() => _AddChildSheetState();
}

class _AddChildSheetState extends State<_AddChildSheet> {
  final _name = TextEditingController();
  DateTime? _birthday;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pickBirthday() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthday ?? DateTime(now.year - 5, now.month, now.day),
      firstDate: DateTime(now.year - 18, now.month, now.day + 1),
      lastDate: now,
      helpText: 'Their date of birth',
    );
    if (picked != null) setState(() => _birthday = picked);
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty || _birthday == null) {
      setState(() => _error = name.isEmpty ? 'Enter their name.' : 'Choose their date of birth.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final child = await HouseholdApi.addChild(name, _birthday!);
      if (mounted) Navigator.pop(context, child);
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = userFacingError(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Add a child', style: ChurchType.headline),
            const SizedBox(height: 6),
            Text(
              'For children under 18 who come with you. Only you and the church team see this.',
              style: ChurchType.label,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              style: ChurchType.body,
              decoration: const InputDecoration(labelText: 'Their name'),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickBirthday,
              icon: const Icon(Icons.cake_outlined),
              label: Text(_birthday == null ? 'Date of birth' : DateFormat('d MMMM y').format(_birthday!)),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: ChurchType.label.copyWith(color: ChurchColors.accent)),
            ],
            const SizedBox(height: 20),
            ChurchPrimaryButton(label: 'Add', loading: _saving, onPressed: _save),
          ],
        ),
      ),
    );
  }
}
