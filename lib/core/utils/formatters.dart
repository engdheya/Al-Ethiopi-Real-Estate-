import '../constants/app_constants.dart';

/// Arabic formatting helpers (implemented without `intl` on purpose so the
/// project never conflicts with the Flutter SDK's pinned `intl` version).
class Formatters {
  Formatters._();

  static const List<String> _arabicDigits = <String>[
    '٠',
    '١',
    '٢',
    '٣',
    '٤',
    '٥',
    '٦',
    '٧',
    '٨',
    '٩',
  ];

  /// Converts Western digits to Arabic-Indic digits: 123 -> ١٢٣
  static String toArabicDigits(String input) {
    final StringBuffer buffer = StringBuffer();
    for (final int code in input.codeUnits) {
      if (code >= 48 && code <= 57) {
        buffer.write(_arabicDigits[code - 48]);
      } else {
        buffer.writeCharCode(code);
      }
    }
    return buffer.toString();
  }

  /// 12500000 -> ١٢٬٥٠٠٬٠٠٠
  static String formatNumber(num value, {bool arabicDigits = true}) {
    final bool isNegative = value < 0;
    String integer = value.abs().truncate().toString();
    final StringBuffer grouped = StringBuffer();
    int count = 0;
    for (int i = integer.length - 1; i >= 0; i--) {
      grouped.write(integer[i]);
      count++;
      if (count % 3 == 0 && i != 0) grouped.write('٬');
    }
    integer = grouped.toString().split('').reversed.join();
    final String result = isNegative ? '-$integer' : integer;
    return arabicDigits ? toArabicDigits(result) : result;
  }

  static String currencyLabel(String currency) {
    switch (currency) {
      case AppConstants.currencyUSD:
        return 'دولار';
      case AppConstants.currencySAR:
        return 'ر.س';
      case AppConstants.currencyYER:
      default:
        return 'ر.ي';
    }
  }

  /// 250000 YER -> ٢٥٠٬٠٠٠ ر.ي
  static String formatPrice(num price, String currency) {
    return '${formatNumber(price)} ${currencyLabel(currency)}';
  }

  /// 150 -> ١٥٠ م²
  static String formatArea(num size) {
    final String value =
        size.truncateToDouble() == size ? formatNumber(size) : '$size';
    return '$value ${AppStringsSizeUnit.unit}';
  }

  /// 2026-09-13 -> ٢٠٢٦/٠٩/١٣
  static String formatDate(DateTime date) {
    String two(int n) => n.toString().padLeft(2, '0');
    return toArabicDigits('${date.year}/${two(date.month)}/${two(date.day)}');
  }

  /// "منذ ساعتين", "منذ ٣ أيام" ...
  static String timeAgo(DateTime date, {DateTime? now}) {
    final DateTime current = now ?? DateTime.now();
    Duration diff = current.difference(date);
    if (diff.isNegative) diff = Duration.zero;

    if (diff.inSeconds < 60) return 'الآن';
    if (diff.inMinutes < 60) {
      return 'منذ ${_arabicPlural(
        diff.inMinutes,
        one: 'دقيقة',
        two: 'دقيقتين',
        few: 'دقائق',
        many: 'دقيقة',
      )}';
    }
    if (diff.inHours < 24) {
      return 'منذ ${_arabicPlural(
        diff.inHours,
        one: 'ساعة',
        two: 'ساعتين',
        few: 'ساعات',
        many: 'ساعة',
      )}';
    }
    if (diff.inDays < 7) {
      return 'منذ ${_arabicPlural(
        diff.inDays,
        one: 'يوم',
        two: 'يومين',
        few: 'أيام',
        many: 'يوماً',
      )}';
    }
    final int weeks = diff.inDays ~/ 7;
    if (weeks < 5) {
      return 'منذ ${_arabicPlural(
        weeks,
        one: 'أسبوع',
        two: 'أسبوعين',
        few: 'أسابيع',
        many: 'أسبوعاً',
      )}';
    }
    final int months = diff.inDays ~/ 30;
    if (months < 12) {
      return 'منذ ${_arabicPlural(
        months,
        one: 'شهر',
        two: 'شهرين',
        few: 'أشهر',
        many: 'شهراً',
      )}';
    }
    final int years = diff.inDays ~/ 365;
    return 'منذ ${_arabicPlural(
      years,
      one: 'سنة',
      two: 'سنتين',
      few: 'سنوات',
      many: 'سنة',
    )}';
  }

  static String _arabicPlural(
    int n, {
    required String one,
    required String two,
    required String few,
    required String many,
  }) {
    if (n <= 1) return one;
    if (n == 2) return two;
    if (n >= 3 && n <= 10) return '${toArabicDigits(n.toString())} $few';
    return '${toArabicDigits(n.toString())} $many';
  }

  /// 4.5 -> ٤.٥
  static String formatRating(double rating) {
    final String fixed =
        rating.truncateToDouble() == rating ? rating.toStringAsFixed(0) : rating.toStringAsFixed(1);
    return toArabicDigits(fixed);
  }

  /// Compact count: 1500 -> ١.٥ ألف
  static String formatCompactCount(int count) {
    if (count < 1000) return toArabicDigits(count.toString());
    if (count < 1000000) {
      final double v = count / 1000;
      final String s = v.truncateToDouble() == v
          ? v.toStringAsFixed(0)
          : v.toStringAsFixed(1);
      return '${toArabicDigits(s)} ألف';
    }
    final double v = count / 1000000;
    return '${toArabicDigits(v.toStringAsFixed(1))} مليون';
  }
}

/// Keeps the m² unit next to the formatter to avoid scattering literals.
class AppStringsSizeUnit {
  AppStringsSizeUnit._();
  static const String unit = 'م²';
}
