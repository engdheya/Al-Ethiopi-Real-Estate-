import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_strings.dart';

/// Typed application failure with an Arabic user-facing message.
class AppFailure implements Exception {
  const AppFailure(this.message, [this.code]);

  final String message;
  final String? code;

  @override
  String toString() => 'AppFailure($code): $message';
}

/// Maps technical exceptions (Firebase, platform, network) to friendly
/// Arabic messages for snackbars and error states.
String friendlyErrorMessage(Object error) {
  if (error is AppFailure) return error.message;

  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'network-request-failed':
        return AppStrings.noInternet;
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
      case 'invalid-email':
        return 'بيانات الدخول غير صحيحة.';
      case 'email-already-in-use':
        return 'هذا البريد الإلكتروني مسجل بالفعل.';
      case 'weak-password':
        return AppStrings.shortPassword;
      case 'too-many-requests':
        return 'محاولات كثيرة، حاول مرة أخرى لاحقاً.';
      case 'user-disabled':
        return 'تم تعطيل هذا الحساب، تواصل مع الإدارة.';
      case 'requires-recent-login':
        return 'لأجل الأمان، سجّل الدخول مرة أخرى ثم حاول.';
      case 'operation-not-allowed':
        return 'طريقة الدخول هذه غير مفعّلة حالياً.';
    }
  }

  if (error is FirebaseException) {
    switch (error.code) {
      case 'unavailable':
      case 'network-request-failed':
      case 'deadline-exceeded':
        return AppStrings.noInternet;
      case 'permission-denied':
        return AppStrings.noPermission;
      case 'unauthenticated':
        return AppStrings.loginRequired;
      case 'not-found':
        return 'العنصر المطلوب غير موجود.';
      case 'already-exists':
        return 'هذا العنصر موجود بالفعل.';
      case 'resource-exhausted':
        return 'تم تجاوز الحد المسموح، حاول لاحقاً.';
      case 'cancelled':
        return AppStrings.cancel;
    }
  }

  if (error is PlatformException) {
    if (error.code == 'network_error' ||
        error.code == 'firebase_auth/network-request-failed') {
      return AppStrings.noInternet;
    }
    if (error.code == 'sign_in_canceled' ||
        error.code == 'sign_in_cancelled') {
      return 'تم إلغاء تسجيل الدخول.';
    }
  }

  final String text = error.toString();
  if (text.contains('SocketException') ||
      text.contains('Connection closed') ||
      text.contains('Failed host lookup')) {
    return AppStrings.noInternet;
  }

  return AppStrings.somethingWentWrong;
}
