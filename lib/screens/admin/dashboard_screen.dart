import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/formatters.dart';
import '../../core/widgets/error_state.dart';
import '../../l10n/app_strings.dart';
import '../../providers/admin_providers.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';

/// Admin dashboard: counters + quick actions.
class DashboardTab extends ConsumerWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<AdminStats> async =
        ref.watch(adminStatsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(adminStatsProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Text(
                AppStrings.dashboard,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            async.when(
              data: (AdminStats stats) =>
                  _StatsGrid(stats: stats),
              loading: () => const Padding(
                padding: EdgeInsets.all(48),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (Object e, StackTrace _) => ErrorState(
                message: e.toString(),
                onRetry: () =>
                    ref.invalidate(adminStatsProvider),
              ),
            ),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'إجراءات سريعة',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.9,
              children: <Widget>[
                _QuickAction(
                  icon: Icons.add_home_work_outlined,
                  label: AppStrings.addProperty,
                  highlight: true,
                  onTap: () => Navigator.of(context).pushNamed(
                    AppRoutes.propertyForm,
                    arguments: const PropertyFormArgs(null),
                  ),
                ),
                _QuickAction(
                  icon: Icons.category_outlined,
                  label: 'التصنيفات والمدن',
                  onTap: () => Navigator.of(context)
                      .pushNamed(AppRoutes.lookups),
                ),
                _QuickAction(
                  icon: Icons.campaign_outlined,
                  label: AppStrings.sendNotification,
                  onTap: () => Navigator.of(context)
                      .pushNamed(AppRoutes.sendNotification),
                ),
                _QuickAction(
                  icon: Icons.settings_outlined,
                  label: AppStrings.appSettings,
                  onTap: () => Navigator.of(context)
                      .pushNamed(AppRoutes.appSettings),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats});

  final AdminStats stats;

  @override
  Widget build(BuildContext context) {
    final List<_Stat> items = <_Stat>[
      _Stat(
        icon: Icons.home_work_outlined,
        label: AppStrings.totalProperties,
        value: stats.properties.total,
        color: AppColors.primary,
      ),
      _Stat(
        icon: Icons.sell_outlined,
        label: AppStrings.propertiesForSale,
        value: stats.properties.sale,
        color: AppColors.saleBadge,
      ),
      _Stat(
        icon: Icons.key_outlined,
        label: AppStrings.propertiesForRent,
        value: stats.properties.rent,
        color: AppColors.rentBadge,
      ),
      _Stat(
        icon: Icons.star_outline,
        label: AppStrings.featuredCount,
        value: stats.properties.featured,
        color: AppColors.goldDark,
      ),
      _Stat(
        icon: Icons.check_circle_outline,
        label: AppStrings.availableCount,
        value: stats.properties.available,
        color: AppColors.success,
      ),
      _Stat(
        icon: Icons.money_off_outlined,
        label: AppStrings.soldCount,
        value: stats.properties.sold,
        color: AppColors.error,
      ),
      _Stat(
        icon: Icons.vpn_key_outlined,
        label: AppStrings.rentedCount,
        value: stats.properties.rented,
        color: AppColors.warning,
      ),
      _Stat(
        icon: Icons.comment_outlined,
        label: AppStrings.totalComments,
        value: stats.totalComments,
        color: AppColors.info,
      ),
      _Stat(
        icon: Icons.report_outlined,
        label: AppStrings.pendingReports,
        value: stats.pendingReports,
        color: AppColors.favoriteRed,
      ),
      _Stat(
        icon: Icons.people_outline,
        label: AppStrings.totalUsers,
        value: stats.totalUsers,
        color: AppColors.primaryDark,
      ),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.75,
      ),
      itemCount: items.length,
      itemBuilder: (BuildContext context, int i) {
        final _Stat s = items[i];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: s.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(s.icon, color: s.color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        Formatters.formatCompactCount(s.value),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        s.label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Stat {
  const _Stat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final int value;
  final Color color;
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.highlight = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          gradient: highlight ? AppColors.heroGradient : null,
          color: highlight ? null : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: highlight
              ? null
              : Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              icon,
              color: highlight
                  ? AppColors.gold
                  : AppColors.primary,
              size: 30,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: highlight
                    ? Colors.white
                    : AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
