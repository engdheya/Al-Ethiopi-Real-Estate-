import 'package:flutter/material.dart';

/// Maps the catalog `icon` string to a Material icon.
IconData typeIconFromName(String? name) {
  switch (name) {
    case 'apartment':
      return Icons.apartment;
    case 'home':
      return Icons.home_outlined;
    case 'villa':
      return Icons.villa_outlined;
    case 'landscape':
      return Icons.landscape_outlined;
    case 'terrain':
      return Icons.terrain_outlined;
    case 'store':
      return Icons.store_outlined;
    case 'business':
      return Icons.business_outlined;
    case 'domain':
      return Icons.domain_outlined;
    case 'real_estate_agent':
      return Icons.real_estate_agent_outlined;
    case 'hotel':
      return Icons.hotel_outlined;
    case 'warehouse':
      return Icons.warehouse_outlined;
    case 'cabin':
      return Icons.cabin_outlined;
    default:
      return Icons.home_work_outlined;
  }
}

/// Maps feature catalog `icon` strings to Material icons.
IconData featureIconFromName(String? name) {
  switch (name) {
    case 'water':
      return Icons.water_drop_outlined;
    case 'electric':
      return Icons.electric_bolt_outlined;
    case 'parking':
      return Icons.local_parking_outlined;
    case 'kitchen':
      return Icons.kitchen_outlined;
    case 'ac':
      return Icons.ac_unit_outlined;
    case 'yard':
      return Icons.yard_outlined;
    case 'elevator':
      return Icons.elevator_outlined;
    case 'furniture':
      return Icons.chair_outlined;
    case 'road':
      return Icons.add_road_outlined;
    case 'tank':
      return Icons.water_outlined;
    case 'internet':
      return Icons.wifi_outlined;
    case 'security':
      return Icons.security_outlined;
    default:
      return Icons.check_circle_outline;
  }
}
