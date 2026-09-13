import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
import '../../l10n/app_strings.dart';
import '../../models/comment.dart';
import '../../providers/admin_providers.dart';
import '../../routes/app_routes.dart';
import '../properties/comments_widgets.dart';

/// Admin comment moderation queue (hide / show / delete + view property).
class ModerateCommentsTab extends ConsumerStatefulWidget {
  const ModerateCommentsTab({super.key});

  @override
  ConsumerState<ModerateCommentsTab> createState() =>
      _ModerateCommentsTabState();
}

class _ModerateCommentsTabState
    extends ConsumerState<ModerateCommentsTab> {
  bool _hiddenOnly = false;

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<PropertyComment>> async =
        ref.watch(adminCommentsProvider);

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Row(
            children: <Widget>[
              const Expanded(
                child: Text(
                  AppStrings.moderateComments,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              ChoiceChip(
                label: const Text('المخفية فقط'),
                selected: _hiddenOnly,
                onSelected: (bool v) =>
                    setState(() => _hiddenOnly = v),
              ),
            ],
          ),
        ),
        Expanded(
          child: async.when(
            data: (List<PropertyComment> comments) {
              final List<PropertyComment> visible = _hiddenOnly
                  ? comments
                      .where((PropertyComment c) => c.isHidden)
                      .toList()
                  : comments;
              if (visible.isEmpty) {
                return const EmptyState(
                  icon: Icons.comment_outlined,
                  title: AppStrings.noCommentsYet,
                );
              }
              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(adminCommentsProvider);
                },
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: visible.length,
                  separatorBuilder:
                      (BuildContext context, int _) =>
                          const SizedBox(height: 10),
                  itemBuilder:
                      (BuildContext context, int i) {
                    final PropertyComment c = visible[i];
                    return Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        CommentTile(comment: c),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () =>
                                AppRoutes.openProperty(
                              context,
                              c.propertyId,
                            ),
                            icon: const Icon(
                              Icons.open_in_new,
                              size: 16,
                            ),
                            label: const Text(
                              AppStrings.openProperty,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (Object e, StackTrace _) => ErrorState(
              message: e.toString(),
              onRetry: () =>
                  ref.invalidate(adminCommentsProvider),
            ),
          ),
        ),
      ],
    );
  }
}
