// widgets/navigation_drawer.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/admin/equipment/upcoming_inspections_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../services/auth_service.dart';
import '../screens/admin/equipment/equipment_list_screen.dart';

class AppNavigationDrawer extends StatefulWidget {
  const AppNavigationDrawer({Key? key}) : super(key: key);

  @override
  State<AppNavigationDrawer> createState() => _AppNavigationDrawerState();
}

class _AppNavigationDrawerState extends State<AppNavigationDrawer> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _userName = '';
  String _userRole = '';
  String _userFireStation = '';
  bool _isAdmin = false;
  bool _isLoading = true;

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
      User? user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();

        if (userDoc.exists) {
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

          setState(() {
            _userName = userData['name'] ?? '';
            _userRole = userData['role'] ?? '';
            _userFireStation = userData['fireStation'] ?? '';
            // Hier definieren wir, welche Rollen Admin-Rechte haben
            _isAdmin = _userRole == 'Gemeindebrandmeister' ||
                _userRole == 'Stv. Gemeindebrandmeister' ||
                _userRole == 'Gemeindezeugwart';
          });
        }
      }
    } catch (e) {
      print('Fehler beim Laden der Benutzerdaten: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = _auth.currentUser;
    final String userEmail = currentUser?.email ?? 'Nicht angemeldet';
    final String userInitial = _userName.isNotEmpty
        ? _userName[0].toUpperCase()
        : (userEmail.isNotEmpty ? userEmail[0].toUpperCase() : 'U');

    return Drawer(
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(_userName.isNotEmpty ? _userName : 'Benutzer'),
              accountEmail: Text(userEmail),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: Text(
                  userInitial,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              otherAccountsPictures: [
                if (_userFireStation.isNotEmpty)
                  Tooltip(
                    message: _userFireStation,
                    child: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      child: const Icon(
                        Icons.location_city,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                if (_userRole.isNotEmpty)
                  Tooltip(
                    message: _userRole,
                    child: CircleAvatar(
                      backgroundColor: _isAdmin
                          ? Colors.orange
                          : Theme.of(context).colorScheme.tertiary,
                      child: Icon(
                        _isAdmin ? Icons.admin_panel_settings : Icons.person,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/home');
              },
            ),
            // Einsatzkleidung für alle Benutzer
            ListTile(
              leading: const Icon(Icons.security),
              title: const Text('Einsatzkleidung'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EquipmentListScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.event_note),
              title: const Text('Anstehende Prüfungen'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UpcomingInspectionsScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.assignment),
              title: const Text('Einsätze'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/missions');
              },
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DashboardScreen(),
                  ),
                );
              },
            ),

            // Admin-Bereich nur für Administratoren anzeigen
            if (_isAdmin) ...[
              const Divider(),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Text(
                  'Administration',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.admin_panel_settings),
                title: const Text('Benutzer-Verwaltung'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/admin-users');
                },
              ),
            ],
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Einstellungen'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/settings');
              },
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('Über'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/about');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Abmelden'),
              onTap: () async {
                Navigator.pop(context);
                await AuthService().signOut();
                // Navigation erfolgt automatisch durch den StreamBuilder in main.dart
              },
            ),
          ],
        ),
      ),
    );
  }
}