import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/formatters.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/network_image.dart';
import '../../l10n/app_strings.dart';
import '../../models/app_notification.dart';
import '../../providers/settings_providers.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';

/// In-app notification inbox (mirrors the admin broadcast log).
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<AppNotification>> async =
        ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.notificationsTitle)),
      body: async.when(
        data: (List<AppNotification> items) {
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.notifications_none_outlined,
              title: AppStrings.noNotifications,
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(notificationsProvider);
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder:
                  (BuildContext context, int _) =>
                      const SizedBox(height: 10),
              itemBuilder: (BuildContext context, int i) {
                final AppNotification n = items[i];
                return Card(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: n.propertyId?.isNotEmpty == true
                        ? () => AppRoutes.openProperty(
                              context,
                              n.propertyId!,
                            )
                        : null,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: <Widget>[
                          if (n.imageUrl?.isNotEmpty == true)
                            AppNetworkImage(
                              url: n.imageUrl,
                              width: 64,
                              height: 64,
                              borderRadius:
                                  BorderRadius.circular(12),
                            )
                          else
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: n.type == 'featured_property'
                                    ? AppColors.goldSoft
                                    : AppColors.primarySoft,
                                borderRadius:
                                    BorderRadius.circular(14),
                              ),
                              child: Icon(
                                n.type == 'featured_property'
                                    ? Icons.star_outline
                                    : Icons.campaign_outlined,
                                color: n.type ==
                                        'featured_property'
                                    ? AppColors.goldDark
                                    : AppColors.primary,
                              ),
                            ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  n.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  n.body,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    height: 1.6,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: <Widget>[
                                    if (n.createdAt != null)
                                      Text(
                                        Formatters.timeAgo(
                                          n.createdAt!,
                                        ),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color:
                                              AppColors.textMuted,
                                        ),
                                      ),
                                    if (n.propertyId?.isNotEmpty ==
                                        true) ...<Widget>[
                                      const Spacer(),
                                      const Text(
                                        AppStrings.openProperty,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight:
                                              FontWeight.w700,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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
          onRetry: () => ref.invalidate(notificationsProvider),
        ),
      ),
    );
  }
}
