import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'l10n/app_strings.dart';
import 'routes/app_routes.dart';
import 'theme/app_theme.dart';

/// Global navigator key (used for notification deep-links from main()).
final GlobalKey<NavigatorState> rootNavigatorKey =
    GlobalKey<NavigatorState>();

/// Root widget: Arabic-first RTL Material app.
class AlEthiopiApp extends StatelessWidget {
  const AlEthiopiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      navigatorKey: rootNavigatorKey,
      locale: const Locale('ar'),
      supportedLocales: const <Locale>[Locale('ar'), Locale('en')],
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRoutes.onGenerateRoute,
      builder: (BuildContext context, Widget? child) {
        // Force RTL for the Arabic-first UI.
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
