import 'package:flutter/material.dart';

class OverviewWidget extends StatelessWidget {
  const OverviewWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // User profile (top)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Row(
              children: <Widget>[
                ClipRRect(
                  borderRadius: BorderRadius.circular(25),
                  child: Image.network(
                    'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcST4JjHURtaso7i__VnumOCn8QoUHn-WXURHQ&s',
                    height: 50,
                    width: 50,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "Name goes here",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      "Admin",
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8.0, top: 8.0, bottom: 8.0, right: 8.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  SizedBox(
                    height: 48,
                    width: 48,
                    child: Icon(Icons.notifications, color: Colors.grey),
                  ),
                  SizedBox(width: 10),
                  SizedBox(
                    height: 48,
                    width: 48,
                    child: Icon(Icons.calendar_month, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Today's Attendance Card
        Card(
          shape: RoundedRectangleBorder(
            // borderRadius: BorderRadius.circular(12),
          ),
          // elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Today's Attendance",
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 2.5,
                  children: [
                    _buildStatCard(
                      icon: Icons.person,
                      iconColor: Colors.blue,
                      title: 'Present',
                      value: '198',
                    ),
                    _buildStatCard(
                      icon: Icons.person_off,
                      iconColor: Colors.blue,
                      title: 'Absent',
                      value: '47',
                    ),
                    _buildStatCard(
                      icon: Icons.people,
                      iconColor: Colors.blue,
                      title: 'Total Members',
                      value: '245',
                    ),
                    _buildStatCard(
                      icon: Icons.show_chart,
                      iconColor: Colors.blue,
                      title: 'Attendance Rate',
                      value: '81%',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Send Reminder Card
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          color: Colors.blue[400],
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Send reminder to absentees",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w400,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Message Absentees',
                    filled: true,
                    fillColor: Colors.white,
                    suffixIcon: const Icon(Icons.arrow_forward),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Filter Tabs
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildFilterChip('All', true),
            _buildFilterChip('Present', false),
            _buildFilterChip('Absent', false),
          ],
        ),

        const SizedBox(height: 16),

        // Members List
        ...List.generate(3, (index) {
          bool present = index != 2;
          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 1,
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: ListTile(
              leading: Checkbox(value: false, onChanged: (_) {}),
              title: const Text('John Doe'),
              subtitle: const Text('NFC'),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: present ? Colors.green[50] : Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  present ? 'Present' : 'Absent',
                  style: TextStyle(
                    color: present ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start, // ← add this

        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 24),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
          Text(
            value,
            textAlign: TextAlign.left,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool selected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: selected ? Colors.blue[100] : Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: const TextStyle(fontSize: 14)),
    );
  }
}
