import 'package:flutter/material.dart';

import '../services/church_api.dart';
import '../services/user_facing_error.dart';
import '../theme/church_colors.dart';
import '../theme/church_type.dart';
import '../widgets/church_buttons.dart';

/// "I'm new here": a first-time visitor says hello without making an
/// account. The church team sees it and, if asked, reaches out.
class VisitorHelloPage extends StatefulWidget {
  const VisitorHelloPage({super.key});

  @override
  State<VisitorHelloPage> createState() => _VisitorHelloPageState();
}

class _VisitorHelloPageState extends State<VisitorHelloPage> {
  static const _howHeard = [
    'A friend or family member',
    'Social media',
    'Walked or drove past',
    'Searched online',
    'Something else',
  ];

  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _note = TextEditingController();
  String? _heard;
  bool _wantsContact = true;
  bool _sending = false;
  bool _done = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_name, _phone, _email, _note]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _send() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Please tell us your name.');
      return;
    }
    if (_wantsContact && _phone.text.trim().isEmpty && _email.text.trim().isEmpty) {
      setState(() => _error = 'Leave a phone number or email so we can reach you, or untick the box below.');
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await ChurchApi.postJson('/visitors', {
        'name': name,
        'phone': _phone.text.trim(),
        'email': _email.text.trim(),
        'howHeard': _heard,
        'note': _note.text.trim(),
        'wantsContact': _wantsContact,
        'source': 'APP',
      });
      if (mounted) setState(() => _done = true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _sending = false;
          _error = userFacingError(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ChurchColors.background,
      appBar: AppBar(title: Text('Welcome', style: ChurchType.headline)),
      body: SafeArea(
        child: _done ? _thanks() : _form(),
      ),
    );
  }

  Widget _thanks() {
    final first = _name.text.trim().split(RegExp(r'\s+')).first;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.favorite_outline_rounded, size: 44, color: ChurchColors.accent),
            const SizedBox(height: 16),
            Text('Thank you, $first!', style: ChurchType.display, textAlign: TextAlign.center),
            const SizedBox(height: 10),
            Text(
              _wantsContact
                  ? 'We’re so glad you came. Someone from the church will be in touch this week.'
                  : 'We’re so glad you came, and hope to see you again soon.',
              style: ChurchType.body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ChurchSecondaryButton(label: 'Done', onPressed: () => Navigator.of(context).maybePop()),
          ],
        ),
      ),
    );
  }

  Widget _form() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        Text('We’re glad you’re here', style: ChurchType.display.copyWith(fontSize: 26)),
        const SizedBox(height: 8),
        Text(
          'First time with us? Say hello, and we’ll make sure you’re looked after. No account needed.',
          style: ChurchType.body.copyWith(color: ChurchColors.muted),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _name,
          textCapitalization: TextCapitalization.words,
          autofillHints: const [AutofillHints.name],
          decoration: const InputDecoration(labelText: 'Your name'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _phone,
          keyboardType: TextInputType.phone,
          autofillHints: const [AutofillHints.telephoneNumber],
          decoration: const InputDecoration(labelText: 'Phone'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          decoration: const InputDecoration(labelText: 'Email'),
        ),
        const SizedBox(height: 20),
        Text('How did you hear about us?', style: ChurchType.bodyStrong.copyWith(fontSize: 15)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final option in _howHeard)
              ChoiceChip(
                label: Text(option),
                selected: _heard == option,
                onSelected: (on) => setState(() => _heard = on ? option : null),
              ),
          ],
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _note,
          minLines: 3,
          maxLines: 6,
          maxLength: 1000,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'Anything you’d like us to know, or pray about?'),
        ),
        CheckboxListTile(
          value: _wantsContact,
          onChanged: (v) => setState(() => _wantsContact = v ?? false),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: ChurchColors.button,
          title: Text('I’d like someone from the church to reach out', style: ChurchType.body),
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: ChurchType.label.copyWith(color: ChurchColors.danger)),
        ],
        const SizedBox(height: 16),
        ChurchPrimaryButton(label: 'Say hello', loading: _sending, onPressed: _send),
        const SizedBox(height: 10),
        Text(
          'Only our church team sees this. We’ll never share it.',
          style: ChurchType.caption,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
