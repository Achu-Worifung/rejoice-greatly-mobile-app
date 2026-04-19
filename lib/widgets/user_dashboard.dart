import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../components/show_streak.dart';
import '../components/upcoming_events_section.dart';
import '../components/worship_with_us.dart';
import '../components/sermon_card.dart';

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
          secondary: const Color(0xFFFFF7EB),
        ),
        scaffoldBackgroundColor: const Color(0xFFFFF7EB),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFFD27E09),
          elevation: 0,
        ),
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

  @override
  void initState() {
    super.initState();
    // Initialize once to prevent flickering on rebuilds
    _greetingFuture = _getGreeting();
  }

  Future<String> _getGreeting() async {
    final pref = await SharedPreferences.getInstance();
    final name = pref.getString('name') ?? 'Friend'; // Default value

    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = 'Good morning';
    } else if (hour < 18) {
      greeting = 'Good afternoon';
    } else {
      greeting = 'Good evening';
    }
    return '$greeting, $name!';
  }

  // Static data that will be passed to all child components
  final Map<String, dynamic> dashboardData = {
    'verseOfTheWeek': {
      'reference': 'Psalm 23:1-3',
      'text':
          'The Lord is my shepherd; I shall not want. He makes me lie down in green pastures. He leads me beside still waters. He restores my soul.',
      'version': 'English Standard Version',
    },
    'attendanceStreak': {
      'currentStreak': 7,
      'streakLabel': 'DAYS STREAK',
      'totalAttendance': 42,
      'totalLabel': 'TOTAL SERVICES',
      'bestStreak': 30,
      'bestLabel': 'BEST STREAK',
    },
    'latestSermon': {
      'title': 'Walking in Faith During Difficult Times',
      'speaker': 'Pastor John Smith',
      'date': 'November 15, 2023',
      'duration': '45 minutes',
      'thumbnailColor': 0xFFD27E09,
      // Add this line for the web image
      'imageUrl':
          'https://images.unsplash.com/photo-1515021212813-f14da1862391?auto=format&fit=crop&q=80&w=200',
    },
    'upcomingEvents': [
      {
        'title': 'Wednesday Bible Study',
        'date': 'Tomorrow, 7:00 PM',
        'location': 'Main Sanctuary',
        'imageUrl':
            'https://images.unsplash.com/photo-1504052434569-70ad5836ab65?w=400',
        'color': 0xFF4CAF50,
      },
      {
        'title': 'Youth Worship Night',
        'date': 'Friday, 6:30 PM',
        'location': 'Youth Hall',
        'imageUrl':
            'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=400',
        'color': 0xFF9C27B0,
      },
      {
        'title': 'Community Outreach',
        'date': 'Saturday, 9:00 AM',
        'location': 'Downtown Center',
        'imageUrl':
            'https://images.unsplash.com/photo-1469571480357-0a8a01aa197f?w=400',
        'color': 0xFF2196F3,
      },
    ],
    'churchInfo': {
      'name': 'REJOICE GREATLY',
      'address': '2323 E Magnolia st, \nPhoenix, AZ 85034',
      'serviceTimes': 'Sundays: 10:00 AM ',
      'lat': 37.7749,
      'lng': -122.4194,
    },
    'userGreeting': 'Welcome back, Michael!',
    'lastAttendance': 'Last attended: Sunday, Nov 12',
  };

  //for the attendace sheet
  void _showAttendanceStats() {
    showModalBottomSheet(
      context: context,
      backgroundColor:
          Colors.transparent, // Required for our custom rounded corners
      isScrollControlled: true,
      builder: (context) => AttendanceSheet(data: dashboardData),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 50,
        centerTitle: false,
        title: FutureBuilder<String>(
          future: _greetingFuture,
          builder: (context, snapshot) {
            final greeting = snapshot.data ?? 'Welcome';
            return AutoSizeText(
              greeting,
              maxLines: 1,
              minFontSize: 16,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFFD27E09),
              ),
            );
          },
        ),
        actions: [
          IconButton(
            icon: SvgPicture.asset(
              'assets/icons/lightning.svg',
              color: const Color(0xFFD27E09),
              width: 24,
              height: 24,
            ),
            onPressed: _showAttendanceStats,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main Content
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                child: Column(
                  children: [
                    // Verse of the week Component
                    verseOfTheWeekCard(data: dashboardData['verseOfTheWeek']),
                    const SizedBox(height: 20),

                    // Latest Sermon Component
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Title OUTSIDE and ABOVE the card
                        const Padding(
                          padding: EdgeInsets.only(left: 4, bottom: 8),
                          child: Text(
                            'LATEST SERMON',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFD27E09),
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        LatestSermonCard(data: dashboardData['latestSermon']),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: SizedBox(
                            height: 36,
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFD27E09),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius
                                      .zero, // Match the square card style
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                              ),
                              child: const Text(
                                'VIEW MORE',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Upcoming Events Component
                    UpcomingEventsSection(
                      events: dashboardData['upcomingEvents'],
                    ),
                    const SizedBox(height: 20),

                    // Worship With Us Component
                    WorshipWithUsCard(data: dashboardData['churchInfo']),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8)),
        ),
      ],
    );
  }
}

