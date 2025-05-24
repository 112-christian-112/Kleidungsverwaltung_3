// services/permission_service.dart (Neue Datei)
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PermissionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Prüft, ob der aktuelle Benutzer ein Administrator ist
  Future<bool> isAdmin() async {
    User? currentUser = _auth.currentUser;

    if (currentUser == null) {
      return false;
    }

    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(currentUser.uid).get();

      if (!userDoc.exists) {
        return false;
      }

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

      return userData['role'] == 'Gemeindebrandmeister' ||
          userData['role'] == 'Stv. Gemeindebrandmeister' || userData['role'] == 'Gemeindezeugwart' ;
    } catch (e) {
      print('Fehler beim Prüfen der Admin-Berechtigung: $e');
      return false;
    }
  }

  // Prüft, ob der Benutzer für die angegebene Ortsfeuerwehr berechtigt ist
  Future<bool> canAccessFireStation(String fireStation) async {
    User? currentUser = _auth.currentUser;

    if (currentUser == null) {
      return false;
    }

    // Admins haben Zugriff auf alle Ortsfeuerwehren
    if (await isAdmin()) {
      return true;
    }

    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(currentUser.uid).get();

      if (!userDoc.exists) {
        return false;
      }

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

      // Reguläre Benutzer haben nur Zugriff auf ihre eigene Ortsfeuerwehr
      return userData['fireStation'] == fireStation;
    } catch (e) {
      print('Fehler beim Prüfen der Ortsfeuerwehr-Berechtigung: $e');
      return false;
    }
  }

  // Prüft, ob der Benutzer eine bestimmte Einsatzkleidung bearbeiten darf
  Future<bool> canEditEquipment(String equipmentId) async {
    try {
      // Admin-Berechtigungen prüfen (Admins dürfen alles bearbeiten)
      if (await isAdmin()) {
        return true;
      }

      // Einsatzkleidung abrufen
      DocumentSnapshot equipmentDoc = await _firestore.collection('equipment').doc(equipmentId).get();

      if (!equipmentDoc.exists) {
        return false;
      }

      Map<String, dynamic> equipmentData = equipmentDoc.data() as Map<String, dynamic>;
      String fireStation = equipmentData['fireStation'] ?? '';

      // Prüfen, ob der Benutzer Zugriff auf die Ortsfeuerwehr hat
      return await canAccessFireStation(fireStation);
    } catch (e) {
      print('Fehler beim Prüfen der Bearbeitungsberechtigung: $e');
      return false;
    }
  }

  Future<String> getUserFireStation() async {
    User? currentUser = _auth.currentUser;

    if (currentUser == null) {
      return '';
    }

    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(currentUser.uid).get();

      if (!userDoc.exists) {
        return '';
      }

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

      return userData['fireStation'] ?? '';
    } catch (e) {
      print('Fehler beim Abrufen der Feuerwehrstation: $e');
      return '';
    }
  }

}