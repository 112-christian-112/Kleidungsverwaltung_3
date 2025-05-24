// models/equipment_model.dart
import 'package:flutter/material.dart';

class EquipmentModel {
  final String id;
  final String nfcTag;
  final String? barcode;
  final String article;
  final String type;
  final String size;
  final String fireStation;
  final String owner;
  final int washCycles;
  final DateTime checkDate;
  final DateTime createdAt;
  final String createdBy;
  final String status;

  EquipmentModel({
    required this.id,
    required this.nfcTag,
    this.barcode,
    required this.article,
    required this.type,
    required this.size,
    required this.fireStation,
    required this.owner,
    required this.washCycles,
    required this.checkDate,
    required this.createdAt,
    required this.createdBy,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'nfcTag': nfcTag,
      'barcode': barcode,
      'article': article,
      'type': type,
      'size': size,
      'fireStation': fireStation,
      'owner': owner,
      'washCycles': washCycles,
      'checkDate': checkDate,
      'createdAt': createdAt,
      'createdBy': createdBy,
      'status': status,
    };
  }

  factory EquipmentModel.fromMap(Map<String, dynamic> map, String documentId) {
    return EquipmentModel(
      id: documentId,
      nfcTag: map['nfcTag'] ?? '',
      barcode: map['barcode'],
      article: map['article'] ?? '',
      type: map['type'] ?? '',
      size: map['size'] ?? '',
      fireStation: map['fireStation'] ?? '',
      owner: map['owner'] ?? '',
      washCycles: map['washCycles'] ?? 0,
      checkDate: map['checkDate']?.toDate() ?? DateTime.now(),
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
      createdBy: map['createdBy'] ?? '',
        status: map['status'] ?? 'Einsatzbereit',
    );
  }
}

// Konstanten für Status-Optionen hinzufügen
class EquipmentStatus {
  static const String ready = 'Einsatzbereit';
  static const String cleaning = 'In der Reinigung';
  static const String repair = 'In Reparatur';
  static const String retired = 'Ausgemustert';

  static const List<String> values = [ready, cleaning, repair, retired];

  // Farbzuordnungen für die verschiedenen Status
  static Color getStatusColor(String status) {
    switch (status) {
      case ready:
        return Colors.green;
      case cleaning:
        return Colors.blue;
      case repair:
        return Colors.orange;
      case retired:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Icon-Zuordnungen für die verschiedenen Status
  static IconData getStatusIcon(String status) {
    switch (status) {
      case ready:
        return Icons.check_circle;
      case cleaning:
        return Icons.local_laundry_service;
      case repair:
        return Icons.build;
      case retired:
        return Icons.do_not_disturb;
      default:
        return Icons.help;
    }
  }
}
