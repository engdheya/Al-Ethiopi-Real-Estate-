import 'package:al_ethiopi_real_estate/core/utils/keywords.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SearchKeywords.normalize', () {
    test('unifies alef forms and teh marbuta', () {
      expect(SearchKeywords.normalize('شقة'), 'شقه');
      expect(SearchKeywords.normalize('أحمد'), 'احمد');
      expect(SearchKeywords.normalize('إلى'), 'الي');
      expect(SearchKeywords.normalize('مستشفى'), 'مستشفي');
    });

    test('strips diacritics and tatweel', () {
      expect(SearchKeywords.normalize('مُحَمَّد'), 'محمد');
      expect(SearchKeywords.normalize('عــقــار'), 'عقار');
    });
  });

  group('SearchKeywords.build', () {
    test('builds prefix tokens', () {
      final List<String> tokens = SearchKeywords.build(
        title: 'شقة فاخرة',
        cityName: 'صنعاء',
        areaName: 'حدة',
        typeName: 'شقة',
      );
      expect(tokens, contains('شقه'));
      expect(tokens, contains('شق'));
      expect(tokens, contains('صنعا'));
      expect(tokens.length, lessThanOrEqualTo(60));
    });
  });

  group('SearchKeywords.queryTokens', () {
    test('drops single letters', () {
      expect(SearchKeywords.queryTokens('ش'), isEmpty);
      expect(SearchKeywords.queryTokens('شقة حدة'), hasLength(2));
    });
  });
}
