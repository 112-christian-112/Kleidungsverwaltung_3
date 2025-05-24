// screens/dashboard/dashboard_widgets/inspection_calendar_widget.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../models/equipment_model.dart';
import '../../../services/equipment_service.dart';
import '../../admin/equipment/equipment_inspection_form_screen.dart';

class InspectionCalendarWidget extends StatefulWidget {
  final bool isAdmin;
  final String userFireStation;

  const InspectionCalendarWidget({
    Key? key,
    required this.isAdmin,
    required this.userFireStation,
  }) : super(key: key);

  @override
  State<InspectionCalendarWidget> createState() => _InspectionCalendarWidgetState();
}

class _InspectionCalendarWidgetState extends State<InspectionCalendarWidget> {
  final EquipmentService _equipmentService = EquipmentService();
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  Map<DateTime, List<EquipmentModel>> _inspectionEvents = {};

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    _loadInspectionEvents();
  }

  Future<void> _loadInspectionEvents() async {
    final now = DateTime.now();
    final threeMonthsLater = DateTime(now.year, now.month + 3, now.day);

    final stream = widget.isAdmin
        ? _equipmentService.getEquipmentByCheckDate(now, threeMonthsLater)
        : _equipmentService.getEquipmentByCheckDateAndFireStation(
        now, threeMonthsLater, widget.userFireStation);

    stream.listen((equipment) {
      final Map<DateTime, List<EquipmentModel>> events = {};

      for (final item in equipment) {
        // Normalisiertes Datum (ohne Uhrzeit)
        final normalizedDate = DateTime(
          item.checkDate.year,
          item.checkDate.month,
          item.checkDate.day,
        );

        if (events[normalizedDate] == null) {
          events[normalizedDate] = [];
        }

        events[normalizedDate]!.add(item);
      }

      if (mounted) {
        setState(() {
          _inspectionEvents = events;
        });
      }
    });
  }

  List<EquipmentModel> _getEventsForDay(DateTime day) {
    final normalizedDate = DateTime(day.year, day.month, day.day);
    return _inspectionEvents[normalizedDate] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TableCalendar(
              firstDay: DateTime.now().subtract(const Duration(days: 30)),
              lastDay: DateTime.now().add(const Duration(days: 365)),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDay, day);
              },
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              calendarFormat: _calendarFormat,
              onFormatChanged: (format) {
                setState(() {
                  _calendarFormat = format;
                });
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
              eventLoader: _getEventsForDay,
              calendarStyle: CalendarStyle(
                markerDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Prüfungen am ${DateFormat('dd.MM.yyyy').format(_selectedDay)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildEventList(),
          ],
        ),
      ),
    );
  }

  Widget _buildEventList() {
    final events = _getEventsForDay(_selectedDay);

    if (events.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: Text('Keine Prüfungen an diesem Tag'),
      );
    }

    return SizedBox(
      height: 150,
      child: ListView.builder(
        itemCount: events.length,
        itemBuilder: (context, index) {
          final equipment = events[index];
          final isOverdue = equipment.checkDate.isBefore(DateTime.now());

          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: isOverdue ? Colors.red : Theme.of(context).colorScheme.primary,
              child: Icon(
                equipment.type == 'Jacke'
                    ? Icons.accessibility_new
                    : Icons.airline_seat_legroom_normal,
                color: Colors.white,
              ),
            ),
            title: Text(
              equipment.article,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              'Besitzer: ${equipment.owner} | Station: ${equipment.fireStation}',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EquipmentInspectionFormScreen(
                      equipment: equipment,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                minimumSize: const Size(80, 30),
              ),
              child: const Text('Prüfen'),
            ),
            onTap: () {
              // Details anzeigen oder direkt zum Prüfungsformular navigieren
            },
          );
        },
      ),
    );
  }
}
