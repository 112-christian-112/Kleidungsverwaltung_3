// screens/missions/mission_list_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/mission_model.dart';
import '../../services/mission_service.dart';
import '../../services/permission_service.dart';

import 'add_missions_screen.dart';
import 'mission_detail_screen.dart';

class MissionListScreen extends StatefulWidget {
  const MissionListScreen({Key? key}) : super(key: key);

  @override
  State<MissionListScreen> createState() => _MissionListScreenState();
}

class _MissionListScreenState extends State<MissionListScreen> {
  final MissionService _missionService = MissionService();
  final PermissionService _permissionService = PermissionService();
  bool _isAdmin = false;
  String _userFireStation = '';
  bool _isLoading = true;
  String _searchQuery = '';
  String? _filterType;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final isAdmin = await _permissionService.isAdmin();
      final userFireStation = await _permissionService.getUserFireStation();

      if (mounted) {
        setState(() {
          _isAdmin = isAdmin;
          _userFireStation = userFireStation;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Fehler beim Laden der Benutzerinformationen: $e');
      if (mounted) {
        setState(() {
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
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filter',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Suchen',
                hintText: 'Nach Einsatzname oder Ort suchen...',
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

          Expanded(
            child: StreamBuilder<List<MissionModel>>(
              stream: _isAdmin
                  ? _missionService.getAllMissions()
                  : _missionService.getMissionsByFireStation(_userFireStation),
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
                    child: Text('Keine Einsätze vorhanden'),
                  );
                }

                List<MissionModel> missionList = snapshot.data!;

                // Filtern nach Suchbegriff
                if (_searchQuery.isNotEmpty) {
                  missionList = missionList
                      .where((mission) =>
                  mission.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                      mission.location.toLowerCase().contains(_searchQuery.toLowerCase()))
                      .toList();
                }

                // Filtern nach Typ
                if (_filterType != null) {
                  missionList = missionList
                      .where((mission) => mission.type == _filterType)
                      .toList();
                }

                if (missionList.isEmpty) {
                  return const Center(
                    child: Text('Keine passenden Einsätze gefunden'),
                  );
                }

                return ListView.builder(
                  itemCount: missionList.length,
                  itemBuilder: (context, index) {
                    final mission = missionList[index];

                    // Icon und Farbe basierend auf Einsatztyp
                    IconData typeIcon;
                    Color typeColor;

                    switch (mission.type) {
                      case 'fire':
                        typeIcon = Icons.local_fire_department;
                        typeColor = Colors.red;
                        break;
                      case 'technical':
                        typeIcon = Icons.build;
                        typeColor = Colors.blue;
                        break;
                      case 'hazmat':
                        typeIcon = Icons.dangerous;
                        typeColor = Colors.orange;
                        break;
                      case 'water':
                        typeIcon = Icons.water;
                        typeColor = Colors.lightBlue;
                        break;
                      case 'training':
                        typeIcon = Icons.school;
                        typeColor = Colors.green;
                        break;
                      default: // Handles 'other' and any unexpected values
                        typeIcon = Icons.more_horiz;
                        typeColor = Colors.grey;
                        break;
                    }

                    final formattedDate = DateFormat('dd.MM.yyyy').format(mission.startTime);
                    final formattedTime = DateFormat('HH:mm').format(mission.startTime);

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: typeColor.withOpacity(0.2),
                          child: Icon(typeIcon, color: typeColor),
                        ),
                        title: Text(mission.name),
                        subtitle: Text('$formattedDate um $formattedTime Uhr\n${mission.location}'),
                        isThreeLine: true,
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${mission.equipmentIds.length}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const Text(
                              'Ausrüstung',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
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
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddMissionScreen(),
            ),
          );

          if (result == true) {
            // Optional: Reload oder Feedback
          }
        },
        tooltip: 'Einsatz hinzufügen',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Filter'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Einsatztyp'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                    label: const Text('Alle'),
                    selected: _filterType == null,
                    onSelected: (selected) {
                      setState(() {
                        _filterType = null;
                      });
                    },
                  ),
                  FilterChip(
                    label: const Text('Brand'),
                    selected: _filterType == 'fire',
                    onSelected: (selected) {
                      setState(() {
                        _filterType = selected ? 'fire' : null;
                      });
                    },
                  ),
                  FilterChip(
                    label: const Text('Technisch'),
                    selected: _filterType == 'technical',
                    onSelected: (selected) {
                      setState(() {
                        _filterType = selected ? 'technical' : null;
                      });
                    },
                  ),
                  FilterChip(
                    label: const Text('Gefahrgut'),
                    selected: _filterType == 'hazmat',
                    onSelected: (selected) {
                      setState(() {
                        _filterType = selected ? 'hazmat' : null;
                      });
                    },
                  ),
                  FilterChip(
                    label: const Text('Wasser'),
                    selected: _filterType == 'water',
                    onSelected: (selected) {
                      setState(() {
                        _filterType = selected ? 'water' : null;
                      });
                    },
                  ),
                  FilterChip(
                    label: const Text('Übung'),
                    selected: _filterType == 'training',
                    onSelected: (selected) {
                      setState(() {
                        _filterType = selected ? 'training' : null;
                      });
                    },
                  ),
                  FilterChip(
                    label: const Text('Sonstige'),
                    selected: _filterType == 'other',
                    onSelected: (selected) {
                      setState(() {
                        _filterType = selected ? 'other' : null;
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _filterType = null;
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