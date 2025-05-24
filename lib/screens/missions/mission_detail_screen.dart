// screens/missions/mission_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/mission_model.dart';
import '../../models/equipment_model.dart';
import '../../services/mission_service.dart';
import '../../services/permission_service.dart';
import 'edit_mission_screen.dart';
import 'add_equipment_to_mission_nfc_screen.dart';
import 'mission_send_to_cleaning_screen.dart'; // Neue Import-Zeile
import '../admin/equipment/equipment_detail_screen.dart';

class MissionDetailScreen extends StatefulWidget {
  final String missionId;

  const MissionDetailScreen({
    Key? key,
    required this.missionId,
  }) : super(key: key);

  @override
  State<MissionDetailScreen> createState() => _MissionDetailScreenState();
}

class _MissionDetailScreenState extends State<MissionDetailScreen> {
  final MissionService _missionService = MissionService();
  final PermissionService _permissionService = PermissionService();
  bool _isAdmin = false;
  bool _isLoading = true;
  MissionModel? _mission;
  List<EquipmentModel> _equipmentList = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Admin-Rechte prüfen
      final isAdmin = await _permissionService.isAdmin();

      // Mission-Daten abrufen
      final missionDoc = await FirebaseFirestore.instance
          .collection('missions')
          .doc(widget.missionId)
          .get();

      if (!missionDoc.exists) {
        throw Exception('Einsatz nicht gefunden');
      }

      final mission = MissionModel.fromMap(
          missionDoc.data() as Map<String, dynamic>,
          missionDoc.id
      );

      // Ausrüstung für den Einsatz abrufen
      final equipmentList = await _missionService.getEquipmentForMission(widget.missionId);

      if (mounted) {
        setState(() {
          _isAdmin = isAdmin;
          _mission = mission;
          _equipmentList = equipmentList;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Fehler beim Laden der Einsatzdaten: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _addEquipmentByNfc() async {
    if (_mission == null) return;

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddEquipmentToMissionNfcScreen(
          missionId: _mission!.id,
          alreadyAddedEquipmentIds: _mission!.equipmentIds,
        ),
      ),
    );

    if (result == true) {
      // Daten neu laden
      _loadData();
    }
  }

  Future<void> _sendToCleaningAndGeneratePdf() async {
    if (_mission == null) return;

    // Zur Reinigungsseite navigieren
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MissionSendToCleaningScreen(
          missionId: _mission!.id,
          missionName: _mission!.name,
        ),
      ),
    );

