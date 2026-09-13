import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/formatters.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
import '../../firebase/firebase_providers.dart';
import '../../l10n/app_strings.dart';
import '../../models/comment_report.dart';
import '../../providers/admin_providers.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';

/// Admin triage for comment reports.
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  String? _status = 'pending';

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<CommentReport>> async =
        ref.watch(reportsProvider(_status));

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.reports)),
      body: Column(
        children: <Widget>[
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: <Widget>[
                _StatusChip(
                  label: 'قيد المراجعة',
                  selected: _status == 'pending',
                  onTap: () =>
                      setState(() => _status = 'pending'),
                ),
                const SizedBox(width: 8),
                _StatusChip(
                  label: 'تمت المراجعة',
                  selected: _status == 'reviewed',
                  onTap: () =>
                      setState(() => _status = 'reviewed'),
                ),
                const SizedBox(width: 8),
                _StatusChip(
                  label: 'متجاهلة',
                  selected: _status == 'dismissed',
                  onTap: () =>
                      setState(() => _status = 'dismissed'),
                ),
                const SizedBox(width: 8),
                _StatusChip(
                  label: AppStrings.all,
                  selected: _status == null,
                  onTap: () => setState(() => _status = null),
                ),
              ],
            ),
          ),
          Expanded(
            child: async.when(
              data: (List<CommentReport> reports) {
                if (reports.isEmpty) {
                  return const EmptyState(
                    icon: Icons.report_outlined,
                    title: 'لا توجد بلاغات.',
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(reportsProvider(_status));
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: reports.length,
                    separatorBuilder:
                        (BuildContext context, int _) =>
                            const SizedBox(height: 10),
                    itemBuilder:
                        (BuildContext context, int i) {
                      return _ReportCard(
                        report: reports[i],
                        onChanged: () => ref.invalidate(
                          reportsProvider(_status),
                        ),
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
                    ref.invalidate(reportsProvider(_status)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}

class _ReportCard extends ConsumerWidget {
  const _ReportCard({
    required this.report,
    required this.onChanged,
  });

  final CommentReport report;
  final VoidCallback onChanged;

  Color get _statusColor {
    switch (report.status) {
      case 'pending':
        return AppColors.warning;
      case 'reviewed':
        return AppColors.success;
      case 'dismissed':
        return AppColors.textMuted;
      default:
        return AppColors.info;
    }
  }

  String get _statusLabel {
    switch (report.status) {
      case 'pending':
        return 'قيد المراجعة';
      case 'reviewed':
        return 'تمت المراجعة';
      case 'dismissed':
        return 'متجاهلة';
      default:
        return report.status;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _statusLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _statusColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    report.reason,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
                if (report.createdAt != null)
                  Text(
                    Formatters.timeAgo(report.createdAt!),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
              ],
            ),
            if (report.commentText?.isNotEmpty == true) ...<Widget>[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '«${report.commentText}»',
                  style: const TextStyle(
                    fontSize: 13.5,
                    height: 1.6,
                  ),
                ),
              ),
            ],
            if (report.details?.isNotEmpty == true) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                report.details!,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                OutlinedButton.icon(
                  onPressed: () => AppRoutes.openProperty(
                    context,
                    report.propertyId,
                  ),
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text(AppStrings.openProperty),
                ),
                ElevatedButton(
                  onPressed: () => _setStatus(
                    context,
                    ref,
                    'reviewed',
                  ),
                  child: const Text(
                    AppStrings.markReportReviewed,
                  ),
                ),
                TextButton(
                  onPressed: () => _setStatus(
                    context,
                    ref,
                    'dismissed',
                  ),
                  child: const Text(AppStrings.dismissReport),
                ),
                TextButton(
                  onPressed: () =>
                      _deleteComment(context, ref),
                  child: const Text(
                    AppStrings.deleteComment,
                    style: TextStyle(color: AppColors.error),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _setStatus(
    BuildContext context,
    WidgetRef ref,
    String status,
  ) async {
    try {
      await ref
          .read(reportRepositoryProvider)
          .setStatus(report.id, status);
      onChanged();
      if (context.mounted) {
        showSuccessSnack(context, AppStrings.propertySaved);
      }
    } catch (e) {
      if (context.mounted) showErrorSnack(context, e);
    }
  }

  Future<void> _deleteComment(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final bool confirm = await showConfirmDialog(
      context,
      title: AppStrings.deleteComment,
      message:
          'سيتم حذف التعليق المُبلغ عنه نهائياً. هل تريد المتابعة؟',
    );
    if (!confirm) return;
    try {
      await ref
          .read(commentRepositoryProvider)
          .deleteComment(report.commentId);
      await ref
          .read(reportRepositoryProvider)
          .setStatus(report.id, 'reviewed');
      onChanged();
      if (context.mounted) {
        showSuccessSnack(context, AppStrings.commentDeleted);
      }
    } catch (e) {
      if (context.mounted) showErrorSnack(context, e);
    }
  }
}
