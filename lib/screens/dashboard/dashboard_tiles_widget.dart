// widgets/dashboard_tiles_widget.dart
import 'package:flutter/material.dart';

class DashboardTilesWidget extends StatelessWidget {
  final bool isAdmin;
  final String userFireStation;

  const DashboardTilesWidget({
    Key? key,
    required this.isAdmin,
    required this.userFireStation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        // Einsatzkleidung suchen/scannen
        _buildDashboardTile(
          context,
          title: 'Ausrüstung suchen',
          icon: Icons.search,
          color: Colors.blue,
          onTap: () {
            Navigator.pushNamed(context, '/admin-equipment');
          },
        ),

        // Neue Prüfung durchführen
        _buildDashboardTile(
          context,
          title: 'Neue Prüfung',
          icon: Icons.check_circle_outline,
          color: Colors.green,
          onTap: () {
            // Hier zur NFC/Barcode-Scan-Seite navigieren, um Ausrüstung für Prüfung zu identifizieren
            Navigator.pushNamed(context, '/equipment-scan');
          },
        ),

        // Überfällige Prüfungen anzeigen
        _buildDashboardTile(
          context,
          title: 'Überfällige Prüfungen',
          icon: Icons.warning_amber_rounded,
          color: Colors.orange,
          onTap: () {
            Navigator.pushNamed(context, '/overdue-inspections');
          },
        ),

        // Statusübersicht der Ausrüstung
        _buildDashboardTile(
          context,
          title: 'Statusübersicht',
          icon: Icons.pie_chart,
          color: Colors.purple,
          onTap: () {
            Navigator.pushNamed(context, '/equipment-status');
          },
        ),
      ],
    );
  }

  Widget _buildDashboardTile(
      BuildContext context, {
        required String title,
        required IconData icon,
        required Color color,
        required VoidCallback onTap,
      }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: color,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}