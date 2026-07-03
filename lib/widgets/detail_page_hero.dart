import 'package:flutter/material.dart';

import '../theme/church_colors.dart';

/// Hero image (natural height, max half screen) + back affordance for detail screens.
class DetailPageHeroHeader extends StatelessWidget {
  const DetailPageHeroHeader({
    super.key,
    required this.imageUrl,
    required this.onBack,
    this.placeholderIcon = Icons.image_outlined,
  });

  final String? imageUrl;
  final VoidCallback onBack;
  final IconData placeholderIcon;

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.5;
    final topInset = MediaQuery.paddingOf(context).top;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        DetailHeroImage(
          imageUrl: imageUrl,
          maxHeight: maxHeight,
          placeholderIcon: placeholderIcon,
        ),
        Positioned(
          top: topInset + 8,
          left: 12,
          child: DetailBackOverlayButton(onPressed: onBack),
        ),
      ],
    );
  }
}

class DetailHeroImage extends StatefulWidget {
  const DetailHeroImage({
    super.key,
    required this.imageUrl,
    required this.maxHeight,
    this.placeholderIcon = Icons.image_outlined,
  });

  final String? imageUrl;
  final double maxHeight;
  final IconData placeholderIcon;

  @override
  State<DetailHeroImage> createState() => _DetailHeroImageState();
}

class _DetailHeroImageState extends State<DetailHeroImage> {
  static const double _placeholderHeight = 160;

  double? _aspectRatio;
  ImageStream? _imageStream;
  ImageStreamListener? _imageListener;

  @override
  void initState() {
    super.initState();
    _resolveAspectRatio();
  }

  @override
  void didUpdateWidget(DetailHeroImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _clearImageStream();
      _aspectRatio = null;
      _resolveAspectRatio();
    }
  }

  @override
  void dispose() {
    _clearImageStream();
    super.dispose();
  }

  void _clearImageStream() {
    if (_imageStream != null && _imageListener != null) {
      _imageStream!.removeListener(_imageListener!);
    }
    _imageStream = null;
    _imageListener = null;
  }

  void _resolveAspectRatio() {
    final url = widget.imageUrl;
    if (url == null || url.isEmpty) return;

    final provider = NetworkImage(url);
    final stream = provider.resolve(const ImageConfiguration());
    final listener = ImageStreamListener((ImageInfo info, bool _) {
      final w = info.image.width.toDouble();
      final h = info.image.height.toDouble();
      if (!mounted || h <= 0) return;
      setState(() => _aspectRatio = w / h);
    });
    stream.addListener(listener);
    _imageStream = stream;
    _imageListener = listener;
  }

  ({double width, double height}) _layoutSize(double screenWidth) {
    final aspect = _aspectRatio;
    if (aspect == null || aspect <= 0) {
      return (width: screenWidth, height: _placeholderHeight);
    }

    final naturalHeight = screenWidth / aspect;
    if (naturalHeight <= widget.maxHeight) {
      return (width: screenWidth, height: naturalHeight);
    }

    final height = widget.maxHeight;
    return (width: height * aspect, height: height);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final url = widget.imageUrl;

    if (url == null || url.isEmpty) {
      return SizedBox(
        width: screenWidth,
        height: _placeholderHeight,
        child: ColoredBox(
          color: ChurchColors.card,
          child: _placeholder(),
        ),
      );
    }

    if (_aspectRatio == null) {
      return SizedBox(
        width: screenWidth,
        height: _placeholderHeight,
        child: const ColoredBox(
          color: ChurchColors.card,
          child: Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: ChurchColors.accent,
              ),
            ),
          ),
        ),
      );
    }

    final size = _layoutSize(screenWidth);

    return SizedBox(
      width: screenWidth,
      height: size.height,
      child: ColoredBox(
        color: ChurchColors.card,
        child: Center(
          child: Image.network(
            url,
            width: size.width,
            height: size.height,
            fit: BoxFit.contain,
            alignment: Alignment.center,
            errorBuilder: (c, e, s) => _placeholder(),
          ),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Center(
      child: Icon(widget.placeholderIcon, size: 64, color: ChurchColors.muted),
    );
  }
}

class DetailBackOverlayButton extends StatelessWidget {
  const DetailBackOverlayButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.4),
      color: Colors.black.withValues(alpha: 0.45),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: IconButton(
        onPressed: onPressed,
        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
        tooltip: 'Back',
      ),
    );
  }
}

/// Category chip under the title on event/sermon detail pages.
class DetailCategoryChip extends StatelessWidget {
  const DetailCategoryChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: ChurchColors.button.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: ChurchColors.accent,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

/// Icon + text row under the title block on detail pages.
class DetailInfoRow extends StatelessWidget {
  const DetailInfoRow({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: ChurchColors.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: ChurchColors.bodyText,
                fontSize: 16,
                height: 1.35,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
