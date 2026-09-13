import 'package:cloud_firestore/cloud_firestore.dart';

import 'property.dart';

/// One page of a paginated property query.
class PropertyPage {
  const PropertyPage({
    required this.items,
    required this.hasMore,
    this.lastDoc,
  });

  final List<Property> items;

  /// Firestore cursor for the next page (`null` in demo mode, where the
  /// cursor is the last item id handled inside [DemoStore]).
  final DocumentSnapshot<Map<String, dynamic>>? lastDoc;
  final bool hasMore;

  /// Last item id — the demo-mode pagination cursor.
  String? get lastId => items.isEmpty ? null : items.last.id;
}

/// Dashboard counters for the admin panel.
class PropertyStats {
  const PropertyStats({
    this.total = 0,
    this.sale = 0,
    this.rent = 0,
    this.featured = 0,
    this.available = 0,
    this.sold = 0,
    this.rented = 0,
  });

  final int total;
  final int sale;
  final int rent;
  final int featured;
  final int available;
  final int sold;
  final int rented;
}
