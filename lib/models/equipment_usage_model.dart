// models/equipment_usage_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'mission_model.dart';

class EquipmentUsageModel {
  final String id;
  final String equipmentId;
  final String missionId;
  final MissionType missionType;
  final DateTime usageDate;
  final int durationMinutes; // Einsatzdauer in Minuten
  final int temperature;
  final bool wasHazardous;
  final int stressLevel;  // Berechneter Belastungswert (1-10)

  EquipmentUsageModel({
    required this.id,
    required this.equipmentId,
    required this.missionId,
    required this.missionType,
    required this.usageDate,
    required this.durationMinutes,
    required this.temperature,
    required this.wasHazardous,
    required this.stressLevel,
  });

  Map<String, dynamic> toMap() {
    return {
      'equipmentId': equipmentId,
      'missionId': missionId,
      'missionType': missionType.toString().split('.').last,
      'usageDate': usageDate,
      'durationMinutes': durationMinutes,
      'temperature': temperature,
      'wasHazardous': wasHazardous,
      'stressLevel': stressLevel,
    };
  }

  factory EquipmentUsageModel.fromMap(Map<String, dynamic> map, String documentId) {
    MissionType parseType(String typeString) {
      switch (typeString) {
        case 'fire': return MissionType.fire;
        case 'technical': return MissionType.technical;
        case 'hazmat': return MissionType.hazmat;
        case 'water': return MissionType.water;
        case 'training': return MissionType.training;
        default: return MissionType.other;
      }
    }

    return EquipmentUsageModel(
      id: documentId,
      equipmentId: map['equipmentId'] ?? '',
      missionId: map['missionId'] ?? '',
      missionType: parseType(map['missionType'] ?? ''),
      usageDate: map['usageDate']?.toDate() ?? DateTime.now(),
      durationMinutes: map['durationMinutes'] ?? 0,
      temperature: map['temperature'] ?? 20,
      wasHazardous: map['wasHazardous'] ?? false,
      stressLevel: map['stressLevel'] ?? 1,
    );
  }
}