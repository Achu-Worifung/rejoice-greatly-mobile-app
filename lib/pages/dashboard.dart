import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../widgets/overview_widget.dart';
void main() => runApp(const Dashboard());

class Dashboard extends StatelessWidget {
  const Dashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: AdminDashboard());
  }
}

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

  static const List<Widget> _widgetOptions = <Widget>[
    // OverviewWidget(),
    // AttendanceWidget(),
    // RemindersWidget(),
    // ReportsWidget(),
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
      body: _widgetOptions.isNotEmpty
    ? Center(child: _widgetOptions[_selectedIndex])
    : const Center(child: Text('No pages available')),
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
              'assets/icons/dashboard.svg',
              height: 24.0,
              width: 24.0,
              colorFilter: ColorFilter.mode(
                _selectedIndex == 0 ? selectedColor : unselectedColor,
                BlendMode.srcIn,
              ),
            ),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: SvgPicture.asset(
              'assets/icons/microphone.svg',
              height: 24.0,
              width: 24.0,
              colorFilter: ColorFilter.mode(
                _selectedIndex == 1 ? selectedColor : unselectedColor,
                BlendMode.srcIn,
              ),
            ),
            label: 'Sermons',
          ),
          BottomNavigationBarItem(
            icon: SvgPicture.asset(
              'assets/icons/users.svg',
              height: 24.0,
              width: 24.0,
              colorFilter: ColorFilter.mode(
                _selectedIndex == 2 ? selectedColor : unselectedColor,
                BlendMode.srcIn,
              ),
            ),
            label: 'Me',
          ),
          
        ],
      ),
    );
  }
}