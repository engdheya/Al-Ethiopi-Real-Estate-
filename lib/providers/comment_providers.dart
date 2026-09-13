import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/errors/app_failure.dart';
import '../firebase/firebase_providers.dart';
import '../l10n/app_strings.dart';
import '../models/app_user.dart';
import '../models/comment.dart';
import '../models/comment_report.dart';
import 'auth_providers.dart';

final StreamProviderFamily<List<PropertyComment>, String>
    propertyCommentsProvider = StreamProviderFamily<List<PropertyComment>, String>(
        (Ref ref, String propertyId) {
  return ref.watch(commentRepositoryProvider).watchComments(propertyId);
});

class CommentActions {
  CommentActions(this._ref);

  final Ref _ref;

  AppUser _requireUser() {
    final AppUser? user = _ref.read(authStateProvider).valueOrNull;
    if (user == null) {
      throw const AppFailure(AppStrings.loginRequiredToComment);
    }
    return user;
  }

  Future<void> add({
    required String propertyId,
    required String text,
    int rating = 0,
  }) async {
    final AppUser user = _requireUser();
    final String clean = text.trim();
    if (clean.isEmpty) throw const AppFailure(AppStrings.commentEmpty);
    await _ref.read(commentRepositoryProvider).addComment(
          PropertyComment(
            id: '',
            propertyId: propertyId,
            userId: user.uid,
            userName: user.displayName.isEmpty ? 'مستخدم' : user.displayName,
            userPhotoUrl: user.photoUrl,
            text: clean.length > 1000 ? clean.substring(0, 1000) : clean,
            rating: rating,
          ),
        );
  }

  Future<void> update(PropertyComment comment, String text) async {
    final AppUser user = _requireUser();
    final bool isAdmin =
        await _ref.read(authRepositoryProvider).isAdmin();
    if (comment.userId != user.uid && !isAdmin) {
      throw const AppFailure(AppStrings.noPermission);
    }
    final String clean = text.trim();
    if (clean.isEmpty) throw const AppFailure(AppStrings.commentEmpty);
    await _ref
        .read(commentRepositoryProvider)
        .updateComment(comment.copyWith(text: clean));
  }

  Future<void> remove(PropertyComment comment) async {
    final AppUser user = _requireUser();
    final bool isAdmin =
        await _ref.read(authRepositoryProvider).isAdmin();
    if (comment.userId != user.uid && !isAdmin) {
      throw const AppFailure(AppStrings.noPermission);
    }
    await _ref.read(commentRepositoryProvider).deleteComment(comment.id);
  }

  Future<void> toggleLike(String commentId) async {
    final AppUser user = _requireUser();
    await _ref
        .read(commentRepositoryProvider)
        .toggleLike(commentId, user.uid);
  }

  Future<void> fileReport({
    required PropertyComment comment,
    required String reason,
    String? details,
  }) async {
    final AppUser user = _requireUser();
    await _ref.read(reportRepositoryProvider).fileReport(
          CommentReport(
            id: '',
            commentId: comment.id,
            propertyId: comment.propertyId,
            reporterId: user.uid,
            reason: reason,
            details: details,
            commentText: comment.text,
            status: 'pending',
          ),
        );
  }
}

final Provider<CommentActions> commentActionsProvider =
    Provider<CommentActions>((Ref ref) => CommentActions(ref));
