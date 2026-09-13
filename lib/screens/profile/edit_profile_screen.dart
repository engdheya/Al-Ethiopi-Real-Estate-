import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/image_helper.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/app_text_field.dart';
import '../../firebase/firebase_providers.dart';
import '../../l10n/app_strings.dart';
import '../../models/app_user.dart';
import '../../providers/auth_providers.dart';
import '../../theme/app_colors.dart';

/// Edit display name + avatar photo.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() =>
      _EditProfileScreenState();
}

class _EditProfileScreenState
    extends ConsumerState<EditProfileScreen> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  File? _newAvatar;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name.text =
        ref.read(currentUserProvider)?.displayName ?? '';
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    try {
      final File? file = await ImageHelper.pickSingleImage();
      if (file == null) return;
      setState(() => _newAvatar = file);
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    }
  }

  Future<void> _save() async {
    final AppUser? user = ref.read(currentUserProvider);
    if (user == null) return;
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      String? photoUrl;
      if (_newAvatar != null) {
        photoUrl = await ref
            .read(storageRepositoryProvider)
            .uploadAvatar(uid: user.uid, file: _newAvatar!);
      }
      await ref.read(authRepositoryProvider).updateProfile(
            displayName: _name.text.trim(),
            photoUrl: photoUrl,
          );
      if (mounted) {
        showSuccessSnack(context, AppStrings.profileUpdated);
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppUser? user = ref.watch(currentUserProvider);
    ImageProvider? avatar;
    if (_newAvatar != null) {
      avatar = FileImage(_newAvatar!);
    } else if (user?.photoUrl?.isNotEmpty == true) {
      final String url = user!.photoUrl!;
      avatar = url.startsWith('http')
          ? NetworkImage(url)
          : FileImage(File(url)) as ImageProvider;
    }

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.editProfile)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Center(
                child: Stack(
                  children: <Widget>[
                    CircleAvatar(
                      radius: 56,
                      backgroundColor: AppColors.primarySoft,
                      backgroundImage: avatar,
                      child: avatar == null
                          ? Text(
                              _name.text.isEmpty
                                  ? '?'
                                  : _name.text.characters.first,
                              style: const TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      child: Material(
                        color: AppColors.primary,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: _pickAvatar,
                          child: const Padding(
                            padding: EdgeInsets.all(10),
                            child: Icon(
                              Icons.camera_alt_outlined,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              AppTextField(
                label: AppStrings.displayName,
                controller: _name,
                validator: Validators.name,
                prefixIcon: Icons.person_outline,
                textInputAction: TextInputAction.done,
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _save(),
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: AppStrings.email,
                initialValue: user?.email ?? '',
                enabled: false,
                prefixIcon: Icons.email_outlined,
              ),
              const SizedBox(height: 24),
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
      ),
    );
  }
}
