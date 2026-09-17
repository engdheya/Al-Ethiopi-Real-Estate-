import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/contact_utils.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/app_text_field.dart';
import '../../firebase/firebase_providers.dart';
import '../../l10n/app_strings.dart';
import '../../models/app_settings.dart';
import '../../models/app_user.dart';
import '../../models/contact_message.dart';
import '../../providers/auth_providers.dart';
import '../../providers/settings_providers.dart';
import '../../theme/app_colors.dart';

/// "تواصل معنا": office channels + contact form stored in Firestore.
class ContactScreen extends ConsumerStatefulWidget {
  const ContactScreen({super.key});

  @override
  ConsumerState<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends ConsumerState<ContactScreen> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _message = TextEditingController();
  bool _sending = false;
  bool _prefilled = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() => _sending = true);
    try {
      final AppUser? user = ref.read(currentUserProvider);
      await ref.read(contactRepositoryProvider).sendMessage(
            ContactMessage(
              id: '',
              name: _name.text.trim(),
              phone: _phone.text.trim(),
              message: _message.text.trim(),
              userId: user?.uid,
            ),
          );
      if (!mounted) return;
      showSuccessSnack(context, AppStrings.messageSent);
      _message.clear();
      FocusScope.of(context).unfocus();
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppSettings settings =
        ref.watch(appSettingsProvider).valueOrNull ?? const AppSettings();
    if (!_prefilled) {
      _prefilled = true;
      final AppUser? user = ref.read(currentUserProvider);
      if (user != null && user.displayName.isNotEmpty) {
        _name.text = user.displayName;
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.contactTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Text(
              AppStrings.contactSubtitle,
              style: TextStyle(
                color: AppColors.textMuted,
                height: 1.7,
              ),
            ),
            const SizedBox(height: 16),
            if (settings.phone.isNotEmpty)
              _ChannelTile(
                icon: Icons.call_outlined,
                title: AppStrings.callUs,
                subtitle: settings.phone,
                onTap: () =>
                    ContactUtils.callPhone(context, settings.phone),
              ),
            if (settings.whatsapp.isNotEmpty)
              _ChannelTile(
                icon: Icons.chat_outlined,
                title: AppStrings.whatsapp,
                subtitle: settings.whatsapp,
                color: AppColors.success,
                onTap: () => ContactUtils.openWhatsApp(
                  context,
                  settings.whatsapp,
                ),
              ),
            if (settings.email.isNotEmpty)
              _ChannelTile(
                icon: Icons.email_outlined,
                title: AppStrings.emailUs,
                subtitle: settings.email,
                onTap: () =>
                    ContactUtils.sendEmail(context, settings.email),
              ),
            if (settings.address.isNotEmpty)
              _ChannelTile(
                icon: Icons.location_on_outlined,
                title: AppStrings.ourAddress,
                subtitle: settings.address,
                onTap: null,
              ),
            if (settings.facebookUrl.isNotEmpty)
              _ChannelTile(
                icon: Icons.facebook,
                title: 'فيسبوك',
                subtitle: settings.facebookUrl,
                color: AppColors.info,
                onTap: () => ContactUtils.openUrl(
                  context,
                  settings.facebookUrl,
                ),
              ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.stretch,
                    children: <Widget>[
                      const Text(
                        AppStrings.sendMessage,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 14),
                      AppTextField(
                        label: AppStrings.yourName,
                        controller: _name,
                        validator: Validators.name,
                        prefixIcon: Icons.person_outline,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        label: AppStrings.yourPhone,
                        controller: _phone,
                        validator: Validators.phone,
                        keyboardType: TextInputType.phone,
                        prefixIcon: Icons.phone_outlined,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        label: AppStrings.yourMessage,
                        hint: AppStrings.messageHint,
                        controller: _message,
                        validator: Validators.message,
                        maxLines: 4,
                        minLines: 3,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _sending ? null : _send,
                        child: _sending
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(AppStrings.sendMessage),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChannelTile extends StatelessWidget {
  const _ChannelTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.color = AppColors.primary,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textMuted,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        trailing: onTap == null
            ? null
            : const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppColors.textMuted,
              ),
        onTap: onTap,
      ),
    );
  }
}
