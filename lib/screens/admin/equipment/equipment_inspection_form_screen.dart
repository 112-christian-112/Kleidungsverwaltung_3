// 3. Prüfungsformular zum Erstellen einer neuen Prüfung
// screens/admin/equipment/equipment_inspection_form_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/equipment_model.dart';
import '../../../models/equipment_inspection_model.dart';
import '../../../services/equipment_inspection_service.dart';

class EquipmentInspectionFormScreen extends StatefulWidget {
  final EquipmentModel equipment;

  const EquipmentInspectionFormScreen({
    Key? key,
    required this.equipment,
  }) : super(key: key);

  @override
  State<EquipmentInspectionFormScreen> createState() => _EquipmentInspectionFormScreenState();
}

class _EquipmentInspectionFormScreenState extends State<EquipmentInspectionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final EquipmentInspectionService _inspectionService = EquipmentInspectionService();

  DateTime _inspectionDate = DateTime.now();
  final TextEditingController _inspectionDateController = TextEditingController();

  String _inspector = '';
  final TextEditingController _inspectorController = TextEditingController();

  InspectionResult _result = InspectionResult.passed;

  final TextEditingController _commentsController = TextEditingController();

  DateTime _nextInspectionDate = DateTime.now().add(const Duration(days: 365));
  final TextEditingController _nextInspectionDateController = TextEditingController();

  final List<String> _issues = [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _initDateControllers();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        if (userDoc.exists) {
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
          setState(() {
            _inspector = userData['name'] ?? '';
            _inspectorController.text = _inspector;
          });
        }
      }
    } catch (e) {
      print('Fehler beim Laden der Benutzerdaten: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _initDateControllers() {
    _inspectionDateController.text = DateFormat('dd.MM.yyyy').format(_inspectionDate);
    _nextInspectionDateController.text = DateFormat('dd.MM.yyyy').format(_nextInspectionDate);
  }

  @override
  void dispose() {
    _inspectionDateController.dispose();
    _inspectorController.dispose();
    _commentsController.dispose();
    _nextInspectionDateController.dispose();
    super.dispose();
  }

  Future<void> _selectInspectionDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _inspectionDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null && pickedDate != _inspectionDate) {
      setState(() {
        _inspectionDate = pickedDate;
        _inspectionDateController.text = DateFormat('dd.MM.yyyy').format(pickedDate);
      });
    }
  }

  Future<void> _selectNextInspectionDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _nextInspectionDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null && pickedDate != _nextInspectionDate) {
      setState(() {
        _nextInspectionDate = pickedDate;
        _nextInspectionDateController.text = DateFormat('dd.MM.yyyy').format(pickedDate);
      });
    }
  }

  void _toggleIssue(String issue) {
    setState(() {
      if (_issues.contains(issue)) {
        _issues.remove(issue);
      } else {
        _issues.add(issue);
      }
    });
  }

  Future<void> _saveInspection() async {
    if (_formKey.currentState!.validate()) {
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

        EquipmentInspectionModel inspection = EquipmentInspectionModel(
          id: '', // Wird von Firestore generiert
          equipmentId: widget.equipment.id,
          inspectionDate: _inspectionDate,
          inspector: _inspectorController.text.trim(),
          result: _result,
          comments: _commentsController.text.trim(),
          nextInspectionDate: _nextInspectionDate,
          issues: _issues.isNotEmpty ? _issues : null,
          createdAt: DateTime.now(),
          createdBy: userData['name'] ?? currentUser.email ?? '',
        );

        await _inspectionService.addInspection(inspection);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Prüfung erfolgreich gespeichert'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
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
        title: const Text('Neue Prüfung durchführen'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Equipmentinformationen
              Card(
                margin: const EdgeInsets.only(bottom: 16.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Einsatzkleidung',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow('Artikel', widget.equipment.article),
                      _buildInfoRow('Typ', widget.equipment.type),
                      _buildInfoRow('Besitzer', widget.equipment.owner),
                      _buildInfoRow('NFC-Tag', widget.equipment.nfcTag),
                    ],
                  ),
                ),
              ),

              // Prüfungsdaten
              Card(
                margin: const EdgeInsets.only(bottom: 16.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Prüfungsdaten',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Prüfdatum
                      TextFormField(
                        controller: _inspectionDateController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Prüfdatum',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.event),
                        ),
                        onTap: _selectInspectionDate,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Bitte wählen Sie ein Prüfdatum aus';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Prüfer
                      TextFormField(
                        controller: _inspectorController,
                        decoration: const InputDecoration(
                          labelText: 'Prüfer',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Bitte geben Sie den Namen des Prüfers ein';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Prüfergebnis
                      const Text('Prüfergebnis:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<InspectionResult>(
                              title: const Text('Bestanden'),
                              value: InspectionResult.passed,
                              groupValue: _result,
                              onChanged: (InspectionResult? value) {
                                setState(() {
                                  _result = value!;
                                });
                              },
                              activeColor: Colors.green,
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<InspectionResult>(
                              title: const Text('Bedingt'),
                              value: InspectionResult.conditionalPass,
                              groupValue: _result,
                              onChanged: (InspectionResult? value) {
                                setState(() {
                                  _result = value!;
                                });
                              },
                              activeColor: Colors.orange,
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<InspectionResult>(
                              title: const Text('Durchgef.'),
                              value: InspectionResult.failed,
                              groupValue: _result,
                              onChanged: (InspectionResult? value) {
                                setState(() {
                                  _result = value!;
                                });
                              },
                              activeColor: Colors.red,
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Nächstes Prüfdatum
                      TextFormField(
                        controller: _nextInspectionDateController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Nächstes Prüfdatum',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.event_repeat),
                        ),
                        onTap: _selectNextInspectionDate,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Bitte wählen Sie ein Datum für die nächste Prüfung aus';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Festgestellte Probleme
              Card(
                margin: const EdgeInsets.only(bottom: 16.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Festgestellte Probleme',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildIssueChip('Verschleiß'),
                          _buildIssueChip('Nahtbeschädigung'),
                          _buildIssueChip('Reißverschluss defekt'),
                          _buildIssueChip('Fehlende Reflektoren'),
                          _buildIssueChip('Brandlöcher'),
                          _buildIssueChip('Verschmutzung'),
                          _buildIssueChip('Materialermüdung'),
                          _buildIssueChip('Verblasste Farbe'),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Kommentare
                      TextFormField(
                        controller: _commentsController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Kommentare',
                          hintText: 'Zusätzliche Bemerkungen zur Prüfung',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Speichern-Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveInspection,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text(
                    'Prüfung speichern',
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildIssueChip(String issue) {
    final bool isSelected = _issues.contains(issue);
    return FilterChip(
      label: Text(issue),
      selected: isSelected,
      onSelected: (bool selected) {
        _toggleIssue(issue);
      },
      backgroundColor: Colors.grey.shade200,
      selectedColor: Colors.red.shade100,
      checkmarkColor: Colors.red,
    );
  }
}