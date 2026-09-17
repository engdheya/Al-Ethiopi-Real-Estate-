import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_strings.dart';
import '../constants/app_constants.dart';

/// Phone / WhatsApp / e-mail deep links.
class ContactUtils {
  ContactUtils._();

  /// Strips spaces/dashes and converts local Yemeni numbers to international
  /// format (967XXXXXXXXX) as required by wa.me links.
  static String normalizePhoneForWhatsApp(String raw) {
    String digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('00')) digits = digits.substring(2);
    if (digits.startsWith('0')) digits = digits.substring(1);
    if (!digits.startsWith(AppConstants.yemenCountryCode)) {
      // Assume a local Yemeni mobile number.
      if (digits.length == 9) {
        digits = '${AppConstants.yemenCountryCode}$digits';
      }
    }
    return digits;
  }

  static Future<void> callPhone(BuildContext context, String? phone) async {
    if (phone == null || phone.trim().isEmpty) return;
    final Uri uri = Uri.parse('tel:${phone.trim()}');
    final bool ok =
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      _showError(context);
    }
  }

  static Future<void> openWhatsApp(
    BuildContext context,
    String? phone, {
    String? message,
  }) async {
    if (phone == null || phone.trim().isEmpty) return;
    final String digits = normalizePhoneForWhatsApp(phone);
    final String text = message ?? '';
    final Uri uri = Uri.parse(
      'https://wa.me/$digits${text.isEmpty ? '' : '?text=${Uri.encodeComponent(text)}'}',
    );
    final bool ok =
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      _showError(context);
    }
  }

  static Future<void> sendEmail(
    BuildContext context,
    String? email, {
    String subject = '',
  }) async {
    if (email == null || email.trim().isEmpty) return;
    final Uri uri = Uri.parse(
      'mailto:${email.trim()}?subject=${Uri.encodeComponent(subject)}',
    );
    final bool ok =
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      _showError(context);
    }
  }

  static Future<void> openUrl(BuildContext context, String? url) async {
    if (url == null || url.trim().isEmpty) return;
    String normalized = url.trim();
    if (!normalized.startsWith('http')) normalized = 'https://$normalized';
    final bool ok = await launchUrl(
      Uri.parse(normalized),
      mode: LaunchMode.externalApplication,
    );
    if (!ok && context.mounted) {
      _showError(context);
    }
  }

  static void _showError(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppStrings.somethingWentWrong)),
    );
  }
}
