import 'package:flutter/material.dart';
import 'dart:math';

class ReportsWidget extends StatelessWidget {
  const ReportsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FA),
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: const Text(
          'Reports',
          style: TextStyle(
            color: Color(0xFF011A3E),
            fontWeight: FontWeight.w600,
            fontSize: 24,
          ),
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.calendar_month, color: Colors.black),
                onPressed: () {},
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    '2',
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats row
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _StatItem(
                    icon: Icons.people,
                    label: 'Total Members',
                    value: '245',
                  ),
                  _StatItem(
                    icon: Icons.person,
                    label: 'Present',
                    value: '198',
                  ),
                  _StatItem(
                    icon: Icons.person_off,
                    label: 'Absent',
                    value: '47',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Attendance Trend
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
                    text: '(Last 4 Services)',
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

            // Chart
            Container(
              height: 200,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const _AttendanceChart(),
            ),

            const SizedBox(height: 24),

            // Attendance Rate
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
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
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
                        widthFactor: 0.80,
                        child: Container(
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFF438FFC),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            '80%',
                            style: TextStyle(
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

            const Spacer(),

            // Export button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.upload_outlined, color: Colors.white),
                label: const Text(
                  'Export Report',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF438FFC),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: const Color(0xFF438FFC)),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ],
    );
  }
}

class _AttendanceChart extends StatelessWidget {
  const _AttendanceChart();

  @override
  Widget build(BuildContext context) {
    final data = [
      {'label': 'Jan 30', 'value': 0.6},
      {'label': 'Feb 6', 'value': 0.75},
      {'label': 'Feb 13', 'value': 0.55},
      {'label': 'Feb 23', 'value': 0.9},
    ];

    return Column(
      children: [
        Expanded(
          child: CustomPaint(
            painter: _LinChartPainter(data: data),
            size: Size.infinite,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: data.map((d) {
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

class _LinChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;

  _LinChartPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    final points = <Offset>[];

    for (int i = 0; i < data.length; i++) {
      final x = i * size.width / (data.length - 1);
      final y = size.height - (data[i]['value'] as double) * size.height;
      points.add(Offset(x, y));
    }

    // Draw filled area
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

    // Draw line
    final linePaint = Paint()
      ..color = const Color(0xFF438FFC)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      linePath.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(linePath, linePaint);

    // Draw dots
    final dotPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    for (final p in points) {
      canvas.drawCircle(p, 4, dotPaint);
    }

    // Draw grid lines
    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..strokeWidth = 1;

    for (int i = 1; i <= 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}