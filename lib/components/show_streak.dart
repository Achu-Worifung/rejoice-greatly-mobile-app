import 'package:flutter/material.dart';

import '../services/church_api.dart';
import '../theme/church_colors.dart';
import '../theme/church_type.dart';

/// Loads `POST /member/stats` and shows [AttendanceSheet].
class AttendanceStatsLoader extends StatefulWidget {
  const AttendanceStatsLoader({super.key});

  @override
  State<AttendanceStatsLoader> createState() => _AttendanceStatsLoaderState();
}

class _AttendanceStatsLoaderState extends State<AttendanceStatsLoader> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _sheetData;
  bool _profileIncomplete = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _profileIncomplete = false;
    });

    try {
      final profileResult = await ChurchApi.loadMemberProfile();
      if (!ChurchApi.hasMemberProfile(profileResult.profile)) {
        if (!mounted) return;
        setState(() {
          _profileIncomplete = true;
          _loading = false;
        });
        return;
      }

      final statsResult = await ChurchApi.loadMemberStats();
      if (!mounted) return;

      final stats = statsResult.stats;
      if (stats == null) {
        setState(() {
          _error = statsResult.error ?? 'Could not load attendance stats';
          _loading = false;
        });
        return;
      }

      setState(() {
        _sheetData = ChurchApi.statsToAttendanceSheetData(stats);
        _error = statsResult.syncedFromServer ? null : statsResult.error;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
        decoration: const BoxDecoration(
          color: ChurchColors.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(ChurchRadius.lg)),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 8),
            CircularProgressIndicator(color: ChurchColors.button),
            SizedBox(height: 20),
            Text('Loading your stats…', style: TextStyle(color: ChurchColors.muted)),
          ],
        ),
      );
    }

    if (_profileIncomplete) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        decoration: const BoxDecoration(
          color: ChurchColors.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(ChurchRadius.lg)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Complete your profile',
              style: ChurchType.headline,
            ),
            const SizedBox(height: 8),
            const Text(
              'Finish signup with a profile photo before attendance stats are available.',
              textAlign: TextAlign.center,
              style: TextStyle(color: ChurchColors.muted, fontSize: 13),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(
                backgroundColor: ChurchColors.button,
                foregroundColor: ChurchColors.buttonText,
              ),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }

    if (_error != null && _sheetData == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        decoration: const BoxDecoration(
          color: ChurchColors.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(ChurchRadius.lg)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Could not load stats',
              style: ChurchType.headline,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: ChurchColors.muted, fontSize: 13),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _load,
              style: FilledButton.styleFrom(
                backgroundColor: ChurchColors.button,
                foregroundColor: ChurchColors.buttonText,
              ),
              child: const Text('Try again'),
            ),
          ],
        ),
      );
    }

    return AttendanceSheet(
      data: _sheetData!,
      bannerMessage: _error,
    );
  }
}

class AttendanceSheet extends StatelessWidget {
  const AttendanceSheet({
    super.key,
    required this.data,
    this.bannerMessage,
  });

  final Map<String, dynamic> data;
  final String? bannerMessage;

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> attendance = Map<String, dynamic>.from(
      data['attendanceStreak'] as Map? ?? <String, dynamic>{},
    );

    int n(String key) {
      final v = attendance[key];
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse('$v') ?? 0;
    }

    final current = n('currentStreak');
    final total = n('totalAttendance');
    final best = n('bestStreak');
    final absences = n('absences');
    final absenceStreak = n('absenceStreak');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
      decoration: const BoxDecoration(
        color: ChurchColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: ChurchColors.divider,
              borderRadius: ChurchRadius.mdAll,
            ),
          ),
          const SizedBox(height: 20),
          if (bannerMessage != null) ...[
            Text(
              bannerMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: ChurchColors.muted),
            ),
            const SizedBox(height: 12),
          ],
          const Text('Attendance stats', style: ChurchType.headline),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _RegisterStat(
                  label: attendance['streakLabel'] as String? ?? 'Current streak',
                  value: '$current',
                  accent: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _RegisterStat(
                  label: attendance['totalLabel'] as String? ?? 'Total attendances',
                  value: '$total',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _RegisterStat(
            label: attendance['bestLabel'] as String? ?? 'Longest streak',
            value: '$best',
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(
                backgroundColor: ChurchColors.button,
                foregroundColor: ChurchColors.buttonText,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: ChurchRadius.mdAll),
              ),
              child: const Text('Close'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: ChurchColors.background,
        borderRadius: ChurchRadius.mdAll,
        border: Border.all(color: ChurchColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: ChurchColors.muted,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: ChurchColors.bodyText,
            ),
          ),
        ],
      ),
    );
  }
}

/// A register stat: a mono label over a large mono tabular number. The focal
/// stat takes the accent as its ink; the rest stay in ink.
class _RegisterStat extends StatelessWidget {
  const _RegisterStat({
    required this.label,
    required this.value,
    this.accent = false,
  });

  final String label;
  final String value;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: ChurchColors.background,
        borderRadius: ChurchRadius.lgAll,
        border: Border.all(color: ChurchColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ChurchEyebrow(label),
          const SizedBox(height: 6),
          Text(
            value,
            style: accent
                ? ChurchType.data.copyWith(color: ChurchColors.accent)
                : ChurchType.data,
          ),
        ],
      ),
    );
  }
}
