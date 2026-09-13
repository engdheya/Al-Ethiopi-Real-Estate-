import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_strings.dart';
import '../../models/app_settings.dart';
import '../../providers/settings_providers.dart';
import '../../theme/app_colors.dart';

enum InfoKind { about, terms, privacy }

extension InfoKindX on InfoKind {
  String get title {
    switch (this) {
      case InfoKind.about:
        return AppStrings.aboutApp;
      case InfoKind.terms:
        return AppStrings.termsOfUse;
      case InfoKind.privacy:
        return AppStrings.privacyPolicy;
    }
  }

  String bodyOf(AppSettings settings) {
    switch (this) {
      case InfoKind.about:
        return settings.aboutAr.isEmpty
            ? _defaultAbout
            : settings.aboutAr;
      case InfoKind.terms:
        return settings.termsAr.isEmpty
            ? _defaultTerms
            : settings.termsAr;
      case InfoKind.privacy:
        return settings.privacyAr.isEmpty
            ? _defaultPrivacy
            : settings.privacyAr;
    }
  }
}

/// About / Terms / Privacy page fed by `settings/app`.
class InfoScreen extends ConsumerWidget {
  const InfoScreen({super.key, required this.kind});

  final InfoKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppSettings settings =
        ref.watch(appSettingsProvider).valueOrNull ?? const AppSettings();
    return Scaffold(
      appBar: AppBar(title: Text(kind.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              kind.bodyOf(settings),
              style: const TextStyle(
                fontSize: 15,
                height: 1.9,
                color: AppColors.textDark,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

const String _defaultAbout =
    'الأثيوبي للعقارات منصة يمنية متخصصة في عرض الشقق والأراضي والعقارات للبيع والإيجار، بهدف تسهيل رحلة البحث عن العقار المثالي عبر معلومات دقيقة وصور واضحة وتواصل مباشر مع المعلن.';

const String _defaultTerms =
    'باستخدامك للتطبيق فأنت توافق على احترام حقوق الآخرين وعدم نشر محتوى مسيء أو مضلل، وأن المعلومات المعروضة استرشادية ويُنصح بالمعاينة قبل أي تعاقد. يحق للإدارة حذف أي محتوى مخالف دون إشعار مسبق.';

const String _defaultPrivacy =
    'نجمع الحد الأدنى من البيانات اللازمة لتشغيل التطبيق (الاسم والبريد الإلكتروني عند التسجيل)، ولا نبيع بياناتك لأي طرف ثالث. تُستخدم بيانات التواصل فقط لتحسين الخدمة والرد على استفساراتك.';