// Child Component 1: Verse of the Day
class verseOfTheWeekCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const verseOfTheWeekCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'VERSE OF THE WEEK',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFD27E09),
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            data['text'],
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                data['reference'],
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFD27E09),
                ),
              ),
              Text(
                data['version'],
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Child Component 3: Latest Sermon
// class LatestSermonCard extends StatelessWidget {
//   final Map<String, dynamic> data;

//   const LatestSermonCard({super.key, required this.data});

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         // 1. Title OUTSIDE and ABOVE the card
//         const Padding(
//           padding: EdgeInsets.only(left: 4, bottom: 8),
//           child: Text(
//             'LATEST SERMON',
//             style: TextStyle(
//               fontSize: 13,
//               fontWeight: FontWeight.bold,
//               color: Color(0xFFD27E09),
//               letterSpacing: 1.2,
//             ),
//           ),
//         ),

//         // 2. The Card (White box, square edges)
//         Container(
//           width: double.infinity,
//           padding: const EdgeInsets.all(12),
//           decoration: const BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.zero, // Square edges
//           ),
//           child: Row(
//             children: [
//               CircleAvatar(
//                 radius: 28,
//                 backgroundColor: const Color(0xFFD27E09).withOpacity(0.1),
//                 backgroundImage: NetworkImage(
//                   data['imageUrl'] ?? 'https://via.placeholder.com/150',
//                 ),
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Text(
//                       data['title'],
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                       style: const TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.black87,
//                       ),
//                     ),
//                     const SizedBox(height: 2),
//                     Text(
//                       data['date'],
//                       style: TextStyle(fontSize: 13, color: Colors.grey[600]),
//                     ),
//                   ],
//                 ),
//               ),
//               IconButton(
//                 onPressed: () {},
//                 icon: const Icon(
//                   Icons.play_circle_fill,
//                   color: Color(0xFFD27E09),
//                   size: 36,
//                 ),
//               ),
//             ],
//           ),
//         ),

//         // 3. View More Button OUTSIDE and BELOW (Orange bg, white text)
//         const SizedBox(height: 12),
//         Align(
//           alignment: Alignment.centerRight,
//           child: SizedBox(
//             height: 36,
//             width: double.infinity,
//             child: ElevatedButton(
//               onPressed: () {},
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: const Color(0xFFD27E09),
//                 foregroundColor: Colors.white,
//                 elevation: 0,
//                 shape: const RoundedRectangleBorder(
//                   borderRadius:
//                       BorderRadius.zero, // Match the square card style
//                 ),
//                 padding: const EdgeInsets.symmetric(horizontal: 20),
//               ),
//               child: const Text(
//                 'VIEW MORE',
//                 style: TextStyle(
//                   fontSize: 12,
//                   fontWeight: FontWeight.bold,
//                   letterSpacing: 1,
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }
