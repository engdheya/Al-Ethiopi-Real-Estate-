import 'package:flutter/material.dart';

/// Brand palette: deep emerald + gold (trust + premium real estate).
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF0B5C38);
  static const Color primaryDark = Color(0xFF08452B);
  static const Color primaryDarker = Color(0xFF06331F);
  static const Color primarySoft = Color(0xFFE7F1EB);

  static const Color gold = Color(0xFFC9A24B);
  static const Color goldDark = Color(0xFFA98634);
  static const Color goldSoft = Color(0xFFF7ECD2);

  static const Color background = Color(0xFFF5F6F8);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF1A1D21);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color border = Color(0xFFE5E7EB);

  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFD97706);
  static const Color error = Color(0xFFDC2626);
  static const Color info = Color(0xFF2563EB);

  // Purpose badges
  static const Color saleBadge = Color(0xFF1D4ED8);
  static const Color rentBadge = Color(0xFFC2410C);

  // Status colors
  static const Color statusAvailable = Color(0xFF16A34A);
  static const Color statusRented = Color(0xFFD97706);
  static const Color statusSold = Color(0xFFDC2626);
  static const Color statusUnavailable = Color(0xFF6B7280);

  static const Color favoriteRed = Color(0xFFE11D48);
  static const Color whatsappGreen = Color(0xFF25D366);

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: <Color>[primaryDarker, primary, Color(0xFF0E7046)],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[Color(0xFFE3C57C), gold],
  );
}
