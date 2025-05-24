// services/nfc_service.dart
import 'dart:async';

import 'package:nfc_manager/nfc_manager.dart';

class NfcService {
  // Singleton-Pattern
  static final NfcService _instance = NfcService._internal();

  factory NfcService() {
    return _instance;
  }

  NfcService._internal();

  // Prüft, ob NFC auf dem Gerät verfügbar ist
  Future<bool> isNfcAvailable() async {
    try {
      return await NfcManager.instance.isAvailable();
    } catch (e) {
      print('Fehler beim Prüfen der NFC-Verfügbarkeit: $e');
      return false;
    }
  }

  // Startet eine NFC-Lesesession und gibt die NFC-Tag-ID zurück
  Future<String?> readNfcTag() async {
    String? tagId;
    bool completed = false;

    try {
      // Prüfen, ob NFC verfügbar ist
      final isAvailable = await isNfcAvailable();
      if (!isAvailable) {
        return null;
      }

      // Erstellen eines Completer für asynchrone Verarbeitung
      final completer = Completer<String?>();

      // NFC-Session starten
      NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          try {
            if (completed) return;

            // Tag-ID extrahieren
            String? id = _extractTagId(tag);

            if (id != null && id.isNotEmpty) {
              completed = true;
              tagId = id;

              await NfcManager.instance.stopSession();
              completer.complete(id);
            } else {
              // Keine ID gefunden, Session fortsetzen
            }
          } catch (e) {
            print('Fehler beim Lesen des NFC-Tags: $e');
            if (!completed) {
              completed = true;
              await NfcManager.instance.stopSession();
              completer.complete(null);
            }
          }
        },
        onError: (error) async {
          print('NFC-Fehler: $error');
          if (!completed) {
            completed = true;
            completer.complete(null);
          }
        },
      );

      // Warten auf Abschluss des NFC-Lesevorgangs (mit Timeout)
      return await completer.future.timeout(
        const Duration(seconds: 60), // Timeout nach 1 Minute
        onTimeout: () async {
          if (!completed) {
            completed = true;
            await NfcManager.instance.stopSession();
          }
          return null;
        },
      );
    } catch (e) {
      print('Allgemeiner Fehler bei NFC-Scan: $e');
      return null;
    }
  }

  // Extrahiert die ID aus verschiedenen NFC-Tag-Formaten
  String? _extractTagId(NfcTag tag) {
    try {
      // NDEF-Format (häufigster Typ für NFC-Tags)
      if (tag.data.containsKey('ndef')) {
        final ndefTag = tag.data['ndef']['identifier'];
        if (ndefTag != null) {
          return _bytesToHex(ndefTag);
        }
      }
      // NFC-A (ISO 14443-3A)
      else if (tag.data.containsKey('nfca')) {
        final nfcA = tag.data['nfca']['identifier'];
        if (nfcA != null) {
          return _bytesToHex(nfcA);
        }
      }
      // NFC-B (ISO 14443-3B)
      else if (tag.data.containsKey('nfcb')) {
        final nfcB = tag.data['nfcb']['applicationData'];
        if (nfcB != null) {
          return _bytesToHex(nfcB);
        }
      }
      // NFC-F (JIS 6319-4)
      else if (tag.data.containsKey('nfcf')) {
        final nfcF = tag.data['nfcf']['identifier'];
        if (nfcF != null) {
          return _bytesToHex(nfcF);
        }
      }
      // NFC-V (ISO 15693)
      else if (tag.data.containsKey('nfcv')) {
        final nfcV = tag.data['nfcv']['identifier'];
        if (nfcV != null) {
          return _bytesToHex(nfcV);
        }
      }
      // Fallback: Irgendwelche vorhandenen ID-Daten verwenden
      else {
        final keys = tag.data.keys.toList();
        if (keys.isNotEmpty && tag.data[keys[0]] != null && tag.data[keys[0]]['identifier'] != null) {
          return _bytesToHex(tag.data[keys[0]]['identifier']);
        }
      }
    } catch (e) {
      print('Fehler beim Extrahieren der Tag-ID: $e');
    }

    return null;
  }

  // Bytes in Hex-String umwandeln
  String _bytesToHex(List<int> bytes) {
    return bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join(':').toUpperCase();
  }

  // Stoppt die aktuelle NFC-Session
  Future<void> stopNfcSession() async {
    try {
      await NfcManager.instance.stopSession();
    } catch (e) {
      print('Fehler beim Stoppen der NFC-Session: $e');
    }
  }
}