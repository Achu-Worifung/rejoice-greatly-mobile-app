import 'package:flutter/material.dart';

import '../theme/church_colors.dart';

/// A single shimmering placeholder block. Warm-tinted to sit naturally on the
/// cream/white surfaces. Honors reduced-motion (renders a static fill).
class Skeleton extends StatefulWidget {
  const Skeleton({
    super.key,
    this.width,
    this.height = 14,
    this.radius = 8,
    this.shape = BoxShape.rectangle,
  });

  final double? width;
  final double height;
  final double radius;
  final BoxShape shape;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  static const Color _base = Color(0xFFEDE4D6); // warm sand
  static const Color _highlight = Color(0xFFF8F2E8);

  late final AnimationController _c;
  bool _animate = true;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _animate = !MediaQuery.of(context).disableAnimations;
    if (_animate && !_c.isAnimating) {
      _c.repeat();
    } else if (!_animate && _c.isAnimating) {
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCircle = widget.shape == BoxShape.circle;
    final borderRadius =
        isCircle ? null : BorderRadius.circular(widget.radius);

    if (!_animate) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: _base,
          shape: widget.shape,
          borderRadius: borderRadius,
        ),
      );
    }

    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final dx = -1.0 + 2.0 * _c.value;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            shape: widget.shape,
            borderRadius: borderRadius,
            gradient: LinearGradient(
              colors: const [_base, _highlight, _base],
              stops: const [0.35, 0.5, 0.65],
              begin: Alignment(dx - 0.3, 0),
              end: Alignment(dx + 0.3, 0),
            ),
          ),
        );
      },
    );
  }
}

/// Card-shaped skeleton matching the app's list rows: thumbnail + two lines.
class SkeletonRowCard extends StatelessWidget {
  const SkeletonRowCard({super.key, this.thumbSize = 72});

  final double thumbSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: ChurchColors.cardDecoration(shadow: const []),
      child: Row(
        children: [
          Skeleton(width: thumbSize, height: thumbSize, radius: 12),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                Skeleton(height: 15, radius: 6),
                SizedBox(height: 10),
                Skeleton(width: 120, height: 12, radius: 6),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A vertical stack of [SkeletonRowCard]s for full-list loading states.
class SkeletonList extends StatelessWidget {
  const SkeletonList({
    super.key,
    this.count = 5,
    this.thumbSize = 76,
    this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 32),
  });

  final int count;
  final double thumbSize;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: padding,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) => SkeletonRowCard(thumbSize: thumbSize),
    );
  }
}
