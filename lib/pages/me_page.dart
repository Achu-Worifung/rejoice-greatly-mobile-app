import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../main.dart' show navigatorKey;
import '../services/auth_service.dart';
import '../services/church_api.dart';
import '../services/profile_picture_upload.dart';
import '../theme/church_colors.dart';
import '../widgets/church_app_bar.dart';
import '../widgets/church_buttons.dart';
import '../widgets/dashboard_label_title.dart';
import '../widgets/nfc_checkin_card.dart';
import '../widgets/skeletons.dart';

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

  Widget _meSkeleton() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: ChurchColors.cardDecoration(shadow: const []),
          child: Row(
            children: const [
              Skeleton(width: 72, height: 72, radius: 20),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Skeleton(width: 150, height: 16, radius: 6),
                    SizedBox(height: 10),
                    Skeleton(width: 190, height: 12, radius: 6),
                    SizedBox(height: 8),
                    Skeleton(width: 110, height: 12, radius: 6),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Row(
          children: const [
            Expanded(child: Skeleton(height: 76, radius: 16)),
            SizedBox(width: 12),
            Expanded(child: Skeleton(height: 76, radius: 16)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: const [
            Expanded(child: Skeleton(height: 76, radius: 16)),
            SizedBox(width: 12),
            Expanded(child: Skeleton(height: 76, radius: 16)),
          ],
        ),
      ],
    );
  }

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
              ChurchDangerButton(
                label: 'Yes, log out',
                onPressed: () => Navigator.pop(ctx, true),
              ),
              const SizedBox(height: 10),
              ChurchSecondaryButton(
                label: 'Stay signed in',
                onPressed: () => Navigator.pop(ctx, false),
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

  // --- Change profile photo -------------------------------------------------

  /// Replaces the profile photo from a single picked image (camera or library),
  /// rather than the multi-angle enrolment sweep used at signup. The picked
  /// frame runs through the same [ProfilePictureUpload] contract, so the
  /// backend still validates the face and publishes a fresh `imgURL`.
  Future<void> _changeProfilePhoto() async {
    final source = await _chooseImageSource();
    if (source == null || !mounted) return;

    XFile? file;
    try {
      file = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 88,
        preferredCameraDevice: CameraDevice.front,
      );
    } catch (e) {
      debugPrint('MePage: pickImage failed: $e');
      _showMessage(
        source == ImageSource.camera
            ? "Couldn't open the camera. Check the app's camera permission and try again."
            : "Couldn't open your photos. Check the app's photo permission and try again.",
        isError: true,
      );
      return;
    }
    if (file == null || !mounted) return;

    _showBlockingProgress('Updating your photo…');
    try {
      final bytes = await file.readAsBytes();
      final newUrl = await ProfilePictureUpload.upload(bytes);
      final cached = await ChurchApi.getCachedAccountJson();
      await ChurchApi.persistAccountFromServer({
        if (cached != null) ...cached,
        'imgURL': newUrl,
      });
      if (!mounted) return;
      _dismissBlockingProgress();
      _reload();
      _showMessage('Your profile photo has been updated.');
    } on PictureUploadException catch (e) {
      if (!mounted) return;
      _dismissBlockingProgress();
      _showMessage(e.message, isError: true);
    } catch (e) {
      debugPrint('MePage: profile photo update failed: $e');
      if (!mounted) return;
      _dismissBlockingProgress();
      _showMessage('Could not update your photo. Please try again.', isError: true);
    }
  }

  Future<ImageSource?> _chooseImageSource() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: ChurchColors.cardDecoration(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Change profile photo',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                  color: ChurchColors.bodyText,
                ),
              ),
              const SizedBox(height: 6),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 28),
                child: Text(
                  'Use a clear, well-lit photo of your face so you can still be '
                  'recognised at check-in.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: ChurchColors.muted, height: 1.4),
                ),
              ),
              const SizedBox(height: 8),
              _sourceTile(ctx, Icons.camera_alt_outlined, 'Take a photo', ImageSource.camera),
              _sourceTile(ctx, Icons.photo_library_outlined, 'Choose from library', ImageSource.gallery),
              _sourceTile(ctx, Icons.close_rounded, 'Cancel', null),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sourceTile(BuildContext ctx, IconData icon, String label, ImageSource? value) {
    final isCancel = value == null;
    return ListTile(
      leading: Icon(icon, color: isCancel ? ChurchColors.muted : ChurchColors.accent),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: isCancel ? ChurchColors.muted : ChurchColors.bodyText,
        ),
      ),
      onTap: () => Navigator.pop(ctx, value),
    );
  }

  // --- Delete account (handled by the church team) --------------------------

  /// Account and facial-data deletion is done by the church team, not
  /// self-service — this mirrors the policy already shown at signup
  /// (`user_prep.dart`). We simply help the member reach them with the details
  /// pre-filled.
  Future<void> _requestAccountDeletion(Map<String, dynamic> profile) async {
    final proceed = await showDialog<bool>(
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
                  color: _danger.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_forever_rounded, color: _danger, size: 28),
              ),
              const SizedBox(height: 20),
              const Text(
                'Delete your account',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: ChurchColors.bodyText,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'To keep your facial recognition data safe, account deletion is '
                'handled personally by the church team. Tap below to send them a '
                "request — we'll fill in your details for you.",
                textAlign: TextAlign.center,
                style: TextStyle(color: ChurchColors.muted, height: 1.45, fontSize: 14),
              ),
              const SizedBox(height: 24),
              ChurchDangerButton(
                label: 'Email the church',
                icon: Icons.mail_outline_rounded,
                onPressed: () => Navigator.pop(ctx, true),
              ),
              const SizedBox(height: 10),
              ChurchSecondaryButton(
                label: 'Not now',
                onPressed: () => Navigator.pop(ctx, false),
              ),
            ],
          ),
        ),
      ),
    );
    if (proceed != true || !mounted) return;
    await _sendDeletionEmail(profile);
  }

  Future<void> _sendDeletionEmail(Map<String, dynamic> profile) async {
    final configured = dotenv.env['CHURCH_ADMIN_EMAIL']?.trim();
    final adminEmail =
        (configured != null && configured.isNotEmpty) ? configured : 'hello@rejoicegreatly.org';
    final churchName = dotenv.env['CHURCH_NAME'] ?? 'Rejoice Greatly';
    final name = (profile['name'] as String?)?.trim() ?? '';
    final email = (profile['email'] as String?)?.trim() ?? '';

    const subject = 'Account deletion request';
    final body = 'Hello $churchName team,\n\n'
        'I would like to permanently delete my $churchName app account and all '
        'associated data, including my facial recognition data.\n\n'
        'Name: ${name.isEmpty ? '(not set)' : name}\n'
        'Account email: ${email.isEmpty ? '(not set)' : email}\n\n'
        'Thank you.';

    final uri = Uri.parse(
      'mailto:$adminEmail'
      '?subject=${Uri.encodeComponent(subject)}'
      '&body=${Uri.encodeComponent(body)}',
    );

    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) throw 'launchUrl returned false';
    } catch (e) {
      debugPrint('MePage: could not open mail client: $e');
      await Clipboard.setData(ClipboardData(text: adminEmail));
      if (!mounted) return;
      _showMessage(
        'No email app found. We copied $adminEmail to your clipboard so you '
        'can reach the church.',
        isError: true,
      );
    }
  }

  // --- Small shared UI helpers ----------------------------------------------

  void _showBlockingProgress(String message) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
          decoration: ChurchColors.cardDecoration(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: ChurchColors.button),
              const SizedBox(height: 18),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: ChurchColors.bodyText,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _dismissBlockingProgress() {
    Navigator.of(context, rootNavigator: true).pop();
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? _danger : ChurchColors.button,
        behavior: SnackBarBehavior.floating,
      ),
    );
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
    for (final m in raw) {
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
        // leading: IconButton(
        //   icon: const Icon(Icons.arrow_back_rounded, color: ChurchColors.accent),
        //   onPressed: _onBack,
        // ),
      ),
      body: FutureBuilder<MePageLoadResult>(
        future: _pageFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _meSkeleton();
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
                    if (signedIn) ...[
                      ChurchPrimaryButton(
                        label: 'Try again',
                        onPressed: () => _reload(forceRefresh: true),
                      ),
                      const SizedBox(height: 10),
                      ChurchSecondaryButton(
                        label: 'Back to app',
                        onPressed: _onBack,
                      ),
                    ] else
                      ChurchPrimaryButton(
                        label: 'Back to app',
                        onPressed: _onBack,
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
                  onEditPhoto: hasProfile ? _changeProfilePhoto : null,
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
                        ChurchPrimaryButton(
                          label: 'Finish signup',
                          onPressed: () =>
                              Navigator.pushNamed(context, '/complete-signup'),
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
                  const DashboardLabelText(label: 'Attendance'),
                  NfcCheckInCard(
                    onCheckedIn: () => _reload(forceRefresh: true),
                  ),
                  const SizedBox(height: 16),
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
                  const DashboardLabelText(label: 'Activity'),
                  _AttendanceActivityList(
                    activities: _parseActivities(result?.activities ?? []),
                  ),
                ],
                const SizedBox(height: 28),
                const DashboardLabelText(label: 'Account'),
                if (hasProfile)
                  _ActionTile(
                    icon: Icons.photo_camera_outlined,
                    title: 'Change profile photo',
                    subtitle: 'Update the photo shown on your profile.',
                    onTap: _changeProfilePhoto,
                  ),
                _ActionTile(
                  icon: Icons.delete_outline_rounded,
                  title: 'Delete my account',
                  subtitle: 'Ask the church team to remove your account and data.',
                  danger: true,
                  onTap: () => _requestAccountDeletion(profile),
                ),
                const SizedBox(height: 36),
                const Divider(color: ChurchColors.divider, height: 1),
                const SizedBox(height: 20),
                const DashboardLabelText(label: 'Session', color: _danger),
                ChurchDangerButton(
                  label: 'Log out of account',
                  icon: Icons.power_settings_new_rounded,
                  onPressed: _logout,
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
    this.onEditPhoto,
  });

  final String name;
  final String email;
  final String churchLine;
  final Map<String, dynamic>? account;

  /// When non-null, the avatar becomes tappable and shows a camera badge so the
  /// member can replace their profile photo. Null hides the affordance (e.g.
  /// before the profile has been completed).
  final VoidCallback? onEditPhoto;

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
              _buildAvatar(url),
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

  Widget _buildAvatar(String? url) {
    final image = ClipRRect(
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
    );

    if (onEditPhoto == null) return image;

    return GestureDetector(
      onTap: onEditPhoto,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          image,
          Positioned(
            right: -3,
            bottom: -3,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: ChurchColors.button,
                shape: BoxShape.circle,
                border: Border.all(color: ChurchColors.card, width: 2),
              ),
              child: const Icon(
                Icons.photo_camera_rounded,
                size: 14,
                color: ChurchColors.buttonText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _placeholder() {
    return Container(
      color: ChurchColors.button.withValues(alpha: 0.1),
      child: const Icon(Icons.person, size: 40, color: ChurchColors.accent),
    );
  }
}

/// A tappable card row for a profile-management action (change photo, delete).
class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool danger;

  static const Color _danger = Color(0xFFC62828);

  @override
  Widget build(BuildContext context) {
    final color = danger ? _danger : ChurchColors.accent;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: ChurchColors.cardDecoration(shadow: const []),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: ChurchColors.borderRadiusCard,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: danger ? _danger : ChurchColors.bodyText,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: ChurchColors.muted,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: ChurchColors.muted.withValues(alpha: 0.7),
                ),
              ],
            ),
          ),
        ),
      ),
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
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
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
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: ChurchColors.muted,
                    letterSpacing: 0.2,
                    height: 1.2,
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
