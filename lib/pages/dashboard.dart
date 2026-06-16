import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../widgets/user_dashboard.dart';
import '../theme/church_colors.dart';
import 'sermons.dart';
import 'events_page.dart';
import 'cafe.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  BottomNavigationBarItem _buildNavItem(String assetPath, String label, int index) {
    final Color unselectedColor = Colors.grey.shade400;
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
      Cafe(
        isActive: _selectedIndex == 3,
        onExit: () => setState(() => _selectedIndex = 0),
      ),
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
          border: Border(
            top: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: ChurchColors.background,
          selectedItemColor: ChurchColors.accent,
          unselectedItemColor: Colors.grey.shade400,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          elevation: 0,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
          items: [
            _buildNavItem('assets/icons/dashboard.svg', 'Dashboard', 0),
            _buildNavItem('assets/icons/microphone.svg', 'Sermons', 1),
            _buildNavItem('assets/icons/announcement.svg', 'Events', 2),
            _buildNavItem('assets/icons/cafe.svg', 'Cafe', 3),
          ],
        ),
      ),
    );
  }
}
