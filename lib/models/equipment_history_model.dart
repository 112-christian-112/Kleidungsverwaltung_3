// models/equipment_history_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class EquipmentHistoryModel {
  final String id;
  final String equipmentId;
  final String action;
  final String field;
  final dynamic oldValue;
  final dynamic newValue;
  final DateTime timestamp;
  final String performedBy;
  final String performedByName;

  EquipmentHistoryModel({
    required this.id,
    required this.equipmentId,
    required this.action,
    required this.field,
    this.oldValue,
    this.newValue,
    required this.timestamp,
    required this.performedBy,
    required this.performedByName,
  });

  Map<String, dynamic> toMap() {
    return {
      'equipmentId': equipmentId,
      'action': action,
      'field': field,
      'oldValue': oldValue,
      'newValue': newValue,
      'timestamp': timestamp,
      'performedBy': performedBy,
      'performedByName': performedByName,
    };
  }

  factory EquipmentHistoryModel.fromMap(Map<String, dynamic> map, String documentId) {
    return EquipmentHistoryModel(
      id: documentId,
      equipmentId: map['equipmentId'] ?? '',
      action: map['action'] ?? '',
      field: map['field'] ?? '',
      oldValue: map['oldValue'],
      newValue: map['newValue'],
      timestamp: map['timestamp']?.toDate() ?? DateTime.now(),
      performedBy: map['performedBy'] ?? '',
      performedByName: map['performedByName'] ?? '',
    );
  }
}

// Aktionskonstanten für die Historie
class HistoryAction {
  static const String created = 'Erstellt';
  static const String updated = 'Aktualisiert';
  static const String deleted = 'Gelöscht';
}

