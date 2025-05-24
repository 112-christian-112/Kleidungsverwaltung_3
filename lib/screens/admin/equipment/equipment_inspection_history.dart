// screens/admin/equipment/equipment_inspection_history_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/equipment_model.dart';
import '../../../models/equipment_inspection_model.dart';
import '../../../services/equipment_inspection_service.dart';
import 'equipment_inspection_form_screen.dart';

class EquipmentInspectionHistoryScreen extends StatefulWidget {
  final EquipmentModel equipment;

  const EquipmentInspectionHistoryScreen({
    Key? key,
    required this.equipment,
  }) : super(key: key);

  @override
  State<EquipmentInspectionHistoryScreen> createState() => _EquipmentInspectionHistoryScreenState();
}

class _EquipmentInspectionHistoryScreenState extends State<EquipmentInspectionHistoryScreen> {
  final EquipmentInspectionService _inspectionService = EquipmentInspectionService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prüfungshistorie'),
      ),
      body: Column(
        children: [
          // Übersicht
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
                          color: widget.equipment.type == 'Jacke'
                              ? Colors.blue
                              : Colors.amber,
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
                    Text(
                      'Nächste Prüfung: ${DateFormat('dd.MM.yyyy').format(widget.equipment.checkDate)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: widget.equipment.checkDate.isBefore(DateTime.now())
                            ? Colors.red
                            : Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Prüfungshistorie
          Expanded(
            child: StreamBuilder<List<EquipmentInspectionModel>>(
              stream: _inspectionService.getInspectionsForEquipment(widget.equipment.id),
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

                final inspections = snapshot.data ?? [];

                if (inspections.isEmpty) {
                  return const Center(
                    child: Text('Keine Prüfungen vorhanden'),
                  );
                }

                return ListView.builder(
                  itemCount: inspections.length,
                  itemBuilder: (context, index) {
                    final inspection = inspections[index];

                    // Farbe und Icon basierend auf dem Prüfergebnis
                    Color resultColor;
                    IconData resultIcon;

                    switch (inspection.result) {
                      case InspectionResult.passed:
                        resultColor = Colors.green;
                        resultIcon = Icons.check_circle;
                        break;
                      case InspectionResult.conditionalPass:
                        resultColor = Colors.orange;
                        resultIcon = Icons.warning;
                        break;
                      case InspectionResult.failed:
                        resultColor = Colors.red;
                        resultIcon = Icons.cancel;
                        break;
                    }

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor: resultColor.withOpacity(0.2),
                          child: Icon(
                            resultIcon,
                            color: resultColor,
                          ),
                        ),
                        title: Text(
                          'Prüfung am ${DateFormat('dd.MM.yyyy').format(inspection.inspectionDate)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          'Durchgeführt von: ${inspection.inspector}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(resultIcon, color: resultColor, size: 16),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Ergebnis: ${_getResultText(inspection.result)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: resultColor,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Nächste Prüfung: ${DateFormat('dd.MM.yyyy').format(inspection.nextInspectionDate)}',
                                ),

                                if (inspection.issues != null && inspection.issues!.isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Festgestellte Probleme:',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: inspection.issues!.map((issue) => Chip(
                                      label: Text(issue),
                                      backgroundColor: Colors.red.shade50,
                                    )).toList(),
                                  ),
                                ],

                                if (inspection.comments.isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Kommentare:',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(inspection.comments),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
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
              builder: (context) => EquipmentInspectionFormScreen(
                equipment: widget.equipment,
              ),
            ),
          );

          if (result == true && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Neue Prüfung wurde hinzugefügt'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
        tooltip: 'Neue Prüfung',
        child: const Icon(Icons.add),
      ),
    );
  }

  String _getResultText(InspectionResult result) {
    switch (result) {
      case InspectionResult.passed:
        return 'Bestanden';
      case InspectionResult.conditionalPass:
        return 'Bedingt bestanden';
      case InspectionResult.failed:
        return 'Durchgefallen';
    }
  }
}