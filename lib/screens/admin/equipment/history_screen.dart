
// screens/admin/equipment/equipment_history_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/equipment_history_model.dart';
import '../../../models/equipment_model.dart';
import '../../../services/equipment_history_service.dart';

class EquipmentHistoryScreen extends StatelessWidget {
  final EquipmentModel equipment;

  const EquipmentHistoryScreen({
    Key? key,
    required this.equipment,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final EquipmentHistoryService _historyService = EquipmentHistoryService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Änderungsverlauf'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  equipment.article,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'NFC-Tag: ${equipment.nfcTag}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
                const SizedBox(height: 8),
                const Divider(),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Änderungsverlauf',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<EquipmentHistoryModel>>(
              stream: _historyService.getEquipmentHistory(equipment.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Fehler beim Laden des Verlaufs: ${snapshot.error}',
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  );
                }

                final historyEntries = snapshot.data ?? [];

                if (historyEntries.isEmpty) {
                  return const Center(
                    child: Text('Keine Änderungen gefunden.'),
                  );
                }

                return ListView.builder(
                  itemCount: historyEntries.length,
                  itemBuilder: (context, index) {
                    final entry = historyEntries[index];

                    // Icon und Farbe basierend auf der Aktion bestimmen
                    IconData actionIcon;
                    Color actionColor;

                    switch (entry.action) {
                      case HistoryAction.created:
                        actionIcon = Icons.add_circle;
                        actionColor = Colors.green;
                        break;
                      case HistoryAction.updated:
                        actionIcon = Icons.edit;
                        actionColor = Colors.blue;
                        break;
                      case HistoryAction.deleted:
                        actionIcon = Icons.delete;
                        actionColor = Colors.red;
                        break;
                      default:
                        actionIcon = Icons.info;
                        actionColor = Colors.grey;
                    }

                    // Datum formatieren
                    final formattedDate = DateFormat('dd.MM.yyyy HH:mm').format(entry.timestamp);

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: actionColor.withOpacity(0.2),
                          child: Icon(
                            actionIcon,
                            color: actionColor,
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                entry.field,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Text(
                              formattedDate,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (entry.action == HistoryAction.updated)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Vorher: ${_formatValue(entry.field, entry.oldValue)}'),
                                  Text('Nachher: ${_formatValue(entry.field, entry.newValue)}'),
                                ],
                              )
                            else if (entry.action == HistoryAction.created)
                              Text('Erstellt: ${_formatValue(entry.field, entry.newValue)}')
                            else if (entry.action == HistoryAction.deleted)
                                Text('Gelöscht: ${_formatValue(entry.field, entry.oldValue)}'),
                            const SizedBox(height: 4),
                            Text(
                              'Durchgeführt von: ${entry.performedByName}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Formatiert Werte basierend auf dem Feldtyp
  String _formatValue(String field, dynamic value) {
    if (value == null) return 'Nicht gesetzt';

    switch (field) {
      case 'Prüfdatum':
        try {
          // Versuche, das Datum zu parsen (ISO-Format)
          final date = DateTime.parse(value.toString());
          return DateFormat('dd.MM.yyyy').format(date);
        } catch (e) {
          return value.toString();
        }
      case 'Waschzyklen':
        return value.toString();
      case 'Status':
        return value.toString();
      default:
        return value.toString();
    }
  }
}