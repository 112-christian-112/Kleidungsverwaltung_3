// screens/admin/equipment/add_equipment_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../models/equipment_model.dart';
import '../../../services/equipment_service.dart';
import '../services/barcode_service.dart';
import 'admin/equipment/barcode_scanner_screen.dart';
import 'admin/equipment/nfc_scanner_screen.dart';

class AddEquipmentScreen extends StatefulWidget {
  const AddEquipmentScreen({Key? key}) : super(key: key);

  @override
  State<AddEquipmentScreen> createState() => _AddEquipmentScreenState();
}

class _AddEquipmentScreenState extends State<AddEquipmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final EquipmentService _equipmentService = EquipmentService();

  String _nfcTag = '';
  String _barcode = '';
  String _article = 'Viking Performer Evolution Einsatzjacke AGT';
  String _type = 'Jacke';
  final TextEditingController _sizeController = TextEditingController();
  String _fireStation = 'Esklum';
  final TextEditingController _ownerController = TextEditingController();
  final TextEditingController _checkDateController = TextEditingController();
  String _status = EquipmentStatus.ready; // Standardwert: Einsatzbereit

  bool _isLoading = false;
  DateTime _selectedCheckDate = DateTime.now();

  final List<String> _articles = [
    'Viking Performer Evolution Einsatzjacke AGT',
    'Viking Performer Evolution Einsatzhose AGT'
  ];

  final List<String> _types = ['Jacke', 'Hose'];

  final List<String> _fireStations = [
    'Esklum',
    'Breinermoor',
    'Grotegaste',
    'Flachsmeer',
    'Folmhusen',
    'Großwolde',
    'Ihrhove',
    'Steenfelde',
    'Völlen',
    'Völlenerfehn',
    'Völlenerkönigsfehn'
  ];

  @override
  void initState() {
    super.initState();
    _checkDateController.text = DateFormat('dd.MM.yyyy').format(DateTime.now());
  }

  @override
  void dispose() {
    _sizeController.dispose();
    _ownerController.dispose();
    _checkDateController.dispose();
    super.dispose();
  }

  Future<void> _scanNfcTag() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NfcScannerScreen(),
      ),
    );

    if (result != null && result is String) {
      setState(() {
        _nfcTag = result;
      });
    }
  }

  Future<void> _scanBarcode() async {
    try {
      // Barcode-Service verwenden
      final barcodeService = BarcodeService();

      // Scanner starten
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const BarcodeScannerScreen(),
        ),
      );

      if (result != null && result is String && result.isNotEmpty) {
        setState(() {
          _barcode = result;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Barcode-Scan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _selectCheckDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedCheckDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null && pickedDate != _selectedCheckDate) {
      setState(() {
        _selectedCheckDate = pickedDate;
        _checkDateController.text = DateFormat('dd.MM.yyyy').format(pickedDate);
      });
    }
  }

  void _setTypeBasedOnArticle(String article) {
    setState(() {
      _article = article;
      if (article.contains('Jacke')) {
        _type = 'Jacke';
      } else if (article.contains('Hose')) {
        _type = 'Hose';
      }
    });
  }

  Future<void> _saveEquipment() async {
    if (_formKey.currentState!.validate()) {
      if (_nfcTag.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bitte scannen Sie einen NFC-Tag'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        User? currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser == null) {
          throw Exception('Kein Benutzer angemeldet');
        }

        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

        EquipmentModel newEquipment = EquipmentModel(
          id: '', // Wird von Firestore generiert
          nfcTag: _nfcTag,
          barcode: _barcode.isNotEmpty ? _barcode : null,
          article: _article,
          type: _type,
          size: _sizeController.text.trim(),
          fireStation: _fireStation,
          owner: _ownerController.text.trim(),
          washCycles: 0, // Initial auf 0 setzen
          checkDate: _selectedCheckDate,
          createdAt: DateTime.now(),
          createdBy: userData['name'] ?? currentUser.email ?? '',
          status: _status, // Status hinzufügen
        );

        await _equipmentService.addEquipment(newEquipment);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Einsatzkleidung erfolgreich angelegt'),
              backgroundColor: Colors.green,
            ),
          );

          // Formular zurücksetzen
          setState(() {
            _nfcTag = '';
            _barcode = '';
            _article = _articles.first;
            _type = 'Jacke';
            _sizeController.clear();
            _fireStation = _fireStations.first;
            _ownerController.clear();
            _selectedCheckDate = DateTime.now();
            _checkDateController.text = DateFormat('dd.MM.yyyy').format(DateTime.now());
            _status = EquipmentStatus.ready;
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Fehler: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Einsatzkleidung anlegen'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'NFC-Tag und Barcode',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              // NFC-Tag (obligatorisch)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'NFC-Tag scannen (erforderlich)',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _nfcTag.isNotEmpty
                                  ? 'NFC-Tag: $_nfcTag'
                                  : 'Kein NFC-Tag gescannt',
                              style: TextStyle(
                                color: _nfcTag.isNotEmpty
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _scanNfcTag,
                            icon: const Icon(Icons.nfc),
                            label: const Text('Scannen'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Barcode (optional)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Barcode scannen (optional)',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _barcode.isNotEmpty
                                  ? 'Barcode: $_barcode'
                                  : 'Kein Barcode gescannt',
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _scanBarcode,
                            icon: const Icon(Icons.qr_code_scanner),
                            label: const Text('Scannen'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Artikelinformationen',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              // Artikel
              DropdownButtonFormField<String>(
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Artikel',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                value: _article,
                items: _articles.map((String article) {
                  return DropdownMenuItem<String>(
                    value: article,
                    child: Text(article),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    _setTypeBasedOnArticle(newValue);
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Bitte wählen Sie einen Artikel aus';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Typ
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Typ',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.style),
                ),
                value: _type,
                items: _types.map((String type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _type = newValue;
                    });
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Bitte wählen Sie einen Typ aus';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Größe
              TextFormField(
                controller: _sizeController,
                decoration: const InputDecoration(
                  labelText: 'Größe',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.format_size),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Bitte geben Sie eine Größe ein';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              const Text(
                'Zuordnung',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              // Ortsfeuerwehr
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Ortsfeuerwehr',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_city),
                ),
                value: _fireStation,
                items: _fireStations.map((String station) {
                  return DropdownMenuItem<String>(
                    value: station,
                    child: Text(station),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _fireStation = newValue;
                    });
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Bitte wählen Sie eine Ortsfeuerwehr aus';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Besitzer
              TextFormField(
                controller: _ownerController,
                decoration: const InputDecoration(
                  labelText: 'Besitzer',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Bitte geben Sie einen Besitzer ein';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              const Text(
                'Prüfinformationen',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              // Prüfdatum
              TextFormField(
                controller: _checkDateController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Prüfdatum',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.event),
                ),
                onTap: _selectCheckDate,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Bitte wählen Sie ein Prüfdatum aus';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              const Text(
                'Status',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              // Status
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.flag),
                ),
                value: _status,
                items: EquipmentStatus.values.map((String status) {
                  return DropdownMenuItem<String>(
                    value: status,
                    child: Row(
                      children: [
                        Icon(
                          EquipmentStatus.getStatusIcon(status),
                          color: EquipmentStatus.getStatusColor(status),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(status),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _status = newValue;
                    });
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Bitte wählen Sie einen Status aus';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveEquipment,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text(
                    'Einsatzkleidung anlegen',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}