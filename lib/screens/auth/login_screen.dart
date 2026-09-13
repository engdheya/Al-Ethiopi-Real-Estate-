import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/validators.dart';
import '../../core/widgets/app_logo.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/app_text_field.dart';
import '../../demo/demo_store.dart';
import '../../firebase/firebase_providers.dart';
import '../../l10n/app_strings.dart';
import '../../providers/auth_providers.dart';
import '../../routes/app_routes.dart';
import '../../services/notification_service.dart';
import '../../theme/app_colors.dart';

/// Email/password + Google sign-in. Guests can skip.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  bool _googleLoading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _afterLogin() async {
    // Best-effort: enable push + store token for the new session.
    try {
      final String? token = await ref
          .read(notificationServiceProvider)
          .enableNotifications();
      final String? uid =
          ref.read(authStateProvider).valueOrNull?.uid;
      if (token != null && token.isNotEmpty && uid != null) {
        await ref.read(authRepositoryProvider).saveFcmToken(uid, token);
      }
    } catch (_) {}
    // Fresh admin-claim evaluation for admins.
    ref.invalidate(isAdminProvider);
    if (!mounted) return;
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      await Navigator.of(context)
          .pushReplacementNamed(AppRoutes.main);
    }
  }

  Future<void> _login() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).signInWithEmail(
            _email.text,
            _password.text,
          );
      await _afterLogin();
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loginGoogle() async {
    setState(() => _googleLoading = true);
    try {
      await ref.read(authRepositoryProvider).signInWithGoogle();
      await _afterLogin();
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.login)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Center(child: AppLogoMark(size: 84, radius: 20)),
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  AppStrings.welcomeBack,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (DemoStore.enabled)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.goldSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'وضع العرض: سجّل بأي بريد، واستخدم admin@alethiopi.com لتجربة لوحة الإدارة.',
                    style: TextStyle(fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),
              AppTextField(
                label: AppStrings.email,
                hint: 'example@mail.com',
                controller: _email,
                validator: Validators.email,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email_outlined,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: AppStrings.password,
                controller: _password,
                validator: Validators.password,
                obscureText: _obscure,
                prefixIcon: Icons.lock_outline,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _login(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () =>
                      setState(() => _obscure = !_obscure),
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => Navigator.of(context)
                      .pushNamed(AppRoutes.forgotPassword),
                  child: const Text(AppStrings.forgotPassword),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _loading ? null : _login,
                child: _loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(AppStrings.login),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _googleLoading ? null : _loginGoogle,
                icon: _googleLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(
                        Icons.g_mobiledata,
                        size: 26,
                        color: AppColors.primary,
                      ),
                label: const Text(AppStrings.loginWithGoogle),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Text(AppStrings.noAccount),
                  TextButton(
                    onPressed: () => Navigator.of(context)
                        .pushReplacementNamed(AppRoutes.register),
                    child: const Text(AppStrings.register),
                  ),
                ],
              ),
              Center(
                child: TextButton(
                  onPressed: () {
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    } else {
                      Navigator.of(context)
                          .pushReplacementNamed(AppRoutes.main);
                    }
                  },
                  child: const Text(AppStrings.continueAsGuest),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
