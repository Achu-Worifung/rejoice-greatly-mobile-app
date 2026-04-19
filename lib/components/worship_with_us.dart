import 'package:flutter/material.dart';

class WorshipWithUsCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const WorshipWithUsCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Title OUTSIDE
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'WORSHIP WITH US',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFFD27E09),
              letterSpacing: 1.2,
            ),
          ),
        ),

        // 2. The Card (Flat white box, square edges)
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.zero,
          ),
          child: Column(
            children: [
              // Simple Map Placeholder (Full width, no border)
              Container(
                height: 150,
                width: double.infinity,
                color: const Color(0xFFD27E09).withOpacity(0.05),
                child: Center(
                  child: Icon(
                    Icons.map_outlined,
                    size: 40,
                    color: const Color(0xFFD27E09).withOpacity(0.4),
                  ),
                ),
              ),
              
              // Church Info Details
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildCompactRow(Icons.church, data['name']),
                    const SizedBox(height: 12),
                    _buildCompactRow(Icons.location_on_outlined, data['address']),
                    const SizedBox(height: 12),
                    _buildCompactRow(Icons.access_time, data['serviceTimes']),
                  ],
                ),
              ),
            ],
          ),
        ),

        // 3. Action Buttons OUTSIDE
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 40,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD27E09),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                  ),
                  child: const Text('GET DIRECTIONS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 40,
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFD27E09),
                  side: const BorderSide(color: Color(0xFFD27E09)),
                  // shape: const RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
                ),
                child: const Icon(Icons.share, size: 20),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompactRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFFD27E09)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}