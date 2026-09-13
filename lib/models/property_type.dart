import 'package:equatable/equatable.dart';

/// Firestore `property_types/{id}` — admin-managed catalog.
class PropertyType extends Equatable {
  const PropertyType({
    required this.id,
    required this.name,
    this.icon = 'home',
    this.order = 0,
    this.isActive = true,
  });

  final String id;
  final String name;
  final String icon;
  final int order;
  final bool isActive;

  factory PropertyType.fromMap(String id, Map<String, dynamic> map) {
    return PropertyType(
      id: id,
      name: (map['name'] as String? ?? '').trim(),
      icon: map['icon'] as String? ?? 'home',
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
