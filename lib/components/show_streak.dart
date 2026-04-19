import 'package:flutter/material.dart';

class AttendanceSheet extends StatelessWidget {
  final Map<String, dynamic> data;

  const AttendanceSheet({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    // Extracting data for easier access
    final attendance = data['attendanceStreak'];

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 25),
          
          const Text(
            'Attendance Stats',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFFD27E09),
            ),
          ),
          const SizedBox(height: 25),

          // Main Streak Display
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatCircle(
                label: attendance['streakLabel'],
                value: attendance['currentStreak'].toString(),
                icon: Icons.local_fire_department,
                color: Colors.orange,
              ),
              _buildStatCircle(
                label: attendance['totalLabel'],
                value: attendance['totalAttendance'].toString(),
                icon: Icons.calendar_today,
                color: const Color(0xFFD27E09),
              ),
            ],
          ),
          
          const Divider(height: 40, thickness: 1),

          // Best Streak Row
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7EB),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                const Icon(Icons.emoji_events, color: Color(0xFFD27E09), size: 30),
                const SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      attendance['bestLabel'],
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      '${attendance['bestStreak']} Days',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          // Close Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD27E09),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              child: const Text('Great!'),
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget for the circular stats
  Widget _buildStatCircle({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: CircularProgressIndicator(
                value: 0.7, // You can calculate this based on goals
                strokeWidth: 6,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                backgroundColor: color.withOpacity(0.1),
              ),
            ),
            Icon(icon, color: color, size: 30),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          value,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}