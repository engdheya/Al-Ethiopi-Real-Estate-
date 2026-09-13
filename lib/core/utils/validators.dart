import '../../l10n/app_strings.dart';
import '../constants/app_constants.dart';

/// Form + business validation (Arabic messages).
class Validators {
  Validators._();

  static final RegExp _emailRegex =
      RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

  /// Accepts local Yemeni numbers (e.g. 771234567 / 0771234567) and
  /// international format (+967771234567).
  static final RegExp _phoneRegex = RegExp(r'^\+?[0-9][0-9\s\-()]{6,18}$');

  static String? required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.requiredField;
    }
    return null;
  }

  static String? name(String? value, {int max = AppConstants.maxNameLength}) {
    final String? req = required(value);
    if (req != null) return req;
    if (value!.trim().length > max) return 'الاسم طويل جداً.';
    return null;
  }

  static String? email(String? value) {
    final String? req = required(value);
    if (req != null) return req;
    if (!_emailRegex.hasMatch(value!.trim())) return AppStrings.invalidEmail;
    return null;
  }

  static String? password(String? value) {
    final String? req = required(value);
    if (req != null) return req;
    if (value!.length < 6) return AppStrings.shortPassword;
    return null;
  }

  static String? confirmPassword(String? value, String? original) {
    final String? req = required(value);
    if (req != null) return req;
    if (value != original) return AppStrings.passwordMismatch;
    return null;
  }

  static String? phone(String? value, {bool allowEmpty = false}) {
    if (value == null || value.trim().isEmpty) {
      return allowEmpty ? null : AppStrings.requiredField;
    }
    final String digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (!_phoneRegex.hasMatch(value.trim()) ||
        digits.length < 7 ||
        digits.length > 15) {
      return AppStrings.invalidPhone;
    }
    return null;
  }

  static String? price(String? value) {
    final String? req = required(value);
    if (req != null) return req;
    final double? parsed =
        double.tryParse(value!.trim().replaceAll(',', ''));
    if (parsed == null || parsed <= 0) return AppStrings.invalidPrice;
    return null;
  }

  static String? areaSize(String? value) {
    final String? req = required(value);
    if (req != null) return req;
    final double? parsed =
        double.tryParse(value!.trim().replaceAll(',', ''));
    if (parsed == null || parsed <= 0) return AppStrings.invalidSize;
    return null;
  }

  static String? optionalInt(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final int? parsed = int.tryParse(value.trim());
    if (parsed == null || parsed < 0) return 'أدخل رقماً صالحاً.';
    return null;
  }

  static String? comment(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.commentEmpty;
    }
    if (value.trim().length > AppConstants.maxCommentLength) {
      return AppStrings.commentTooLong;
    }
    return null;
  }

  static String? message(String? value) {
    final String? req = required(value);
    if (req != null) return req;
    if (value!.trim().length > AppConstants.maxMessageLength) {
      return 'الرسالة طويلة جداً.';
    }
    return null;
  }
}
