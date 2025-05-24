// services/barcode_service.dart
import 'package:barcode_scan2/barcode_scan2.dart';

class BarcodeService {
  // Singleton-Pattern
  static final BarcodeService _instance = BarcodeService._internal();

  factory BarcodeService() {
    return _instance;
  }

  BarcodeService._internal();

  // Barcode scannen
  Future<String?> scanBarcode() async {
    try {
      // Barcode-Scanner-Konfiguration
      var options = ScanOptions(
        strings: {
          'cancel': 'Abbrechen',
          'flash_on': 'Blitz an',
          'flash_off': 'Blitz aus',
        },
        restrictFormat: [], // Alle Formate erlauben
        useCamera: -1, // Standardkamera
        autoEnableFlash: false,
        android: AndroidOptions(
          aspectTolerance: 0.5,
          useAutoFocus: true,
        ),
      );

      // Scanner öffnen und Ergebnis abwarten
      ScanResult result = await BarcodeScanner.scan(options: options);

      // Ergebnis verarbeiten
      if (result.type == ResultType.Barcode) {
        return result.rawContent;
      } else if (result.type == ResultType.Error) {
        throw Exception('Fehler beim Scannen: ${result.rawContent}');
      } else {
        // Benutzer hat abgebrochen
        return null;
      }
    } catch (e) {
      throw Exception('Fehler: $e');
    }
  }

  // Barcode-Format validieren
  bool isValidBarcode(String barcode) {
    // Einfache Prüfung, ob der Barcode mindestens 6 Zeichen lang ist
    if (barcode.length < 6) {
      return false;
    }

    // Optional: Weitere Format-Validierungen hinzufügen
    // - EAN-13 (13 Ziffern)
    // - UPC-A (12 Ziffern)
    // - Code 39 (variable Länge, nur Großbuchstaben und bestimmte Zeichen)
    // - Code 128 (variable Länge, ASCII-Zeichen)
    // - QR Code (variable Größe und Format)

    // Zum Beispiel für EAN-13:
    // return barcode.length == 13 && RegExp(r'^\d{13}$').hasMatch(barcode);

    return true;
  }

  // Barcode generieren (falls später benötigt)
  Future<String> generateBarcode() async {
    // Einfache Implementierung: Zeitstempel-basierter Barcode
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomPart = (1000 + (timestamp % 9000)).toString();
    return '$timestamp$randomPart';
  }
}