import 'package:al_ethiopi_real_estate/core/utils/formatters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Formatters.toArabicDigits', () {
    test('converts western digits', () {
      expect(Formatters.toArabicDigits('123'), '١٢٣');
      expect(Formatters.toArabicDigits('Year 2026'), 'Year ٢٠٢٦');
    });
  });

  group('Formatters.formatNumber', () {
    test('groups thousands with Arabic separator', () {
      expect(Formatters.formatNumber(12500000), '١٢٬٥٠٠٬٠٠٠');
      expect(Formatters.formatNumber(950), '٩٥٠');
      expect(Formatters.formatNumber(0), '٠');
    });
  });

  group('Formatters.formatPrice', () {
    test('adds currency labels', () {
      expect(Formatters.formatPrice(250000, 'YER'), '٢٥٠٬٠٠٠ ر.ي');
      expect(Formatters.formatPrice(120000, 'USD'), '١٢٠٬٠٠٠ دولار');
      expect(Formatters.formatPrice(5000, 'SAR'), '٥٬٠٠٠ ر.س');
    });
  });

  group('Formatters.formatArea', () {
    test('appends m2 unit', () {
      expect(Formatters.formatArea(150), '١٥٠ م²');
    });
  });

  group('Formatters.timeAgo', () {
    final DateTime now = DateTime(2026, 9, 13, 12);

    test('moments', () {
      expect(
        Formatters.timeAgo(now.subtract(const Duration(seconds: 5)), now: now),
        'الآن',
      );
    });

    test('arabic plurals', () {
      expect(
        Formatters.timeAgo(now.subtract(const Duration(minutes: 1)), now: now),
        'منذ دقيقة',
      );
      expect(
        Formatters.timeAgo(now.subtract(const Duration(minutes: 2)), now: now),
        'منذ دقيقتين',
      );
      expect(
        Formatters.timeAgo(now.subtract(const Duration(minutes: 5)), now: now),
        'منذ ٥ دقائق',
      );
      expect(
        Formatters.timeAgo(now.subtract(const Duration(hours: 2)), now: now),
        'منذ ساعتين',
      );
      expect(
        Formatters.timeAgo(now.subtract(const Duration(days: 1)), now: now),
        'منذ يوم',
      );
      expect(
        Formatters.timeAgo(now.subtract(const Duration(days: 3)), now: now),
        'منذ ٣ أيام',
      );
    });
  });

  group('Formatters.formatCompactCount', () {
    test('compacts thousands', () {
      expect(Formatters.formatCompactCount(999), '٩٩٩');
      expect(Formatters.formatCompactCount(1500), '١.٥ ألف');
    });
  });
}
