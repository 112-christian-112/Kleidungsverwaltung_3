// screens/admin/equipment/fallback_nfc_scanner_screen.dart
import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';

class FallbackNfcScannerScreen extends StatefulWidget {
  const FallbackNfcScannerScreen({Key? key}) : super(key: key);

  @override
  State<FallbackNfcScannerScreen> createState() => _FallbackNfcScannerScreenState();
}

class _FallbackNfcScannerScreenState extends State<FallbackNfcScannerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nfcIdController = TextEditingController();
  bool _isNfcAvailable = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _checkNfcAvailability();
  }

  @override
  void dispose() {
    _nfcIdController.dispose();
    super.dispose();
  }

  // Prüfen, ob NFC auf dem Gerät verfügbar ist
  Future<void> _checkNfcAvailability() async {
    try {
      final isAvailable = await NfcManager.instance.isAvailable();
      setState(() {
        _isNfcAvailable = isAvailable;
        if (!isAvailable) {
          _errorMessage = 'NFC ist auf diesem Gerät nicht verfügbar. Bitte geben Sie die NFC-ID manuell ein.';
        }
      });
    } catch (e) {
      setState(() {
        _isNfcAvailable = false;
        _errorMessage = 'Fehler beim Prüfen der NFC-Verfügbarkeit: $e';
      });
    }
  }

  void _submitManualId() {
    if (_formKey.currentState!.validate()) {
      final nfcId = _nfcIdController.text.trim();
      Navigator.pop(context, nfcId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NFC-ID eingeben'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_errorMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.amber),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.amber),
                      ),
                    ),
                  ],
                ),
              ),

            if (_isNfcAvailable)
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/nfc-scanner');
                },
                icon: const Icon(Icons.nfc),
                label: const Text('NFC scannen'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),

            if (_isNfcAvailable)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('ODER'),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
              ),

            Text(
              _isNfcAvailable
                  ? 'NFC-ID manuell eingeben'
                  : 'NFC-ID manuell eingeben (NFC nicht verfügbar)',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nfcIdController,
                    decoration: const InputDecoration(
                      labelText: 'NFC-ID',
                      border: OutlineInputBorder(),
                      hintText: 'Format: XX:XX:XX:XX:XX:XX',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Bitte geben Sie eine NFC-ID ein';
                      }
                      // Optionale Validierung für Hex-Format
                      final hexPattern = RegExp(r'^([0-9A-Fa-f]{2}:?)+$');
                      if (!hexPattern.hasMatch(value)) {
                        return 'Ungültiges Format. Verwenden Sie hexadezimale Werte (0-9, A-F).';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _submitManualId,
                      child: const Text('ID übernehmen'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}