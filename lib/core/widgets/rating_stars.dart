import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../utils/formatters.dart';

/// Read-only star rating display with optional count.
class RatingStars extends StatelessWidget {
  const RatingStars({
    super.key,
    required this.rating,
    this.size = 16,
    this.count,
  });

  final double rating;
  final double size;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final List<Widget> stars = <Widget>[];
    for (int i = 1; i <= 5; i++) {
      IconData icon;
      if (rating >= i - 0.25) {
        icon = Icons.star;
      } else if (rating >= i - 0.75) {
        icon = Icons.star_half;
      } else {
        icon = Icons.star_border;
      }
      stars.add(Icon(icon, size: size, color: AppColors.goldDark));
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ...stars,
        if (rating > 0) ...<Widget>[
          const SizedBox(width: 4),
          Text(
            Formatters.formatRating(rating),
            style: TextStyle(
              fontSize: size * 0.85,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
        ],
        if (count != null && count! > 0) ...<Widget>[
          const SizedBox(width: 4),
          Text(
            '(${Formatters.toArabicDigits(count.toString())})',
            style: TextStyle(
              fontSize: size * 0.8,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ],
    );
  }
}
