// screens/dashboard/dashboard_widgets/equipment_stats_widget.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../models/equipment_model.dart';
import '../../../services/equipment_service.dart';

class EquipmentStatsWidget extends StatelessWidget {
  final bool isAdmin;
  final String userFireStation;

  const EquipmentStatsWidget({
    Key? key,
    required this.isAdmin,
    required this.userFireStation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final EquipmentService equipmentService = EquipmentService();

    return StreamBuilder<List<EquipmentModel>>(
      stream: isAdmin
          ? equipmentService.getAllEquipment()
          : equipmentService.getEquipmentByFireStation(userFireStation),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (snapshot.hasError) {
          return SizedBox(
            height: 200,
            child: Center(
              child: Text(
                'Fehler beim Laden der Daten: ${snapshot.error}',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          );
        }

        final equipmentList = snapshot.data ?? [];

        if (equipmentList.isEmpty) {
          return const SizedBox(
            height: 200,
            child: Center(
              child: Text('Keine Einsatzkleidung vorhanden'),
            ),
          );
        }

        // Statistiken berechnen
        final typeStats = _calculateTypeStats(equipmentList);
        final statusStats = _calculateStatusStats(equipmentList);
        final stationStats = isAdmin ? _calculateStationStats(equipmentList) : null;

        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: _buildStatCard(
                    context,
                    'Nach Typ',
                    _buildPieChart(typeStats, context),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: _buildStatCard(
                    context,
                    'Nach Status',
                    _buildPieChart(statusStats, context, isStatus: true),
                  ),
                ),
              ],
            ),
            if (isAdmin && stationStats != null) ...[
              const SizedBox(height: 16),
              _buildStatCard(
                context,
                'Nach Ortsfeuerwehr',
                SizedBox(
                  height: 200,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: stationStats.entries
                          .map((e) => e.value.toDouble())
                          .fold(0.0, (a, b) => a > b ? a : b) * 1.2,
                      barTouchData: BarTouchData(enabled: false),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              if (value < 0 || value >= stationStats.length) {
                                return const SizedBox.shrink();
                              }
                              final stations = stationStats.keys.toList();
                              final station = stations[value.toInt()];
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: RotatedBox(
                                  quarterTurns: 1,
                                  child: Text(
                                    station,
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (value, meta) {
                              if (value == 0) {
                                return const SizedBox.shrink();
                              }
                              return Text(
                                value.toInt().toString(),
                                style: const TextStyle(fontSize: 10),
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      barGroups: List.generate(
                        stationStats.length,
                            (index) {
                          final entry = stationStats.entries.elementAt(index);
                          return BarChartGroupData(
                            x: index,
                            barRods: [
                              BarChartRodData(
                                toY: entry.value.toDouble(),
                                color: Theme.of(context).colorScheme.primary,
                                width: 20,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(6),
                                  topRight: Radius.circular(6),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildStatCard(BuildContext context, String title, Widget content) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart(Map<String, int> data, BuildContext context, {bool isStatus = false}) {
    final totalItems = data.values.fold(0, (sum, item) => sum + item);
    final List<Color> colors = isStatus
        ? data.keys.map((key) => EquipmentStatus.getStatusColor(key)).toList()
        : [
      Theme.of(context).colorScheme.primary,
      Theme.of(context).colorScheme.secondary,
      Theme.of(context).colorScheme.tertiary,
      Colors.amber,
      Colors.purple,
    ];

    return SizedBox(
      height: 200,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 30,
                sections: List.generate(
                  data.length,
                      (index) {
                    final entry = data.entries.elementAt(index);
                    final percent = totalItems > 0
                        ? (entry.value / totalItems * 100).toStringAsFixed(1)
                        : '0.0';

                    return PieChartSectionData(
                      color: colors[index % colors.length],
                      value: entry.value.toDouble(),
                      title: '$percent%',
                      radius: 80,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(
                data.length,
                    (index) {
                  final entry = data.entries.elementAt(index);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          color: colors[index % colors.length],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${entry.key} (${entry.value})',
                            style: const TextStyle(fontSize: 10),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, int> _calculateTypeStats(List<EquipmentModel> equipment) {
    final stats = <String, int>{};

    for (final item in equipment) {
      stats[item.type] = (stats[item.type] ?? 0) + 1;
    }

    return stats;
  }

  Map<String, int> _calculateStatusStats(List<EquipmentModel> equipment) {
    final stats = <String, int>{};

    for (final item in equipment) {
      stats[item.status] = (stats[item.status] ?? 0) + 1;
    }

    return stats;
  }

  Map<String, int> _calculateStationStats(List<EquipmentModel> equipment) {
    final stats = <String, int>{};

    for (final item in equipment) {
      stats[item.fireStation] = (stats[item.fireStation] ?? 0) + 1;
    }

    return stats;
  }
}