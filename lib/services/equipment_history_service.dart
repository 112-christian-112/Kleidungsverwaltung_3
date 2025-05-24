// services/equipment_history_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/equipment_history_model.dart';
import '../models/equipment_model.dart';

class EquipmentHistoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Fügt einen neuen Historien-Eintrag hinzu
  Future<DocumentReference> addHistoryEntry({
    required String equipmentId,
    required String action,
    required String field,
    dynamic oldValue,
    dynamic newValue,
  }) async {
    try {
      // Aktuellen Benutzer ermitteln
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Kein Benutzer angemeldet');
      }

      // Benutzername aus Firestore holen
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      String userName = userDoc.exists
          ? (userDoc.data() as Map<String, dynamic>)['name'] ?? currentUser.email ?? 'Unbekannt'
          : currentUser.email ?? 'Unbekannt';

      // Historien-Eintrag erstellen
      EquipmentHistoryModel historyEntry = EquipmentHistoryModel(
        id: '', // Wird von Firestore generiert
        equipmentId: equipmentId,
        action: action,
        field: field,
        oldValue: oldValue,
        newValue: newValue,
        timestamp: DateTime.now(),
        performedBy: currentUser.uid,
        performedByName: userName,
      );

      // In Firestore speichern
      return await _firestore.collection('equipment_history').add(historyEntry.toMap());
    } catch (e) {
      throw Exception('Fehler beim Hinzufügen des Historien-Eintrags: $e');
    }
  }

  // Holt die Historie für ein bestimmtes Equipment-Element
  Stream<List<EquipmentHistoryModel>> getEquipmentHistory(String equipmentId) {
    return _firestore
        .collection('equipment_history')
        .where('equipmentId', isEqualTo: equipmentId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => EquipmentHistoryModel.fromMap(
        doc.data() as Map<String, dynamic>, doc.id))
        .toList());
  }

  // Erfasst die Erstellung eines neuen Equipment-Elements
  Future<void> recordEquipmentCreation(EquipmentModel equipment) async {
    try {
      await addHistoryEntry(
        equipmentId: equipment.id,
        action: HistoryAction.created,
        field: 'Einsatzkleidung',
        newValue: '${equipment.article} (${equipment.type}, ${equipment.size})',
      );
    } catch (e) {
      print('Fehler beim Aufzeichnen der Ausrüstungserstellung: $e');
      // Wir werfen hier keine Exception, damit die Hauptoperation fortgesetzt werden kann
    }
  }

  // Erfasst eine Feldaktualisierung
  Future<void> recordFieldUpdate({
    required String equipmentId,
    required String field,
    required dynamic oldValue,
    required dynamic newValue,
  }) async {
    try {
      await addHistoryEntry(
        equipmentId: equipmentId,
        action: HistoryAction.updated,
        field: field,
        oldValue: oldValue,
        newValue: newValue,
      );
    } catch (e) {
      print('Fehler beim Aufzeichnen der Feldaktualisierung: $e');
    }
  }

  // Erfasst die Löschung eines Equipment-Elements
  Future<void> recordEquipmentDeletion(EquipmentModel equipment) async {
    try {
      await addHistoryEntry(
        equipmentId: equipment.id,
        action: HistoryAction.deleted,
        field: 'Einsatzkleidung',
        oldValue: '${equipment.article} (${equipment.type}, ${equipment.size})',
      );
    } catch (e) {
      print('Fehler beim Aufzeichnen der Ausrüstungslöschung: $e');
    }
  }
}
