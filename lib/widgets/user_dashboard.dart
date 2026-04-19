import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../components/show_streak.dart';


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
      'text': 'The Lord is my shepherd; I shall not want. He makes me lie down in green pastures. He leads me beside still waters. He restores my soul.',
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
    },
    'upcomingEvents': [
      {
        'title': 'Wednesday Bible Study',
        'date': 'Tomorrow, 7:00 PM',
        'location': 'Main Sanctuary',
        'icon': Icons.menu_book,
        'color': 0xFF4CAF50,
      },
      {
        'title': 'Youth Worship Night',
        'date': 'Friday, 6:30 PM',
        'location': 'Youth Hall',
        'icon': Icons.music_note,
        'color': 0xFF9C27B0,
      },
      {
        'title': 'Community Outreach',
        'date': 'Saturday, 9:00 AM',
        'location': 'Downtown Center',
        'icon': Icons.volunteer_activism,
        'color': 0xFF2196F3,
      },
      {
        'title': 'Sunday Service',
        'date': 'Sunday, 10:30 AM',
        'location': 'Main Sanctuary',
        'icon': Icons.church,
        'color': 0xFFD27E09,
      },
    ],
    'churchInfo': {
      'name': 'Grace Community Church',
      'address': '123 Faith Avenue\nCity, State 12345',
      'serviceTimes': 'Sundays: 9:00 AM & 11:00 AM\nWednesdays: 7:00 PM',
      'phone': '(555) 123-4567',
      'email': 'info@gracechurch.org',
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
    backgroundColor: Colors.transparent, // Required for our custom rounded corners
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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  children: [
                    // Verse of the week Component
                    verseOfTheWeekCard(data: dashboardData['verseOfTheWeek']),
                    const SizedBox(height: 20),

                    
                    // Latest Sermon Component
                    LatestSermonCard(data: dashboardData['latestSermon']),
                    const SizedBox(height: 20),
                    
                    // Upcoming Events Component
                    UpcomingEventsSection(events: dashboardData['upcomingEvents']),
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
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.8),
          ),
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
        borderRadius: BorderRadius.circular(25),
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
                'VERSE OF THE DAY',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFD27E09),
                  letterSpacing: 1.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFD27E09).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'DAILY',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFD27E09),
                  ),
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
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Child Component 2: Attendance Streak

// Child Component 3: Latest Sermon
class LatestSermonCard extends StatelessWidget {
  final Map<String, dynamic> data;
  
  const LatestSermonCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
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
          // Thumbnail Section
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: Color(data['thumbnailColor']).withOpacity(0.2),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(25),
                topRight: Radius.circular(25),
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD27E09),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFD27E09).withOpacity(0.4),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'Tap to listen',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFFD27E09),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Content Section
          Padding(
            padding: const EdgeInsets.all(25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'LATEST SERMON',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFD27E09),
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  data['title'],
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      color: Colors.grey[600],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      data['speaker'],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.access_time,
                      color: Colors.grey[600],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      data['duration'],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      color: Colors.grey[600],
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      data['date'],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      // Play sermon functionality
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD27E09),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 0,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.play_arrow, size: 24),
                        SizedBox(width: 10),
                        Text(
                          'PLAY SERMON',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
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

// Child Component 4: Upcoming Events
class UpcomingEventsSection extends StatelessWidget {
  final List<dynamic> events;
  
  const UpcomingEventsSection({super.key, required this.events});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 5, bottom: 15),
          child: Text(
            'UPCOMING EVENTS',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFFD27E09),
              letterSpacing: 1,
            ),
          ),
        ),
        Column(
          children: events.map((event) => _buildEventCard(event)).toList(),
        ),
      ],
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Event Icon
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Color(event['color']).withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              event['icon'],
              color: Color(event['color']),
              size: 30,
            ),
          ),
          
          const SizedBox(width: 20),
          
          // Event Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event['title'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      event['date'],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      event['location'],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // RSVP Button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFD27E09).withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Text(
              'RSVP',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFFD27E09),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Child Component 5: Worship With Us
class WorshipWithUsCard extends StatelessWidget {
  final Map<String, dynamic> data;
  
  const WorshipWithUsCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
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
          const Text(
            'WORSHIP WITH US',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFFD27E09),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 20),
          
          // Church Info
          _buildInfoRow(Icons.church, data['name']),
          const SizedBox(height: 15),
          _buildInfoRow(Icons.location_on, data['address']),
          const SizedBox(height: 15),
          _buildInfoRow(Icons.access_time, data['serviceTimes']),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _buildInfoRow(Icons.phone, data['phone']),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildInfoRow(Icons.email, data['email']),
              ),
            ],
          ),
          
          const SizedBox(height: 25),
          
          // Map Placeholder
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFD27E09).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFD27E09).withOpacity(0.2),
                width: 2,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.map,
                  size: 60,
                  color: const Color(0xFFD27E09).withOpacity(0.6),
                ),
                const SizedBox(height: 15),
                const Text(
                  '📍 Church Location',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFD27E09),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  data['address'].split('\n').first,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 25),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Open maps functionality
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD27E09),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: const Icon(Icons.directions),
                  label: const Text(
                    'GET DIRECTIONS',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Share functionality
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFD27E09),
                    side: const BorderSide(color: Color(0xFFD27E09)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: const Icon(Icons.share),
                  label: const Text(
                    'SHARE',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: const Color(0xFFD27E09),
          size: 24,
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.black87,
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }
}