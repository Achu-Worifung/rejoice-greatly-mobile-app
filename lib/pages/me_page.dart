import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';

import '../main.dart' show navigatorKey;
import '../services/auth_service.dart';
import '../services/church_api.dart';
import '../theme/church_colors.dart';
import '../widgets/church_app_bar.dart';

class MePage extends StatefulWidget {
  const MePage({super.key});

  @override
  State<MePage> createState() => _MePageState();
}

class _MePageState extends State<MePage> {
  late Future<MePageLoadResult> _pageFuture;

  @override
  void initState() {
    super.initState();
    _pageFuture = ChurchApi.loadMePage();
  }

  void _reload({bool forceRefresh = false}) {
    setState(() {
      _pageFuture = ChurchApi.loadMePage(forceRefresh: forceRefresh);
    });
  }

  void _onBack() {
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
    } else {
      nav.pushReplacementNamed('/dashboard');
    }
  }

  static const Color _danger = Color(0xFFC62828);
  static const Color _dangerDark = Color(0xFF8E0000);

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          decoration: ChurchColors.cardDecoration(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: ChurchColors.button.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.power_settings_new_rounded,
                  color: ChurchColors.accent,
                  size: 28,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Leave this account?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: ChurchColors.accent,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'You will be signed out of Rejoice Greatly and the cafe tab. '
                'You must sign in again to check in or view your stats.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: ChurchColors.muted,
                  height: 1.45,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: FilledButton.styleFrom(
                    backgroundColor: ChurchColors.button,
                    foregroundColor: ChurchColors.buttonText,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Yes, log out',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ChurchColors.accent,
                    side: const BorderSide(color: ChurchColors.divider),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Stay signed in',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (confirm != true || !mounted) return;

    await AuthService().logout();
    if (!mounted) return;
    navigatorKey.currentState?.pushNamedAndRemoveUntil('/', (route) => false);
  }

  String _syncStatusText(MePageLoadResult? result) {
    if (result == null) return '';
    if (result.statsSynced) return 'Stats are loaded from your church attendance records.';
    final cachedAt = result.cachedAt;
    if (cachedAt != null) {
      final days = DateTime.now().difference(cachedAt).inDays;
      if (days == 0) return 'Showing data saved today. Pull down to refresh.';
      if (days == 1) return 'Showing data from yesterday. Pull down to refresh.';
      return 'Showing data from $days days ago. Pull down to refresh.';
    }
    return 'Showing saved stats — pull down to refresh from the server.';
  }

  int _i(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? 0;
  }

  List<_AttendanceActivity> _parseActivities(List<Map<String, dynamic>> raw) {
    final out = <_AttendanceActivity>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final m = Map<String, dynamic>.from(item);
      final dateStr = m['date']?.toString() ?? '';
      if (dateStr.isEmpty) continue;
      DateTime? dt = DateTime.tryParse(dateStr);
      if (dt == null && dateStr.length >= 10) {
        try {
          dt = DateFormat('yyyy-MM-dd').parse(dateStr.substring(0, 10));
        } catch (_) {}
      }
      if (dt == null) continue;
      final isPresent = m['present'] as bool? ?? true;
      out.add(_AttendanceActivity(date: dt, isPresent: isPresent));
    }
    out.sort((a, b) => b.date.compareTo(a.date));
    return out;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ChurchColors.background,
      appBar: ChurchAppBar.pageTitle(
        'My profile',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: ChurchColors.accent),
          onPressed: _onBack,
        ),
      ),
      body: FutureBuilder<MePageLoadResult>(
        future: _pageFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: ChurchColors.button),
            );
          }
          final result = snapshot.data;
          final profile = result?.profile;
          final syncError = result?.error;
          final signedIn =
              FirebaseAuth.instance.currentUser != null || profile != null;
          if (profile == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person_off_outlined, size: 48, color: ChurchColors.muted),
                    const SizedBox(height: 12),
                    Text(
                      signedIn ? 'Could not load your church account' : 'No account connected',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: ChurchColors.bodyText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      signedIn
                          ? 'You are signed in, but we could not reach the church server. Check your connection and try again.'
                          : 'Sign in to connect your profile and see attendance stats.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: ChurchColors.muted, fontSize: 14),
                    ),
                    const SizedBox(height: 20),
                    if (signedIn)
                      FilledButton(
                        onPressed: () => _reload(forceRefresh: true),
                        style: FilledButton.styleFrom(
                          backgroundColor: ChurchColors.button,
                          foregroundColor: ChurchColors.buttonText,
                        ),
                        child: const Text('Try again'),
                      ),
                    if (signedIn) const SizedBox(height: 10),
                    FilledButton(
                      onPressed: _onBack,
                      style: FilledButton.styleFrom(
                        backgroundColor: signedIn
                            ? ChurchColors.card
                            : ChurchColors.button,
                        foregroundColor: signedIn
                            ? ChurchColors.bodyText
                            : ChurchColors.buttonText,
                      ),
                      child: const Text('Back to app'),
                    ),
                  ],
                ),
              ),
            );
          }

          final name = profile['name'] as String? ?? 'Member';
          final email = profile['email'] as String? ?? '';
          final churchSubtitle = dotenv.env['CHURCH_SUBTITLE'] ?? 'Rejoice Greatly - PHX';
          final hasProfile = result?.hasProfile ?? false;
          final stats = result?.stats;
          final profileSynced = result?.profileSynced ?? false;

          return RefreshIndicator(
            color: ChurchColors.button,
            onRefresh: () async {
              _reload(forceRefresh: true);
              await _pageFuture;
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                _ProfileHeader(
                  name: name,
                  email: email,
                  churchLine: churchSubtitle,
                  account: profile,
                ),
                if (!profileSynced && syncError != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: ChurchColors.button.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: ChurchColors.divider),
                    ),
                    child: Text(
                      'Could not refresh profile. Pull down to retry.\n$syncError',
                      style: const TextStyle(fontSize: 12, color: ChurchColors.muted, height: 1.35),
                    ),
                  ),
                ],
                if (!hasProfile) ...[
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: ChurchColors.button.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: ChurchColors.divider),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Complete your profile',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: ChurchColors.bodyText,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Add a profile photo to unlock attendance stats and your check-in history.',
                          style: TextStyle(fontSize: 13, color: ChurchColors.muted, height: 1.4),
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: () => Navigator.pushNamed(context, '/complete-signup'),
                          style: FilledButton.styleFrom(
                            backgroundColor: ChurchColors.button,
                            foregroundColor: ChurchColors.buttonText,
                          ),
                          child: const Text('Finish signup'),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  if (syncError != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: ChurchColors.button.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: ChurchColors.divider),
                      ),
                      child: Text(
                        'Some data could not refresh. Pull down to try again.\n$syncError',
                        style: const TextStyle(fontSize: 12, color: ChurchColors.muted, height: 1.35),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Text(
                    'ATTENDANCE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: ChurchColors.accent,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (stats != null)
                    _StatGrid(
                      currentStreak: _i(stats['currentStreak']),
                      longestStreak: _i(stats['longestStreak']),
                      totalAttendance: _i(stats['totalAttendance']),
                      totalAbsences: _i(stats['totalAbsences']),
                      absenceStreak: _i(stats['absenceStreak']),
                    )
                  else
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Stats unavailable. Pull down to refresh.',
                        style: TextStyle(color: ChurchColors.muted, fontSize: 13),
                      ),
                    ),
                  const SizedBox(height: 28),
                  Text(
                    _syncStatusText(result),
                    style: TextStyle(
                      fontSize: 12,
                      color: ChurchColors.muted.withValues(alpha: 0.9),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'ACTIVITY',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: ChurchColors.accent,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _AttendanceActivityList(
                    activities: _parseActivities(result?.activities ?? []),
                  ),
                ],
                const SizedBox(height: 36),
                const Divider(color: ChurchColors.divider, height: 1),
                const SizedBox(height: 20),
                Text(
                  'SESSION',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: _danger.withValues(alpha: 0.85),
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 10),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _logout,
                    borderRadius: BorderRadius.circular(14),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_danger, _dangerDark],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: _danger.withValues(alpha: 0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Container(
                        width: double.infinity,
                        height: 56,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.power_settings_new_rounded,
                              color: Colors.white.withValues(alpha: 0.95),
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Log out of account',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.98),
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ends your session on this device immediately.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: _danger.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.name,
    required this.email,
    required this.churchLine,
    this.account,
  });

  final String name;
  final String email;
  final String churchLine;
  final Map<String, dynamic>? account;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: ChurchApi.resolveProfileImageUrl(account: account),
      builder: (context, snap) {
        final url = snap.data;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: ChurchColors.cardDecoration(),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: url != null && url.isNotEmpty
                      ? Image.network(
                          url,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => _placeholder(),
                        )
                      : _placeholder(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: ChurchColors.bodyText,
                      ),
                    ),
                    if (email.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, color: ChurchColors.muted),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      churchLine,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: ChurchColors.accent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget _placeholder() {
    return Container(
      color: ChurchColors.button.withValues(alpha: 0.1),
      child: const Icon(Icons.person, size: 40, color: ChurchColors.accent),
    );
  }
}

