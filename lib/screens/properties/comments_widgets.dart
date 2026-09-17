import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/rating_stars.dart';
import '../../firebase/firebase_providers.dart';
import '../../l10n/app_strings.dart';
import '../../models/app_user.dart';
import '../../models/comment.dart';
import '../../providers/auth_providers.dart';
import '../../providers/comment_providers.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';

/// Inline comments section for the property details screen.
class CommentsSection extends ConsumerWidget {
  const CommentsSection({super.key, required this.propertyId});

  final String propertyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<PropertyComment>> async =
        ref.watch(propertyCommentsProvider(propertyId));
    final AppUser? user = ref.watch(currentUserProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            const Expanded(
              child: Text(
                AppStrings.comments,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => _onAdd(context, ref, user),
              icon: const Icon(Icons.add_comment_outlined, size: 18),
              label: const Text(AppStrings.addComment),
            ),
          ],
        ),
        const SizedBox(height: 10),
        async.when(
          data: (List<PropertyComment> comments) {
            if (comments.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Column(
                  children: <Widget>[
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 40,
                      color: AppColors.textMuted,
                    ),
                    SizedBox(height: 8),
                    Text(
                      AppStrings.noCommentsYet,
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 4),
                    Text(
                      AppStrings.beFirstToComment,
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              );
            }
            return Column(
              children: <Widget>[
                for (final PropertyComment c in comments) ...<Widget>[
                  CommentTile(comment: c),
                  const SizedBox(height: 10),
                ],
              ],
            );
          },
          loading: () =>
              const Center(child: CircularProgressIndicator()),
          error: (Object e, StackTrace _) => Text(
            e.toString(),
            style: const TextStyle(color: AppColors.error),
          ),
        ),
      ],
    );
  }

  void _onAdd(BuildContext context, WidgetRef ref, AppUser? user) {
    if (user == null) {
      showDialog<void>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text(AppStrings.loginRequired),
          content: const Text(AppStrings.loginRequiredToComment),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(AppStrings.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed(AppRoutes.login);
              },
              child: const Text(AppStrings.login),
            ),
          ],
        ),
      );
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) =>
          CommentSheet(propertyId: propertyId),
    );
  }
}

/// A single comment with like / report / owner actions.
class CommentTile extends ConsumerWidget {
  const CommentTile({super.key, required this.comment});

