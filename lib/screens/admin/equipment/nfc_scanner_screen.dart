// screens/admin/equipment/nfc_scanner_screen.dart
import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'dart:async';

class NfcScannerScreen extends StatefulWidget {
  const NfcScannerScreen({Key? key}) : super(key: key);

  @override
  State<NfcScannerScreen> createState() => _NfcScannerScreenState();
}

class _NfcScannerScreenState extends State<NfcScannerScreen> {
  bool _isScanning = true;
  String _nfcId = '';
  bool _nfcAvailable = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _checkNfcAvailability();
  }

  @override
  void dispose() {
    // NFC-Session stoppen, wenn Screen verlassen wird
    _stopNfcSession();
    super.dispose();
  }

  // Prüfen, ob NFC auf dem Gerät verfügbar ist
  Future<void> _checkNfcAvailability() async {
    try {
      final isAvailable = await NfcManager.instance.isAvailable();
      setState(() {
        _nfcAvailable = isAvailable;
        if (!isAvailable) {
          _errorMessage = 'NFC ist auf diesem Gerät nicht verfügbar.';
          _isScanning = false;
        } else {
          _startNfcSession();
        }
      });
    } catch (e) {
      setState(() {
        _nfcAvailable = false;
        _errorMessage = 'Fehler beim Prüfen der NFC-Verfügbarkeit: $e';
        _isScanning = false;
      });
    }
  }

  // NFC-Session starten
  void _startNfcSession() {
    setState(() {
      _isScanning = true;
      _nfcId = '';
      _errorMessage = '';
    });

    // NFC-Session starten
    NfcManager.instance.startSession(
      onDiscovered: (NfcTag tag) async {
        try {
          // NFC-Tag-ID extrahieren
          var tagId = '';

          // NDEF-Format (häufigster Typ für NFC-Tags)
          if (tag.data.containsKey('ndef')) {
            final ndefTag = tag.data['ndef']['identifier'];
            if (ndefTag != null) {
              tagId = _bytesToHex(ndefTag);
            }
          }
          // NFC-A (ISO 14443-3A)
          else if (tag.data.containsKey('nfca')) {
            final nfcA = tag.data['nfca']['identifier'];
            if (nfcA != null) {
              tagId = _bytesToHex(nfcA);
            }
          }
          // NFC-B (ISO 14443-3B)
          else if (tag.data.containsKey('nfcb')) {
            final nfcB = tag.data['nfcb']['applicationData'];
            if (nfcB != null) {
              tagId = _bytesToHex(nfcB);
            }
          }
          // NFC-F (JIS 6319-4)
          else if (tag.data.containsKey('nfcf')) {
            final nfcF = tag.data['nfcf']['identifier'];
            if (nfcF != null) {
              tagId = _bytesToHex(nfcF);
            }
          }
          // NFC-V (ISO 15693)
          else if (tag.data.containsKey('nfcv')) {
            final nfcV = tag.data['nfcv']['identifier'];
            if (nfcV != null) {
              tagId = _bytesToHex(nfcV);
            }
          }
          // Fallback: Irgendwelche vorhandenen ID-Daten verwenden
          else {
            final keys = tag.data.keys.toList();
            if (keys.isNotEmpty && tag.data[keys[0]] != null && tag.data[keys[0]]['identifier'] != null) {
              tagId = _bytesToHex(tag.data[keys[0]]['identifier']);
            }
          }

          if (tagId.isNotEmpty) {
            // NFC-Session stoppen
            await NfcManager.instance.stopSession();

            setState(() {
              _nfcId = tagId;
              _isScanning = false;
            });
          } else {
            setState(() {
              _errorMessage = 'Konnte keine Tag-ID lesen. Bitte versuchen Sie es erneut.';
            });
            // Session fortsetzen für einen neuen Versuch
          }
        } catch (e) {
          setState(() {
            _errorMessage = 'Fehler beim Lesen des NFC-Tags: $e';
          });
          await NfcManager.instance.stopSession();
          setState(() {
            _isScanning = false;
          });
        }
      },
      onError: (error) async {
        // Session stoppen
        try {
          await NfcManager.instance.stopSession();
        } catch (e) {
          print('Fehler beim Stoppen der NFC-Session nach Fehler: $e');
        }

        if (mounted) {
          setState(() {
            _errorMessage = 'NFC-Fehler: $error';
            _isScanning = false;
          });
        }
        return; // Explizites Return zur Fehlerbehandlung
      },
    );
  }

  // NFC-Session stoppen
  Future<void> _stopNfcSession() async {
    try {
      await NfcManager.instance.stopSession();
    } catch (e) {
      // Fehler beim Stoppen ignorieren
      print('Fehler beim Stoppen der NFC-Session: $e');
    }
  }

  // Bytes in Hex-String umwandeln
  String _bytesToHex(List<int> bytes) {
    return bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join(':').toUpperCase();
  }

  void _resetScan() {
    _stopNfcSession().then((_) {
      _startNfcSession();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NFC-Tag scannen'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isScanning && _nfcAvailable)
                Column(
                  children: [
                    const Icon(
                      Icons.nfc,
                      size: 80,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'NFC-Tag scannen',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Bitte halten Sie den NFC-Tag an die Rückseite Ihres Smartphones',
                      style: TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    const CircularProgressIndicator(),
                  ],
                )
              else if (!_isScanning && _nfcId.isNotEmpty)
                Column(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 80,
                      color: Colors.green,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'NFC-Tag erkannt',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'NFC-ID: $_nfcId',
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
                          onPressed: _resetScan,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Neu scannen'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context, _nfcId);
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
                        'Fehler beim NFC-Scan',
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
                          if (_nfcAvailable)
                            ElevatedButton.icon(
                              onPressed: _resetScan,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Erneut versuchen'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
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
    );
  }
}