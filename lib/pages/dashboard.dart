import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/member_events.dart';
import '../services/prayer_wall_api.dart';
import '../widgets/user_dashboard.dart';
import '../theme/church_colors.dart';
import 'sermons.dart';
import 'event_detail_page.dart';
import 'events_page.dart';
import 'community_page.dart';
import 'prayer_thread_page.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  static const int _eventsTab = 2;
  static const int _communityTab = 3;

  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    PrayerWallApi.pendingThread.addListener(_openPendingThread);
    MemberEvents.pendingEvent.addListener(_openPendingEvent);
    // A push tapped on a cold start lands before this screen exists.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openPendingThread();
      _openPendingEvent();
    });
  }

  @override
  void dispose() {
    PrayerWallApi.pendingThread.removeListener(_openPendingThread);
    MemberEvents.pendingEvent.removeListener(_openPendingEvent);
    super.dispose();
  }

  /// Opens the event a tapped reminder or announcement is about.
  Future<void> _openPendingEvent() async {
    final id = MemberEvents.pendingEvent.value;
    if (id == null || !mounted) return;
    MemberEvents.pendingEvent.value = null;
    setState(() => _selectedIndex = _eventsTab);
    try {
      final feed = await MemberEvents.load();
      final event = feed.events.where((e) => e['id'] == id).firstOrNull;
      if (event != null && mounted) openEventDetailPage(context, event);
    } catch (e) {
      debugPrint('Dashboard: could not open event $id: $e');
    }
  }

  /// Opens the prayer request a tapped prayer notification is about, or
  /// just the prayer wall when it isn't about one.
  void _openPendingThread() {
    final id = PrayerWallApi.pendingThread.value;
    if (id == null || !mounted) return;
    PrayerWallApi.pendingThread.value = null;
    setState(() => _selectedIndex = _communityTab);
    if (id.isNotEmpty) openPrayerThread(context, id);
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  BottomNavigationBarItem _buildNavItem(String assetPath, String label, int index) {
    // Muted brown, not light grey: the unselected tabs still need AA contrast.
    const Color unselectedColor = ChurchColors.muted;
    final Color color = _selectedIndex == index ? ChurchColors.accent : unselectedColor;

    return BottomNavigationBarItem(
      icon: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: SvgPicture.asset(
          assetPath,
          height: 22,
          width: 22,
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        ),
      ),
      label: label,
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardPage(
        onViewAllSermons: () => setState(() => _selectedIndex = 1),
        onViewAllEvents: () => setState(() => _selectedIndex = 2),
      ),
      const SermonsPage(),
      const EventsPage(),
      CommunityPage(isActive: _selectedIndex == _communityTab),
    ];

    return Scaffold(
      backgroundColor: ChurchColors.background,
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: ChurchColors.background,
          // The register's rule closes the page above the nav.
          border: const Border(top: BorderSide(color: ChurchColors.divider)),
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: ChurchColors.background,
          selectedItemColor: ChurchColors.accent,
          unselectedItemColor: ChurchColors.muted,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          elevation: 0,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
          items: [
            _buildNavItem('assets/icons/dashboard.svg', 'Home', 0),
            _buildNavItem('assets/icons/microphone.svg', 'Sermons', 1),
            _buildNavItem('assets/icons/announcement.svg', 'Events', 2),
            _buildNavItem('assets/icons/users.svg', 'Community', _communityTab),
          ],
        ),
      ),
    );
  }
}
