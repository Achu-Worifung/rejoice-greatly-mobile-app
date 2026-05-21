import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/church_colors.dart';

/// Playing indicator: microphone SVG plus animated “equalizer” bars (SVG-style motion).
class SermonPlayingWaveform extends StatefulWidget {
  const SermonPlayingWaveform({
    super.key,
    this.size = 22,
    this.barCount = 3,
    this.isPlaying = false,
    this.foregroundColor = ChurchColors.button,
  });

  final double size;

  /// Number of animated bars (keep low to avoid row overflow in list tiles).
  final int barCount;

  /// When false, animation stops (e.g. playback completed or paused).
  final bool isPlaying;

  /// Waveform + microphone tint (use [ChurchColors.buttonText] on dark buttons).
  final Color foregroundColor;

  @override
  State<SermonPlayingWaveform> createState() => _SermonPlayingWaveformState();
}

class _SermonPlayingWaveformState extends State<SermonPlayingWaveform>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  void _syncAnimation() {
    if (widget.isPlaying) {
      if (!_controller.isAnimating) {
        _controller.repeat(reverse: true);
      }
    } else {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _syncAnimation();
  }

  @override
  void didUpdateWidget(SermonPlayingWaveform oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isPlaying != widget.isPlaying || oldWidget.barCount != widget.barCount) {
      _syncAnimation();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.barCount.clamp(1, 6);
    final mic = widget.size * 0.42;
    return SizedBox(
      width: widget.size + 4,
      height: widget.size,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SvgPicture.asset(
            'assets/icons/microphone.svg',
            width: mic,
            height: mic,
            colorFilter: ColorFilter.mode(widget.foregroundColor, BlendMode.srcIn),
          ),
          const SizedBox(width: 4),
          ...List.generate(n, (i) {
            return AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final phase = (i * 0.45) + (_controller.value * math.pi * 2);
                final h = widget.size * (0.32 + 0.52 * (0.5 + 0.5 * math.sin(phase)));
                return Padding(
                  padding: const EdgeInsets.only(left: 2),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      width: 2.5,
                      height: h.clamp(5.0, widget.size),
                      decoration: BoxDecoration(
                        color: widget.foregroundColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                );
              },
            );
          }),
        ],
      ),
    );
  }
}
