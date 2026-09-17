import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// `users/{uid}/favorites/{propertyId}` document (also cached for guests).
class FavoriteItem extends Equatable {
  const FavoriteItem({required this.propertyId, this.createdAt});

  final String propertyId;
  final DateTime? createdAt;

  static DateTime? _toDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return null;
  }

  factory FavoriteItem.fromMap(String propertyId, Map<String, dynamic> map) {
    return FavoriteItem(
      propertyId: propertyId,
      createdAt: _toDate(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'propertyId': propertyId,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  @override
  List<Object?> get props => <Object?>[propertyId, createdAt];
}
