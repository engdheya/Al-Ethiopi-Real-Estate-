import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Firestore `ratings/{propertyId}_{uid}` — one rating per user per property.
class RatingEntry extends Equatable {
  const RatingEntry({
    required this.id,
    required this.propertyId,
    required this.userId,
    required this.value,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String propertyId;
  final String userId;
  final int value;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  static String docId(String propertyId, String uid) => '${propertyId}_$uid';

  static DateTime? _toDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return null;
  }

  factory RatingEntry.fromMap(String id, Map<String, dynamic> map) {
    return RatingEntry(
      id: id,
      propertyId: map['propertyId'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      value: ((map['value'] as num?) ?? 0).toInt(),
      createdAt: _toDate(map['createdAt']),
      updatedAt: _toDate(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap({bool forCreate = false}) {
    final Map<String, dynamic> map = <String, dynamic>{
      'propertyId': propertyId,
      'userId': userId,
      'value': value,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (forCreate) map['createdAt'] = FieldValue.serverTimestamp();
    return map;
  }

  @override
  List<Object?> get props => <Object?>[id, propertyId, userId, value];
}
