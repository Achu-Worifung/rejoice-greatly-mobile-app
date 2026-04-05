import 'package:flutter/material.dart';
import '../dataobject/admin-type.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AttendanceWidget extends StatefulWidget {
  const AttendanceWidget({super.key});

  @override
  State<AttendanceWidget> createState() => _AttendanceWidgetState();
}

class _AttendanceWidgetState extends State<AttendanceWidget> {
  String _selectedFilter = 'All';
  late DateTime _selectedSunday;
  final TextEditingController _searchController = TextEditingController();

  List<AdminType>? _totalPresent;
  List<AdminType>? _totalAbsent;
  List<AdminType>? _totalMembers;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedSunday = _mostRecentSunday(DateTime.now());
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  DateTime _mostRecentSunday(DateTime from) {
    final daysBack = from.weekday % 7;
    return DateTime(from.year, from.month, from.day)
        .subtract(Duration(days: daysBack == 0 ? 0 : from.weekday));
  }

  List<DateTime> _getSundays({int count = 12}) {
    final List<DateTime> sundays = [];
    DateTime current = _mostRecentSunday(DateTime.now());
    for (int i = 0; i < count; i++) {
      sundays.add(current);
      current = current.subtract(const Duration(days: 7));
    }
    return sundays;
  }

  String _formatSunday(DateTime date) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return 'Sunday, ${months[date.month]} ${date.day}, ${date.year}';
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    String ip_addr = dotenv.env['IP_ADDRESS'] ?? 'localhost';
    print("making sure we are using the correct ip address: $ip_addr");
    final Uri uri = Uri.parse("http://$ip_addr:8080/admin/overview");

    final String dateStr =
        "${_selectedSunday.year}-${_selectedSunday.month.toString().padLeft(2, '0')}-${_selectedSunday.day.toString().padLeft(2, '0')}";

    final Map<String, dynamic> payload = {
      "date": dateStr,
      "userId": prefs.getString("firebaseUid") ?? "",
    };

    try {
      final http.Response response = await http.post(
        uri,
        body: jsonEncode(payload),
        headers: {"Content-Type": "application/json"},
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        setState(() {
          _totalPresent = List<AdminType>.from(
            data['totalPresent'].map((x) => AdminType.fromJson(x)),
          );
          _totalAbsent = List<AdminType>.from(
            data['totalAbsent'].map((x) => AdminType.fromJson(x)),
          );
          _totalMembers = List<AdminType>.from(
            data['totalMemberDTOs'].map((x) => AdminType.fromJson(x)),
          );
        });
      } else {
        print("Server error: ${response.statusCode}");
      }
    } catch (e) {
      print("Error loading attendance: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<AdminType> get _activeList {
    switch (_selectedFilter) {
      case 'Present':
        return _totalPresent ?? [];
      case 'Absent':
        return _totalAbsent ?? [];
      default:
        return _totalMembers ?? [];
    }
  }

  List<AdminType> get _filteredMembers {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) return _activeList;
    return _activeList
        .where((m) => m.name.toLowerCase().contains(query))
        .toList();
  }

