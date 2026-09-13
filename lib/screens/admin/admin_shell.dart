import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/offline_banner.dart';
import '../../firebase/firebase_providers.dart';
import '../../l10n/app_strings.dart';
import '../../providers/auth_providers.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../info/info_screen.dart';
import 'dashboard_screen.dart';
import 'manage_properties_screen.dart';
import 'messages_screen.dart';
import 'moderate_comments_screen.dart';

/// Admin area shell. The UI gate is a convenience only — real enforcement
/// lives in Firestore Security Rules + the `admin` custom claim.
class AdminShell extends ConsumerStatefulWidget {
  const AdminShell({super.key});

  @override
  ConsumerState<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends ConsumerState<AdminShell> {
  int _index = 0;

  static const List<Widget> _tabs = <Widget>[
    DashboardTab(),
    ManagePropertiesTab(),
    ModerateCommentsTab(),
    MessagesTab(),
    AdminMoreTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final AsyncValue<bool> admin = ref.watch(isAdminProvider);

    return admin.when(
      data: (bool isAdmin) {
        if (!isAdmin) return const _AccessDenied();
        return Scaffold(
          body: SafeArea(
            child: Column(
              children: <Widget>[
                const DemoBanner(),
                const OfflineBanner(),
                Expanded(
                  child: IndexedStack(index: _index, children: _tabs),
                ),
              ],
            ),
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _index,
            onTap: (int i) => setState(() => _index = i),
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_outlined),
                activeIcon: Icon(Icons.dashboard),
                label: AppStrings.navDashboard,
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.apartment_outlined),
                activeIcon: Icon(Icons.apartment),
                label: AppStrings.navAdminProperties,
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.comment_outlined),
                activeIcon: Icon(Icons.comment),
                label: AppStrings.navAdminComments,
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.inbox_outlined),
                activeIcon: Icon(Icons.inbox),
                label: AppStrings.navAdminMessages,
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.menu),
                activeIcon: Icon(Icons.menu_open),
                label: AppStrings.navAdminMore,
              ),
            ],
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (Object e, StackTrace _) => const _AccessDenied(),
    );
  }
}

class _AccessDenied extends StatelessWidget {
  const _AccessDenied();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.adminPanel)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_outline,
                  size: 48,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                AppStrings.adminOnly,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(AppStrings.close),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Admin "more" tab: lookups, reports, notifications, settings, sign-out.
class AdminMoreTab extends ConsumerWidget {
  const AdminMoreTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Text(
              AppStrings.navAdminMore,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Card(
            child: Column(
              children: <Widget>[
                _Tile(
                  icon: Icons.category_outlined,
                  title: 'إدارة التصنيفات والمدن',
                  subtitle:
                      'الأنواع، المدن، المناطق، المميزات',
                  onTap: () => Navigator.of(context)
                      .pushNamed(AppRoutes.lookups),
                ),
                _Tile(
                  icon: Icons.report_outlined,
                  title: AppStrings.reports,
                  subtitle: AppStrings.pendingReports,
                  onTap: () => Navigator.of(context)
                      .pushNamed(AppRoutes.reports),
                ),
                _Tile(
                  icon: Icons.campaign_outlined,
                  title: AppStrings.sendNotification,
                  subtitle: 'إشعار للمستخدمين',
                  onTap: () => Navigator.of(context)
                      .pushNamed(AppRoutes.sendNotification),
                ),
                _Tile(
                  icon: Icons.settings_outlined,
                  title: AppStrings.appSettings,
                  subtitle: 'بيانات التواصل والصفحات',
                  onTap: () => Navigator.of(context)
                      .pushNamed(AppRoutes.appSettings),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: <Widget>[
                _Tile(
                  icon: Icons.store_outlined,
                  title: 'عرض التطبيق',
                  subtitle: 'العودة لواجهة المستخدمين',
                  onTap: () => Navigator.of(context).pop(),
                ),
                _Tile(
                  icon: Icons.info_outline,
                  title: AppStrings.aboutApp,
                  subtitle: AppStrings.appName,
                  onTap: () => Navigator.of(context).pushNamed(
                    AppRoutes.info,
                    arguments: const InfoArgs(InfoKind.about),
                  ),
                ),
                _Tile(
                  icon: Icons.logout,
                  title: AppStrings.logout,
                  subtitle: '',
                  danger: true,
                  onTap: () async {
                    await ref
                        .read(authRepositoryProvider)
                        .signOut();
                    ref.invalidate(isAdminProvider);
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final Color color =
        danger ? AppColors.error : AppColors.primary;
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: danger
              ? AppColors.error.withOpacity(0.1)
              : AppColors.primarySoft,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: danger ? AppColors.error : null,
        ),
      ),
      subtitle: subtitle.isEmpty ? null : Text(subtitle),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 15,
        color: AppColors.textMuted,
      ),
      onTap: onTap,
    );
  }
}
