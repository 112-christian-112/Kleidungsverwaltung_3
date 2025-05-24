// screens/dashboard/dashboard_widgets/dashboard_metrics_widget.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/equipment_model.dart';
import '../../../services/equipment_service.dart';
import '../../../services/permission_service.dart';

class DashboardMetricsWidget extends StatefulWidget {
  final bool isAdmin;
  final String userFireStation;

  const DashboardMetricsWidget({
    Key? key,
    required this.isAdmin,
    required this.userFireStation,
  }) : super(key: key);

  @override
  State<DashboardMetricsWidget> createState() => _DashboardMetricsWidgetState();
}

class _DashboardMetricsWidgetState extends State<DashboardMetricsWidget> {
  final EquipmentService _equipmentService = EquipmentService();
  bool _isLoading = true;
  Map<String, int> _overdueCounts = {};
  Map<String, int> _cleaningCounts = {};
  Map<String, int> _repairCounts = {};
  Map<String, double> _avgEquipmentAge = {};
  int _totalEquipment = 0;
  int _totalOverdue = 0;
  int _totalInCleaning = 0;
  int _totalInRepair = 0;
  double _overallAvgAge = 0.0;

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
      // Ausrüstungsliste abrufen (entweder alle für Admins oder nur für bestimmte Feuerwehr)
      Stream<List<EquipmentModel>> equipmentStream = widget.isAdmin
          ? _equipmentService.getAllEquipment()
          : _equipmentService.getEquipmentByFireStation(widget.userFireStation);

      // Auf die Daten warten
      List<EquipmentModel> allEquipment = await equipmentStream.first;

      // Aktuelles Datum für Berechnungen
      final now = DateTime.now();

      // Maps für die Zählung initialisieren
      Map<String, List<EquipmentModel>> equipmentByStation = {};
      _overdueCounts = {};
      _cleaningCounts = {};
      _repairCounts = {};
      _avgEquipmentAge = {};

      // Gesamtzähler initialisieren
      _totalEquipment = allEquipment.length;
      _totalOverdue = 0;
      _totalInCleaning = 0;
      _totalInRepair = 0;

      // Summe der Alter für Durchschnittsberechnung
      Map<String, int> totalAgeInDaysByStation = {};
      int overallTotalAgeInDays = 0;

      // Gruppierung nach Feuerwehr
      for (var equipment in allEquipment) {
        if (!equipmentByStation.containsKey(equipment.fireStation)) {
          equipmentByStation[equipment.fireStation] = [];
          _overdueCounts[equipment.fireStation] = 0;
          _cleaningCounts[equipment.fireStation] = 0;
          _repairCounts[equipment.fireStation] = 0;
          totalAgeInDaysByStation[equipment.fireStation] = 0;
        }

        equipmentByStation[equipment.fireStation]!.add(equipment);

        // Prüfen, ob überfällig (älter als 1 Jahr)
        if (equipment.checkDate.isBefore(now.subtract(const Duration(days: 365)))) {
          _overdueCounts[equipment.fireStation] = (_overdueCounts[equipment.fireStation] ?? 0) + 1;
          _totalOverdue++;
        }

        // Zählung nach Status
        if (equipment.status == EquipmentStatus.cleaning) {
          _cleaningCounts[equipment.fireStation] = (_cleaningCounts[equipment.fireStation] ?? 0) + 1;
          _totalInCleaning++;
        } else if (equipment.status == EquipmentStatus.repair) {
          _repairCounts[equipment.fireStation] = (_repairCounts[equipment.fireStation] ?? 0) + 1;
          _totalInRepair++;
        }

        // Alter der Ausrüstung berechnen (in Tagen seit Erstellung)
        final ageInDays = now.difference(equipment.createdAt).inDays;
        totalAgeInDaysByStation[equipment.fireStation] =
            (totalAgeInDaysByStation[equipment.fireStation] ?? 0) + ageInDays;
        overallTotalAgeInDays += ageInDays;
      }

      // Durchschnittsalter berechnen
      for (var station in equipmentByStation.keys) {
        if (equipmentByStation[station]!.isNotEmpty) {
          _avgEquipmentAge[station] = totalAgeInDaysByStation[station]! /
              equipmentByStation[station]!.length / 365.25; // In Jahre umrechnen
        } else {
          _avgEquipmentAge[station] = 0;
        }
      }

