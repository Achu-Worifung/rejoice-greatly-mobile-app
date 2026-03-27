import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({Key? key}) : super(key: key);

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  String greeting = ""; // will store the greeting

  @override
  void initState() {
    super.initState();
    _loadGreeting();
  }

  Future<void> _loadGreeting() async {
    final prefs = await SharedPreferences.getInstance();
    String name = prefs.getString("name") ?? "User";
    DateTime now = DateTime.now();

    String greet;
    if (now.hour < 12) {
      greet = "Good Morning, $name";
    } else if (now.hour < 18) {
      greet = "Good Afternoon, $name";
    } else {
      greet = "Good Evening, $name";
    }

    setState(() {
      greeting = greet;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        scrolledUnderElevation: 4.0,
        title: Text(greeting.isEmpty ? "Loading..." : greeting),
        elevation: 0.0, 
        actions: [
          
          
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                final authService = AuthService();
                await authService.logout();
                Navigator.pushNamed(context, '/login');
              },
                    ),
          )],
      ),
      body: const Center(child: Text("Dashboard")),
    );
  }
}
