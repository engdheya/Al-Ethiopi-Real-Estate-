import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../theme/app_colors.dart';
import '../constants/app_constants.dart';

/// Brand logo mark.
class AppLogoMark extends StatelessWidget {
  const AppLogoMark({super.key, this.size = 56, this.radius = 14});

  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.asset(
        AppConstants.assetLogo,
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );
  }
}

/// Full lockup: mark + Arabic name + English name.
class AppLogoFull extends StatelessWidget {
  const AppLogoFull({
    super.key,
    this.markSize = 88,
    this.titleColor = Colors.white,
    this.subtitleColor = AppColors.goldSoft,
  });

  final double markSize;
  final Color titleColor;
  final Color subtitleColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        AppLogoMark(size: markSize, radius: 22),
        const SizedBox(height: 16),
        Text(
          AppStrings.appName,
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: titleColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          AppStrings.appNameEn,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: subtitleColor,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
