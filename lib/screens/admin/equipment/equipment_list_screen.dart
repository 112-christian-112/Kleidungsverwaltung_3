// Aktualisierte equipment_list_screen.dart mit Gruppierung nach Besitzer
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/equipment_model.dart';
import '../../../services/equipment_service.dart';
import '../../../services/permission_service.dart';
import '../../add_equipment_screen.dart';
import 'equipment_detail_screen.dart';
import 'history_screen.dart';

class EquipmentListScreen extends StatefulWidget {
  const EquipmentListScreen({Key? key}) : super(key: key);

  @override
  State<EquipmentListScreen> createState() => _EquipmentListScreenState();
}

class _EquipmentListScreenState extends State<EquipmentListScreen> {
  final EquipmentService _equipmentService = EquipmentService();
  final PermissionService _permissionService = PermissionService();
  bool _isAdmin = false;
  String _searchQuery = '';
  String _filterFireStation = '';
  String _filterType = '';
  String _filterStatus = 'Alle';
  bool _groupByOwner = true; // Standardmäßig nach Besitzer gruppieren

  // Neue Variablen für Mehrfachauswahl
  bool _selectionMode = false;
  final Set<String> _selectedEquipmentIds = {};
  bool _isProcessingBatch = false;

  final List<String> _fireStations = [
    'Alle',
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

  final List<String> _types = ['Alle', 'Jacke', 'Hose'];

  final List<String> _statusOptions = ['Alle', ...EquipmentStatus.values];

  @override
  void initState() {
    super.initState();
    _filterFireStation = _fireStations.first;
    _filterType = _types.first;
    _filterStatus = _statusOptions.first;
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

  // Neues Verhalten für Mehrfachauswahl
  void _toggleSelection(String equipmentId) {
    setState(() {
      if (_selectedEquipmentIds.contains(equipmentId)) {
        _selectedEquipmentIds.remove(equipmentId);
        if (_selectedEquipmentIds.isEmpty) {
          _selectionMode = false;
        }
      } else {
        _selectedEquipmentIds.add(equipmentId);
      }
    });
  }

  // Auswahl aller angezeigten Ausrüstungen
  void _selectAll(List<EquipmentModel> equipmentList) {
    setState(() {
      if (_selectedEquipmentIds.length == equipmentList.length) {
        // Wenn bereits alle ausgewählt sind, dann Auswahl aufheben
        _selectedEquipmentIds.clear();
        _selectionMode = false;
      } else {
        // Sonst alle auswählen
        _selectedEquipmentIds.clear();
        for (var equipment in equipmentList) {
          _selectedEquipmentIds.add(equipment.id);
        }
        _selectionMode = true;
      }
    });
  }

  // Status für ausgewählte Ausrüstungen ändern
  Future<void> _updateStatusForSelected(String newStatus) async {
    if (_selectedEquipmentIds.isEmpty) return;

    setState(() {
      _isProcessingBatch = true;
    });

    try {
      // Batch-Statusaktualisierung für alle ausgewählten Elemente durchführen
      await _equipmentService.updateStatusBatch(_selectedEquipmentIds.toList(), newStatus);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status für ${_selectedEquipmentIds.length} Ausrüstungsgegenstände aktualisiert'),
            backgroundColor: Colors.green,
          ),
        );

        // Auswahl zurücksetzen
        setState(() {
          _selectedEquipmentIds.clear();
          _selectionMode = false;
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
          _isProcessingBatch = false;
        });
      }
    }
  }

  // Dialog zum Statusändern anzeigen
  void _showBatchStatusUpdateDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Status ändern'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Status für ${_selectedEquipmentIds.length} ausgewählte Ausrüstungsgegenstände ändern:'),
            const SizedBox(height: 16),
            SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: EquipmentStatus.values.map((status) {
                  return ListTile(
                    leading: Icon(
                      EquipmentStatus.getStatusIcon(status),
                      color: EquipmentStatus.getStatusColor(status),
                    ),
                    title: Text(status),
                    onTap: () {
                      Navigator.pop(context);
                      _updateStatusForSelected(status);
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
        ],
      ),
    );
  }

  // Gruppierungsumschalter
  void _toggleGrouping() {
    setState(() {
      _groupByOwner = !_groupByOwner;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Einsatzkleidung verwalten'),
        actions: [
          // Gruppierungsumschalter
          IconButton(
            icon: Icon(_groupByOwner ? Icons.person : Icons.view_list),
            onPressed: _toggleGrouping,
            tooltip: _groupByOwner ? 'Gruppierung nach Besitzer aufheben' : 'Nach Besitzer gruppieren',
          ),
          // Anzeigen des Mehrfachauswahl-Buttons nur wenn im Auswahlmodus
          if (_selectionMode) ...[
            IconButton(
              icon: const Icon(Icons.change_circle),
              onPressed: _showBatchStatusUpdateDialog,
              tooltip: 'Status ändern',
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _selectedEquipmentIds.clear();
                  _selectionMode = false;
                });
              },
              tooltip: 'Auswahl abbrechen',
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: _showFilterDialog,
              tooltip: 'Filter',
            ),
          ],
        ],
      ),
      body: _isProcessingBatch
          ? const Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Status wird aktualisiert...'),
        ],
      ))
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Suchen',
                hintText: 'Nach NFC, Barcode, Besitzer suchen...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          if (_filterFireStation != 'Alle' || _filterType != 'Alle' || _filterStatus != 'Alle')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Aktive Filter:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (_filterFireStation != 'Alle')
                        Chip(
                          label: Text(_filterFireStation),
                          deleteIcon: const Icon(Icons.clear),
                          onDeleted: () {
                            setState(() {
                              _filterFireStation = 'Alle';
                            });
                          },
                        ),
                      if (_filterType != 'Alle')
                        Chip(
                          label: Text(_filterType),
                          deleteIcon: const Icon(Icons.clear),
                          onDeleted: () {
                            setState(() {
                              _filterType = 'Alle';
                            });
                          },
                        ),
                      if (_filterStatus != 'Alle')
                        Chip(
                          label: Text(_filterStatus),
                          avatar: Icon(
                            EquipmentStatus.getStatusIcon(_filterStatus),
                            size: 16,
                            color: EquipmentStatus.getStatusColor(_filterStatus),
                          ),
                          deleteIcon: const Icon(Icons.clear),
                          onDeleted: () {
                            setState(() {
                              _filterStatus = 'Alle';
                            });
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ),
          Expanded(
            child: StreamBuilder<List<EquipmentModel>>(
              stream: _equipmentService.getEquipmentByUserFireStation(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Fehler beim Laden der Daten: ${snapshot.error}',
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text('Keine Einsatzkleidung vorhanden'),
                  );
                }

                List<EquipmentModel> equipmentList = snapshot.data!;

                // Filtern nach Suchbegriff
                if (_searchQuery.isNotEmpty) {
                  equipmentList = equipmentList
                      .where((equipment) =>
                  equipment.nfcTag.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                      (equipment.barcode != null &&
                          equipment.barcode!.toLowerCase().contains(_searchQuery.toLowerCase())) ||
                      equipment.owner.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                      equipment.size.toLowerCase().contains(_searchQuery.toLowerCase()))
                      .toList();
                }

                // Filtern nach Ortsfeuerwehr (nur für Admins relevant)
                if (_filterFireStation != 'Alle' && _isAdmin) {
                  equipmentList = equipmentList
                      .where((equipment) => equipment.fireStation == _filterFireStation)
                      .toList();
                }

                // Filtern nach Typ
                if (_filterType != 'Alle') {
                  equipmentList = equipmentList
                      .where((equipment) => equipment.type == _filterType)
                      .toList();
                }

                // Filtern nach Status
                if (_filterStatus != 'Alle') {
                  equipmentList = equipmentList
                      .where((equipment) => equipment.status == _filterStatus)
                      .toList();
                }

                if (equipmentList.isEmpty) {
                  return const Center(
                    child: Text('Keine Einsatzkleidung gefunden, die den Filterkriterien entspricht'),
                  );
                }

                // Wenn nach Besitzer gruppiert werden soll
                if (_groupByOwner) {
                  // Nach Besitzer gruppieren
                  Map<String, List<EquipmentModel>> ownerGroups = {};

                  for (var equipment in equipmentList) {
                    if (!ownerGroups.containsKey(equipment.owner)) {
                      ownerGroups[equipment.owner] = [];
                    }
                    ownerGroups[equipment.owner]!.add(equipment);
                  }

                  // Nach Besitzer sortierte Liste erstellen
                  List<String> sortedOwners = ownerGroups.keys.toList()..sort();

                  return ListView.builder(
                    itemCount: sortedOwners.length,
                    itemBuilder: (context, index) {
                      final owner = sortedOwners[index];
                      final ownerEquipment = ownerGroups[owner]!;

                      // Nach Typ (Jacke, Hose) sortieren
                      ownerEquipment.sort((a, b) => a.type.compareTo(b.type));

                      return Card(
                        margin: const EdgeInsets.all(8.0),
                        child: ExpansionTile(
                          title: Text(
                            owner,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Text(
                            '${ownerEquipment.length} Ausrüstungsgegenstände',
                            style: const TextStyle(fontSize: 12),
                          ),
                          initiallyExpanded: true, // Standardmäßig geöffnet
                          children: [
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: ownerEquipment.length,
                              itemBuilder: (context, equipIndex) {
                                return _buildEquipmentItem(ownerEquipment[equipIndex]);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                } else {
                  // Normale Listenansicht ohne Gruppierung
                  return Column(
                    children: [
                      // Headerzeile mit Auswahloptionen
                      if (equipmentList.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: Row(
                            children: [
                              Checkbox(
                                value: _selectedEquipmentIds.length == equipmentList.length && equipmentList.isNotEmpty,
                                onChanged: (value) => _selectAll(equipmentList),
                              ),
                              Text('${equipmentList.length} Ausrüstungsgegenstände',
                                  style: const TextStyle(fontWeight: FontWeight.bold)),
                              const Spacer(),
                              if (_selectionMode)
                                Text('${_selectedEquipmentIds.length} ausgewählt',
                                    style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                            ],
                          ),
                        ),

                      // Liste der Ausrüstung
                      Expanded(
                        child: ListView.builder(
                          itemCount: equipmentList.length,
                          itemBuilder: (context, index) {
                            return _buildEquipmentItem(equipmentList[index]);
                          },
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
          ),
        ],
      ),
      // Nur Admins dürfen neue Einsatzkleidung hinzufügen
      // Aber im Auswahlmodus zeigen wir einen anderen FAB an
      floatingActionButton: _selectionMode
          ? _selectedEquipmentIds.isNotEmpty
          ? FloatingActionButton.extended(
        onPressed: _showBatchStatusUpdateDialog,
        label: const Text('Status ändern'),
        icon: const Icon(Icons.change_circle),
      )
          : null
          : (_isAdmin
          ? FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddEquipmentScreen(),
            ),
          );
        },
        tooltip: 'Einsatzkleidung hinzufügen',
        child: const Icon(Icons.add),
      )
          : null),
    );
  }

  // Widget für den einzelnen Ausrüstungsgegenstand
  Widget _buildEquipmentItem(EquipmentModel equipment) {
    final bool isSelected = _selectedEquipmentIds.contains(equipment.id);
    final formattedCheckDate = DateFormat('dd.MM.yyyy').format(equipment.checkDate);
    final bool isCheckDateExpired = equipment.checkDate.isBefore(
        DateTime.now().subtract(const Duration(days: 365))
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : (equipment.status == EquipmentStatus.ready
              ? Colors.green.withOpacity(0.5)
              : Colors.grey.withOpacity(0.2)),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _selectionMode
            ? () => _toggleSelection(equipment.id)
            : () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EquipmentDetailScreen(
                equipment: equipment,
              ),
            ),
          );
        },
        onLongPress: () {
          // Lange drücken aktiviert Auswahlmodus oder zeigt Optionen
          if (_selectionMode) {
            _toggleSelection(equipment.id);
          } else {
            setState(() {
              _selectionMode = true;
              _selectedEquipmentIds.add(equipment.id);
            });
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Checkbox für Mehrfachauswahl
              if (_selectionMode)
                Checkbox(
                  value: isSelected,
                  onChanged: (bool? value) {
                    _toggleSelection(equipment.id);
                  },
                ),

              // Icon für Jacke/Hose
              Container(
                decoration: BoxDecoration(
                  color: equipment.type == 'Jacke'
                      ? Colors.blue.withOpacity(0.1)
                      : Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(10),
                child: Icon(
                  equipment.type == 'Jacke'
                      ? Icons.accessibility_new
                      : Icons.airline_seat_legroom_normal,
                  color: equipment.type == 'Jacke'
                      ? Colors.blue
                      : Colors.amber,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      equipment.article,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          EquipmentStatus.getStatusIcon(equipment.status),
                          color: EquipmentStatus.getStatusColor(equipment.status),
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          equipment.status,
                          style: TextStyle(
                            color: EquipmentStatus.getStatusColor(equipment.status),
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Größe: ${equipment.size}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    Text(
                      'Prüfdatum: $formattedCheckDate',
                      style: TextStyle(
                        fontSize: 12,
                        color: isCheckDateExpired ? Colors.red : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Filter'),
          content: SingleChildScrollView(
            child: Container(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ortsfeuerwehr-Filter nur für Admins anzeigen
                  if (_isAdmin) ...[
                    const Text('Ortsfeuerwehr'),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.maxFinite,
                      child: DropdownButtonFormField<String>(
                        value: _filterFireStation,
                        items: _fireStations.map((String station) {
                          return DropdownMenuItem<String>(
                            value: station,
                            child: Text(station),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _filterFireStation = newValue;
                            });
                          }
                        },
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  const Text('Typ'),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.maxFinite,
                    child: DropdownButtonFormField<String>(
                      value: _filterType,
                      items: _types.map((String type) {
                        return DropdownMenuItem<String>(
                          value: type,
                          child: Text(type),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _filterType = newValue;
                          });
                        }
                      },
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Status'),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.maxFinite,
                    child: DropdownButtonFormField<String>(
                      value: _filterStatus,
                      items: _statusOptions.map((String status) {
                        return DropdownMenuItem<String>(
                          value: status,
                          child: status == 'Alle'
                              ? const Text('Alle')
                              : Row(
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
                            _filterStatus = newValue;
                          });
                        }
                      },
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _filterFireStation = 'Alle';
                  _filterType = 'Alle';
                  _filterStatus = 'Alle';
                });
              },
              child: const Text('Zurücksetzen'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                this.setState(() {});
              },
              child: const Text('Anwenden'),
            ),
          ],
        ),
      ),
    );
  }
}