// models/mission_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum MissionType {
  fire,       // Brandeinsatz
  technical,  // Technische Hilfeleistung
  hazmat,     // Gefahrgut
  water,      // Hochwasser/Wasserschaden
  training,   // Übung
  other       // Sonstige
}

class MissionModel {
  final String id;
  final String name;
  final DateTime startTime;
  final String type;
  final String location;
  final String description;
  final List<String> equipmentIds; // Verwendete Ausrüstungs-IDs
  final String fireStation;        // Hauptfeuerwehr (die den Einsatz angelegt hat)
  final List<String> involvedFireStations; // Beteiligte Ortswehren (NEU)
  final String createdBy;
  final DateTime createdAt;

  MissionModel({
    required this.id,
    required this.name,
    required this.startTime,
    required this.type,
    required this.location,
    required this.description,
    required this.equipmentIds,
    required this.fireStation,
    required this.involvedFireStations, // NEU
    required this.createdBy,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'startTime': startTime,
      'type': type,
      'location': location,
      'description': description,
      'equipmentIds': equipmentIds,
      'fireStation': fireStation,
      'involvedFireStations': involvedFireStations, // NEU
      'createdBy': createdBy,
      'createdAt': createdAt,
    };
  }

  factory MissionModel.fromMap(Map<String, dynamic> map, String documentId) {
    return MissionModel(
      id: documentId,
      name: map['name'] ?? '',
      startTime: map['startTime']?.toDate() ?? DateTime.now(),
      type: map['type'] ?? 'other',
      location: map['location'] ?? '',
      description: map['description'] ?? '',
      equipmentIds: List<String>.from(map['equipmentIds'] ?? []),
      fireStation: map['fireStation'] ?? '',
      involvedFireStations: List<String>.from(map['involvedFireStations'] ?? []), // NEU
      createdBy: map['createdBy'] ?? '',
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
    );
  }
}