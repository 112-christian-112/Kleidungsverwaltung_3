// screens/about_screen.dart
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({Key? key}) : super(key: key);

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  PackageInfo _packageInfo = PackageInfo(
    appName: 'Unbekannt',
    packageName: 'Unbekannt',
    version: 'Unbekannt',
    buildNumber: 'Unbekannt',
    buildSignature: 'Unbekannt',
  );

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
  }

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _packageInfo = info;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Über'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App-Logo und Name
            Center(
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.local_fire_department,
                      size: 60,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Einsatzkleidung',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Version ${_packageInfo.version} (${_packageInfo.buildNumber})',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // App-Beschreibung
            _buildSectionTitle(context, 'Über die App'),
            const SizedBox(height: 8),
            _buildCard(
              context,
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Diese App wurde für die Verwaltung von Einsatzkleidung der Feuerwehr entwickelt. Sie ermöglicht die Überwachung, Inspektion und Verfolgung von Feuerwehrausrüstung mit NFC-Tags.',
                    style: TextStyle(height: 1.5),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Hauptfunktionen:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  BulletPoint(
                    text: 'Verwaltung und Überwachung von Einsatzkleidung',
                  ),
                  BulletPoint(
                    text: 'NFC-basierte Identifikation von Ausrüstungsgegenständen',
                  ),
                  BulletPoint(
                    text: 'Prüfungsmanagement und Benachrichtigungen',
                  ),
                  BulletPoint(
                    text: 'Einsatzdokumentation und -zuweisung',
                  ),
                  BulletPoint(
                    text: 'Automatische Nachverfolgung von Reinigungszyklen',
                  ),
                  BulletPoint(
                    text: 'Analytische Dashboards für Administratoren',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Entwicklerinformationen
            _buildSectionTitle(context, 'Entwicklung'),
            const SizedBox(height: 8),
            _buildCard(
              context,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Diese App wurde entwickelt für:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Feuerwehr Gemeinde Westoverledingen',
                    style: TextStyle(height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Entwickelt von:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Christian Greve',
                    style: TextStyle(height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text(
                        'Kontakt: ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      GestureDetector(
                        onTap: () => _launchEmail('zeugwart.wol@gmail.com'),
                        child: Text(
                          'zeugwart.wol@gmail.com',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Technische Informationen
            _buildSectionTitle(context, 'Technische Informationen'),
            const SizedBox(height: 8),
            _buildCard(
              context,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Diese App wurde mit folgenden Technologien entwickelt:',
                    style: TextStyle(height: 1.5),
                  ),
                  const SizedBox(height: 8),
                  const BulletPoint(text: 'Flutter Framework'),
                  const BulletPoint(text: 'Firebase (Authentifizierung, Firestore, Cloud Functions)'),
                  const BulletPoint(text: 'NFC-Integration für Ausrüstungsidentifikation'),
                  const BulletPoint(text: 'Barcode-Scanning für alternative Identifikation'),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text(
                        'Dokumentation: ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      GestureDetector(
                        onTap: () => _launchUrl('https://example.com/docs'),
                        child: Text(
                          'Benutzerhandbuch',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Datenschutz und Impressum
            _buildSectionTitle(context, 'Rechtliches'),
            const SizedBox(height: 8),
            _buildCard(
              context,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => _launchUrl('https://example.com/privacy'),
                    child: Text(
                      'Datenschutzerklärung',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => _launchUrl('https://example.com/imprint'),
                    child: Text(
                      'Impressum',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => _launchUrl('https://example.com/license'),
                    child: Text(
                      'Lizenzinformationen',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            Center(
              child: Text(
                '© ${DateTime.now().year} Feuerwehr Gemeinde Westoverledingen',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // Hilfsmethoden
  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildCard(BuildContext context, {required Widget child}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: child,
      ),
    );
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Konnte die URL nicht öffnen'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _launchEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {
        'subject': 'Anfrage: Einsatzkleidung App',
      },
    );

    if (!await launchUrl(emailUri)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Konnte die E-Mail-App nicht öffnen'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class BulletPoint extends StatelessWidget {
  final String text;

  const BulletPoint({Key? key, required this.text}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}