  void _showMemberDrawer(AdminType member) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _MemberDetailDrawer(member: member),
    );
  }

  Future<void> _showSundayPicker() async {
    final sundays = _getSundays();
    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _SundayPickerSheet(
        sundays: sundays,
        selected: _selectedSunday,
      ),
    );
    if (picked != null && picked != _selectedSunday) {
      setState(() => _selectedSunday = picked);
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final members = _filteredMembers;
    final presentCount = _totalPresent?.length ?? 0;
    final absentCount = _totalAbsent?.length ?? 0;
    final totalCount = _totalMembers?.length ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FA),
        elevation: 0,
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
                  hintText: 'Search members',
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

            const SizedBox(height: 12),

            // Sunday picker chip
            GestureDetector(
              onTap: _showSundayPicker,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFDDE3F0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        size: 16, color: Colors.grey),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _formatSunday(_selectedSunday),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Filter tabs
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  _filterTab('All', totalCount),
                  _filterTab('Present', presentCount),
                  _filterTab('Absent', absentCount),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Member list
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : members.isEmpty
                      ? const Center(
                          child: Text(
                            'No members found',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.separated(
                          itemCount: members.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            return _MemberTile(
                              member: members[index],
                              showStatus: _selectedFilter == 'All',
                              onTap: () =>
                                  _showMemberDrawer(members[index]),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterTab(String label, int count) {
    final isSelected = _selectedFilter == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedFilter = label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFEAF3FF)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$label ($count)',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight:
                  isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected
                  ? const Color(0xFF438FFC)
                  : Colors.black54,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Member row tile ──────────────────────────────────────────────────────────

class _MemberTile extends StatelessWidget {
  final AdminType member;
  final bool showStatus;
  final VoidCallback onTap;

  const _MemberTile({
    required this.member,
    required this.showStatus,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPresent = member.isPresent;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 22,
              backgroundImage: member.imgURL != null
                  ? NetworkImage(member.imgURL!)
                  : null,
              backgroundColor: Colors.grey[200],
              child: member.imgURL == null
                  ? Text(
                      member.name.isNotEmpty
                          ? member.name[0].toUpperCase()
                          : '?',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            // Name
            Expanded(
              child: Text(
                member.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
            // Status badge (only on "All" tab)
            if (showStatus)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isPresent
                      ? const Color(0xFFE6F9F0)
                      : const Color(0xFFFFEDED),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isPresent ? 'Present' : 'Absent',
                  style: TextStyle(
                    color: isPresent
                        ? const Color(0xFF2ECC71)
                        : const Color(0xFFE74C3C),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Member detail drawer ─────────────────────────────────────────────────────

class _MemberDetailDrawer extends StatelessWidget {
  final AdminType member;

  const _MemberDetailDrawer({required this.member});

  @override
  Widget build(BuildContext context) {
    final isPresent = member.isPresent;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          // Avatar
          CircleAvatar(
            radius: 36,
            backgroundImage: member.imgURL != null
                ? NetworkImage(member.imgURL!)
                : null,
            backgroundColor: Colors.grey[200],
            child: member.imgURL == null
                ? Text(
                    member.name.isNotEmpty
                        ? member.name[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                        fontSize: 28, fontWeight: FontWeight.bold),
                  )
                : null,
          ),
          const SizedBox(height: 12),
          Text(
            member.name,
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: isPresent
                  ? const Color(0xFFE6F9F0)
                  : const Color(0xFFFFEDED),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isPresent ? 'Present' : 'Absent',
              style: TextStyle(
                color: isPresent
                    ? const Color(0xFF2ECC71)
                    : const Color(0xFFE74C3C),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 12),
          _InfoRow(label: 'Member ID', value: member.id),
          // Placeholder rows — wire up real fields when available
          const SizedBox(height: 8),
          _InfoRow(
            label: 'Check-in method',
            value: isPresent ? 'NFC' : '—',
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF438FFC),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Close',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.grey, fontSize: 14)),
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.w500, fontSize: 14)),
      ],
    );
  }
}

// ── Sunday picker sheet ──────────────────────────────────────────────────────

class _SundayPickerSheet extends StatelessWidget {
  final List<DateTime> sundays;
  final DateTime selected;

  const _SundayPickerSheet(
      {required this.sundays, required this.selected});

  String _format(DateTime d) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return 'Sunday, ${months[d.month]} ${d.day}, ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Select a Sunday',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...sundays.map((sunday) {
            final isSelected = sunday == selected;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.calendar_today,
                color: isSelected ? const Color(0xFF438FFC) : Colors.grey,
                size: 20,
              ),
              title: Text(
                _format(sunday),
                style: TextStyle(
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
                  color:
                      isSelected ? const Color(0xFF438FFC) : null,
                ),
              ),
              trailing: isSelected
                  ? const Icon(Icons.check, color: Color(0xFF438FFC))
                  : null,
              onTap: () => Navigator.pop(context, sunday),
            );
          }),
        ],
      ),
    );
  }
}