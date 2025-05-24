
// 5. Übersichtsseite für anstehende Prüfungen
// screens/admin/equipment/upcoming_inspections_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/equipment_inspection_model.dart';
import '../../../models/equipment_model.dart';
import '../../../services/equipment_inspection_service.dart';
import '../../../services/equipment_service.dart';
import 'equipment_inspection_form_screen.dart';

class UpcomingInspectionsScreen extends StatefulWidget {
  const UpcomingInspectionsScreen({Key? key}) : super(key: key);

  @override
  State<UpcomingInspectionsScreen> createState() => _UpcomingInspectionsScreenState();
}

class _UpcomingInspectionsScreenState extends State<UpcomingInspectionsScreen> {
  final EquipmentService _equipmentService = EquipmentService();
  late final DateTime _today = DateTime.now();
  late final DateTime _oneMonthFromNow = _today.add(const Duration(days: 30));
  late final DateTime _threeMonthsFromNow = _today.add(const Duration(days: 90));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Anstehende Prüfungen'),
      ),
      body: StreamBuilder<List<EquipmentModel>>(
        stream: _equipmentService.getEquipmentByCheckDate(_today, _threeMonthsFromNow),
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

          final equipmentList = snapshot.data ?? [];

          if (equipmentList.isEmpty) {
            return const Center(
              child: Text('Keine anstehenden Prüfungen in den nächsten 3 Monaten'),
            );
          }

          // Nach Prüfdatum sortieren
          equipmentList.sort((a, b) => a.checkDate.compareTo(b.checkDate));

          // In Kategorien einteilen: überfällig, diesen Monat, nächste 3 Monate
          final overdue = equipmentList.where((e) => e.checkDate.isBefore(_today)).toList();
          final thisMonth = equipmentList.where((e) =>
          e.checkDate.isAfter(_today) && e.checkDate.isBefore(_oneMonthFromNow)).toList();
          final comingMonths = equipmentList.where((e) =>
          e.checkDate.isAfter(_oneMonthFromNow) && e.checkDate.isBefore(_threeMonthsFromNow)).toList();

          return ListView(
            children: [
              // Überfällige Prüfungen
              if (overdue.isNotEmpty) ...[
                const _SectionHeader(
                  title: 'Überfällige Prüfungen',
                  color: Colors.red,
                  icon: Icons.warning,
                ),
                ...overdue.map((equipment) => _buildEquipmentCard(equipment, isOverdue: true)),
              ],

              // Prüfungen diesen Monat
              if (thisMonth.isNotEmpty) ...[
                const _SectionHeader(
                  title: 'Prüfungen diesen Monat',
                  color: Colors.orange,
                  icon: Icons.event,
                ),
                ...thisMonth.map((equipment) => _buildEquipmentCard(equipment)),
              ],

              // Prüfungen in den nächsten 3 Monaten
              if (comingMonths.isNotEmpty) ...[
                const _SectionHeader(
                  title: 'Prüfungen in den nächsten 3 Monaten',
                  color: Colors.blue,
                  icon: Icons.event_available,
                ),
                ...comingMonths.map((equipment) => _buildEquipmentCard(equipment)),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildEquipmentCard(EquipmentModel equipment, {bool isOverdue = false}) {
    final daysDifference = equipment.checkDate.difference(_today).inDays;
    String timeDescription;
    Color timeColor;

    if (isOverdue) {
      timeDescription = 'Überfällig seit ${-daysDifference} Tagen';
      timeColor = Colors.red;
    } else if (daysDifference <= 30) {
      timeDescription = 'In $daysDifference Tagen';
      timeColor = Colors.orange;
    } else {
      timeDescription = 'In $daysDifference Tagen';
      timeColor = Colors.blue;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
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
        title: Text(
          equipment.article,
          style: const TextStyle(fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Besitzer: ${equipment.owner}'),
            Text(
              'Prüfdatum: ${DateFormat('dd.MM.yyyy').format(equipment.checkDate)}',
              style: TextStyle(color: timeColor, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        trailing: Text(
          timeDescription,
          style: TextStyle(
            color: timeColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EquipmentInspectionFormScreen(
                equipment: equipment,
              ),
            ),
          );
        },
      ),
    );
  }
}

// Hilfswiedget für Abschnittsüberschriften
class _SectionHeader extends StatelessWidget {
  final String title;
  final Color color;
  final IconData icon;

  const _SectionHeader({
    required this.title,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}