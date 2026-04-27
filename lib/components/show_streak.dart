import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/church_api.dart';
import '../theme/church_colors.dart';

/// Fetches `POST /auth/firebase` with the current id token, then shows [AttendanceSheet].
class AttendanceStatsLoader extends StatefulWidget {
  const AttendanceStatsLoader({super.key});

  @override
  State<AttendanceStatsLoader> createState() => _AttendanceStatsLoaderState();
}

class _AttendanceStatsLoaderState extends State<AttendanceStatsLoader> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _sheetData;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final u = FirebaseAuth.instance.currentUser;
      if (u == null) {
        throw StateError('Not signed in');
      }
      final token = await u.getIdToken();
      if (token == null || token.isEmpty) {
        throw StateError('No id token');
      }
      final prefs = await SharedPreferences.getInstance();
      final provider = prefs.getString('authProvider') ?? 'app';
      final account = await ChurchApi.refreshAccountWithFirebaseToken(
        token,
        provider: provider,
        name: u.displayName,
      );
      if (!mounted) return;
      setState(() {
        _sheetData = ChurchApi.accountToAttendanceSheetData(account);
        _loading = false;
      });
    } catch (e) {
      final cached = await ChurchApi.getCachedAccountJson();
      if (!mounted) return;
      if (cached != null) {
        setState(() {
          _sheetData = ChurchApi.accountToAttendanceSheetData(cached);
          _error = 'Using saved data. Could not refresh: $e';
          _loading = false;
        });
      } else {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
        decoration: const BoxDecoration(
          color: ChurchColors.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
    if (_error != null && _sheetData == null) {
      return Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        decoration: const BoxDecoration(
          color: ChurchColors.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Could not load stats',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: ChurchColors.bodyText,
              ),
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
              borderRadius: BorderRadius.circular(10),
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
          const Text(
            'Attendance stats',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: ChurchColors.accent,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatCircle(
                label: attendance['streakLabel'] as String? ?? 'Current streak',
                value: '$current',
                icon: Icons.local_fire_department,
                color: Colors.orange,
              ),
              _buildStatCircle(
                label: attendance['totalLabel'] as String? ?? 'Total attendances',
                value: '$total',
                icon: Icons.calendar_today,
                color: ChurchColors.button,
              ),
            ],
          ),
          const Divider(height: 40, thickness: 1, color: ChurchColors.divider),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ChurchColors.background,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: ChurchColors.divider),
            ),
            child: Row(
              children: [
                const Icon(Icons.emoji_events, color: ChurchColors.accent, size: 30),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        attendance['bestLabel'] as String? ?? 'Longest streak',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: ChurchColors.muted,
                        ),
                      ),
                      Text(
                        '$best',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: ChurchColors.bodyText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _miniStat('Total absences', '$absences'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _miniStat('Absence streak', '$absenceStreak'),
              ),
            ],
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        borderRadius: BorderRadius.circular(12),
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

  Widget _buildStatCircle({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: CircularProgressIndicator(
                value: 1.0,
                strokeWidth: 6,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                backgroundColor: color.withValues(alpha: 0.12),
              ),
            ),
            Icon(icon, color: color, size: 30),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: ChurchColors.bodyText,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 9,
            color: ChurchColors.muted,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}
