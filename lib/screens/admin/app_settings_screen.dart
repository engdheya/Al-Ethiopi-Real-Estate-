import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/validators.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/app_text_field.dart';
import '../../firebase/firebase_providers.dart';
import '../../l10n/app_strings.dart';
import '../../models/app_settings.dart';
import '../../providers/settings_providers.dart';

/// Admin editor for `settings/app` (contact info + legal pages).
class AppSettingsScreen extends ConsumerStatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  ConsumerState<AppSettingsScreen> createState() =>
      _AppSettingsScreenState();
}

class _AppSettingsScreenState
    extends ConsumerState<AppSettingsScreen> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _whatsapp = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _address = TextEditingController();
  final TextEditingController _facebook = TextEditingController();
  final TextEditingController _about = TextEditingController();
  final TextEditingController _terms = TextEditingController();
  final TextEditingController _privacy = TextEditingController();
  bool _loaded = false;
  bool _saving = false;

  @override
  void dispose() {
    _phone.dispose();
    _whatsapp.dispose();
    _email.dispose();
    _address.dispose();
    _facebook.dispose();
    _about.dispose();
    _terms.dispose();
    _privacy.dispose();
    super.dispose();
  }

  void _fill(AppSettings s) {
    _phone.text = s.phone;
    _whatsapp.text = s.whatsapp;
    _email.text = s.email;
    _address.text = s.address;
    _facebook.text = s.facebookUrl;
    _about.text = s.aboutAr;
    _terms.text = s.termsAr;
    _privacy.text = s.privacyAr;
    _loaded = true;
  }

  Future<void> _save() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      await ref.read(settingsRepositoryProvider).saveSettings(
            AppSettings(
              phone: _phone.text.trim(),
              whatsapp: _whatsapp.text.trim(),
              email: _email.text.trim(),
              address: _address.text.trim(),
              facebookUrl: _facebook.text.trim(),
              aboutAr: _about.text.trim(),
              termsAr: _terms.text.trim(),
              privacyAr: _privacy.text.trim(),
            ),
          );
      if (mounted) {
        showSuccessSnack(context, AppStrings.settingsSaved);
      }
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<AppSettings> async =
        ref.watch(appSettingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.appSettings)),
      body: async.when(
        data: (AppSettings settings) {
          if (!_loaded) _fill(settings);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.stretch,
                children: <Widget>[
                  AppTextField(
                    label: AppStrings.settingsPhone,
                    controller: _phone,
                    validator: (String? v) =>
                        Validators.phone(v, allowEmpty: true),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    label: AppStrings.settingsWhatsapp,
                    controller: _whatsapp,
                    validator: (String? v) =>
                        Validators.phone(v, allowEmpty: true),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    label: AppStrings.settingsEmail,
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    label: AppStrings.settingsAddress,
                    controller: _address,
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    label: AppStrings.settingsFacebook,
                    controller: _facebook,
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    label: AppStrings.settingsAbout,
                    controller: _about,
                    maxLines: 5,
                    minLines: 3,
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    label: AppStrings.settingsTerms,
                    controller: _terms,
                    maxLines: 6,
                    minLines: 3,
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    label: AppStrings.settingsPrivacy,
                    controller: _privacy,
                    maxLines: 6,
                    minLines: 3,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(AppStrings.saveChanges),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (Object e, StackTrace _) => Center(
          child: Text(e.toString()),
        ),
      ),
    );
  }
}