class _AttendanceActivity {
  const _AttendanceActivity({required this.date, required this.isPresent});

  final DateTime date;
  final bool isPresent;
}

class _AttendanceActivityList extends StatelessWidget {
  const _AttendanceActivityList({required this.activities});

  final List<_AttendanceActivity> activities;

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: ChurchColors.cardDecoration(shadow: const []),
        child: const Text(
          'No services recorded yet. Your attendance history will appear here once services begin.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: ChurchColors.muted, height: 1.4),
        ),
      );
    }

    final dateFmt = DateFormat('EEEE, MMM d, yyyy');

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 340),
      child: SingleChildScrollView(
        child: Column(
          children: [
            for (var i = 0; i < activities.length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              _ActivityRow(activity: activities[i], dateFmt: dateFmt),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.activity, required this.dateFmt});

  final _AttendanceActivity activity;
  final DateFormat dateFmt;

  @override
  Widget build(BuildContext context) {
    final isPresent = activity.isPresent;
    final iconColor = isPresent ? ChurchColors.button : const Color(0xFFC62828);
    final bgColor = isPresent
        ? ChurchColors.button.withValues(alpha: 0.12)
        : const Color(0xFFC62828).withValues(alpha: 0.08);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: ChurchColors.cardDecoration(shadow: const []),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isPresent ? Icons.check_circle_outline : Icons.cancel_outlined,
              color: iconColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPresent ? 'Marked present' : 'Absent',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isPresent ? ChurchColors.bodyText : const Color(0xFFC62828),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dateFmt.format(activity.date),
                  style: const TextStyle(fontSize: 12, color: ChurchColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({
    required this.currentStreak,
    required this.longestStreak,
    required this.totalAttendance,
    required this.totalAbsences,
    required this.absenceStreak,
  });

  final int currentStreak;
  final int longestStreak;
  final int totalAttendance;
  final int totalAbsences;
  final int absenceStreak;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatTile(
                label: 'Current streak',
                value: '$currentStreak',
                icon: Icons.local_fire_department,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatTile(
                label: 'Longest streak',
                value: '$longestStreak',
                icon: Icons.emoji_events_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                label: 'Total attendances',
                value: '$totalAttendance',
                icon: Icons.check_circle_outline,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatTile(
                label: 'Total absences',
                value: '$totalAbsences',
                icon: Icons.remove_circle_outline,
              ),
            ),
          ],
        ),
        
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    this.fullWidth = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: ChurchColors.cardDecoration(
        shadow: const [],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: ChurchColors.button.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: ChurchColors.button, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    text: label.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: ChurchColors.muted,
                    ),
                  ),
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: ChurchColors.muted,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: ChurchColors.bodyText,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
