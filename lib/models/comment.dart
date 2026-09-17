import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Firestore `comments/{id}` document.
class PropertyComment extends Equatable {
  const PropertyComment({
    required this.id,
    required this.propertyId,
    required this.userId,
    required this.userName,
    required this.text,
    this.userPhotoUrl,
    this.rating = 0,
    this.likedBy = const <String>[],
    this.isHidden = false,
    this.reportCount = 0,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String propertyId;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final String text;
  final int rating;
  final List<String> likedBy;
  final bool isHidden;
  final int reportCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  int get likeCount => likedBy.length;

  bool isLikedBy(String? uid) => uid != null && likedBy.contains(uid);

  static DateTime? _toDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return null;
  }

  factory PropertyComment.fromMap(String id, Map<String, dynamic> map) {
    return PropertyComment(
      id: id,
      propertyId: map['propertyId'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      userName: (map['userName'] as String? ?? '').trim(),
      userPhotoUrl: map['userPhotoUrl'] as String?,
      text: (map['text'] as String? ?? '').trim(),
      rating: ((map['rating'] as num?) ?? 0).toInt(),
      likedBy: (map['likedBy'] as List?)
              ?.map((dynamic e) => e.toString())
              .toList() ??
          const <String>[],
      isHidden: map['isHidden'] as bool? ?? false,
      reportCount: ((map['reportCount'] as num?) ?? 0).toInt(),
      createdAt: _toDate(map['createdAt']),
      updatedAt: _toDate(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap({bool forCreate = false}) {
    final Map<String, dynamic> map = <String, dynamic>{
      'propertyId': propertyId,
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'text': text,
      'rating': rating,
      'likedBy': likedBy,
      'isHidden': isHidden,
      'reportCount': reportCount,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (forCreate) map['createdAt'] = FieldValue.serverTimestamp();
    return map;
  }

  PropertyComment copyWith({
    String? text,
    int? rating,
    List<String>? likedBy,
    bool? isHidden,
    String? userName,
    String? userPhotoUrl,
  }) {
    return PropertyComment(
      id: id,
      propertyId: propertyId,
      userId: userId,
      userName: userName ?? this.userName,
      userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
      text: text ?? this.text,
      rating: rating ?? this.rating,
      likedBy: likedBy ?? this.likedBy,
      isHidden: isHidden ?? this.isHidden,
      reportCount: reportCount,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        id,
        propertyId,
        userId,
        userName,
        text,
        rating,
        likedBy,
        isHidden,
        reportCount,
      ];
}
