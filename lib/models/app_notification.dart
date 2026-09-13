import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Firestore `notifications/{id}` — admin-written broadcast log.
/// Actual push delivery is performed by the Cloud Function in `functions/`.
class AppNotification extends Equatable {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.propertyId,
    this.imageUrl,
    this.createdAt,
  });

  final String id;
  final String title;
  final String body;
  final String type; // announcement | featured_property
  final String? propertyId;
  final String? imageUrl;
  final DateTime? createdAt;

  static DateTime? _toDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return null;
  }

  factory AppNotification.fromMap(String id, Map<String, dynamic> map) {
    return AppNotification(
      id: id,
      title: (map['title'] as String? ?? '').trim(),
      body: (map['body'] as String? ?? '').trim(),
      type: map['type'] as String? ?? 'announcement',
      propertyId: map['propertyId'] as String?,
      imageUrl: map['imageUrl'] as String?,
      createdAt: _toDate(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap({bool forCreate = false}) {
    final Map<String, dynamic> map = <String, dynamic>{
      'title': title,
      'body': body,
      'type': type,
      'propertyId': propertyId,
      'imageUrl': imageUrl,
    };
    if (forCreate) {
      map['createdAt'] = FieldValue.serverTimestamp();
    }
    return map;
  }

  @override
  List<Object?> get props => <Object?>[id, title, body, type, propertyId];
}
