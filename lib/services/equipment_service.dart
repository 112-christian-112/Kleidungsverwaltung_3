// services/equipment_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/equipment_model.dart';
import '../services/equipment_history_service.dart';

class EquipmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final EquipmentHistoryService _historyService = EquipmentHistoryService();

  // Einsatzkleidung hinzufügen
  Future<DocumentReference> addEquipment(EquipmentModel equipment) async {
    User? currentUser = _auth.currentUser;

    if (currentUser == null) {
      throw Exception('Kein Benutzer angemeldet');
    }

    // Prüfen, ob der NFC-Tag bereits existiert
    QuerySnapshot nfcCheck = await _firestore
        .collection('equipment')
        .where('nfcTag', isEqualTo: equipment.nfcTag)
        .limit(1)
        .get();

    if (nfcCheck.docs.isNotEmpty) {
      throw Exception('Dieser NFC-Tag ist bereits registriert');
    }

    // Prüfen, ob der Barcode bereits existiert (falls vorhanden)
    if (equipment.barcode != null && equipment.barcode!.isNotEmpty) {
      QuerySnapshot barcodeCheck = await _firestore
          .collection('equipment')
          .where('barcode', isEqualTo: equipment.barcode)
          .limit(1)
          .get();

      if (barcodeCheck.docs.isNotEmpty) {
        throw Exception('Dieser Barcode ist bereits registriert');
      }
    }

    // Einsatzkleidung in Firestore speichern
    DocumentReference docRef = await _firestore.collection('equipment').add(
        equipment.toMap());

    // Historien-Eintrag für die Erstellung
    EquipmentModel createdEquipment = EquipmentModel(
      id: docRef.id,
      nfcTag: equipment.nfcTag,
      barcode: equipment.barcode,
      article: equipment.article,
      type: equipment.type,
      size: equipment.size,
      fireStation: equipment.fireStation,
      owner: equipment.owner,
      washCycles: equipment.washCycles,
      checkDate: equipment.checkDate,
      createdAt: equipment.createdAt,
      createdBy: equipment.createdBy,
      status: equipment.status,
    );

    await _historyService.recordEquipmentCreation(createdEquipment);

    return docRef;
  }

  // Alle Einsatzkleidungen abrufen
  Stream<List<EquipmentModel>> getAllEquipment() {
    return _firestore
        .collection('equipment')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs
            .map((doc) =>
            EquipmentModel.fromMap(
                doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // Einsatzkleidung nach NFC-Tag suchen
  Future<EquipmentModel?> getEquipmentByNfcTag(String nfcTag) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('equipment')
          .where('nfcTag', isEqualTo: nfcTag)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      return EquipmentModel.fromMap(
          snapshot.docs.first.data() as Map<String, dynamic>,
          snapshot.docs.first.id);
    } catch (e) {
      print('Fehler beim Suchen nach NFC-Tag: $e');
      return null;
    }
  }

  // Einsatzkleidung nach Barcode suchen
  Future<EquipmentModel?> getEquipmentByBarcode(String barcode) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('equipment')
          .where('barcode', isEqualTo: barcode)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      return EquipmentModel.fromMap(
          snapshot.docs.first.data() as Map<String, dynamic>,
          snapshot.docs.first.id);
    } catch (e) {
      print('Fehler beim Suchen nach Barcode: $e');
      return null;
    }
  }

  // Waschzyklen aktualisieren
  Future<void> updateWashCycles(String equipmentId, int newWashCycles) async {
    try {
      // Aktuellen Wert abrufen
      DocumentSnapshot equipmentDoc = await _firestore.collection('equipment')
          .doc(equipmentId)
          .get();
      final oldWashCycles = (equipmentDoc.data() as Map<String,
          dynamic>)['washCycles'] ?? 0;

      // Daten aktualisieren
      await _firestore.collection('equipment').doc(equipmentId).update({
        'washCycles': newWashCycles,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Historie aufzeichnen
      await _historyService.recordFieldUpdate(
        equipmentId: equipmentId,
        field: 'Waschzyklen',
        oldValue: oldWashCycles,
        newValue: newWashCycles,
      );
    } catch (e) {
      throw Exception('Fehler beim Aktualisieren der Waschzyklen: $e');
    }
  }

  // Status aktualisieren
  Future<void> updateStatus(String equipmentId, String newStatus) async {
    try {
      // Aktuellen Wert und Status abrufen
      DocumentSnapshot equipmentDoc = await _firestore.collection('equipment')
          .doc(equipmentId)
          .get();

      if (!equipmentDoc.exists) {
        throw Exception('Einsatzkleidung nicht gefunden');
      }

      Map<String, dynamic> equipmentData = equipmentDoc.data() as Map<
          String,
          dynamic>;
      final oldStatus = equipmentData['status'] ?? '';
      final currentWashCycles = equipmentData['washCycles'] ?? 0;

      // Prüfen, ob der Status auf "In der Reinigung" geändert wird
      bool increaseWashCycles = newStatus == EquipmentStatus.cleaning &&
          oldStatus != EquipmentStatus.cleaning;

      // Daten-Updates vorbereiten
      Map<String, dynamic> updates = {
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Wenn der Status auf "In der Reinigung" geändert wird, Waschzyklen erhöhen
      if (increaseWashCycles) {
        updates['washCycles'] = currentWashCycles + 1;
      }

      // Daten in Firestore aktualisieren
      await _firestore.collection('equipment').doc(equipmentId).update(updates);

      // Historie aufzeichnen - Status
      await _historyService.recordFieldUpdate(
        equipmentId: equipmentId,
        field: 'Status',
        oldValue: oldStatus,
        newValue: newStatus,
      );

      // Separat Historie für Waschzyklen aufzeichnen, falls erhöht
      if (increaseWashCycles) {
        await _historyService.recordFieldUpdate(
          equipmentId: equipmentId,
          field: 'Waschzyklen',
          oldValue: currentWashCycles,
          newValue: currentWashCycles + 1,
        );
      }
    } catch (e) {
      throw Exception('Fehler beim Aktualisieren des Status: $e');
    }
  }

  // Prüfdatum aktualisieren
  Future<void> updateCheckDate(String equipmentId,
      DateTime newCheckDate) async {
    try {
      // Aktuellen Wert abrufen
      DocumentSnapshot equipmentDoc = await _firestore.collection('equipment')
          .doc(equipmentId)
          .get();
      final oldCheckDate = (equipmentDoc.data() as Map<String,
          dynamic>)['checkDate']?.toDate() ?? DateTime.now();

      // Daten aktualisieren
      await _firestore.collection('equipment').doc(equipmentId).update({
        'checkDate': newCheckDate,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Historie aufzeichnen
      await _historyService.recordFieldUpdate(
        equipmentId: equipmentId,
        field: 'Prüfdatum',
        oldValue: oldCheckDate.toIso8601String(),
        newValue: newCheckDate.toIso8601String(),
      );
    } catch (e) {
      throw Exception('Fehler beim Aktualisieren des Prüfdatums: $e');
    }
  }

  // Besitzer aktualisieren
  Future<void> updateOwner(String equipmentId, String newOwner) async {
    try {
      // Aktuellen Wert abrufen
      DocumentSnapshot equipmentDoc = await _firestore.collection('equipment')
          .doc(equipmentId)
          .get();
      final oldOwner = (equipmentDoc.data() as Map<String, dynamic>)['owner'] ??
          '';

      // Daten aktualisieren
      await _firestore.collection('equipment').doc(equipmentId).update({
        'owner': newOwner,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Historie aufzeichnen
      await _historyService.recordFieldUpdate(
        equipmentId: equipmentId,
        field: 'Besitzer',
        oldValue: oldOwner,
        newValue: newOwner,
      );
    } catch (e) {
      throw Exception('Fehler beim Aktualisieren des Besitzers: $e');
    }
  }

  // Ortsfeuerwehr aktualisieren
  Future<void> updateFireStation(String equipmentId,
      String newFireStation) async {
    try {
      // Aktuellen Wert abrufen
      DocumentSnapshot equipmentDoc = await _firestore.collection('equipment')
          .doc(equipmentId)
          .get();
      final oldFireStation = (equipmentDoc.data() as Map<String,
          dynamic>)['fireStation'] ?? '';

      // Daten aktualisieren
      await _firestore.collection('equipment').doc(equipmentId).update({
        'fireStation': newFireStation,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Historie aufzeichnen
      await _historyService.recordFieldUpdate(
        equipmentId: equipmentId,
        field: 'Ortsfeuerwehr',
        oldValue: oldFireStation,
        newValue: newFireStation,
      );
    } catch (e) {
      throw Exception('Fehler beim Aktualisieren der Ortsfeuerwehr: $e');
    }
  }

  // Größe aktualisieren
  Future<void> updateSize(String equipmentId, String newSize) async {
    try {
      // Aktuellen Wert abrufen
      DocumentSnapshot equipmentDoc = await _firestore.collection('equipment')
          .doc(equipmentId)
          .get();
      final oldSize = (equipmentDoc.data() as Map<String, dynamic>)['size'] ??
          '';

      // Daten aktualisieren
      await _firestore.collection('equipment').doc(equipmentId).update({
        'size': newSize,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Historie aufzeichnen
      await _historyService.recordFieldUpdate(
        equipmentId: equipmentId,
        field: 'Größe',
        oldValue: oldSize,
        newValue: newSize,
      );
    } catch (e) {
      throw Exception('Fehler beim Aktualisieren der Größe: $e');
    }
  }

  // Einsatzkleidung löschen
  Future<void> deleteEquipment(String equipmentId) async {
    try {
      // Aktuelle Daten abrufen für den Historien-Eintrag
      DocumentSnapshot equipmentDoc = await _firestore.collection('equipment')
          .doc(equipmentId)
          .get();

      if (!equipmentDoc.exists) {
        throw Exception('Dokument nicht gefunden');
      }

      Map<String, dynamic> equipmentData = equipmentDoc.data() as Map<
          String,
          dynamic>;

      EquipmentModel equipment = EquipmentModel(
        id: equipmentId,
        nfcTag: equipmentData['nfcTag'] ?? '',
        barcode: equipmentData['barcode'],
        article: equipmentData['article'] ?? '',
        type: equipmentData['type'] ?? '',
        size: equipmentData['size'] ?? '',
        fireStation: equipmentData['fireStation'] ?? '',
        owner: equipmentData['owner'] ?? '',
        washCycles: equipmentData['washCycles'] ?? 0,
        checkDate: equipmentData['checkDate']?.toDate() ?? DateTime.now(),
        createdAt: equipmentData['createdAt']?.toDate() ?? DateTime.now(),
        createdBy: equipmentData['createdBy'] ?? '',
        status: equipmentData['status'] ?? '',
      );

      // Historie für die Löschung aufzeichnen
      await _historyService.recordEquipmentDeletion(equipment);

      // Dokument löschen
      await _firestore.collection('equipment').doc(equipmentId).delete();
    } catch (e) {
      throw Exception('Fehler beim Löschen der Einsatzkleidung: $e');
    }
  }

  // Eine einzelne Einsatzkleidung abrufen
  Future<EquipmentModel?> getEquipmentById(String equipmentId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('equipment').doc(
          equipmentId).get();

      if (!doc.exists) {
        return null;
      }

      return EquipmentModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    } catch (e) {
      print('Fehler beim Abrufen der Einsatzkleidung: $e');
      return null;
    }
  }

  // Einsatzkleidung nach Besitzer filtern
  Stream<List<EquipmentModel>> getEquipmentByOwner(String owner) {
    return _firestore
        .collection('equipment')
        .where('owner', isEqualTo: owner)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs
            .map((doc) =>
            EquipmentModel.fromMap(
                doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // Einsatzkleidung nach Ortsfeuerwehr filtern
  Stream<List<EquipmentModel>> getEquipmentByFireStation(String fireStation) {
    return _firestore
        .collection('equipment')
        .where('fireStation', isEqualTo: fireStation)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs
            .map((doc) =>
            EquipmentModel.fromMap(
                doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // Einsatzkleidung nach Status filtern
  Stream<List<EquipmentModel>> getEquipmentByStatus(String status) {
    return _firestore
        .collection('equipment')
        .where('status', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs
            .map((doc) =>
            EquipmentModel.fromMap(
                doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // Einsatzkleidung mit abgelaufenem Prüfdatum finden
  Stream<List<EquipmentModel>> getEquipmentWithExpiredCheckDate() {
    final now = DateTime.now();
    // Prüfdatum älter als 1 Jahr
    final oneYearAgo = DateTime(now.year - 1, now.month, now.day);

    return _firestore
        .collection('equipment')
        .where('checkDate', isLessThan: oneYearAgo)
        .orderBy('checkDate', descending: false)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs
            .map((doc) =>
            EquipmentModel.fromMap(
                doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // Zusammenfassung nach Typ und Status
  Future<Map<String, Map<String, int>>> getEquipmentSummary() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('equipment').get();

      Map<String, Map<String, int>> summary = {};

      // Initialisiere Zusammenfassungsstruktur
      for (var type in ['Jacke', 'Hose']) {
        summary[type] = {};
        for (var status in EquipmentStatus.values) {
          summary[type]![status] = 0;
        }
      }

      // Zähle die Ausrüstungsgegenstände nach Typ und Status
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String type = data['type'] ?? 'Sonstiges';
        String status = data['status'] ?? EquipmentStatus.ready;

        if (summary.containsKey(type)) {
          if (summary[type]!.containsKey(status)) {
            summary[type]![status] = (summary[type]![status] ?? 0) + 1;
          } else {
            summary[type]![status] = 1;
          }
        }
      }

      return summary;
    } catch (e) {
      print('Fehler beim Erstellen der Zusammenfassung: $e');
      return {};
    }
  }

  Stream<List<EquipmentModel>> getEquipmentByUserFireStation() async* {
    User? currentUser = _auth.currentUser;

    if (currentUser == null) {
      yield [];
      return;
    }

    try {
      // Benutzerinformationen abrufen
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(
          currentUser.uid).get();
      if (!userDoc.exists) {
        yield [];
        return;
      }

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      String userFireStation = userData['fireStation'] ?? '';
      bool isAdmin = userData['role'] == 'Gemeindebrandmeister' ||
          userData['role'] == 'Stv. Gemeindebrandmeister' ||
          userData['role'] == 'Gemeindezeugwart';

      // Wenn der Benutzer ein Admin ist, alle Einsatzkleidungen zurückgeben
      if (isAdmin) {
        yield* _firestore
            .collection('equipment')
            .orderBy('createdAt', descending: true)
            .snapshots()
            .map((snapshot) =>
            snapshot.docs
                .map((doc) =>
                EquipmentModel.fromMap(
                    doc.data() as Map<String, dynamic>, doc.id))
                .toList());
      } else {
        // Sonst nur Einsatzkleidung der eigenen Ortsfeuerwehr zurückgeben
        yield* _firestore
            .collection('equipment')
            .where('fireStation', isEqualTo: userFireStation)
            .orderBy('createdAt', descending: true)
            .snapshots()
            .map((snapshot) =>
            snapshot.docs
                .map((doc) =>
                EquipmentModel.fromMap(
                    doc.data() as Map<String, dynamic>, doc.id))
                .toList());
      }
    } catch (e) {
      print('Fehler beim Abrufen der Einsatzkleidung: $e');
      yield [];
    }
  }


  Stream<List<EquipmentModel>> getEquipmentByCheckDate(DateTime startDate, DateTime endDate) async* {
    User? currentUser = _auth.currentUser;

    if (currentUser == null) {
      yield [];
      return;
    }

    try {
      // Benutzerinformationen abrufen
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      if (!userDoc.exists) {
        yield [];
        return;
      }

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      String userFireStation = userData['fireStation'] ?? '';
      bool isAdmin = userData['role'] == 'Gemeindebrandmeister' ||
          userData['role'] == 'Stv. Gemeindebrandmeister' ||
          userData['role'] == 'Gemeindezeugwart';

      // Für Admins alle Ausrüstungen abrufen
      if (isAdmin) {
        yield* _firestore
            .collection('equipment')
            .where('checkDate', isLessThanOrEqualTo: endDate)
            .orderBy('checkDate')
            .snapshots()
            .map((snapshot) => snapshot.docs
            .map((doc) => EquipmentModel.fromMap(
            doc.data() as Map<String, dynamic>, doc.id))
            .toList());
      } else {
        // Für normale Benutzer nur Ausrüstungen ihrer Ortsfeuerwehr
        yield* _firestore
            .collection('equipment')
            .where('fireStation', isEqualTo: userFireStation)
            .where('checkDate', isGreaterThanOrEqualTo: startDate)
            .where('checkDate', isLessThanOrEqualTo: endDate)
            .orderBy('checkDate')
            .snapshots()
            .map((snapshot) => snapshot.docs
            .map((doc) => EquipmentModel.fromMap(
            doc.data() as Map<String, dynamic>, doc.id))
            .toList());
      }
    } catch (e) {
      print('Fehler beim Abrufen der Einsatzkleidung: $e');
      yield [];
    }
  }

// Einsatzkleidung vollständig aktualisieren (nur für Admins)
  Future<void> updateEquipment({
    required String equipmentId,
    required String article,
    required String type,
    required String size,
    required String fireStation,
    required String owner,
    required DateTime checkDate,
    required String status,
  }) async {
    try {
      // Aktuelle Werte abrufen für Historie
      DocumentSnapshot equipmentDoc = await _firestore.collection('equipment').doc(equipmentId).get();

      if (!equipmentDoc.exists) {
        throw Exception('Einsatzkleidung nicht gefunden');
      }

      Map<String, dynamic> currentData = equipmentDoc.data() as Map<String, dynamic>;

      // Daten aktualisieren
      await _firestore.collection('equipment').doc(equipmentId).update({
        'article': article,
        'type': type,
        'size': size,
        'fireStation': fireStation,
        'owner': owner,
        'checkDate': checkDate,
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Historieneinträge für geänderte Felder
      if (currentData['article'] != article) {
        await _historyService.recordFieldUpdate(
          equipmentId: equipmentId,
          field: 'Artikel',
          oldValue: currentData['article'],
          newValue: article,
        );
      }

      if (currentData['type'] != type) {
        await _historyService.recordFieldUpdate(
          equipmentId: equipmentId,
          field: 'Typ',
          oldValue: currentData['type'],
          newValue: type,
        );
      }

      if (currentData['size'] != size) {
        await _historyService.recordFieldUpdate(
          equipmentId: equipmentId,
          field: 'Größe',
          oldValue: currentData['size'],
          newValue: size,
        );
      }

      if (currentData['fireStation'] != fireStation) {
        await _historyService.recordFieldUpdate(
          equipmentId: equipmentId,
          field: 'Ortsfeuerwehr',
          oldValue: currentData['fireStation'],
          newValue: fireStation,
        );
      }

      if (currentData['owner'] != owner) {
        await _historyService.recordFieldUpdate(
          equipmentId: equipmentId,
          field: 'Besitzer',
          oldValue: currentData['owner'],
          newValue: owner,
        );
      }

      final DateTime oldCheckDate = currentData['checkDate']?.toDate() ?? DateTime.now();
      if (oldCheckDate != checkDate) {
        await _historyService.recordFieldUpdate(
          equipmentId: equipmentId,
          field: 'Prüfdatum',
          oldValue: oldCheckDate.toIso8601String(),
          newValue: checkDate.toIso8601String(),
        );
      }

      if (currentData['status'] != status) {
        await _historyService.recordFieldUpdate(
          equipmentId: equipmentId,
          field: 'Status',
          oldValue: currentData['status'],
          newValue: status,
        );
      }
    } catch (e) {
      throw Exception('Fehler beim Aktualisieren der Einsatzkleidung: $e');
    }
  }
// Einsatzkleidung nach Prüfdatum und Feuerwehrstation filtern
  Stream<List<EquipmentModel>> getEquipmentByCheckDateAndFireStation(
      DateTime startDate, DateTime endDate, String fireStation) {
    return _firestore
        .collection('equipment')
        .where('fireStation', isEqualTo: fireStation)
        .where('checkDate', isGreaterThanOrEqualTo: startDate)
        .where('checkDate', isLessThanOrEqualTo: endDate)
        .orderBy('checkDate')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => EquipmentModel.fromMap(
        doc.data() as Map<String, dynamic>, doc.id))
        .toList());
  }

  // Überfällige Einsatzkleidung abrufen
  Stream<List<EquipmentModel>> getOverdueEquipment() {
    final now = DateTime.now();

    return _firestore
        .collection('equipment')
        .where('checkDate', isLessThan: now)
        .orderBy('checkDate')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => EquipmentModel.fromMap(
        doc.data() as Map<String, dynamic>, doc.id))
        .toList());
  }

// Überfällige Einsatzkleidung nach Feuerwehrstation abrufen
  Stream<List<EquipmentModel>> getOverdueEquipmentByFireStation(String fireStation) {
    final now = DateTime.now();

    return _firestore
        .collection('equipment')
        .where('fireStation', isEqualTo: fireStation)
        .where('checkDate', isLessThan: now)
        .orderBy('checkDate')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => EquipmentModel.fromMap(
        doc.data() as Map<String, dynamic>, doc.id))
        .toList());
  }

  // Neue Funktion für EquipmentService, um in services/equipment_service.dart hinzuzufügen

  // Statusaktualisierung für mehrere Ausrüstungsgegenstände in einem Batch
  Future<void> updateStatusBatch(List<String> equipmentIds, String newStatus) async {
    if (equipmentIds.isEmpty) return;

    try {
      // Batch-Verarbeitung in Firestore verwenden
      WriteBatch batch = _firestore.batch();

      // Aktuelle Werte für die Historie abrufen
      for (String equipmentId in equipmentIds) {
        DocumentSnapshot equipmentDoc = await _firestore.collection('equipment').doc(equipmentId).get();

        if (!equipmentDoc.exists) {
          print('Warnung: Equipment mit ID $equipmentId nicht gefunden');
          continue;
        }

        Map<String, dynamic> equipmentData = equipmentDoc.data() as Map<String, dynamic>;
        final oldStatus = equipmentData['status'] ?? '';
        final currentWashCycles = equipmentData['washCycles'] ?? 0;

        // Prüfen, ob der Status auf "In der Reinigung" geändert wird
        bool increaseWashCycles = newStatus == EquipmentStatus.cleaning &&
            oldStatus != EquipmentStatus.cleaning;

        // Daten-Updates vorbereiten
        Map<String, dynamic> updates = {
          'status': newStatus,
          'updatedAt': FieldValue.serverTimestamp(),
        };

        // Wenn der Status auf "In der Reinigung" geändert wird, Waschzyklen erhöhen
        if (increaseWashCycles) {
          updates['washCycles'] = currentWashCycles + 1;
        }

        // Aktualisierung zum Batch hinzufügen
        batch.update(_firestore.collection('equipment').doc(equipmentId), updates);

        // Historie für jedes Element separat erfassen
        // (Dies kann nicht in einem Batch erfolgen, da wir die Historie in einer anderen Kollektion speichern)
        await _historyService.recordFieldUpdate(
          equipmentId: equipmentId,
          field: 'Status',
          oldValue: oldStatus,
          newValue: newStatus,
        );

        // Separat Historie für Waschzyklen aufzeichnen, falls erhöht
        if (increaseWashCycles) {
          await _historyService.recordFieldUpdate(
            equipmentId: equipmentId,
            field: 'Waschzyklen',
            oldValue: currentWashCycles,
            newValue: currentWashCycles + 1,
          );
        }
      }

      // Batch-Aktualisierung ausführen
      await batch.commit();
    } catch (e) {
      throw Exception('Fehler bei der Batch-Aktualisierung des Status: $e');
    }
  }

  // Einsatzkleidung nach Teilstring von NFC-Tag oder Barcode suchen
  Future<List<EquipmentModel>> searchEquipmentByPartialTagOrBarcode(String searchString) async {
    try {
      // Suchstring in Kleinbuchstaben für case-insensitive Suche
      final searchLower = searchString.toLowerCase();

      // Alle Einsatzkleidungen abrufen
      QuerySnapshot snapshot = await _firestore.collection('equipment').get();

      // Liste für die gefundenen Übereinstimmungen
      List<EquipmentModel> matchingEquipment = [];

      // Durch die Ergebnisse iterieren und nach Teilübereinstimmungen suchen
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final nfcTag = (data['nfcTag'] ?? '').toLowerCase();
        final barcode = (data['barcode'] ?? '').toLowerCase();

        // Prüfen, ob der Suchstring ein Teilstring des NFC-Tags oder Barcodes ist
        if (nfcTag.contains(searchLower) || barcode.contains(searchLower)) {
          matchingEquipment.add(EquipmentModel.fromMap(data, doc.id));
        }
      }

      return matchingEquipment;
    } catch (e) {
      print('Fehler bei der Teilsuche nach NFC-Tag oder Barcode: $e');
      return [];
    }
  }


}
