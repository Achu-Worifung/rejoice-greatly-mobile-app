import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/church_colors.dart';

class WorshipWithUsCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const WorshipWithUsCard({super.key, required this.data});

  // ── Directions ──────────────────────────────────────────────────────────────
  Future<void> _openDirections(BuildContext context) async {
    final address = data['address'] as String? ?? '';
    if (address.isEmpty) return;

    final encodedAddress = Uri.encodeComponent(address);

    Uri uri;
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      // Apple Maps: daddr = destination address
      uri = Uri.parse('https://maps.apple.com/?daddr=$encodedAddress');
    } else {
      // Android: geo intent or google maps url
      // Use the google maps web URL which Android intercepts perfectly
      uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$encodedAddress',
      );
    }

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $uri';
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: Could not open maps.')));
      }
    }
  }

  // ── Share ────────────────────────────────────────────────────────────────────
  Future<void> _shareChurch(BuildContext context) async {
    final name = data['name'] as String? ?? 'Our Church';
    final address = data['address'] as String? ?? '';
    final times = data['serviceTimes'] as String? ?? '';

    final mapsLink =
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}';
    final message = [
      'Join us for worship at $name!',
      if (address.isNotEmpty) '📍 $address',
      if (times.isNotEmpty) '🕐 $times',
      mapsLink,
    ].join('\n');

    try {
      await Share.shareUri(Uri.parse(mapsLink)); // fallback if text share fails
    } catch (_) {
      // share plain text if shareUri isn't supported
      try {
        await Share.share(message, subject: 'Worship with us at $name');
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open share sheet. Please try again.'),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel(label: 'WORSHIP WITH US'),
        const SizedBox(height: 10),

        Container(
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: ChurchColors.cardDecoration(
            color: ChurchColors.card,
            shadow: [
              BoxShadow(
                color: const Color(0xFF633A02).withValues(alpha: 0.07),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => _openDirections(context),
                child: const _MapPlaceholder(),
              ),
              Container(height: 3, color: ChurchColors.button),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                child: Column(
                  children: [
                    _InfoRow(
                      icon: Icons.church_outlined,
                      label: 'CHURCH',
                      value: data['name'] ?? '',
                    ),
                    const _RowDivider(),
                    _InfoRow(
                      icon: Icons.location_on_outlined,
                      label: 'ADDRESS',
                      value: data['address'] ?? '',
                    ),
                    const _RowDivider(),
                    _InfoRow(
                      icon: Icons.access_time_rounded,
                      label: 'SERVICE TIMES',
                      value: data['serviceTimes'] ?? '',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _PrimaryButton(
                label: 'GET DIRECTIONS',
                icon: Icons.directions_outlined,
                onTap: () => _openDirections(context),
              ),
            ),
            const SizedBox(width: 8),
            _IconOutlineButton(
              icon: Icons.share_outlined,
              onTap: () => _shareChurch(context),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: ChurchColors.button,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: ChurchColors.accent,
            letterSpacing: 1.8,
          ),
        ),
      ],
    );
  }
}

class _MapPlaceholder extends StatelessWidget {
  const _MapPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 160,
          width: double.infinity,
          color: ChurchColors.card,
          child: CustomPaint(painter: _MapGridPainter()),
        ),
        const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 20),
              Icon(Icons.location_pin, size: 36, color: ChurchColors.accent),
              SizedBox(height: 4),
              Text(
                'TAP FOR MAP',
                style: TextStyle(
                  fontSize: 9,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w700,
                  color: ChurchColors.accent,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = ChurchColors.button.withValues(alpha: 0.08)
      ..strokeWidth = 1;

    const step = 24.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    final roadPaint = Paint()
      ..color = ChurchColors.button.withValues(alpha: 0.15)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(size.width * 0.2, 0),
      Offset(size.width * 0.35, size.height),
      roadPaint,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.45),
      Offset(size.width, size.height * 0.6),
      roadPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.6, 0),
      Offset(size.width * 0.7, size.height),
      roadPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: ChurchColors.button.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: ChurchColors.accent),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF6B6B6B),
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF1A1A1A),
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 14),
      child: Divider(height: 1, color: Color(0xFFF0F0F0)),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: ChurchColors.button,
          foregroundColor: ChurchColors.buttonText,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

class _IconOutlineButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconOutlineButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      width: 52,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: ChurchColors.button,
          side: const BorderSide(color: ChurchColors.button, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: EdgeInsets.zero,
        ),
        child: Icon(icon, size: 20),
      ),
    );
  }
}
