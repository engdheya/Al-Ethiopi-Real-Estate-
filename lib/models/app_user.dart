import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Firestore `users/{uid}` document.
class AppUser extends Equatable {
  const AppUser({
    required this.uid,
    required this.displayName,
    required this.email,
    this.photoUrl,
    this.createdAt,
    this.lastSeenAt,
  });

  final String uid;
  final String displayName;
  final String email;
  final String? photoUrl;
  final DateTime? createdAt;
  final DateTime? lastSeenAt;

  static DateTime? _toDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return null;
  }

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    return AppUser(
      uid: uid,
      displayName: (map['displayName'] as String? ?? '').trim(),
      email: (map['email'] as String? ?? '').trim(),
      photoUrl: map['photoUrl'] as String?,
      createdAt: _toDate(map['createdAt']),
      lastSeenAt: _toDate(map['lastSeenAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'displayName': displayName,
      'email': email,
      'photoUrl': photoUrl,
      'createdAt':
          createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'lastSeenAt': FieldValue.serverTimestamp(),
    };
  }

  AppUser copyWith({
    String? displayName,
    String? email,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? lastSeenAt,
  }) {
    return AppUser(
      uid: uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
    );
  }

  @override
  List<Object?> get props =>
      <Object?>[uid, displayName, email, photoUrl, createdAt, lastSeenAt];
}
