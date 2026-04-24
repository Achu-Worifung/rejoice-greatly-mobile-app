import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../widgets/user_dashboard.dart';
import './sermons.dart';
import './events_page.dart';
import './me_page.dart';
import './cafe.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    DashboardPage(), 
    SermonsPage(data: {}),
    EventsPage(),
    Cafe(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  BottomNavigationBarItem _buildNavItem(String assetPath, String label, int index) {
    final Color selectedColor = const Color(0xFFD27E09);
    final Color unselectedColor = Colors.grey.shade400;
    final Color color = _selectedIndex == index ? selectedColor : unselectedColor;

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
    const Color goldColor = Color(0xFFD27E09);

    return Scaffold(
      body: _widgetOptions.length > _selectedIndex
          ? _widgetOptions[_selectedIndex]
          : const Center(child: Text('Page not found')),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: goldColor,
          unselectedItemColor: Colors.grey.shade400,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          elevation: 0,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
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