import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:auto_size_text/auto_size_text.dart';

class UserPrepPage extends StatefulWidget {
  const UserPrepPage({super.key});

  @override
  State<UserPrepPage> createState() => _UserPrepPageState();
}

class _UserPrepPageState extends State<UserPrepPage> {
  int _currentIndex = 0;

  final List<Map<String, dynamic>> _slides = [
    {
      'icon': Icons.lock_outline,
      'title': 'Your Data is Secure',
      'description':
          'Your facial data is encrypted and stored securely. It is never shared with third parties or used outside of attendance tracking.',
    },
    {
      'icon': Icons.timer_outlined,
      'title': 'Takes Less Than 30 Seconds',
      'description':
          'The registration process is quick and simple. Just look at the camera and we\'ll handle the rest.',
    },
    {
      'icon': Icons.visibility_off_outlined,
      'title': 'Privacy First',
      'description':
          'Only your church administrators can access attendance records. Your facial data is never visible to other members.',
    },
    {
      'icon': Icons.delete_outline,
      'title': 'You\'re in Control',
      'description':
          'You can request to have your facial data deleted at any time by contacting your church administrator.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),

              const Text(
                "Set Up Facial Recognition",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00174B),
                ),
              ),
              const SizedBox(height: 12),

              Text(
                "To take attendance with your face, we need to register your facial data. Don\'t worry, it\'s quick and secure!",
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 25),

              CarouselSlider(
                options: CarouselOptions(
                  height: 280,
                  // This is the equivalent to onScrollIndexChanged
                  onPageChanged: (index, reason) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  viewportFraction:
                      0.82, // Controls how much of the side items are visible
                  enlargeCenterPage: true, // Optional: makes the middle one pop
                ),
                items: _slides.map((slide) => _buildSlide(slide)).toList(),
              ),

              const SizedBox(height: 20),

              // Dot indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_slides.length, (index) {
                  final isActive = index == _currentIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isActive ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFF00174B)
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),

              const Spacer(),

              Center(
                child: Text(
                  "${_currentIndex + 1} of ${_slides.length}",
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),

      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/complete-signup');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00174B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    "I Understand, Continue",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // TextButton(
              //   onPressed: () => Navigator.pop(context),
              //   child: Text(
              //     "I'd rather not do this",
              //     style: TextStyle(
              //       fontSize: 14,
              //       color: Colors.grey.shade500,
              //     ),
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSlide(Map<String, dynamic> slide) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD0DAF5)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF00174B).withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              slide['icon'] as IconData,
              size: 40,
              color: const Color(0xFF00174B),
            ),
          ),
          const SizedBox(height: 10),
          AutoSizeText(
            slide['title'] as String,
            textAlign: TextAlign.center,
            minFontSize: 18,
            maxFontSize: 30,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF00174B),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: AutoSizeText(
              slide['description'] as String,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 30),
              minFontSize: 11,
              maxFontSize: 14,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
