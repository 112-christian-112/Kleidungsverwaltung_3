//f services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Benutzerdaten abrufen
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      DocumentSnapshot docSnapshot =
      await _firestore.collection('users').doc(userId).get();

      if (docSnapshot.exists) {
        return docSnapshot.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Fehler beim Abrufen der Benutzerdaten: $e');
      return null;
    }
  }

  // Beispieldaten für die Homepage abrufen
  Future<List<Map<String, dynamic>>> getExampleData() async {
    try {
      User? currentUser = _auth.currentUser;

      if (currentUser == null) {
        return [];
      }

      // Hier würde die benutzerspezifische Datenabfrage erfolgen
      // Dies ist nur ein Beispiel und sollte an Ihre Datenstruktur angepasst werden
      QuerySnapshot snapshot = await _firestore
          .collection('example_data')
      // Später hier Benutzerbezogene Einschränkungen hinzufügen:
      // .where('userId', isEqualTo: currentUser.uid)
          .limit(10)
          .get();

      return snapshot.docs
          .map((doc) => {
        'id': doc.id,
        ...doc.data() as Map<String, dynamic>,
      })
          .toList();
    } catch (e) {
      print('Fehler beim Abrufen der Beispieldaten: $e');
      return [];
    }
  }

  // Daten hinzufügen (wird später benötigt)
  Future<DocumentReference> addData(
      String collection, Map<String, dynamic> data) async {
    User? currentUser = _auth.currentUser;

    if (currentUser == null) {
      throw Exception('Kein Benutzer angemeldet');
    }

    // Füge automatisch den Benutzer-ID und Zeitstempel hinzu
    data['userId'] = currentUser.uid;
    data['createdAt'] = FieldValue.serverTimestamp();

    return await _firestore.collection(collection).add(data);
  }

  // Daten aktualisieren (wird später benötigt)
  Future<void> updateData(
      String collection, String docId, Map<String, dynamic> data) async {
    User? currentUser = _auth.currentUser;

    if (currentUser == null) {
      throw Exception('Kein Benutzer angemeldet');
    }

    // Füge automatisch den Aktualisierungszeitstempel hinzu
    data['updatedAt'] = FieldValue.serverTimestamp();

    // Optional: Prüfe, ob der Benutzer Zugriff auf das Dokument hat
    DocumentSnapshot docSnapshot =
    await _firestore.collection(collection).doc(docId).get();

    if (!docSnapshot.exists) {
      throw Exception('Dokument nicht gefunden');
    }

    Map<String, dynamic> docData = docSnapshot.data() as Map<String, dynamic>;

    if (docData['userId'] != currentUser.uid) {
      throw Exception('Keine Berechtigung zum Bearbeiten dieses Dokuments');
    }

    await _firestore.collection(collection).doc(docId).update(data);
  }

  // Daten löschen (wird später benötigt)
  Future<void> deleteData(String collection, String docId) async {
    User? currentUser = _auth.currentUser;

    if (currentUser == null) {
      throw Exception('Kein Benutzer angemeldet');
    }

    // Optional: Prüfe, ob der Benutzer Zugriff auf das Dokument hat
    DocumentSnapshot docSnapshot =
    await _firestore.collection(collection).doc(docId).get();

    if (!docSnapshot.exists) {
      throw Exception('Dokument nicht gefunden');
    }

    Map<String, dynamic> docData = docSnapshot.data() as Map<String, dynamic>;

    if (docData['userId'] != currentUser.uid) {
      throw Exception('Keine Berechtigung zum Löschen dieses Dokuments');
    }

    await _firestore.collection(collection).doc(docId).delete();
  }
}
