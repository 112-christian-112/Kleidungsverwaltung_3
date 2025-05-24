// screens/dashboard/dashboard_widgets/warnings_widget.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/equipment_model.dart';
import '../../../services/equipment_service.dart';

class WarningsWidget extends StatelessWidget {
  final bool isAdmin;
  final String userFireStation;

  const WarningsWidget({
    Key? key,
    required this.isAdmin,
    required this.userFireStation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final EquipmentService equipmentService = EquipmentService();
    final now = DateTime.now();

    return StreamBuilder<List<EquipmentModel>>(
      stream: isAdmin
          ? equipmentService.getAllEquipment()
          : equipmentService.getEquipmentByFireStation(userFireStation),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 100,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return SizedBox(
            height: 100,
            child: Center(
              child: Text(
                'Fehler beim Laden der Warnungen: ${snapshot.error}',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          );
        }

        final equipmentList = snapshot.data ?? [];

        // Warnungen berechnen
        final overdueInspections = equipmentList
            .where((item) => item.checkDate.isBefore(now))
            .toList()
          ..sort((a, b) => a.checkDate.compareTo(b.checkDate));

        final upcomingInspections = equipmentList
            .where((item) =>
        item.checkDate.isAfter(now) &&
            item.checkDate.isBefore(DateTime(now.year, now.month, now.day + 30)))
            .toList()
          ..sort((a, b) => a.checkDate.compareTo(b.checkDate));

        final nonReadyItems = equipmentList
            .where((item) => item.status != EquipmentStatus.ready)
            .toList();

        if (overdueInspections.isEmpty && upcomingInspections.isEmpty && nonReadyItems.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: Text('Keine Warnungen vorhanden'),
              ),
            ),
          );
        }

        return Column(
          children: [
            if (overdueInspections.isNotEmpty)
              _buildWarningCard(
                context,
                'Überfällige Prüfungen',
                'Die folgenden Artikel haben überfällige Prüfungen und sollten umgehend geprüft werden:',
                overdueInspections,
                Colors.red,
                Icons.warning,
              ),

            if (upcomingInspections.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildWarningCard(
                context,
                'Anstehende Prüfungen',
                'Die folgenden Artikel müssen in den nächsten 30 Tagen geprüft werden:',
                upcomingInspections,
                Colors.amber,
                Icons.event_note,
              ),
            ],

            if (nonReadyItems.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildWarningCard(
                context,
                'Nicht einsatzbereite Ausrüstung',
                'Die folgenden Artikel sind aktuell nicht einsatzbereit:',
                nonReadyItems,
                Colors.blue,
                Icons.handyman,
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildWarningCard(
      BuildContext context,
      String title,
      String subtitle,
      List<EquipmentModel> items,
      Color color,
      IconData icon,
      ) {
    return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Row(
              children: [
              Icon(icon, color: color),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          ],
        ),
        const SizedBox(height: 8),
        Text(subtitle),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length > 3 ? 3 : items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                item.article,
                style: const TextStyle(fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                title == 'Nicht einsatzbereite Ausrüstung'
                    ? 'Status: ${item.status} | Besitzer: ${item.owner}'
                    : 'Prüfdatum: ${DateFormat('dd.MM.yyyy').format(item.checkDate)} | Besitzer: ${item.owner}',
                style: const TextStyle(fontSize: 12),
              ),
              trailing: Icon(
                title == 'Überfällige Prüfungen'
                    ? Icons.priority_high
                    : (title == 'Anstehende Prüfungen' ? Icons.event : Icons.info),
                color: color,
              ),
            );
          },
        )

    ]
    )
    )
    );

  }
}