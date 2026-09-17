import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/offline_banner.dart';
import '../../firebase/firebase_providers.dart';
import '../../l10n/app_strings.dart';
import '../../providers/auth_providers.dart';
import '../../services/cache_service.dart';
import '../../services/notification_service.dart';
import '../favorites/favorites_screen.dart';
import '../home/home_screen.dart';
import '../profile/account_screen.dart';
import '../properties/properties_screen.dart';

/// Selected bottom-tab index (lets nested content switch tabs).
final StateProvider<int> mainTabIndexProvider =
    StateProvider<int>((Ref ref) => 0);

/// Main scaffold with bottom navigation:
/// الرئيسية / العقارات / المفضلة / الحساب
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  static const List<Widget> _tabs = <Widget>[
    HomeTab(),
    PropertiesTab(),
    FavoritesTab(),
    AccountTab(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(mainTabIndexProvider.notifier).state = widget.initialIndex;
      _initNotificationsOnce();
    });
  }

  /// Requests notification permission on first launch and stores the token.
  Future<void> _initNotificationsOnce() async {
    try {
      final CacheService cache = ref.read(cacheServiceProvider);
      if (!cache.notificationsEnabled()) return;
      final String? token = await ref
          .read(notificationServiceProvider)
          .enableNotifications();
      if (token == null || token.isEmpty) return;
      final String? uid = ref.read(authStateProvider).valueOrNull?.uid;
      if (uid != null) {
        await ref.read(authRepositoryProvider).saveFcmToken(uid, token);
      }
    } catch (_) {
      // Notifications are best-effort; never block the UI.
    }
  }

  @override
  Widget build(BuildContext context) {
    final int index = ref.watch(mainTabIndexProvider);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            const DemoBanner(),
            const OfflineBanner(),
            Expanded(
              child: IndexedStack(index: index, children: _tabs),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        onTap: (int i) =>
            ref.read(mainTabIndexProvider.notifier).state = i,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: AppStrings.navHome,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.apartment_outlined),
            activeIcon: Icon(Icons.apartment),
            label: AppStrings.navProperties,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            activeIcon: Icon(Icons.favorite),
            label: AppStrings.navFavorites,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: AppStrings.navAccount,
          ),
        ],
      ),
    );
  }
}
