import 'dart:async';

import 'package:flutter/material.dart';

import '../services/nfc_checkin_service.dart';
import '../theme/church_colors.dart';
import 'church_buttons.dart';

/// Admin-only tag provisioning: writes a chosen tag id onto a blank NFC tag as
/// an NDEF Text record so members can later check in by tapping it.
///
/// Opens as a bottom sheet from the admin attendance screen.
Future<void> showNfcWriteTagSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: ChurchColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: const _NfcWriteTagSheet(),
    ),
  );
}

class _NfcWriteTagSheet extends StatefulWidget {
  const _NfcWriteTagSheet();

  @override
  State<_NfcWriteTagSheet> createState() => _NfcWriteTagSheetState();
}

class _NfcWriteTagSheetState extends State<_NfcWriteTagSheet> {
  final TextEditingController _controller = TextEditingController();
  bool _busy = false;
  String? _status;
  bool _isError = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _write() async {
    final tagId = _controller.text.trim();
    if (tagId.isEmpty) {
      setState(() {
        _status = 'Enter a tag id first (e.g. "entrance-a3").';
        _isError = true;
      });
      return;
    }

    setState(() {
      _busy = true;
      _status = 'Hold a blank tag against the phone…';
      _isError = false;
    });

    try {
      await NfcCheckinService.writeTag(tagId);
      if (!mounted) return;
      setState(() {
        _status = 'Wrote "$tagId" to the tag.';
        _isError = false;
      });
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _status = 'No tag detected. Try again and hold the tag steady.';
        _isError = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = 'Could not write the tag. Make sure it is blank and writable.';
        _isError = true;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: ChurchColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Provision an NFC tag',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: ChurchColors.bodyText,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Write a tag id onto a blank tag. Members tap it to check in. The id '
            'must match one registered in the admin console.',
            style: TextStyle(
              fontSize: 13,
              color: ChurchColors.muted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            enabled: !_busy,
            autocorrect: false,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _write(),
            decoration: InputDecoration(
              labelText: 'Tag id',
              hintText: 'entrance-a3',
              filled: true,
              fillColor: ChurchColors.card,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: ChurchColors.divider),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: ChurchColors.divider),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: ChurchColors.accent),
              ),
            ),
          ),
          if (_status != null) ...[
            const SizedBox(height: 12),
            Text(
              _status!,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _isError
                    ? const Color(0xFFB3261E)
                    : const Color(0xFF1B5E20),
              ),
            ),
          ],
          const SizedBox(height: 20),
          ChurchPrimaryButton(
            label: 'Write to tag',
            icon: Icons.nfc_rounded,
            loading: _busy,
            onPressed: _write,
          ),
        ],
      ),
    );
  }
}
