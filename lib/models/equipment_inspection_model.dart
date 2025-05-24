// 1. Zuerst ergänzen wir das Datenmodell um Prüfungsinformationen
// models/equipment_inspection_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

enum InspectionResult {
  passed,
  conditionalPass,
  failed
}

class EquipmentInspectionModel {
  final String id;
  final String equipmentId;
  final DateTime inspectionDate;
  final String inspector;
  final InspectionResult result;
  final String comments;
  final DateTime nextInspectionDate;
  final List<String>? issues;
  final DateTime createdAt;
  final String createdBy;

  EquipmentInspectionModel({
    required this.id,
    required this.equipmentId,
    required this.inspectionDate,
    required this.inspector,
    required this.result,
    required this.comments,
    required this.nextInspectionDate,
    this.issues,
    required this.createdAt,
    required this.createdBy,
  });

  Map<String, dynamic> toMap() {
    return {
      'equipmentId': equipmentId,
      'inspectionDate': inspectionDate,
      'inspector': inspector,
      'result': result.toString().split('.').last,
      'comments': comments,
      'nextInspectionDate': nextInspectionDate,
      'issues': issues,
      'createdAt': createdAt,
      'createdBy': createdBy,
    };
  }

  factory EquipmentInspectionModel.fromMap(Map<String, dynamic> map, String documentId) {
    InspectionResult parseResult(String resultString) {
      switch (resultString) {
        case 'passed':
          return InspectionResult.passed;
        case 'conditionalPass':
          return InspectionResult.conditionalPass;
        case 'failed':
          return InspectionResult.failed;
        default:
          return InspectionResult.failed;
      }
    }

    return EquipmentInspectionModel(
      id: documentId,
      equipmentId: map['equipmentId'] ?? '',
      inspectionDate: map['inspectionDate']?.toDate() ?? DateTime.now(),
      inspector: map['inspector'] ?? '',
      result: parseResult(map['result'] ?? 'failed'),
      comments: map['comments'] ?? '',
      nextInspectionDate: map['nextInspectionDate']?.toDate() ?? DateTime.now().add(const Duration(days: 365)),
      issues: List<String>.from(map['issues'] ?? []),
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
      createdBy: map['createdBy'] ?? '',
    );
  }
}
