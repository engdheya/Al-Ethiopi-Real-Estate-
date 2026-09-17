import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/formatters.dart';
import '../../core/widgets/app_logo.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../firebase/firebase_providers.dart';
import '../../l10n/app_strings.dart';
import '../../models/app_user.dart';
import '../../providers/auth_providers.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../info/info_screen.dart';
import '../main/main_shell.dart';

/// Account tab: guest upsell, profile header, menu, admin entry, logout.
class AccountTab extends ConsumerWidget {
  const AccountTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppUser? user = ref.watch(currentUserProvider);
    final bool isAdmin =
        ref.watch(isAdminProvider).valueOrNull ?? false;

    return SingleChildScrollView(
      child: Column(
        children: <Widget>[
          _Header(user: user),
          const SizedBox(height: 16),
          if (user == null)
            _GuestActions()
          else ...<Widget>[
            if (isAdmin) _AdminEntry(),
            _Menu(
              onFavorites: () => ref
                  .read(mainTabIndexProvider.notifier)
                  .state = 2,
              onLogout: () => _logout(context, ref),
            ),
          ],
          if (user == null)
            _Menu(
              onFavorites: () => ref
                  .read(mainTabIndexProvider.notifier)
                  .state = 2,
              onLogout: () {},
              guest: true,
            ),
          const SizedBox(height: 8),
          Text(
            '${AppStrings.appVersion} 1.0.0',
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final bool confirm = await showConfirmDialog(
      context,
      title: AppStrings.logout,
      message: AppStrings.logoutConfirm,
      confirmLabel: AppStrings.logout,
    );
    if (!confirm) return;
    try {
      await ref.read(authRepositoryProvider).signOut();
      ref.invalidate(isAdminProvider);
    } catch (e) {
      if (context.mounted) showErrorSnack(context, e);
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.user});

  final AppUser? user;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(28),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
      child: user == null
          ? const Column(
              children: <Widget>[
                AppLogoMark(size: 72, radius: 18),
                SizedBox(height: 12),
                Text(
                  AppStrings.guestUser,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  AppStrings.loginRequiredToComment,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            )
          : Row(
              children: <Widget>[
                CircleAvatar(
                  radius: 34,
                  backgroundColor: Colors.white24,
                  backgroundImage:
                      user!.photoUrl?.isNotEmpty == true
                          ? NetworkImage(user!.photoUrl!)
                          : null,
                  child: user!.photoUrl?.isNotEmpty == true
                      ? null
                      : Text(
                          user!.displayName.isEmpty
                              ? '?'
                              : user!.displayName.characters.first,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        user!.displayName.isEmpty
                            ? AppStrings.guestUser
                            : user!.displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (user!.email.isNotEmpty)
                        Text(
                          user!.email,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      if (user!.createdAt != null)
                        Text(
                          '${AppStrings.memberSince} ${Formatters.formatDate(user!.createdAt!)}',
                          style: const TextStyle(
                            color: AppColors.goldSoft,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context)
                      .pushNamed(AppRoutes.editProfile),
                  icon: const Icon(
                    Icons.edit_outlined,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
    );
  }
}

class _GuestActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: <Widget>[
          Expanded(
            child: ElevatedButton(
              onPressed: () => Navigator.of(context)
                  .pushNamed(AppRoutes.login),
              child: const Text(AppStrings.login),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.of(context)
                  .pushNamed(AppRoutes.register),
              child: const Text(AppStrings.register),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminEntry extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: InkWell(
        onTap: () =>
            Navigator.of(context).pushNamed(AppRoutes.admin),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: AppColors.goldGradient,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(
            children: <Widget>[
              Icon(
                Icons.admin_panel_settings_outlined,
                color: AppColors.primaryDarker,
                size: 30,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      AppStrings.adminPanel,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: AppColors.primaryDarker,
                      ),
                    ),
                    Text(
                      AppStrings.openAdminPanel,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.primaryDarker,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: AppColors.primaryDarker,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Menu extends StatelessWidget {
  const _Menu({
    required this.onFavorites,
    required this.onLogout,
    this.guest = false,
  });

  final VoidCallback onFavorites;
  final VoidCallback onLogout;
  final bool guest;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Card(
        child: Column(
          children: <Widget>[
            _MenuTile(
              icon: Icons.favorite_border,
              title: AppStrings.myFavorites,
              onTap: onFavorites,
            ),
            _MenuTile(
              icon: Icons.notifications_outlined,
              title: AppStrings.notifications,
              onTap: () => Navigator.of(context)
                  .pushNamed(AppRoutes.notifications),
            ),
            if (!guest)
              _MenuTile(
                icon: Icons.person_outline,
                title: AppStrings.editProfile,
                onTap: () => Navigator.of(context)
                    .pushNamed(AppRoutes.editProfile),
              ),
            _MenuTile(
              icon: Icons.headset_mic_outlined,
              title: AppStrings.contactUs,
              onTap: () => Navigator.of(context)
                  .pushNamed(AppRoutes.contact),
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            _MenuTile(
              icon: Icons.info_outline,
              title: AppStrings.aboutApp,
              onTap: () => Navigator.of(context).pushNamed(
                AppRoutes.info,
                arguments: const InfoArgs(InfoKind.about),
              ),
            ),
            _MenuTile(
              icon: Icons.description_outlined,
              title: AppStrings.termsOfUse,
              onTap: () => Navigator.of(context).pushNamed(
                AppRoutes.info,
                arguments: const InfoArgs(InfoKind.terms),
              ),
            ),
            _MenuTile(
              icon: Icons.privacy_tip_outlined,
              title: AppStrings.privacyPolicy,
              onTap: () => Navigator.of(context).pushNamed(
                AppRoutes.info,
                arguments: const InfoArgs(InfoKind.privacy),
              ),
            ),
            if (!guest) ...<Widget>[
              const Divider(height: 1, indent: 16, endIndent: 16),
              _MenuTile(
                icon: Icons.logout,
                title: AppStrings.logout,
                danger: true,
                onTap: onLogout,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final Color color =
        danger ? AppColors.error : AppColors.primary;
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: danger
              ? AppColors.error.withOpacity(0.1)
              : AppColors.primarySoft,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: danger ? AppColors.error : null,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 15,
        color: AppColors.textMuted,
      ),
      onTap: onTap,
    );
  }
}
