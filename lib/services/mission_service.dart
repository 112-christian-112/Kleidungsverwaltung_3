// services/mission_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/mission_model.dart';
import '../models/equipment_model.dart';
import 'equipment_service.dart';

class MissionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final EquipmentService _equipmentService = EquipmentService();

  // Einsatz erstellen
  Future<DocumentReference> createMission(MissionModel mission) async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('Kein Benutzer angemeldet');
    }

    // Einsatz in Firestore speichern
    return await _firestore.collection('missions').add(mission.toMap());
  }

  // Einsatz aktualisieren
  Future<void> updateMission(MissionModel mission) async {
    await _firestore.collection('missions').doc(mission.id).update(mission.toMap());
  }

  // Ausrüstungsgegenstände zu einem Einsatz hinzufügen
  Future<void> addEquipmentToMission(String missionId, List<String> equipmentIds) async {
    DocumentReference missionRef = _firestore.collection('missions').doc(missionId);

    await _firestore.runTransaction((transaction) async {
      DocumentSnapshot missionSnapshot = await transaction.get(missionRef);

      if (!missionSnapshot.exists) {
        throw Exception('Einsatz nicht gefunden');
      }

      List<String> currentEquipment = List<String>.from(
          (missionSnapshot.data() as Map<String, dynamic>)['equipmentIds'] ?? []);

      // Neue IDs hinzufügen (ohne Duplikate)
      for (String id in equipmentIds) {
        if (!currentEquipment.contains(id)) {
          currentEquipment.add(id);
        }
      }

      transaction.update(missionRef, {'equipmentIds': currentEquipment});
    });
  }

  // Alle Einsätze abrufen
  Stream<List<MissionModel>> getAllMissions() {
    return _firestore
        .collection('missions')
        .orderBy('startTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => MissionModel.fromMap(doc.data(), doc.id))
        .toList());
  }

  // Einsätze nach Feuerwehrstation filtern
  Stream<List<MissionModel>> getMissionsByFireStation(String fireStation) {
    return _firestore
        .collection('missions')
        .where('fireStation', isEqualTo: fireStation)
        .orderBy('startTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => MissionModel.fromMap(doc.data(), doc.id))
        .toList());
  }

  // Alle Ausrüstungsgegenstände für einen Einsatz abrufen
  Future<List<EquipmentModel>> getEquipmentForMission(String missionId) async {
    DocumentSnapshot missionDoc = await _firestore.collection('missions').doc(missionId).get();

    if (!missionDoc.exists) {
      throw Exception('Einsatz nicht gefunden');
    }

    List<String> equipmentIds = List<String>.from(
        (missionDoc.data() as Map<String, dynamic>)['equipmentIds'] ?? []);

    List<EquipmentModel> equipmentList = [];

    // Für jede ID die zugehörige Ausrüstung abrufen
    for (String id in equipmentIds) {
      EquipmentModel? equipment = await _equipmentService.getEquipmentById(id);
      if (equipment != null) {
        equipmentList.add(equipment);
      }
    }

    return equipmentList;
  }

  // Einsatz löschen
  Future<void> deleteMission(String missionId) async {
    await _firestore.collection('missions').doc(missionId).delete();
  }

  // NEUE METHODE: Alle Einsätze abrufen, bei denen ein bestimmtes Equipment verwendet wurde
  Future<List<MissionModel>> getMissionsForEquipment(String equipmentId) async {
    try {
      // Firestore-Abfrage, um Einsätze zu finden, die dieses Equipment verwenden
      QuerySnapshot querySnapshot = await _firestore
          .collection('missions')
          .where('equipmentIds', arrayContains: equipmentId)
          .orderBy('startTime', descending: true)
          .get();

      // Ergebnisse in MissionModel-Objekte umwandeln
      List<MissionModel> missions = querySnapshot.docs
          .map((doc) => MissionModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      return missions;
    } catch (e) {
      print('Fehler beim Abrufen der Einsätze für Equipment $equipmentId: $e');
      return [];
    }
  }

  // Einzelnen Einsatz abrufen
  Future<MissionModel?> getMissionById(String missionId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('missions').doc(missionId).get();

      if (!doc.exists) {
        return null;
      }

      return MissionModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    } catch (e) {
      print('Fehler beim Abrufen des Einsatzes: $e');
      return null;
    }
  }
}