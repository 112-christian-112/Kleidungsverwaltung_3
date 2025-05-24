
// screens/admin_user_approval_screen.dart
import 'package:flutter/material.dart';
import '../models/user_models.dart';
import '../services/auth_service.dart';
import '../widgets/navigation_drawer.dart';

class AdminUserApprovalScreen extends StatefulWidget {
  const AdminUserApprovalScreen({Key? key}) : super(key: key);

  @override
  State<AdminUserApprovalScreen> createState() => _AdminUserApprovalScreenState();
}

class _AdminUserApprovalScreenState extends State<AdminUserApprovalScreen> with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  late TabController _tabController;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Benutzer-Verwaltung'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Ausstehend'),
            Tab(text: 'Freigegebene'),
          ],
        ),
      ),
      drawer: const AppNavigationDrawer(),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUserList(false), // Ausstehende Benutzer
          _buildUserList(true),  // Freigegebene Benutzer
        ],
      ),
    );
  }

  Widget _buildUserList(bool isApproved) {
    return StreamBuilder<List<UserModel>>(
      stream: _authService.getAllUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Fehler beim Laden der Benutzer: ${snapshot.error}',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          );
        }

        final users = snapshot.data ?? [];
        final filteredUsers = users.where((user) =>
        user.isApproved == isApproved &&
            user.name.isNotEmpty &&
            user.role.isNotEmpty &&
            user.fireStation.isNotEmpty
        ).toList();

        if (filteredUsers.isEmpty) {
          return Center(
            child: Text(
              isApproved
                  ? 'Keine freigegebenen Benutzer vorhanden'
                  : 'Keine ausstehenden Benutzeranfragen',
              style: const TextStyle(fontSize: 16),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: filteredUsers.length,
          itemBuilder: (context, index) {
            final user = filteredUsers[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12.0),
              child: ExpansionTile(
                title: Text(user.name),
                subtitle: Text(user.email),
                leading: CircleAvatar(
                  backgroundColor: isApproved
                      ? Theme.of(context).colorScheme.primary
                      : Colors.amber,
                  child: Icon(
                    isApproved ? Icons.verified_user : Icons.hourglass_top,
                    color: Colors.white,
                  ),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow('Name', user.name),
                        _buildInfoRow('E-Mail', user.email),
                        _buildInfoRow('Rolle', user.role),
                        _buildInfoRow('Ortsfeuerwehr', user.fireStation),
                        _buildInfoRow('Registriert am',
                            '${user.createdAt.day}.${user.createdAt.month}.${user.createdAt.year}'),
                        if (user.approvedAt != null)
                          _buildInfoRow('Freigegeben am',
                              '${user.approvedAt!.day}.${user.approvedAt!.month}.${user.approvedAt!.year}'),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (!isApproved) ...[
                              ElevatedButton(
                                onPressed: _isProcessing
                                    ? null
                                    : () => _approveUser(user.uid),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Freigeben'),
                              ),
                              const SizedBox(width: 8),
                            ],
                            if (isApproved) ...[
                              ElevatedButton(
                                onPressed: _isProcessing
                                    ? null
                                    : () => _rejectUser(user.uid),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Zurückziehen'),
                              ),
                              const SizedBox(width: 8),
                            ],
                            ElevatedButton(
                              onPressed: _isProcessing
                                  ? null
                                  : () => _deleteUser(user.uid),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Löschen'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Future<void> _approveUser(String userId) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      await _authService.approveUser(userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Benutzer erfolgreich freigegeben')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _rejectUser(String userId) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      await _authService.rejectUser(userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Freigabe zurückgezogen')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _deleteUser(String userId) async {
    // Bestätigungsdialog anzeigen
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Benutzer löschen'),
        content: const Text(
            'Sind Sie sicher, dass Sie diesen Benutzer löschen möchten? Diese Aktion kann nicht rückgängig gemacht werden.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      await _authService.deleteUser(userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Benutzer erfolgreich gelöscht')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }
}
