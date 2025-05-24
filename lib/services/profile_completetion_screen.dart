// screens/profile_completion_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class ProfileCompletionScreen extends StatefulWidget {
  const ProfileCompletionScreen({Key? key}) : super(key: key);

  @override
  State<ProfileCompletionScreen> createState() => _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState extends State<ProfileCompletionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  String _selectedRole = '';
  String _selectedFireStation = '';
  bool _isLoading = false;

  final List<String> _roles = [
    'Ortszeugwart',
    'Ortsbrandmeister',
    'Stv. Ortsbrandmeister',
    'Gemeindebrandmeister',
    'Stv. Gemeindebrandmeister',
    'Wäscherei',
    'Gemeindezeugwart'
  ];

  final List<String> _fireStations = [
    'Esklum',
    'Breinermoor',
    'Grotegaste',
    'Flachsmeer',
    'Folmhusen',
    'Großwolde',
    'Ihrhove',
    'Steenfelde',
    'Völlen',
    'Völlenerfehn',
    'Völlenerkönigsfehn'
  ];

  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _selectedRole = _roles.first;
    _selectedFireStation = _fireStations.first;
  }

  Future<void> _completeProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        User? currentUser = _authService.currentUser;

        if (currentUser != null) {
          await _authService.updateUserProfile(
              currentUser.uid,
              _nameController.text.trim(),
              _selectedRole,
              _selectedFireStation
          );

          if (mounted) {
            // Zeige Dialog mit Erfolgsmeldung
            await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Profil erfolgreich vervollständigt'),
                  content: const Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ihr Profil wurde erfolgreich vervollständigt.',
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Bitte warten Sie auf die Freigabe durch einen Administrator. Sie erhalten eine Benachrichtigung, sobald Ihr Konto freigeschaltet wurde.',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('Verstanden'),
                    ),
                  ],
                );
              },
            );

            Navigator.pushReplacementNamed(context, '/pending-approval');
          }
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
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil vervollständigen'),
        automaticallyImplyLeading: false, // Zurück-Button entfernen
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Bitte vervollständigen Sie Ihr Profil',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Angemeldet als: ${FirebaseAuth.instance.currentUser?.email ?? ""}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Bitte geben Sie Ihren Namen ein';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Rolle',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.work),
                  ),
                  value: _selectedRole,
                  items: _roles.map((String role) {
                    return DropdownMenuItem<String>(
                      value: role,
                      child: Text(role),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedRole = newValue;
                      });
                    }
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Bitte wählen Sie Ihre Rolle aus';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Ortsfeuerwehr',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_city),
                  ),
                  value: _selectedFireStation,
                  items: _fireStations.map((String station) {
                    return DropdownMenuItem<String>(
                      value: station,
                      child: Text(station),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedFireStation = newValue;
                      });
                    }
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Bitte wählen Sie Ihre Ortsfeuerwehr aus';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : _completeProfile,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text(
                    'Profil speichern',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () async {
                    await _authService.signOut();
                  },
                  child: const Text('Abmelden'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}