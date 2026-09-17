import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Firestore `contact_messages/{id}` — guests may create, admin reads.
class ContactMessage extends Equatable {
  const ContactMessage({
    required this.id,
    required this.name,
    required this.phone,
    required this.message,
    this.userId,
    this.isRead = false,
    this.createdAt,
  });

  final String id;
  final String name;
  final String phone;
  final String message;
  final String? userId;
  final bool isRead;
  final DateTime? createdAt;

  static DateTime? _toDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return null;
  }

  factory ContactMessage.fromMap(String id, Map<String, dynamic> map) {
    return ContactMessage(
      id: id,
      name: (map['name'] as String? ?? '').trim(),
      phone: (map['phone'] as String? ?? '').trim(),
      message: (map['message'] as String? ?? '').trim(),
      userId: map['userId'] as String?,
      isRead: map['isRead'] as bool? ?? false,
      createdAt: _toDate(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap({bool forCreate = false}) {
    final Map<String, dynamic> map = <String, dynamic>{
      'name': name,
      'phone': phone,
      'message': message,
      'userId': userId,
      'isRead': isRead,
    };
    if (forCreate) map['createdAt'] = FieldValue.serverTimestamp();
    return map;
  }

  @override
  List<Object?> get props => <Object?>[id, name, phone, message, isRead];
}
