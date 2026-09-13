import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/validators.dart';
import '../../core/widgets/app_logo.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/app_text_field.dart';
import '../../firebase/firebase_providers.dart';
import '../../l10n/app_strings.dart';
import '../../providers/auth_providers.dart';
import '../../routes/app_routes.dart';

/// Simple registration: name + e-mail + password.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirm = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).registerWithEmail(
            name: _name.text.trim(),
            email: _email.text,
            password: _password.text,
          );
      ref.invalidate(isAdminProvider);
      if (!mounted) return;
      showSuccessSnack(context, AppStrings.accountCreated);
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        await Navigator.of(context)
            .pushReplacementNamed(AppRoutes.main);
      }
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.register)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Center(child: AppLogoMark(size: 76, radius: 18)),
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  AppStrings.createAccountTitle,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              AppTextField(
                label: AppStrings.fullName,
                controller: _name,
                validator: Validators.name,
                prefixIcon: Icons.person_outline,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
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
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: AppStrings.confirmPassword,
                controller: _confirm,
                validator: (String? v) =>
                    Validators.confirmPassword(v, _password.text),
                obscureText: _obscure,
                prefixIcon: Icons.lock_outline,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _register(),
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
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loading ? null : _register,
                child: _loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(AppStrings.register),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Text(AppStrings.alreadyHaveAccount),
                  TextButton(
                    onPressed: () => Navigator.of(context)
                        .pushReplacementNamed(AppRoutes.login),
                    child: const Text(AppStrings.login),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
