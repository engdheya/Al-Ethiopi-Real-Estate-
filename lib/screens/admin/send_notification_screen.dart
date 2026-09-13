import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/app_text_field.dart';
import '../../firebase/firebase_providers.dart';
import '../../l10n/app_strings.dart';
import '../../models/app_notification.dart';
import '../../models/property.dart';
import '../../models/property_filter.dart';
import '../../models/property_page.dart';
import '../../theme/app_colors.dart';

/// Admin broadcast composer. Writes to `notifications` (in-app inbox);
/// push delivery to devices additionally requires the Cloud Function
/// in `functions/` to be deployed (see docs).
class SendNotificationScreen extends ConsumerStatefulWidget {
  const SendNotificationScreen({super.key});

  @override
  ConsumerState<SendNotificationScreen> createState() =>
      _SendNotificationScreenState();
}

class _SendNotificationScreenState
    extends ConsumerState<SendNotificationScreen> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  final TextEditingController _title = TextEditingController();
  final TextEditingController _body = TextEditingController();
  final TextEditingController _imageUrl = TextEditingController();
  String _type = 'announcement';
  String? _propertyId;
  bool _sending = false;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    _imageUrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() => _sending = true);
    try {
      await ref.read(notificationRepositoryProvider).sendNotification(
            AppNotification(
              id: '',
              title: _title.text.trim(),
              body: _body.text.trim(),
              type: _type,
              propertyId:
                  _propertyId?.isEmpty == true ? null : _propertyId,
              imageUrl: _imageUrl.text.trim().isEmpty
                  ? null
                  : _imageUrl.text.trim(),
            ),
          );
      if (!mounted) return;
      showSuccessSnack(context, AppStrings.notificationSent);
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.sendNotification)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'يظهر الإشعار فوراً في صندوق الإشعارات داخل التطبيق، ويصل كإشعار فوري للأجهزة عند نشر دالة Cloud Functions المرفقة (مجلد functions).',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.7,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: AppStrings.notificationTitle,
                controller: _title,
                validator: (String? v) =>
                    v == null || v.trim().isEmpty
                        ? AppStrings.requiredField
                        : null,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: AppStrings.notificationBody,
                controller: _body,
                validator: (String? v) =>
                    v == null || v.trim().isEmpty
                        ? AppStrings.requiredField
                        : null,
                maxLines: 4,
                minLines: 3,
              ),
              const SizedBox(height: 14),
              const Text(
                'النوع',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              SegmentedButton<String>(
                segments: const <ButtonSegment<String>>[
                  ButtonSegment<String>(
                    value: 'announcement',
                    label: Text('إعلان عام'),
                  ),
                  ButtonSegment<String>(
                    value: 'featured_property',
                    label: Text('عقار مميز'),
                  ),
                ],
                selected: <String>{_type},
                onSelectionChanged: (Set<String> s) =>
                    setState(() => _type = s.first),
              ),
              const SizedBox(height: 14),
              _PropertyPicker(
                value: _propertyId,
                onChanged: (String? v) =>
                    setState(() => _propertyId = v),
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: 'رابط صورة (اختياري)',
                hint: 'https://...',
                controller: _imageUrl,
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _sending ? null : _send,
                icon: _sending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_outlined),
                label: const Text(AppStrings.sendNotification),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PropertyPicker extends ConsumerWidget {
  const _PropertyPicker({required this.value, required this.onChanged});

  final String? value;
  final void Function(String?) onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<PropertyPage>(
      future: ref
          .read(propertyRepositoryProvider)
          .fetchProperties(
            filter: const PropertyFilter(),
            limit: 30,
          ),
      builder: (
        BuildContext context,
        AsyncSnapshot<PropertyPage> snap,
      ) {
        final List<Property> items =
            snap.data?.items ?? const <Property>[];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              AppStrings.linkedProperty,
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: value,
              items: <DropdownMenuItem<String>>[
                const DropdownMenuItem<String>(
                  child: Text(AppStrings.noLinkedProperty),
                ),
                for (final Property p in items)
                  DropdownMenuItem<String>(
                    value: p.id,
                    child: Text(
                      p.title,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: onChanged,
            ),
          ],
        );
      },
    );
  }
}
