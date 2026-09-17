import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/contact_utils.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
import '../../firebase/firebase_providers.dart';
import '../../l10n/app_strings.dart';
import '../../models/contact_message.dart';
import '../../providers/admin_providers.dart';
import '../../theme/app_colors.dart';

/// Admin "contact us" inbox.
class MessagesTab extends ConsumerWidget {
  const MessagesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<ContactMessage>> async =
        ref.watch(contactMessagesProvider);

    return Column(
      children: <Widget>[
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
          alignment: Alignment.centerRight,
          child: Text(
            AppStrings.messages,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Expanded(
          child: async.when(
            data: (List<ContactMessage> messages) {
              if (messages.isEmpty) {
                return const EmptyState(
                  icon: Icons.inbox_outlined,
                  title: 'لا توجد رسائل.',
                );
              }
              final int unread = messages
                  .where((ContactMessage m) => !m.isRead)
                  .length;
              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(contactMessagesProvider);
                },
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length + 1,
                  separatorBuilder:
                      (BuildContext context, int _) =>
                          const SizedBox(height: 10),
                  itemBuilder:
                      (BuildContext context, int i) {
                    if (i == 0) {
                      return Text(
                        unread == 0
                            ? 'جميع الرسائل مقروءة.'
                            : 'لديك ${Formatters.toArabicDigits('$unread')} رسائل غير مقروءة.',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13,
                        ),
                      );
                    }
                    final ContactMessage m =
                        messages[i - 1];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: m.isRead
                              ? AppColors.background
                              : AppColors.primarySoft,
                          child: Text(
                            m.name.isEmpty
                                ? '?'
                                : m.name.characters.first,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        title: Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                m.name,
                                maxLines: 1,
                                overflow:
                                    TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: m.isRead
                                      ? FontWeight.w600
                                      : FontWeight.w800,
                                ),
                              ),
                            ),
                            if (!m.isRead)
                              Container(
                                width: 10,
                                height: 10,
                                decoration:
                                    const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              m.message,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                              ),
                            ),
                            if (m.createdAt != null)
                              Text(
                                Formatters.timeAgo(
                                  m.createdAt!,
                                ),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color:
                                      AppColors.textMuted,
                                ),
                              ),
                          ],
                        ),
                        isThreeLine: true,
                        onTap: () => _openMessage(
                          context,
                          ref,
                          m,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (Object e, StackTrace _) => ErrorState(
              message: e.toString(),
              onRetry: () =>
                  ref.invalidate(contactMessagesProvider),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openMessage(
    BuildContext context,
    WidgetRef ref,
    ContactMessage message,
  ) async {
    if (!message.isRead) {
      try {
        await ref
            .read(contactRepositoryProvider)
            .markRead(message.id);
      } catch (_) {}
    }
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(message.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Icon(
                    Icons.phone_outlined,
                    size: 17,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      message.phone,
                      textDirection: TextDirection.ltr,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              if (message.createdAt != null) ...<Widget>[
                const SizedBox(height: 4),
                Text(
                  Formatters.timeAgo(message.createdAt!),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
              const Divider(height: 24),
              Text(
                message.message,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.8,
                ),
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton.icon(
            onPressed: () =>
                ContactUtils.callPhone(context, message.phone),
            icon: const Icon(Icons.call_outlined, size: 18),
            label: const Text(AppStrings.callNow),
          ),
          TextButton.icon(
            onPressed: () => ContactUtils.openWhatsApp(
              context,
              message.phone,
            ),
            icon: const Icon(Icons.chat_outlined, size: 18),
            label: const Text(AppStrings.whatsapp),
          ),
          TextButton(
            onPressed: () async {
              final bool confirm = await showConfirmDialog(
                context,
                title: AppStrings.delete,
                message: 'هل تريد حذف هذه الرسالة؟',
              );
              if (!confirm) return;
              try {
                await ref
                    .read(contactRepositoryProvider)
                    .deleteMessage(message.id);
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              } catch (e) {
                if (context.mounted) {
                  showErrorSnack(context, e);
                }
              }
            },
            child: const Text(
              AppStrings.delete,
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
