import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../../theme/app_colors.dart';

/// Image renderer that handles network URLs, local files (demo mode),
/// bundled assets and graceful fallbacks.
class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    super.key,
    this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
  });

  final String? url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    Widget image;
    final String? src = url;
    if (src == null || src.isEmpty) {
      image = Image.asset(
        AppConstants.assetDefaultProperty,
        fit: fit,
        width: width,
        height: height,
      );
    } else if (src.startsWith('http')) {
      image = CachedNetworkImage(
        imageUrl: src,
        fit: fit,
        width: width,
        height: height,
        fadeInDuration: const Duration(milliseconds: 250),
        placeholder: (BuildContext context, String _) =>
            const _ImagePlaceholder(),
        errorWidget: (BuildContext context, String _, dynamic __) =>
            Image.asset(
          AppConstants.assetDefaultProperty,
          fit: fit,
          width: width,
          height: height,
        ),
      );
    } else if (src.startsWith('assets/')) {
      image = Image.asset(src, fit: fit, width: width, height: height);
    } else {
      image = Image.file(
        File(src),
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (BuildContext context, Object _, StackTrace? __) =>
            Image.asset(
          AppConstants.assetDefaultProperty,
          fit: fit,
          width: width,
          height: height,
        ),
      );
    }

    if (width != null || height != null) {
      image = SizedBox(width: width, height: height, child: image);
    }
    if (borderRadius != null) {
      image = ClipRRect(borderRadius: borderRadius!, child: image);
    }
    return image;
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primarySoft,
      alignment: Alignment.center,
      child: const Icon(
        Icons.home_work_outlined,
        color: AppColors.primary,
        size: 40,
      ),
    );
  }
}
