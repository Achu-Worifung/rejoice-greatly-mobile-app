import 'package:flutter/material.dart';

void main() => runApp(const ChurchDashboard());

class ChurchDashboard extends StatelessWidget {
  const ChurchDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Church App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD27E09),
          primary: const Color(0xFFD27E09),
          secondary: const Color(0xFFFFF7EB),
        ),
        scaffoldBackgroundColor: const Color(0xFFFFF7EB),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFD27E09),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home:  DashboardPage(),
    );
  }
}

class DashboardPage extends StatelessWidget {
   DashboardPage({super.key});

  // Static data that will be passed to all child components
  final Map<String, dynamic> dashboardData = {
    'verseOfTheDay': {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // App Header
              _buildHeader(),
              
              // Main Content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  children: [
                    // Verse of the Day Component
                    VerseOfTheDayCard(data: dashboardData['verseOfTheDay']),
                    const SizedBox(height: 20),
                    
                    // Attendance Streak Component
                    AttendanceStreakCard(data: dashboardData['attendanceStreak']),
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

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
      decoration: BoxDecoration(
        color: const Color(0xFFD27E09),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome and User Info
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dashboardData['userGreeting'],
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                dashboardData['lastAttendance'],
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 25),
          
          // Quick Stats Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildQuickStat('Prayers', '12', Icons.favorite),
              _buildQuickStat('Giving', '\$245', Icons.monetization_on),
              _buildQuickStat('Volunteer', '8 hrs', Icons.people),
              _buildQuickStat('Study', '5 days', Icons.book),
            ],
          ),
        ],
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
class VerseOfTheDayCard extends StatelessWidget {
  final Map<String, dynamic> data;
  
  const VerseOfTheDayCard({super.key, required this.data});

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
class AttendanceStreakCard extends StatelessWidget {
  final Map<String, dynamic> data;
  
  const AttendanceStreakCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFD27E09),
            const Color(0xFFD27E09).withOpacity(0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD27E09).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'ATTENDANCE STREAK',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStreakStat(
                value: data['currentStreak'].toString(),
                label: data['streakLabel'],
                icon: Icons.local_fire_department,
                isMain: true,
              ),
              _buildStreakStat(
                value: data['totalAttendance'].toString(),
                label: data['totalLabel'],
                icon: Icons.calendar_today,
              ),
              _buildStreakStat(
                value: data['bestStreak'].toString(),
                label: data['bestLabel'],
                icon: Icons.star,
              ),
            ],
          ),
          const SizedBox(height: 15),
          LinearProgressIndicator(
            value: data['currentStreak'] / 30,
            backgroundColor: Colors.white.withOpacity(0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            borderRadius: BorderRadius.circular(10),
            minHeight: 8,
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Keep going! ${30 - data['currentStreak']} days to reach your goal',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              Text(
                '${((data['currentStreak'] / 30) * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStreakStat({
    required String value,
    required String label,
    required IconData icon,
    bool isMain = false,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(isMain ? 0.3 : 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: isMain ? 28 : 24,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          value,
          style: TextStyle(
            fontSize: isMain ? 28 : 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
      ],
    );
  }
}

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