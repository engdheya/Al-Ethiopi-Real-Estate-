import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../firebase/firebase_providers.dart';
import '../models/comment.dart';
import '../models/comment_report.dart';
import '../models/contact_message.dart';
import '../models/property_page.dart';

class AdminStats extends Equatable {
  const AdminStats({
    required this.properties,
    required this.totalComments,
    required this.pendingReports,
    required this.totalUsers,
  });

  final PropertyStats properties;
  final int totalComments;
  final int pendingReports;
  final int totalUsers;

  @override
  List<Object?> get props =>
      <Object?>[properties, totalComments, pendingReports, totalUsers];
}

final FutureProvider<AdminStats> adminStatsProvider =
    FutureProvider<AdminStats>((Ref ref) async {
  final PropertyStats properties =
      await ref.watch(propertyRepositoryProvider).getStats();
  final int totalComments =
      await ref.watch(commentRepositoryProvider).countAll();
  final int pendingReports =
      await ref.watch(reportRepositoryProvider).countPending();
  final int totalUsers = await ref.watch(authRepositoryProvider).countUsers();
  return AdminStats(
    properties: properties,
    totalComments: totalComments,
    pendingReports: pendingReports,
    totalUsers: totalUsers,
  );
});

final StreamProvider<List<PropertyComment>> adminCommentsProvider =
    StreamProvider<List<PropertyComment>>((Ref ref) {
  return ref.watch(commentRepositoryProvider).watchRecentForAdmin();
});

/// Pass `null` for all reports, or `'pending'` / `'reviewed'` / `'dismissed'`.
final StreamProviderFamily<List<CommentReport>, String?> reportsProvider =
    StreamProviderFamily<List<CommentReport>, String?>(
        (Ref ref, String? status) {
  return ref.watch(reportRepositoryProvider).watchReports(status: status);
});

final StreamProvider<List<ContactMessage>> contactMessagesProvider =
    StreamProvider<List<ContactMessage>>((Ref ref) {
  return ref.watch(contactRepositoryProvider).watchMessages();
});
