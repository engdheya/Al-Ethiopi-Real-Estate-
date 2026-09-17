import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Firestore `reports/{id}` — user reports against comments.
class CommentReport extends Equatable {
  const CommentReport({
    required this.id,
    required this.commentId,
    required this.propertyId,
    required this.reporterId,
    required this.reason,
    required this.status,
    this.details,
    this.commentText,
    this.createdAt,
  });

  final String id;
  final String commentId;
  final String propertyId;
  final String reporterId;
  final String reason;
  final String details;
  final String? commentText;
  final String status; // pending | reviewed | dismissed
  final DateTime? createdAt;

  bool get isPending => status == 'pending';

  static DateTime? _toDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return null;
  }

  factory CommentReport.fromMap(String id, Map<String, dynamic> map) {
    return CommentReport(
      id: id,
      commentId: map['commentId'] as String? ?? '',
      propertyId: map['propertyId'] as String? ?? '',
      reporterId: map['reporterId'] as String? ?? '',
      reason: (map['reason'] as String? ?? '').trim(),
      details: map['details'] as String?,
      commentText: map['commentText'] as String?,
      status: map['status'] as String? ?? 'pending',
      createdAt: _toDate(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap({bool forCreate = false}) {
    final Map<String, dynamic> map = <String, dynamic>{
      'commentId': commentId,
      'propertyId': propertyId,
      'reporterId': reporterId,
      'reason': reason,
      'details': details,
      'commentText': commentText,
      'status': status,
    };
    if (forCreate) map['createdAt'] = FieldValue.serverTimestamp();
    return map;
  }

  @override
  List<Object?> get props =>
      <Object?>[id, commentId, reporterId, reason, status];
}
