import 'package:al_ethiopi_real_estate/core/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Validators.email', () {
    test('accepts valid emails', () {
      expect(Validators.email('user@example.com'), isNull);
      expect(Validators.email('a.b+1@mail.co'), isNull);
    });

    test('rejects invalid emails', () {
      expect(Validators.email(''), isNotNull);
      expect(Validators.email('plain'), isNotNull);
      expect(Validators.email('a@b'), isNotNull);
      expect(Validators.email(null), isNotNull);
    });
  });

  group('Validators.password', () {
    test('requires at least 6 chars', () {
      expect(Validators.password('123456'), isNull);
      expect(Validators.password('12345'), isNotNull);
      expect(Validators.password(''), isNotNull);
    });

    test('confirm must match', () {
      expect(Validators.confirmPassword('secret1', 'secret1'), isNull);
      expect(
        Validators.confirmPassword('secret1', 'secret2'),
        isNotNull,
      );
    });
  });

  group('Validators.phone', () {
    test('accepts Yemeni local and international numbers', () {
      expect(Validators.phone('771234567'), isNull);
      expect(Validators.phone('0771234567'), isNull);
      expect(Validators.phone('+967771234567'), isNull);
      expect(Validators.phone('967 771 234 567'), isNull);
    });

    test('rejects invalid phones', () {
      expect(Validators.phone(''), isNotNull);
      expect(Validators.phone('123'), isNotNull);
      expect(Validators.phone('abcdefghij'), isNotNull);
    });

    test('allowEmpty flag', () {
      expect(Validators.phone('', allowEmpty: true), isNull);
      expect(Validators.phone(null, allowEmpty: true), isNull);
      expect(Validators.phone('123', allowEmpty: true), isNotNull);
    });
  });

  group('Validators.price / areaSize', () {
    test('accepts positive numbers', () {
      expect(Validators.price('250000'), isNull);
      expect(Validators.price('1,250,000'), isNull);
      expect(Validators.areaSize('180'), isNull);
    });

    test('rejects zero / negative / garbage', () {
      expect(Validators.price('0'), isNotNull);
      expect(Validators.price('-5'), isNotNull);
      expect(Validators.price('abc'), isNotNull);
      expect(Validators.areaSize(''), isNotNull);
    });
  });

  group('Validators.comment', () {
    test('rejects empty comments', () {
      expect(Validators.comment(''), isNotNull);
      expect(Validators.comment('   '), isNotNull);
    });

    test('rejects over-long comments', () {
      expect(Validators.comment('x' * 1001), isNotNull);
      expect(Validators.comment('x' * 1000), isNull);
    });
  });
}
