import 'package:equatable/equatable.dart';

/// Firestore `cities/{id}` — admin-managed catalog.
class City extends Equatable {
  const City({
    required this.id,
    required this.name,
    this.order = 0,
    this.isActive = true,
  });

  final String id;
  final String name;
  final int order;
  final bool isActive;

  factory City.fromMap(String id, Map<String, dynamic> map) {
    return City(
      id: id,
      name: (map['name'] as String? ?? '').trim(),
      order: ((map['order'] as num?) ?? 0).toInt(),
      isActive: map['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'order': order,
      'isActive': isActive,
    };
  }

  @override
  List<Object?> get props => <Object?>[id, name, order, isActive];
}