    // Daten nach Rückkehr aktualisieren
    _loadData();
  }

  Future<void> _deleteMission() async {
    if (!_isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sie haben keine Berechtigung, Einsätze zu löschen'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Bestätigungsdialog anzeigen
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Einsatz löschen'),
        content: const Text(
          'Sind Sie sicher, dass Sie diesen Einsatz löschen möchten? Diese Aktion kann nicht rückgängig gemacht werden.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Löschen', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Einsatz in Firestore löschen
      await _missionService.deleteMission(widget.missionId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Einsatz erfolgreich gelöscht'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Einsatz-Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_mission == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Einsatz-Details')),
        body: const Center(child: Text('Einsatz nicht gefunden')),
      );
    }

    // Formatierte Daten
    final formattedStartDate = DateFormat('dd.MM.yyyy').format(_mission!.startTime);
    final formattedStartTime = DateFormat('HH:mm').format(_mission!.startTime);

    // Einsatztyp-Anzeige
    IconData typeIcon;
    Color typeColor;
    String typeText;

    switch (_mission!.type) {
      case 'fire':
        typeIcon = Icons.local_fire_department;
        typeColor = Colors.red;
        typeText = 'Brandeinsatz';
        break;
      case 'technical':
        typeIcon = Icons.build;
        typeColor = Colors.blue;
        typeText = 'Technische Hilfeleistung';
        break;
      case 'hazmat':
        typeIcon = Icons.dangerous;
        typeColor = Colors.orange;
        typeText = 'Gefahrguteinsatz';
        break;
      case 'water':
        typeIcon = Icons.water;
        typeColor = Colors.lightBlue;
        typeText = 'Wasser/Hochwasser';
        break;
      case 'training':
        typeIcon = Icons.school;
        typeColor = Colors.green;
        typeText = 'Übung';
        break;
      default:
        typeIcon = Icons.more_horiz;
        typeColor = Colors.grey;
        typeText = 'Sonstiger Einsatz';
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Einsatz-Details'),
        actions: [
          if (_isAdmin)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditMissionScreen(
                      mission: _mission!,
                    ),
                  ),
                );

                if (result == true) {
                  _loadData();
                }
              },
              tooltip: 'Bearbeiten',
            ),
          if (_isAdmin)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteMission,
              tooltip: 'Löschen',
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Einsatzübersicht
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Einsatztitel und Typ
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: typeColor.withOpacity(0.2),
                            child: Icon(typeIcon, color: typeColor),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _mission!.name,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  typeText,
                                  style: TextStyle(
                                    color: typeColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Einsatzort und -zeit
                      _buildInfoRow('Einsatzort:', _mission!.location),
                      _buildInfoRow('Datum:', formattedStartDate),
                      _buildInfoRow('Uhrzeit:', '$formattedStartTime Uhr'),
                      _buildInfoRow('Feuerwehr:', _mission!.fireStation),

                      if (_mission!.involvedFireStations.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'Beteiligte Ortswehren:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: _mission!.involvedFireStations.map((station) => Chip(
                            label: Text(station),
                            backgroundColor: station == _mission!.fireStation
                                ? typeColor.withOpacity(0.2)
                                : Colors.grey.withOpacity(0.2),
                            labelStyle: TextStyle(
                              fontWeight: station == _mission!.fireStation ? FontWeight.bold : FontWeight.normal,
                            ),
                          )).toList(),
                        ),
                      ],

                      if (_mission!.description.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'Beschreibung:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(_mission!.description),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

// In der problematischen Zeile in MissionDetailScreen.dart
// Das Problem befindet sich im Widget build bei der Row mit den Buttons

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Überschrift
                  const Text(
                    'Verwendete Ausrüstung',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  // Buttons in eigener Zeile mit Wrap
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Wrap(
                      spacing: 8.0,
                      children: [
                        SizedBox(
                          height: 36, // Festgelegte Höhe für konsistente Buttons
                          child: ElevatedButton.icon(
                            onPressed: _addEquipmentByNfc,
                            icon: const Icon(Icons.nfc, size: 16),
                            label: const Text('NFC'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              minimumSize: Size.zero, // Erlaubt kleinere Größen
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ),
                        if (_equipmentList.isNotEmpty)
                          SizedBox(
                            height: 36, // Gleiche Höhe für konsistente Buttons
                            child: ElevatedButton.icon(
                              onPressed: _sendToCleaningAndGeneratePdf,
                              icon: const Icon(Icons.local_laundry_service, size: 16),
                              label: const Text('Reinigung'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                minimumSize: Size.zero, // Erlaubt kleinere Größen
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              if (_equipmentList.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(
                      child: Text(
                        'Keine Ausrüstung für diesen Einsatz registriert',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                )
              else
                ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: _equipmentList.length,
                  itemBuilder: (context, index) {
                    final equipment = _equipmentList[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: equipment.type == 'Jacke' ? Colors.blue : Colors.amber,
                          child: Icon(
                            equipment.type == 'Jacke'
                                ? Icons.accessibility_new
                                : Icons.airline_seat_legroom_normal,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(equipment.article),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Besitzer: ${equipment.owner} | Größe: ${equipment.size}'),
                            // Status der Ausrüstung anzeigen
                            Row(
                              children: [
                                Icon(
                                  EquipmentStatus.getStatusIcon(equipment.status),
                                  size: 14,
                                  color: EquipmentStatus.getStatusColor(equipment.status),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Status: ${equipment.status}',
                                  style: TextStyle(
                                    color: EquipmentStatus.getStatusColor(equipment.status),
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        isThreeLine: true,
                        trailing: IconButton(
                          icon: const Icon(Icons.info_outline),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EquipmentDetailScreen(
                                  equipment: equipment,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),

              const SizedBox(height: 24),

              // Erstellungsinformationen
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Einsatzinformationen',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow('Erstellt von:', _mission!.createdBy),
                      _buildInfoRow(
                        'Erstellt am:',
                        DateFormat('dd.MM.yyyy HH:mm').format(_mission!.createdAt),
                      ),
                    ],
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
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
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