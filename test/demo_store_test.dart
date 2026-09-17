import 'package:al_ethiopi_real_estate/demo/demo_store.dart';
import 'package:al_ethiopi_real_estate/models/comment.dart';
import 'package:al_ethiopi_real_estate/models/property.dart';
import 'package:al_ethiopi_real_estate/models/property_filter.dart';
import 'package:al_ethiopi_real_estate/models/property_page.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    DemoStore.enabled = true;
    DemoStore.instance.reset();
  });

  test('seed data is populated', () {
    final DemoStore store = DemoStore.instance;
    expect(store.properties.length, greaterThanOrEqualTo(10));
    expect(store.cities.length, greaterThanOrEqualTo(8));
    expect(store.areas.length, greaterThan(10));
    expect(store.types.length, 8);
    expect(store.features.length, greaterThanOrEqualTo(10));
    expect(store.comments, isNotEmpty);
  });

  test('fetchProperties filters + sorts', () async {
    final DemoStore store = DemoStore.instance;
    final PropertyPage page = await store.fetchProperties(
      filter: const PropertyFilter(
        purpose: PropertyPurpose.rent,
        sort: PropertySort.priceAsc,
      ),
      limit: 20,
    );
    expect(page.items, isNotEmpty);
    expect(
      page.items.every((Property p) => p.purpose == PropertyPurpose.rent),
      isTrue,
    );
    for (int i = 1; i < page.items.length; i++) {
      expect(
        page.items[i].price >= page.items[i - 1].price,
        isTrue,
      );
    }
  });

  test('fetchProperties search query matches arabic text', () async {
    final DemoStore store = DemoStore.instance;
    final PropertyPage page = await store.fetchProperties(
      filter: const PropertyFilter(query: 'حدة'),
      limit: 20,
    );
    expect(page.items, isNotEmpty);
    expect(
      page.items.every(
        (Property p) =>
            '${p.title} ${p.areaName}'.contains('حدة'),
      ),
      isTrue,
    );
  });

  test('unpublished properties are hidden from public fetch', () async {
    final DemoStore store = DemoStore.instance;
    final PropertyPage page = await store.fetchProperties(
      filter: const PropertyFilter(),
      limit: 50,
    );
    expect(
      page.items.every((Property p) => p.isPublished),
      isTrue,
    );
    final PropertyPage admin =
        await store.fetchAdminPage(limit: 50);
    expect(admin.items.length, greaterThan(page.items.length));
  });

  test('comments + likes round trip', () async {
    final DemoStore store = DemoStore.instance;
    final int before = store.comments.length;
    final String id = await store.addComment(
      const PropertyComment(
        id: '',
        propertyId: 'demo-p1',
        userId: 'u1',
        userName: 'مستخدم',
        text: 'تعليق تجريبي',
        rating: 5,
      ),
    );
    expect(store.comments.length, before + 1);
    store.toggleCommentLike(id, 'u2');
    expect(
      store.comments
          .firstWhere((PropertyComment c) => c.id == id)
          .likeCount,
      1,
    );
    final Property? p = store.findProperty('demo-p1');
    expect(p?.commentsCount, greaterThan(0));
  });

  test('ratings recompute property aggregates', () {
    final DemoStore store = DemoStore.instance;
    store.submitRating(
      propertyId: 'demo-p4',
      uid: 'u-test',
      value: 5,
    );
    final Property? p = store.findProperty('demo-p4');
    expect(p, isNotNull);
    expect(p!.ratingCount, greaterThan(0));
    expect(p.ratingAvg, greaterThan(0));
  });

  test('demo admin login grants admin session', () async {
    final DemoStore store = DemoStore.instance;
    await store.demoSignIn(email: 'admin@alethiopi.com');
    expect(store.isAdminSession, isTrue);
    await store.demoSignOut();
    expect(store.currentUser, isNull);
    expect(store.isAdminSession, isFalse);
  });
}
