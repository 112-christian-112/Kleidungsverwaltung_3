// screens/admin/equipment/barcode_scanner_screen.dart
import 'package:flutter/material.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'dart:async';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({Key? key}) : super(key: key);

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  bool _isScanning = true;
  String _barcode = '';
  String _errorMessage = '';
  bool _isManualInput = false;
  final TextEditingController _barcodeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Barcode-Scanner direkt beim Öffnen starten
    _startBarcodeScanner();
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    super.dispose();
  }

  // Barcode-Scanner starten
  Future<void> _startBarcodeScanner() async {
    setState(() {
      _isScanning = true;
      _barcode = '';
      _errorMessage = '';
    });

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
        if (mounted) {
          setState(() {
            _barcode = result.rawContent;
            _isScanning = false;
          });
        }
      } else if (result.type == ResultType.Cancelled) {
        // Benutzer hat abgebrochen
        if (mounted) {
          Navigator.pop(context);
        }
      } else if (result.type == ResultType.Error) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Fehler beim Scannen: ${result.rawContent}';
            _isScanning = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Fehler: $e';
          _isScanning = false;
        });
      }
    }
  }

  // Barcode manuell eingeben
  void _toggleManualInput() {
    setState(() {
      _isManualInput = !_isManualInput;
    });
  }

  // Manuell eingegebenen Barcode übernehmen
  void _submitManualBarcode() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _barcode = _barcodeController.text.trim();
        _isManualInput = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Barcode scannen'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isScanning && !_isManualInput)
                Column(
                  children: [
                    const Icon(
                      Icons.qr_code_scanner,
                      size: 80,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Barcode scannen',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Scanner startet...',
                      style: TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    const CircularProgressIndicator(),
                  ],
                )
              else if (_isManualInput)
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const Icon(
                        Icons.edit,
                        size: 80,
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Barcode manuell eingeben',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _barcodeController,
                        decoration: const InputDecoration(
                          labelText: 'Barcode',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.qr_code),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Bitte geben Sie einen Barcode ein';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _toggleManualInput,
                            icon: const Icon(Icons.qr_code_scanner),
                            label: const Text('Zurück zum Scanner'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton.icon(
                            onPressed: _submitManualBarcode,
                            icon: const Icon(Icons.check),
                            label: const Text('Übernehmen'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              else if (!_isScanning && _barcode.isNotEmpty)
                  Column(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        size: 80,
                        color: Colors.green,
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Barcode erkannt',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Barcode: $_barcode',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _startBarcodeScanner,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Neu scannen'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context, _barcode);
                            },
                            icon: const Icon(Icons.check),
                            label: const Text('Übernehmen'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                else if (_errorMessage.isNotEmpty)
                    Column(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 80,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Fehler beim Barcode-Scan',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage,
                          style: const TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              onPressed: _startBarcodeScanner,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Erneut versuchen'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton.icon(
                              onPressed: _toggleManualInput,
                              icon: const Icon(Icons.edit),
                              label: const Text('Manuell eingeben'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple,
                                foregroundColor: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              icon: const Icon(Icons.cancel),
                              label: const Text('Abbrechen'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ),
      // Floating Action Button für manuelle Eingabe
      floatingActionButton: (!_isManualInput && _barcode.isEmpty)
          ? FloatingActionButton(
        onPressed: _toggleManualInput,
        tooltip: 'Manuell eingeben',
        child: const Icon(Icons.edit),
      )
          : null,
    );
  }
}