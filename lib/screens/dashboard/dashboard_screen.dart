// screens/dashboard/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/permission_service.dart';

import 'dashboard_widgets/dashboard_metrics_widget.dart'; // Neue Komponente importieren
import 'dashboard_widgets/equipment_stats_widget.dart';
import 'dashboard_widgets/inspection_calender_widget.dart';
import 'dashboard_widgets/warnings_widget.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final PermissionService _permissionService = PermissionService();
  bool _isAdmin = false;
  bool _isLoading = true;
  String _userName = '';
  String _userFireStation = '';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final isAdmin = await _permissionService.isAdmin();
      final userFireStation = await _permissionService.getUserFireStation();

      // Hier könnten wir auch den Benutzernamen laden, wenn wir ihn benötigen

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
        title: const Text('Dashboard'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: () async {
          await _loadUserInfo();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                margin: const EdgeInsets.only(bottom: 16.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Willkommen' + (_userFireStation.isNotEmpty ? ' - $_userFireStation' : ''),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Heute ist ${DateFormat('EEEE, dd. MMMM yyyy', 'de_DE').format(DateTime.now())}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Neue Metriken-Widget einbinden
              DashboardMetricsWidget(
                isAdmin: _isAdmin,
                userFireStation: _userFireStation,
              ),

              const SizedBox(height: 24),

              // Bestehende Widgets
              const Text(
                'Warnungen & Benachrichtigungen',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              WarningsWidget(
                isAdmin: _isAdmin,
                userFireStation: _userFireStation,
              ),
              const SizedBox(height: 24),

              // Kalender mit anstehenden Prüfungen
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Anstehende Prüfungen',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/overdue-inspections');
                    },
                    child: const Text('Alle anzeigen'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              InspectionCalendarWidget(
                isAdmin: _isAdmin,
                userFireStation: _userFireStation,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}