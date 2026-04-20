import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../widgets/overview_widget.dart';
import '../widgets/attendance_widget.dart';
import '../widgets/reminder_widget.dart';
import './content_moderation.dart';
// import '../widgets/report_widget.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  static const TextStyle optionStyle = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.bold,
  );

  // If your widgets are not const, remove `const` from the list.
  final List<Widget> _widgetOptions = const <Widget>[
    OverviewWidget(),
    AttendanceWidget(),
    RemindersWidget(),
    ContentModerationPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _getData() async {
    // Fetch data if needed
  }

  @override
  Widget build(BuildContext context) {
    final Color selectedColor = Theme.of(context).colorScheme.primary;
    final Color unselectedColor = Colors.black;

    return Scaffold(
      body: Center(child: _widgetOptions.elementAt(_selectedIndex)),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: selectedColor,
        unselectedItemColor: unselectedColor,
        enableFeedback: false,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(
            icon: SvgPicture.asset(
              'assets/icons/home.svg',
              height: 24.0,
              width: 24.0,
              colorFilter: ColorFilter.mode(
                _selectedIndex == 0 ? selectedColor : unselectedColor,
                BlendMode.srcIn,
              ),
            ),
            label: 'Overview',
          ),
          BottomNavigationBarItem(
            icon: SvgPicture.asset(
              'assets/icons/attendance.svg',
              height: 24.0,
              width: 24.0,
              colorFilter: ColorFilter.mode(
                _selectedIndex == 1 ? selectedColor : unselectedColor,
                BlendMode.srcIn,
              ),
            ),
            label: 'Attendance',
          ),
          BottomNavigationBarItem(
            icon: SvgPicture.asset(
              'assets/icons/reminders.svg',
              height: 24.0,
              width: 24.0,
              colorFilter: ColorFilter.mode(
                _selectedIndex == 2 ? selectedColor : unselectedColor,
                BlendMode.srcIn,
              ),
            ),
            label: 'Reminders',
          ),
          BottomNavigationBarItem(
            icon: SvgPicture.asset(
              'assets/icons/content.svg',
              height: 24.0,
              width: 24.0,
              colorFilter: ColorFilter.mode(
                _selectedIndex == 3 ? selectedColor : unselectedColor,
                BlendMode.srcIn,
              ),
            ),
            label: 'Content',
          ),
        ],
      ),
    );
  }
}