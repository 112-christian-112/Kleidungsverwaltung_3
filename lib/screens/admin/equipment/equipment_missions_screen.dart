// screens/admin/equipment/equipment_missions_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/equipment_model.dart';
import '../../../models/mission_model.dart';
import '../../../services/mission_service.dart';
import '../../missions/mission_detail_screen.dart';

class EquipmentMissionsScreen extends StatefulWidget {
  final EquipmentModel equipment;

  const EquipmentMissionsScreen({
    Key? key,
    required this.equipment,
  }) : super(key: key);

  @override
  State<EquipmentMissionsScreen> createState() => _EquipmentMissionsScreenState();
}

class _EquipmentMissionsScreenState extends State<EquipmentMissionsScreen> {
  final MissionService _missionService = MissionService();
  bool _isLoading = true;
  List<MissionModel> _missions = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadMissions();
  }

  Future<void> _loadMissions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Alle Missionen abrufen, bei denen diese Ausrüstung verwendet wurde
      final missions = await _missionService.getMissionsForEquipment(widget.equipment.id);

      if (mounted) {
        setState(() {
          _missions = missions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Fehler beim Laden der Einsätze: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Einsätze'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error, size: 48),
              const SizedBox(height: 16),
              Text(
                _errorMessage,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadMissions,
                child: const Text('Erneut versuchen'),
              ),
            ],
          ),
        ),
      );
    }

    if (_missions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.assignment_outlined, color: Colors.grey, size: 64),
              const SizedBox(height: 16),
              const Text(
                'Keine Einsätze gefunden',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Diese Ausrüstung wurde bisher bei keinem Einsatz verwendet',
                style: TextStyle(color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMissions,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Equipment Info Card
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.equipment.article,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          widget.equipment.type == 'Jacke'
                              ? Icons.accessibility_new
                              : Icons.airline_seat_legroom_normal,
                          color: widget.equipment.type == 'Jacke' ? Colors.blue : Colors.amber,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${widget.equipment.type} - Größe: ${widget.equipment.size}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Besitzer: ${widget.equipment.owner}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Verwendet bei ${_missions.length} Einsätzen',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Missions list header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              'Einsätze',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),

          // Missions list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: _missions.length,
              itemBuilder: (context, index) {
                final mission = _missions[index];

                // Einsatztyp-Anzeige
                IconData typeIcon;
                Color typeColor;
                String typeText;

                switch (mission.type) {
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

                final formattedDate = DateFormat('dd.MM.yyyy').format(mission.startTime);
                final formattedTime = DateFormat('HH:mm').format(mission.startTime);

                return Card(
                  margin: const EdgeInsets.only(bottom: 8.0),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: typeColor.withOpacity(0.2),
                      child: Icon(typeIcon, color: typeColor),
                    ),
                    title: Text(mission.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$formattedDate um $formattedTime Uhr'),
                        Text(mission.location),
                        Text(
                          typeText,
                          style: TextStyle(
                            color: typeColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    isThreeLine: true,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MissionDetailScreen(
                            missionId: mission.id,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}