import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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
  late Future<ProfileLoadResult> _accountFuture;

  @override
  void initState() {
    super.initState();
    _accountFuture = _loadAccount();
  }

  Future<ProfileLoadResult> _loadAccount() => ChurchApi.loadProfileAccount();

  void _onBack() {
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
    } else {
      nav.pushReplacementNamed('/dashboard');
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text(
          'You will need to sign in again to use the app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Log out',
              style: TextStyle(color: ChurchColors.button),
            ),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    await AuthService().logout();
    if (!mounted) return;
    navigatorKey.currentState?.pushNamedAndRemoveUntil('/', (route) => false);
  }

  int _i(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? 0;
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
      body: FutureBuilder<ProfileLoadResult>(
        future: _accountFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: ChurchColors.button),
            );
          }
          final result = snapshot.data;
          final a = result?.account;
          final synced = result?.syncedFromServer ?? false;
          final syncError = result?.error;
          final signedIn =
              FirebaseAuth.instance.currentUser != null || (a != null && synced);
          if (a == null) {
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
                        onPressed: () {
                          setState(() {
                            _accountFuture = _loadAccount();
                          });
                        },
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

          final name = a['name'] as String? ?? 'Member';
          final email = a['email'] as String? ?? '';
          final churchSubtitle = dotenv.env['CHURCH_SUBTITLE'] ?? 'Rejoice Greatly - PHX';

          return RefreshIndicator(
            color: ChurchColors.button,
            onRefresh: () async {
              setState(() {
                _accountFuture = _loadAccount();
              });
              await _accountFuture;
              if (!context.mounted) return;
              setState(() {});
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                _ProfileHeader(
                  name: name,
                  email: email,
                  churchLine: churchSubtitle,
                ),
                if (!synced && syncError != null) ...[
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
                      'Could not refresh from server. Pull down to retry.\n$syncError',
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
                _StatGrid(
                  currentStreak: _i(a['currentStreak']),
                  longestStreak: _i(a['longestStreak']),
                  totalAttendance: _i(a['totalAttendance']),
                  totalAbsences: _i(a['totalAbsences']),
                  absenceStreak: _i(a['absenceStreak']),
                ),
                const SizedBox(height: 28),
                Text(
                  'Streaks reflect Sundays recorded in your church’s system.',
                  style: TextStyle(
                    fontSize: 12,
                    color: ChurchColors.muted.withValues(alpha: 0.9),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout_rounded, size: 20),
                    label: const Text('Log out'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ChurchColors.bodyText,
                      side: const BorderSide(color: ChurchColors.divider),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
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
  });

  final String name;
  final String email;
  final String churchLine;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _avatarUrl(),
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

  static Future<String?> _avatarUrl() => ChurchApi.resolveProfileImageUrl();

  static Widget _placeholder() {
    return Container(
      color: ChurchColors.button.withValues(alpha: 0.1),
      child: const Icon(Icons.person, size: 40, color: ChurchColors.accent),
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
        const SizedBox(height: 12),
        _StatTile(
          label: 'Current absence streak',
          value: '$absenceStreak',
          icon: Icons.trending_down,
          fullWidth: true,
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
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: ChurchColors.muted,
                    letterSpacing: 0.5,
                  ),
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
