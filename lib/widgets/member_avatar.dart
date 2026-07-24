import 'package:flutter/material.dart';

import '../theme/church_colors.dart';

/// A member's avatar: their photo when there is one, their initials when there
/// isn't.
///
/// Initials are the standing fallback for everyone — a member who hasn't added
/// a photo yet is greeted by their own name, not a grey silhouette. For members
/// under 18 they are the *only* avatar: no photo of them is ever collected, so
/// [imageUrl] is always null for those accounts.
class MemberAvatar extends StatelessWidget {
  const MemberAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.size = 40,
    this.radius = 20,
  });

  final String name;
  final String? imageUrl;
  final double size;
  final double radius;

  /// Up to two letters: first name and surname when we have both, otherwise the
  /// first letter. Falls back to a warm dot rather than an empty box.
  static String initialsOf(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '';
    String firstLetter(String word) {
      final match = RegExp(r'[A-Za-z]').firstMatch(word);
      return (match?.group(0) ?? word[0]).toUpperCase();
    }

    if (parts.length == 1) return firstLetter(parts.first);
    return firstLetter(parts.first) + firstLetter(parts.last);
  }

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim();
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: size,
        height: size,
        child: url != null && url.isNotEmpty
            ? Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) => _initials(),
              )
            : _initials(),
      ),
    );
  }

  Widget _initials() {
    final initials = initialsOf(name);
    return Container(
      alignment: Alignment.center,
      color: ChurchColors.button.withValues(alpha: 0.12),
      child: initials.isEmpty
          ? Icon(
              Icons.person_rounded,
              size: size * 0.5,
              color: ChurchColors.accent,
            )
          : Text(
              initials,
              style: TextStyle(
                fontSize: size * 0.36,
                fontWeight: FontWeight.w700,
                color: ChurchColors.accent,
                letterSpacing: 0.5,
              ),
            ),
    );
  }
}