      // Gesamt-Durchschnittsalter
      if (_totalEquipment > 0) {
        _overallAvgAge = overallTotalAgeInDays / _totalEquipment / 365.25; // In Jahre umrechnen
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Fehler beim Laden der Dashboard-Daten: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Gesamtkennzahlen anzeigen
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Übersicht',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMetricTile(
                      context,
                      icon: Icons.warning,
                      iconColor: Colors.red,
                      value: _totalOverdue.toString(),
                      label: 'Überfällige\nPrüfungen',
                    ),
                    _buildMetricTile(
                      context,
                      icon: Icons.local_laundry_service,
                      iconColor: Colors.blue,
                      value: _totalInCleaning.toString(),
                      label: 'In\nReinigung',
                    ),
                    _buildMetricTile(
                      context,
                      icon: Icons.build,
                      iconColor: Colors.orange,
                      value: _totalInRepair.toString(),
                      label: 'In\nReparatur',
                    ),
                    _buildMetricTile(
                      context,
                      icon: Icons.access_time,
                      iconColor: Colors.green,
                      value: _overallAvgAge.toStringAsFixed(1) + ' J',
                      label: 'Durchschn.\nAlter',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Detailkennzahlen nach Feuerwehr (nur für Admins)
        if (widget.isAdmin && _overdueCounts.isNotEmpty) ...[
          const Text(
            'Kennzahlen nach Feuerwehr',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Tabellenkopf
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          'Feuerwehr',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Überfällig',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Reinigung',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Reparatur',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Ø Alter',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  // Tabellendaten
                  ...List.generate(_overdueCounts.length, (index) {
                    final fireStation = _overdueCounts.keys.toList()[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(fireStation),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              '${_overdueCounts[fireStation] ?? 0}',
                              style: TextStyle(
                                color: (_overdueCounts[fireStation] ?? 0) > 0
                                    ? Colors.red
                                    : Colors.black87,
                                fontWeight: (_overdueCounts[fireStation] ?? 0) > 0
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              '${_cleaningCounts[fireStation] ?? 0}',
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              '${_repairCounts[fireStation] ?? 0}',
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              '${(_avgEquipmentAge[fireStation] ?? 0.0).toStringAsFixed(1)} J',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ] else ...[
          // Für normale Benutzer: Details für ihre eigene Feuerwehr
          const Text(
            'Kennzahlen deiner Feuerwehr',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.userFireStation,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(Icons.access_time,
                              color: Theme.of(context).colorScheme.secondary, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            'Ø Alter: ${(_avgEquipmentAge[widget.userFireStation] ?? 0.0).toStringAsFixed(1)} Jahre',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.secondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildDetailMetricColumn(
                        context,
                        icon: Icons.warning,
                        iconColor: Colors.red,
                        count: _overdueCounts[widget.userFireStation] ?? 0,
                        label: 'Überfällige\nPrüfungen',
                      ),
                      _buildDetailMetricColumn(
                        context,
                        icon: Icons.local_laundry_service,
                        iconColor: Colors.blue,
                        count: _cleaningCounts[widget.userFireStation] ?? 0,
                        label: 'In\nReinigung',
                      ),
                      _buildDetailMetricColumn(
                        context,
                        icon: Icons.build,
                        iconColor: Colors.orange,
                        count: _repairCounts[widget.userFireStation] ?? 0,
                        label: 'In\nReparatur',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMetricTile(
      BuildContext context, {
        required IconData icon,
        required Color iconColor,
        required String value,
        required String label,
      }) {
    return Column(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: iconColor.withOpacity(0.2),
          child: Icon(
            icon,
            color: iconColor,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.secondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDetailMetricColumn(
      BuildContext context, {
        required IconData icon,
        required Color iconColor,
        required int count,
        required String label,
      }) {
    return Column(
      children: [
        Icon(
          icon,
          color: iconColor,
          size: 36,
        ),
        const SizedBox(height: 8),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: count > 0 ? iconColor : Colors.black87,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.secondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}