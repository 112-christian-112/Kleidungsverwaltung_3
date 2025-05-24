// screens/admin/equipment/equipment_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/equipment_model.dart';
import '../../../services/equipment_service.dart';
import '../../../services/permission_service.dart';
import 'edit_equipment_screen.dart';
import 'equipment_inspection_history.dart';
import 'equipment_missions_screen.dart';
import 'history_screen.dart';

class EquipmentDetailScreen extends StatefulWidget {
  final EquipmentModel equipment;

  const EquipmentDetailScreen({
    Key? key,
    required this.equipment,
  }) : super(key: key);

  @override
  State<EquipmentDetailScreen> createState() => _EquipmentDetailScreenState();
}

class _EquipmentDetailScreenState extends State<EquipmentDetailScreen> {
  final EquipmentService _equipmentService = EquipmentService();
  final PermissionService _permissionService = PermissionService();
  bool _isProcessing = false;
  bool _isAdmin = false;
  late int _washCycles;
  late DateTime _checkDate;
  late String _status;
  final TextEditingController _checkDateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _washCycles = widget.equipment.washCycles;
    _checkDate = widget.equipment.checkDate;
    _checkDateController.text = DateFormat('dd.MM.yyyy').format(_checkDate);
    _status = widget.equipment.status;
    _loadPermissions();
  }

  Future<void> _loadPermissions() async {
    final isAdmin = await _permissionService.isAdmin();
    if (mounted) {
      setState(() {
        _isAdmin = isAdmin;
      });
    }
  }

  @override
  void dispose() {
    _checkDateController.dispose();
    super.dispose();
  }

  Future<void> _selectCheckDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _checkDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null && pickedDate != _checkDate) {
      setState(() {
        _checkDate = pickedDate;
        _checkDateController.text = DateFormat('dd.MM.yyyy').format(pickedDate);
      });
    }
  }

  Future<void> _updateWashCycles(int newWashCycles) async {
    if (newWashCycles < 0) return;

    // Nur Admins dürfen Waschzyklen aktualisieren
    if (!_isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sie haben keine Berechtigung, die Waschzyklen zu bearbeiten'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      await _equipmentService.updateWashCycles(widget.equipment.id, newWashCycles);
      setState(() {
        _washCycles = newWashCycles;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Waschzyklen erfolgreich aktualisiert'),
            backgroundColor: Colors.green,
          ),
        );
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
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      await _equipmentService.updateStatus(widget.equipment.id, newStatus);

      // Lokalen Status aktualisieren
      setState(() {
        _status = newStatus;

        // Waschzyklen lokal aktualisieren, wenn Status auf "In der Reinigung" geändert wurde
        if (newStatus == EquipmentStatus.cleaning &&
            widget.equipment.status != EquipmentStatus.cleaning) {
          _washCycles += 1;
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Status erfolgreich aktualisiert'),
            backgroundColor: Colors.green,
          ),
        );
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
          _isProcessing = false;
        });
      }
    }
  }


  Future<void> _updateCheckDate() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      await _equipmentService.updateCheckDate(widget.equipment.id, _checkDate);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Prüfdatum erfolgreich aktualisiert'),
            backgroundColor: Colors.green,
          ),
        );
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
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _deleteEquipment() async {
    // Nur Admins dürfen Einsatzkleidung löschen
    if (!_isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sie haben keine Berechtigung, Einsatzkleidung zu löschen'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Bestätigungsdialog anzeigen
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Einsatzkleidung löschen'),
        content: const Text(
            'Sind Sie sicher, dass Sie diese Einsatzkleidung löschen möchten? Diese Aktion kann nicht rückgängig gemacht werden.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Löschen',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      await _equipmentService.deleteEquipment(widget.equipment.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Einsatzkleidung erfolgreich gelöscht'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
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
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Einsatzkleidung Details'),
        actions: [
          if (_isAdmin) // Nur für Admins anzeigen
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditEquipmentScreen(
                      equipment: widget.equipment,
                    ),
                  ),
                );

                // Wenn Änderungen gespeichert wurden (result == true), die Seite neu laden
                if (result == true) {
                  // Hier könnten Sie die Daten neu laden
                  // oder einfach Pop und Push verwenden, um die Seite neu zu laden
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EquipmentDetailScreen(
                        equipment: widget.equipment,
                      ),
                    ),
                  );
                }
              },
              tooltip: 'Bearbeiten',
            ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EquipmentHistoryScreen(
                    equipment: widget.equipment,
                  ),
                ),
              );
            },
            tooltip: 'Verlauf anzeigen',
          ),
          IconButton(
            icon: const Icon(Icons.checklist),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EquipmentInspectionHistoryScreen(
                    equipment: widget.equipment,
                  ),
                ),
              );
            },
            tooltip: 'Prüfungsverlauf anzeigen',
          ),
          if (_isAdmin)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _isProcessing ? null : _deleteEquipment,
              tooltip: 'Löschen',
            ),
        ],
      ),
      body: _isProcessing
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Grundinformationen',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow('Artikel', widget.equipment.article),
                    _buildInfoRow('Typ', widget.equipment.type),
                    _buildInfoRow('Größe', widget.equipment.size),
                    _buildInfoRow('Ortsfeuerwehr', widget.equipment.fireStation),
                    _buildInfoRow('Besitzer', widget.equipment.owner),
                    _buildInfoRow('Erstellt am', DateFormat('dd.MM.yyyy').format(widget.equipment.createdAt)),
                    _buildInfoRow('Erstellt von', widget.equipment.createdBy),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Identifikation',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow('NFC-Tag', widget.equipment.nfcTag),
                    if (widget.equipment.barcode != null && widget.equipment.barcode!.isNotEmpty)
                      _buildInfoRow('Barcode', widget.equipment.barcode!),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Neuer Button für Einsätze-Anzeige
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Einsätze',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Zeigen Sie an, bei welchen Einsätzen diese Einsatzkleidung verwendet wurde:',
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EquipmentMissionsScreen(
                                equipment: widget.equipment,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.assignment),
                        label: const Text('Einsätze anzeigen'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Status',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: EquipmentStatus.getStatusColor(_status).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                EquipmentStatus.getStatusIcon(_status),
                                color: EquipmentStatus.getStatusColor(_status),
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _status,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: EquipmentStatus.getStatusColor(_status),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('Status ändern:'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: EquipmentStatus.values.map((status) {
                        bool isSelected = _status == status;
                        return InkWell(
                          onTap: isSelected ? null : () => _updateStatus(status),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? EquipmentStatus.getStatusColor(status)
                                  : EquipmentStatus.getStatusColor(status).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: EquipmentStatus.getStatusColor(status),
                                width: isSelected ? 0 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  EquipmentStatus.getStatusIcon(status),
                                  color: isSelected
                                      ? Colors.white
                                      : EquipmentStatus.getStatusColor(status),
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  status,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : EquipmentStatus.getStatusColor(status),
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Waschzyklen-Karte basierend auf Berechtigungen anzeigen
            if (_isAdmin)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Waschzyklen',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle),
                            onPressed: _washCycles > 0
                                ? () => _updateWashCycles(_washCycles - 1)
                                : null,
                            color: Colors.red,
                            iconSize: 36,
                          ),
                          const SizedBox(width: 16),
                          Text(
                            '$_washCycles',
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 16),
                          IconButton(
                            icon: const Icon(Icons.add_circle),
                            onPressed: () => _updateWashCycles(_washCycles + 1),
                            color: Colors.green,
                            iconSize: 36,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              )
            else
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Waschzyklen',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          '$_washCycles',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Prüfdatum',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _checkDateController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Prüfdatum',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.event),
                      ),
                      onTap: _selectCheckDate,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _updateCheckDate,
                        child: const Text('Prüfdatum aktualisieren'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
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
            width: 120,
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
}