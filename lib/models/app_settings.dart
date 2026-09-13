import 'package:equatable/equatable.dart';

/// Firestore `settings/app` — public contact info + legal pages.
class AppSettings extends Equatable {
  const AppSettings({
    this.phone = '',
    this.whatsapp = '',
    this.email = '',
    this.address = '',
    this.facebookUrl = '',
    this.aboutAr = '',
    this.termsAr = '',
    this.privacyAr = '',
  });

  final String phone;
  final String whatsapp;
  final String email;
  final String address;
  final String facebookUrl;
  final String aboutAr;
  final String termsAr;
  final String privacyAr;

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      phone: (map['phone'] as String? ?? '').trim(),
      whatsapp: (map['whatsapp'] as String? ?? '').trim(),
      email: (map['email'] as String? ?? '').trim(),
      address: (map['address'] as String? ?? '').trim(),
      facebookUrl: (map['facebookUrl'] as String? ?? '').trim(),
      aboutAr: map['aboutAr'] as String? ?? '',
      termsAr: map['termsAr'] as String? ?? '',
      privacyAr: map['privacyAr'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'phone': phone,
      'whatsapp': whatsapp,
      'email': email,
      'address': address,
      'facebookUrl': facebookUrl,
      'aboutAr': aboutAr,
      'termsAr': termsAr,
      'privacyAr': privacyAr,
    };
  }

  @override
  List<Object?> get props => <Object?>[
        phone,
        whatsapp,
        email,
        address,
        facebookUrl,
        aboutAr,
        termsAr,
        privacyAr,
      ];
}
