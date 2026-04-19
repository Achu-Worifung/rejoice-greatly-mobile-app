import 'package:flutter/material.dart';

class MePage extends StatefulWidget {
  const MePage({super.key});

  @override
  State<MePage> createState() => _MePageState();
}

class _MePageState extends State<MePage> {
  final Color gold = const Color(0xFFD27E09);
  Map<String, dynamic> userStats = {};

  @override
  void initState() {
    super.initState();
    // You can fetch user stats here if needed
    userStats = {
      'currentStreak': 7,
      'longestStreak': 22,
      'consecutiveSundays': 3, // New metric
      'goalProgress': 0.75, // New goal (e.g., attended 3 of 4 target events)
      'sundayAttendance': [
        {'date': 'Oct 22', 'attended': true, 'height': 0.8},
        {'date': 'Oct 29', 'attended': true, 'height': 1.0},
        {'date': 'Nov 5', 'attended': false, 'height': 0.1}, // Missed
        {'date': 'Nov 12', 'attended': true, 'height': 0.9},
        {'date': 'Nov 19', 'attended': true, 'height': 1.0},
      ],
      'attendanceHistory': [
        {'event': 'Sunday Service', 'date': 'Nov 19, 2023'},
        {'event': 'Wednesday Bible Study', 'date': 'Nov 15, 2023'},
        {'event': 'Sunday Service', 'date': 'Nov 12, 2023'},
        {'event': 'Youth Worship Night', 'date': 'Nov 10, 2023'},
        {'event': 'Sunday Service', 'date': 'Oct 29, 2023'},
      ],
    };
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7EB),
      appBar: AppBar(
        title: const Text('MY PROGRESS', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Color(0xFFD27E09))),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. STATS ROW (Reusing the Circular Indicators)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildCircularStat(
                    label: 'CURRENT STREAK',
                    value: '${userStats['currentStreak']} Weeks',
                    icon: Icons.local_fire_department,
                    color: Colors.orange,
                    progress: userStats['currentStreak'] / userStats['longestStreak'], // Current vs. Best
                  ),
                  const SizedBox(width: 12),
                  _buildCircularStat(
                    label: 'LONGEST STREAK',
                    value: '${userStats['longestStreak']} Weeks',
                    icon: Icons.emoji_events,
                    color: gold,
                    progress: 1.0, // Best is always 100%
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // **New:** Goal Progress (Gamification)
            _buildGoalProgress(),

            const SizedBox(height: 24),

            // 2. SUNDAY CONSISTENCY (Chart & Specific Tracker)
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 12),
              child: Text('SUNDAY CONSISTENCY', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFD27E09))),
            ),
            
            // Reusing the Custom Bar Chart (Flat aesthetic)
            Container(
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              height: 200,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: (userStats['sundayAttendance'] as List).map((data) {
                  return _buildBar(data['date'], data['height'], data['attended']);
                }).toList(),
              ),
            ),
            
            // New Detail: Consecutive Sundays indicator
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              margin: const EdgeInsets.only(top: 2),
              child: _buildConsecutiveSundayTracker(),
            ),

            const SizedBox(height: 24),

            // 3. ATTENDANCE HISTORY LIST
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 12),
              child: Text('RECENT ACTIVITY', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFD27E09))),
            ),
            Column(
              children: (userStats['attendanceHistory'] as List).map((item) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 2),
                  color: Colors.white,
                  child: ListTile(
                    leading: Icon(Icons.check_circle, color: gold, size: 20),
                    title: Text(item['event'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    subtitle: Text(item['date'], style: const TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // Circular Stat Widget (Simplified from Dashboard)
  Widget _buildCircularStat({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required double progress,
  }) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 70,
              height: 70,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 5,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                backgroundColor: color.withOpacity(0.1),
              ),
            ),
            Icon(icon, color: color, size: 28),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          value,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 9, color: Colors.grey[600], fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
      ],
    );
  }

  // **New:** Goal Progress (Linear tracking)
Widget _buildGoalProgress() {
  // Use a local variable with a null check
  final double progress = userStats['goalProgress'] ?? 0.0;
  final int percentage = (progress * 100).toInt();

  return Container(
    padding: const EdgeInsets.all(16),
    color: Colors.white,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('MONTHLY ATTENDANCE GOAL', 
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            Text('$percentage%', 
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: gold)),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress, // Now safely defaults to 0.0
          backgroundColor: gold.withOpacity(0.1),
          valueColor: AlwaysStoppedAnimation<Color>(gold),
          minHeight: 6,
        ),
      ],
    ),
  );
}
  // **New:** Specific Sunday-only streak tracker
  Widget _buildConsecutiveSundayTracker() {
    int count = userStats['consecutiveSundays'];
    return Row(
      children: [
        Icon(Icons.calendar_month_outlined, color: Colors.grey.shade400, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Consecutive Sundays attended:',
            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
          ),
        ),
        Text(
          '$count Weeks',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: gold),
        ),
      ],
    );
  }

  // Reused Simple Bar (Flat aesthetic)
  Widget _buildBar(String label, double heightPercentage, bool attended) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Expanded(
          child: Container(
            width: 30,
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: heightPercentage,
              child: Container(
                width: 30,
                color: attended ? gold : gold.withOpacity(0.1),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
      ],
    );
  }
}