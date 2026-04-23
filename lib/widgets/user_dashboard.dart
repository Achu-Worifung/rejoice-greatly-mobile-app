import 'dart:convert';
import 'dart:io';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import "../components/sermon_card.dart";
// import 'components/upcoming_events_section.dart';
// import 'components/worship_with_us.dart';

void main() => runApp(const ChurchDashboard());

class ChurchDashboard extends StatelessWidget {
  const ChurchDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Church App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD27E09),
          primary: const Color(0xFFD27E09),
        ),
        scaffoldBackgroundColor: const Color(0xFFFFF7EB),
      ),
      home: const DashboardPage(),
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late Future<String> _greetingFuture;
  late Future<Map<String, dynamic>> _verseFuture;
  late Future<List<dynamic>> _sermonFuture;

  @override
  void initState() {
    super.initState();
    _greetingFuture = _getGreeting();
    _verseFuture = _fetchCurrentVerse();
    _sermonFuture = _fetchSermons();
  }

  // --- API LOGIC ---
  String ip_address = dotenv.env['IP_ADDRESS'] ?? 'localhost';

  Future<Map<String, dynamic>> _fetchCurrentVerse() async {
    final response = await http.get(Uri.parse('http://$ip_address:8080/weekly-verse/current'));
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to load verse');
  }

  Future<List<dynamic>> _fetchSermons() async {
    final response = await http.get(Uri.parse('http://$ip_address:8080/sermons'));
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to load sermons');
  }

  // --- HELPERS ---
  String _formatReference(String book, int chapter, int start, int? end) {
    if (end == null || start == end) return "$book $chapter:$start";
    return "$book $chapter:$start-$end";
  }

  Future<String> _getGreeting() async {
    final pref = await SharedPreferences.getInstance();
    final name = pref.getString('name') ?? 'Friend';
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning, $name!';
    if (hour < 18) return 'Good afternoon, $name!';
    return 'Good evening, $name!';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 50,
        title: FutureBuilder<String>(
          future: _greetingFuture,
          builder: (context, snapshot) => AutoSizeText(
            snapshot.data ?? 'Welcome',
            style: const TextStyle(
              fontSize: 22, 
              fontWeight: FontWeight.bold, 
              color: Color(0xFFD27E09)
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: SvgPicture.asset(
              'assets/icons/lightning.svg', 
              color: const Color(0xFFD27E09), 
              width: 24
            ),
            onPressed: () {}, 
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. DYNAMIC VERSE OF THE WEEK
                FutureBuilder<Map<String, dynamic>>(
                  future: _verseFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const LoadingPlaceholder();
                    }
                    if (snapshot.hasError) return const Center(child: Text("Error loading verse"));
                    
                    final v = snapshot.data!;
                    return verseOfTheWeekCard(data: {
                      'text': v['content'],
                      'version': v['version'],
                      'reference': _formatReference(v['book'], v['chapter'], v['startVerse'], v['endVerse']),
                    });
                  },
                ),

                const SizedBox(height: 20),

                // 2. DYNAMIC LATEST SERMON SECTION
                const SectionHeader(title: 'LATEST SERMON'),
                FutureBuilder<List<dynamic>>(
                  future: _sermonFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const LoadingPlaceholder();
                    }
                    if (snapshot.hasError || snapshot.data == null || snapshot.data!.isEmpty) {
                      return const Center(child: Text("No sermons available"));
                    }

                    // Get the most recent sermon from your Spring Boot List
                    final s = snapshot.data!.last;
                    
                    // Map Spring Boot fields to your LatestSermonCard's expected keys
                    final mappedSermon = {
                      'title': s['title'],
                      'date': s['datePreached'], // Maps 'datePreached' to 'date'
                      'imageUrl': s['imageUrl'],
                    };

                    return LatestSermonCard(data: mappedSermon);
                  },
                ),
                
                const SizedBox(height: 12),
                _buildViewMoreButton(),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildViewMoreButton() {
    return SizedBox(
      height: 36, 
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFD27E09), 
          foregroundColor: Colors.white, 
          elevation: 0,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero)
        ),
        onPressed: () {},
        child: const Text(
          'VIEW MORE', 
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)
        ),
      ),
    );
  }
}

// --- DASHBOARD COMPONENTS ---

class verseOfTheWeekCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const verseOfTheWeekCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 15, offset: Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'VERSE OF THE WEEK', 
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFD27E09), letterSpacing: 1.5)
          ),
          const SizedBox(height: 15),
          Text(
            data['text'] ?? '', 
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87, height: 1.6)
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                data['reference'] ?? '', 
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFD27E09))
              ),
              Text(
                data['version'] ?? '', 
                style: const TextStyle(fontSize: 12, color: Colors.grey)
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  const SectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8), 
      child: Text(
        title, 
        style: const TextStyle(
          fontSize: 13, 
          fontWeight: FontWeight.bold, 
          color: Color(0xFFD27E09), 
          letterSpacing: 1.2
        )
      )
    );
  }
}

class LoadingPlaceholder extends StatelessWidget {
  const LoadingPlaceholder({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(20), 
        child: CircularProgressIndicator(color: Color(0xFFD27E09))
      )
    );
  }
}