  final PropertyComment comment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppUser? user = ref.watch(currentUserProvider);
    final bool isOwner = user?.uid == comment.userId;
    final bool isAdmin =
        ref.watch(isAdminProvider).valueOrNull ?? false;
    final bool liked = comment.isLikedBy(user?.uid);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primarySoft,
                backgroundImage:
                    comment.userPhotoUrl?.isNotEmpty == true
                        ? NetworkImage(comment.userPhotoUrl!)
                        : null,
                child: comment.userPhotoUrl?.isNotEmpty == true
                    ? null
                    : Text(
                        comment.userName.isEmpty
                            ? '?'
                            : comment.userName.characters.first,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      comment.userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    if (comment.createdAt != null)
                      Text(
                        Formatters.timeAgo(comment.createdAt!),
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              if (comment.rating > 0)
                RatingStars(
                  rating: comment.rating.toDouble(),
                  size: 13,
                ),
              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_horiz,
                  color: AppColors.textMuted,
                ),
                onSelected: (String v) =>
                    _handleMenu(context, ref, v, isOwner, isAdmin),
                itemBuilder: (BuildContext context) =>
                    <PopupMenuEntry<String>>[
                  if (isOwner)
                    const PopupMenuItem<String>(
                      value: 'edit',
                      child: Text(AppStrings.editComment),
                    ),
                  if (isOwner || isAdmin)
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: Text(
                        AppStrings.deleteComment,
                        style: TextStyle(color: AppColors.error),
                      ),
                    ),
                  if (!isOwner)
                    const PopupMenuItem<String>(
                      value: 'report',
                      child: Text(AppStrings.reportComment),
                    ),
                  if (isAdmin)
                    PopupMenuItem<String>(
                      value: comment.isHidden ? 'show' : 'hide',
                      child: Text(
                        comment.isHidden
                            ? AppStrings.showComment
                            : AppStrings.hideComment,
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            comment.text,
            style: const TextStyle(fontSize: 14, height: 1.6),
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              InkWell(
                onTap: user == null
                    ? null
                    : () => _toggleLike(ref, context),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: liked
                        ? AppColors.favoriteRed.withOpacity(0.1)
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        liked
                            ? Icons.favorite
                            : Icons.favorite_border,
                        size: 16,
                        color: liked
                            ? AppColors.favoriteRed
                            : AppColors.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        Formatters.toArabicDigits(
                          comment.likeCount.toString(),
                        ),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: liked
                              ? AppColors.favoriteRed
                              : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (comment.isHidden) ...<Widget>[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isAdmin ? '(مخفي — يظهر للإدارة)' : '',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.warning,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _toggleLike(WidgetRef ref, BuildContext context) async {
    try {
      await ref
          .read(commentActionsProvider)
          .toggleLike(comment.id);
    } catch (e) {
      if (context.mounted) showErrorSnack(context, e);
    }
  }

  Future<void> _handleMenu(
    BuildContext context,
    WidgetRef ref,
    String value,
    bool isOwner,
    bool isAdmin,
  ) async {
    switch (value) {
      case 'edit':
        if (!context.mounted) return;
        await showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          builder: (BuildContext context) => CommentSheet(
            propertyId: comment.propertyId,
            existing: comment,
          ),
        );
        break;
      case 'delete':
        final bool confirm = await showConfirmDialog(
          context,
          title: AppStrings.deleteComment,
          message: AppStrings.deleteCommentConfirm,
        );
        if (!confirm) return;
        try {
          await ref.read(commentActionsProvider).remove(comment);
          if (context.mounted) {
            showSuccessSnack(context, AppStrings.commentDeleted);
          }
        } catch (e) {
          if (context.mounted) showErrorSnack(context, e);
        }
        break;
      case 'report':
        if (!context.mounted) return;
        await showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          builder: (BuildContext context) =>
              ReportSheet(comment: comment),
        );
        break;
      case 'hide':
      case 'show':
        try {
          await ref
              .read(commentRepositoryProvider)
              .setHidden(comment.id, value == 'hide');
          if (context.mounted) {
            showSuccessSnack(context, AppStrings.propertySaved);
          }
        } catch (e) {
          if (context.mounted) showErrorSnack(context, e);
        }
        break;
    }
  }
}

/// Add / edit comment sheet with an inline star rating.
class CommentSheet extends ConsumerStatefulWidget {
  const CommentSheet({super.key, required this.propertyId, this.existing});

  final String propertyId;
  final PropertyComment? existing;

  @override
  ConsumerState<CommentSheet> createState() => _CommentSheetState();
}

class _CommentSheetState extends ConsumerState<CommentSheet> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  late final TextEditingController _text;
  late double _rating;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _text = TextEditingController(text: widget.existing?.text ?? '');
    _rating = (widget.existing?.rating ?? 5).toDouble();
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      final CommentActions actions = ref.read(commentActionsProvider);
      if (widget.existing == null) {
        await actions.add(
          propertyId: widget.propertyId,
          text: _text.text,
          rating: _rating.toInt(),
        );
        if (mounted) {
          showSuccessSnack(context, AppStrings.commentAdded);
        }
      } else {
        await actions.update(widget.existing!, _text.text);
        if (mounted) {
          showSuccessSnack(context, AppStrings.commentUpdated);
        }
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEdit = widget.existing != null;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        8,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: Text(
                isEdit ? AppStrings.editComment : AppStrings.addComment,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (!isEdit) ...<Widget>[
              const Text(
                AppStrings.rateProperty,
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Center(
                child: RatingBar.builder(
                  initialRating: _rating,
                  minRating: 1,
                  direction: Axis.horizontal,
                  allowHalfRating: false,
                  itemCount: 5,
                  itemSize: 38,
                  unratedColor: AppColors.border,
                  itemBuilder: (BuildContext context, int _) =>
                      const Icon(
                    Icons.star,
                    color: AppColors.goldDark,
                  ),
                  onRatingUpdate: (double value) =>
                      setState(() => _rating = value),
                ),
              ),
              const SizedBox(height: 12),
            ],
            AppTextField(
              label: AppStrings.comments,
              hint: AppStrings.commentHint,
              controller: _text,
              validator: Validators.comment,
              maxLines: 4,
              minLines: 3,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        isEdit
                            ? AppStrings.saveChanges
                            : AppStrings.addComment,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Report-a-comment sheet with predefined reasons.
class ReportSheet extends ConsumerStatefulWidget {
  const ReportSheet({super.key, required this.comment});

  final PropertyComment comment;

  @override
  ConsumerState<ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends ConsumerState<ReportSheet> {
  String _reason = AppStrings.reportReasons.first;
  final TextEditingController _details = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() => _sending = true);
    try {
      await ref.read(commentActionsProvider).fileReport(
            comment: widget.comment,
            reason: _reason,
            details: _details.text.trim().isEmpty
                ? null
                : _details.text.trim(),
          );
      if (mounted) {
        showSuccessSnack(context, AppStrings.reportSent);
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        8,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Center(
            child: Text(
              AppStrings.reportComment,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            AppStrings.reportReason,
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          ...AppStrings.reportReasons.map(
            (String reason) => RadioListTile<String>(
              value: reason,
              groupValue: _reason,
              onChanged: (String? v) =>
                  setState(() => _reason = v ?? _reason),
              title: Text(reason),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
          ),
          AppTextField(
            label: AppStrings.reportDetails,
            hint: AppStrings.reportDetailsHint,
            controller: _details,
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _sending ? null : _send,
              child: _sending
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(AppStrings.submitReport),
            ),
          ),
        ],
      ),
    );
  }
}
