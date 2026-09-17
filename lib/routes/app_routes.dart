import 'package:flutter/material.dart';

import '../models/property.dart';
import '../screens/admin/admin_shell.dart';
import '../screens/admin/app_settings_screen.dart';
import '../screens/admin/manage_lookups_screen.dart';
import '../screens/admin/property_form_screen.dart';
import '../screens/admin/reports_screen.dart';
import '../screens/admin/send_notification_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/contact/contact_screen.dart';
import '../screens/info/info_screen.dart';
import '../screens/main/main_shell.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/properties/gallery_screen.dart';
import '../screens/properties/property_details_screen.dart';
import '../screens/search/search_screen.dart';
import '../screens/splash/splash_screen.dart';

/// Named routes + typed arguments for the whole app.
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String main = '/main';
  static const String propertyDetails = '/property';
  static const String gallery = '/gallery';
  static const String search = '/search';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String editProfile = '/edit-profile';
  static const String contact = '/contact';
  static const String notifications = '/notifications';
  static const String info = '/info';
  static const String admin = '/admin';
  static const String propertyForm = '/admin/property-form';
  static const String lookups = '/admin/lookups';
  static const String reports = '/admin/reports';
  static const String sendNotification = '/admin/send-notification';
  static const String appSettings = '/admin/app-settings';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    Widget page;
    switch (settings.name) {
      case AppRoutes.splash:
        page = const SplashScreen();
        break;
      case AppRoutes.main:
        final Object? args = settings.arguments;
        page = MainShell(
          initialIndex: args is MainShellArgs ? args.initialIndex : 0,
        );
        break;
      case AppRoutes.propertyDetails:
        final Object? args = settings.arguments;
        if (args is! PropertyDetailsArgs) {
          return _errorRoute('missing property id');
        }
        page = PropertyDetailsScreen(propertyId: args.propertyId);
        break;
      case AppRoutes.gallery:
        final Object? args = settings.arguments;
        if (args is! GalleryArgs) return _errorRoute('missing images');
        page = GalleryScreen(
          images: args.images,
          initialIndex: args.initialIndex,
        );
        break;
      case AppRoutes.search:
        page = const SearchScreen();
        break;
      case AppRoutes.login:
        page = const LoginScreen();
        break;
      case AppRoutes.register:
        page = const RegisterScreen();
        break;
      case AppRoutes.forgotPassword:
        page = const ForgotPasswordScreen();
        break;
      case AppRoutes.editProfile:
        page = const EditProfileScreen();
        break;
      case AppRoutes.contact:
        page = const ContactScreen();
        break;
      case AppRoutes.notifications:
        page = const NotificationsScreen();
        break;
      case AppRoutes.info:
        final Object? args = settings.arguments;
        if (args is! InfoArgs) return _errorRoute('missing info kind');
        page = InfoScreen(kind: args.kind);
        break;
      case AppRoutes.admin:
        page = const AdminShell();
        break;
      case AppRoutes.propertyForm:
        final Object? args = settings.arguments;
        page = PropertyFormScreen(
          propertyId:
              args is PropertyFormArgs ? args.propertyId : null,
        );
        break;
      case AppRoutes.lookups:
        page = const ManageLookupsScreen();
        break;
      case AppRoutes.reports:
        page = const ReportsScreen();
        break;
      case AppRoutes.sendNotification:
        page = const SendNotificationScreen();
        break;
      case AppRoutes.appSettings:
        page = const AppSettingsScreen();
        break;
      default:
        return _errorRoute('unknown route: ${settings.name}');
    }
    return MaterialPageRoute<dynamic>(
      builder: (BuildContext context) => page,
      settings: settings,
    );
  }

  static Route<dynamic> _errorRoute(String message) {
    return MaterialPageRoute<dynamic>(
      builder: (BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('خطأ')),
        body: Center(child: Text(message)),
      ),
    );
  }

  // -------------------------------------------------------------- navigation

  static Future<void> openProperty(
    BuildContext context,
    String propertyId,
  ) {
    return Navigator.of(context).pushNamed(
      AppRoutes.propertyDetails,
      arguments: PropertyDetailsArgs(propertyId),
    );
  }

  static Future<void> openGallery(
    BuildContext context, {
    required List<PropertyImage> images,
    int initialIndex = 0,
  }) {
    return Navigator.of(context).pushNamed(
      AppRoutes.gallery,
      arguments: GalleryArgs(images, initialIndex),
    );
  }
}

// ------------------------------------------------------------------- arguments

class MainShellArgs {
  const MainShellArgs({this.initialIndex = 0});

  final int initialIndex;
}

class PropertyDetailsArgs {
  const PropertyDetailsArgs(this.propertyId);

  final String propertyId;
}

class GalleryArgs {
  const GalleryArgs(this.images, this.initialIndex);

  final List<PropertyImage> images;
  final int initialIndex;
}

class PropertyFormArgs {
  const PropertyFormArgs(this.propertyId);

  final String? propertyId;
}

class InfoArgs {
  const InfoArgs(this.kind);

  final InfoKind kind;
}
