import 'package:flutter/material.dart';

class AttendanceWidget extends StatefulWidget {
  const AttendanceWidget({super.key});

  @override
  State<AttendanceWidget> createState() => _AttendanceWidgetState();
}

class _AttendanceWidgetState extends State<AttendanceWidget> {
  String _selectedFilter = 'All';
  DateTime? _selectedSunday;
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _members = [
    {'name': 'John Doe', 'method': 'NFC', 'time': '10:20 AM', 'status': 'Present'},
    {'name': 'John Doe', 'method': 'NFC', 'time': '10:00 AM', 'status': 'Present'},
    {'name': 'John Doe', 'method': '', 'time': '', 'status': 'Absent'},
  ];

  List<DateTime> _getSundays() {
    final List<DateTime> sundays = [];
    // Get last 12 Sundays from today
    DateTime now = DateTime.now();
    DateTime day = now.subtract(Duration(days: now.weekday % 7)); // most recent Sunday
    for (int i = 0; i < 12; i++) {
      sundays.add(day.subtract(Duration(days: 7 * i)));
    }
    return sundays;
  }

  String _formatSunday(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return 'Sunday, ${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  List<Map<String, dynamic>> get _filteredMembers {
    return _members.where((m) {
      final matchesFilter =
          _selectedFilter == 'All' || m['status'] == _selectedFilter;
      final matchesSearch = m['name']
          .toLowerCase()
          .contains(_searchController.text.toLowerCase());
      return matchesFilter && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final sundays = _getSundays();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FA),
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: const Text(
          'Attendance',
          style: TextStyle(
            color: Color(0xFF011A3E),
            fontWeight: FontWeight.w600,
            fontSize: 24,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search bar
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search',
                  hintStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Sunday dropdown
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFDDE3F0)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<DateTime>(
                  value: _selectedSunday,
                  hint: const Text(
                    'Select a Sunday',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                  isExpanded: true,
                  items: sundays.map((sunday) {
                    return DropdownMenuItem<DateTime>(
                      value: sunday,
                      child: Text(
                        _formatSunday(sunday),
                        style: const TextStyle(fontSize: 14),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedSunday = value);
                  },
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Filter tabs
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: ['All', 'Present', 'Absent'].map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedFilter = filter),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFEAF3FF)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          filter,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: isSelected
                                ? const Color(0xFF438FFC)
                                : Colors.black54,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 16),

            // Member list
            Expanded(
              child: ListView.separated(
                itemCount: _filteredMembers.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final member = _filteredMembers[index];
                  final isPresent = member['status'] == 'Present';

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        Checkbox(
                          value: false,
                          onChanged: (_) {},
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                member['name'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              if (member['method'].isNotEmpty)
                                Text(
                                  member['method'],
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 13,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isPresent
                                    ? const Color(0xFFE6F9F0)
                                    : const Color(0xFFFFEDED),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                member['status'],
                                style: TextStyle(
                                  color: isPresent
                                      ? const Color(0xFF2ECC71)
                                      : const Color(0xFFE74C3C),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            if (member['time'].isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  member['time'],
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}