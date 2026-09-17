import 'package:equatable/equatable.dart';

/// Firestore `features/{id}` — admin-managed amenity catalog
/// (water, electricity, parking, ...).
class FeatureItem extends Equatable {
  const FeatureItem({
    required this.id,
    required this.name,
    this.icon = 'check_circle',
    this.order = 0,
    this.isActive = true,
  });

  final String id;
  final String name;
  final String icon;
  final int order;
  final bool isActive;

  factory FeatureItem.fromMap(String id, Map<String, dynamic> map) {
    return FeatureItem(
      id: id,
      name: (map['name'] as String? ?? '').trim(),
      icon: map['icon'] as String? ?? 'check_circle',
      order: ((map['order'] as num?) ?? 0).toInt(),
      isActive: map['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'icon': icon,
      'order': order,
      'isActive': isActive,
    };
  }

  @override
  List<Object?> get props => <Object?>[id, name, icon, order, isActive];
}
