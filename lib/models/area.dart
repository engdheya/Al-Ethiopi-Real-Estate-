import 'package:equatable/equatable.dart';

/// Firestore `areas/{id}` — each area belongs to one city.
class Area extends Equatable {
  const Area({
    required this.id,
    required this.name,
    required this.cityId,
    this.order = 0,
    this.isActive = true,
  });

  final String id;
  final String name;
  final String cityId;
  final int order;
  final bool isActive;

  factory Area.fromMap(String id, Map<String, dynamic> map) {
    return Area(
      id: id,
      name: (map['name'] as String? ?? '').trim(),
      cityId: map['cityId'] as String? ?? '',
      order: ((map['order'] as num?) ?? 0).toInt(),
      isActive: map['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'cityId': cityId,
      'order': order,
      'isActive': isActive,
    };
  }

  @override
  List<Object?> get props => <Object?>[id, name, cityId, order, isActive];
}
