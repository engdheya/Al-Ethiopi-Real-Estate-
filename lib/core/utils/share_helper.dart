import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../l10n/app_strings.dart';
import '../constants/app_constants.dart';
import 'formatters.dart';

/// Native Android share sheet + copy-link helpers.
///
/// Note: Firebase Dynamic Links was shut down by Google, so sharing uses a
/// descriptive text payload plus the Play Store link instead of deep links.
class ShareHelper {
  ShareHelper._();

  static Future<void> shareProperty({
    required String title,
    required num price,
    required String currency,
    required String cityName,
    required String areaName,
    Rect? sharePositionOrigin,
  }) async {
    final String text = AppStrings.sharePropertyText(
      title: title,
      priceText: Formatters.formatPrice(price, currency),
      location: '$cityName - $areaName',
      playStoreUrl: AppConstants.playStoreUrl,
    );
    await Share.share(
      text,
      subject: title,
      sharePositionOrigin: sharePositionOrigin,
    );
  }

  static Future<void> copyText(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.textCopied)),
      );
    }
  }
}
