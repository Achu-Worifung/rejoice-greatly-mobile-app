import 'package:flutter/material.dart';
import '../dataobject/admin-type.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

class OverviewWidget extends StatefulWidget {
  const OverviewWidget({super.key});

  @override
  State<OverviewWidget> createState() => _OverviewWidgetState();
}

class _OverviewWidgetState extends State<OverviewWidget> {
  List<AdminType>? _totalPresent;
  List<AdminType>? _totalAbsent;
  List<AdminType>? _totalMembers;
  Map<DateTime, int>? _attendanceRateByMonth;
  int? _attendanceRate;

  late DateTime _selectedSunday;

  @override
  void initState() {
    super.initState();
    _selectedSunday = _mostRecentSunday(DateTime.now());
    _loadData();
  }

  DateTime _mostRecentSunday(DateTime from) {
    final daysBack = from.weekday % 7; // Sunday = 0 in DateTime (weekday 7)
    return DateTime(from.year, from.month, from.day)
        .subtract(Duration(days: daysBack == 0 ? 0 : from.weekday));
  }

  List<DateTime> _pastSundays({int count = 8}) {
    final sundays = <DateTime>[];
    DateTime current = _mostRecentSunday(DateTime.now());
    for (int i = 0; i < count; i++) {
      sundays.add(current);
      current = current.subtract(const Duration(days: 7));
    }
    return sundays;
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final Uri uri = Uri.parse("http://localhost:8080/admin/overview");

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
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        setState(() {
          _totalPresent = List<AdminType>.from(
            responseData['totalPresent'].map((x) => AdminType.fromJson(x)),
          );
          _totalAbsent = List<AdminType>.from(
            responseData['totalAbsent'].map((x) => AdminType.fromJson(x)),
          );
          _totalMembers = List<AdminType>.from(
            responseData['totalMemberDTOs'].map((x) => AdminType.fromJson(x)),
          );
          _attendanceRateByMonth = Map<DateTime, int>.fromEntries(
            (responseData['attendanceRateByMonth'] as Map<String, dynamic>)
                .entries
                .map((e) => MapEntry(DateTime.parse(e.key), e.value as int)),
          );
          _attendanceRate = responseData['attendanceRate'];
        });
      } else {
        print("Server error: ${response.statusCode}");
      }
    } catch (e) {
      print("Error loading data: $e");
    }
  }


  Future<void> _showDatePicker() async {
    final sundays = _pastSundays();
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
    final bool isLoading = _totalPresent == null;
    final int presentCount = _totalPresent?.length ?? 0;
    final int absentCount = _totalAbsent?.length ?? 0;
    final int totalCount = _totalMembers?.length ?? 0;
    final int rate = _attendanceRate ?? 0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
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
            Row(
              children: [
                IconButton(
                  onPressed: _showDatePicker,
                  icon: const Icon(Icons.calendar_month, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Selected date chip
        GestureDetector(
          onTap: _showDatePicker,
          child: Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_drop_down,
                        size: 16, color: Colors.blue[700]),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(_selectedSunday),
                      style: TextStyle(
                          fontSize: 13, color: Colors.blue[700]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Stats card
        Card(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Today's Attendance",
                  style:
                      TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
                ),
                const SizedBox(height: 12),
                if (isLoading)
                  const Center(child: CircularProgressIndicator())
                else
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
                        value: '$presentCount',
                      ),
                      _buildStatCard(
                        icon: Icons.person_off,
                        iconColor: Colors.red,
                        title: 'Absent',
                        value: '$absentCount',
                      ),
                      _buildStatCard(
                        icon: Icons.people,
                        iconColor: Colors.blue,
                        title: 'Total Members',
                        value: '$totalCount',
                      ),
                      _buildStatCard(
                        icon: Icons.show_chart,
                        iconColor: Colors.blue,
                        title: 'Attendance Rate',
                        value: '$rate%',
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Attendance trend chart
        if (!isLoading && _attendanceRateByMonth != null) ...[
          RichText(
            text: const TextSpan(
              text: 'Attendance Trend ',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              children: [
                TextSpan(
                  text: '(By Month)',
                  style: TextStyle(
                    color: Color(0xFF438FFC),
                    fontWeight: FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 200,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 2))
              ],
            ),
            child: _AttendanceChart(data: _attendanceRateByMonth!),
          ),
          const SizedBox(height: 16),
        ],

        // Attendance rate bar
        if (!isLoading) ...[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF3FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Attendance Rate',
                  style:
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                Stack(
                  children: [
                    Container(
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFBDD9FF),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: rate / 100,
                      child: Container(
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFF438FFC),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$rate%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],


      ],
    );
  }

  String _formatDate(DateTime d) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return 'Sunday, ${months[d.month]} ${d.day}, ${d.year}';
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style:
                      const TextStyle(fontSize: 12, color: Colors.black54),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Text(
            value,
            style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ],
      ),
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
    return '${months[d.month]} ${d.day}, ${d.year}';
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
            style:
                TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...sundays.map((sunday) {
            final isSelected = sunday == selected;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.calendar_today,
                color:
                    isSelected ? const Color(0xFF438FFC) : Colors.grey,
                size: 20,
              ),
              title: Text(
                _format(sunday),
                style: TextStyle(
                  fontWeight: isSelected
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: isSelected
                      ? const Color(0xFF438FFC)
                      : null,
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

// ── Attendance chart ─────────────────────────────────────────────────────────

class _AttendanceChart extends StatelessWidget {
  final Map<DateTime, int> data;

  const _AttendanceChart({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('No data'));
    }

    final sorted = data.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    final chartData = sorted
        .map((e) => {
              'label': months[e.key.month],
              'value': e.value / 100.0,
            })
        .toList();

    return Column(
      children: [
        Expanded(
          child: CustomPaint(
            painter: _LineChartPainter(data: chartData),
            size: Size.infinite,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: chartData.map((d) {
            return Text(
              d['label'] as String,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;

  _LineChartPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    final points = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      final x = i * size.width / (data.length - 1);
      final y = size.height - (data[i]['value'] as double) * size.height;
      points.add(Offset(x, y));
    }

    // Filled area
    final fillPath = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      fillPath.lineTo(p.dx, p.dy);
    }
    fillPath
      ..lineTo(points.last.dx, size.height)
      ..lineTo(points.first.dx, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF438FFC).withOpacity(0.4),
          const Color(0xFF438FFC).withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, fillPaint);

    // Line
    final linePaint = Paint()
      ..color = const Color(0xFF438FFC)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      linePath.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(linePath, linePaint);

    // Value labels above dots
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      final pct = ((data[i]['value'] as double) * 100).round();

      // Dot
      canvas.drawCircle(
          p, 5, Paint()..color = const Color(0xFF438FFC));
      canvas.drawCircle(p, 3, Paint()..color = Colors.white);

      // Label
      textPainter.text = TextSpan(
        text: '$pct%',
        style: const TextStyle(fontSize: 10, color: Color(0xFF438FFC)),
      );
      textPainter.layout();
      textPainter.paint(
          canvas,
          Offset(p.dx - textPainter.width / 2,
              p.dy - textPainter.height - 6));
    }

    // Grid lines
    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..strokeWidth = 1;

    for (int i = 1; i <= 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}