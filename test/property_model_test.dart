import 'package:al_ethiopi_real_estate/models/property.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Map<String, dynamic> sampleMap() {
    return <String, dynamic>{
      'title': 'شقة فاخرة للإيجار في حدة',
      'description': 'وصف تجريبي',
      'purpose': 'rent',
      'typeId': 'type-apartment',
      'typeName': 'شقة',
      'cityId': 'city-0',
      'cityName': 'صنعاء',
      'areaId': 'area-0',
      'areaName': 'حدة',
      'address': 'شارع حدة',
      'price': 300000,
      'currency': 'YER',
      'size': 180,
      'bedrooms': 4,
      'bathrooms': 3,
      'floor': 3,
      'status': 'available',
      'isPublished': true,
      'isFeatured': true,
      'images': <Map<String, dynamic>>[
        <String, dynamic>{
          'url': 'https://example.com/1.jpg',
          'path': 'properties/p1/1.jpg',
          'isMain': true,
          'order': 0,
        },
        <String, dynamic>{
          'url': 'https://example.com/2.jpg',
          'path': 'properties/p1/2.jpg',
          'isMain': false,
          'order': 1,
        },
      ],
      'featureIds': <String>['feat-0'],
      'featureNames': <String>['ماء'],
      'phone': '967771234567',
      'whatsapp': '967771234567',
      'ratingAvg': 4.5,
      'ratingCount': 10,
      'favoritesCount': 3,
      'commentsCount': 2,
      'createdAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
      'searchKeywords': <String>['شقه', 'صنعا'],
    };
  }

  test('fromMap parses all fields', () {
    final Property p = Property.fromMap('p1', sampleMap());
    expect(p.id, 'p1');
    expect(p.title, 'شقة فاخرة للإيجار في حدة');
    expect(p.purpose, PropertyPurpose.rent);
    expect(p.status, PropertyStatus.available);
    expect(p.price, 300000);
    expect(p.images, hasLength(2));
    expect(p.mainImage?.url, 'https://example.com/1.jpg');
    expect(p.locationLabel, 'صنعاء - حدة');
    expect(p.isSoldOrRented, isFalse);
    expect(p.createdAt, DateTime(2026, 1, 1));
  });

  test('fromMap tolerates missing / malformed fields', () {
    final Property p = Property.fromMap('x', <String, dynamic>{
      'purpose': 'weird',
      'status': 'weird',
    });
    expect(p.purpose, PropertyPurpose.sale);
    expect(p.status, PropertyStatus.available);
    expect(p.images, isEmpty);
    expect(p.mainImage, isNull);
  });

  test('copyWith preserves aggregates', () {
    final Property p = Property.fromMap('p1', sampleMap());
    final Property next = p.copyWith(title: 'جديد');
    expect(next.title, 'جديد');
    expect(next.ratingAvg, 4.5);
    expect(next.images, hasLength(2));
  });

  test('status helpers', () {
    expect(
      Property.fromMap('a', <String, dynamic>{'status': 'sold'})
          .isSoldOrRented,
      isTrue,
    );
    expect(
      PropertyStatusX.fromValue('rented'),
      PropertyStatus.rented,
    );
    expect(PropertyPurpose.rent.labelAr, 'للإيجار');
  });
}
