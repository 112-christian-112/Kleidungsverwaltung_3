// screens/help_support_screen.dart
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({Key? key}) : super(key: key);

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  String _appName = 'Einsatzkleidungsverwaltung';
  String _appVersion = '';
  String _emailSupport = 'zeugwart.wol@gmail.com';
  String _phoneSupport = '+49 15126130476';

  final List<Map<String, dynamic>> _faqItems = [
    {
      'question': 'Wie scanne ich einen NFC-Tag?',
      'answer': 'Halte dein Smartphone mit aktiviertem NFC an den NFC-Tag der Einsatzkleidung. Die App sollte den Tag automatisch erkennen. Stelle sicher, dass NFC in den Geräteeinstellungen aktiviert ist. Bei Problemen, versuche das Gerät etwas zu bewegen, um den optimalen Erkennungsbereich zu finden.'
    },
    {
      'question': 'Wie ändere ich den Status einer Einsatzkleidung?',
      'answer': 'Du kannst den Status einer Einsatzkleidung auf mehrere Arten ändern:\n\n1. Scanne den NFC-Tag oder Barcode der Einsatzkleidung und tippe dann auf "Status ändern".\n\n2. Gehe zur Einsatzkleidungsliste, suche den gewünschten Artikel und tippe ihn an. Auf der Detailseite kannst du dann den Status ändern.\n\n3. Wähle in der Liste mehrere Artikel aus (lange auf einen Artikel tippen zum Aktivieren der Mehrfachauswahl) und ändere dann den Status für alle ausgewählten Artikel gleichzeitig.'
    },
    {
      'question': 'Wie führe ich eine Prüfung durch?',
      'answer': 'Um eine Prüfung durchzuführen:\n\n1. Scanne den NFC-Tag oder Barcode der zu prüfenden Einsatzkleidung.\n\n2. Tippe auf "Prüfung durchführen".\n\n3. Fülle das Prüfformular aus, indem du das Prüfergebnis, eventuelle Mängel und Kommentare einträgst.\n\n4. Wähle das Datum für die nächste Prüfung.\n\n5. Speichere die Prüfung durch Tippen auf "Prüfung speichern".\n\nDie Prüfhistorie kannst du jederzeit auf der Detailseite der Einsatzkleidung einsehen.'
    },
    {
      'question': 'Wie füge ich eine neue Einsatzkleidung hinzu?',
      'answer': 'Zum Hinzufügen einer neuen Einsatzkleidung:\n\n1. Tippe auf der Hauptseite auf den Plus-Button oder gehe zu "Einsatzkleidung verwalten" und tippe dort auf das Plus-Symbol.\n\n2. Scanne den NFC-Tag und optional den Barcode der neuen Einsatzkleidung.\n\n3. Fülle alle erforderlichen Felder aus (Artikel, Typ, Größe, Besitzer usw.).\n\n4. Speichere die neue Einsatzkleidung durch Tippen auf "Einsatzkleidung anlegen".\n\nHinweis: Je nach deiner Rolle benötigst du möglicherweise Administrator-Rechte, um neue Einsatzkleidung anzulegen.'
    },
    {
      'question': 'Wie registriere ich einen Einsatz?',
      'answer': 'Um einen neuen Einsatz zu registrieren:\n\n1. Gehe zum Menüpunkt "Einsätze" und tippe auf das Plus-Symbol.\n\n2. Fülle die Einsatzinformationen aus (Name, Typ, Ort, Zeitpunkt, Beschreibung).\n\n3. Wähle die beteiligten Ortswehren aus.\n\n4. Füge die verwendete Einsatzkleidung hinzu, indem du auf "Auswählen" tippst und dann entweder aus der Liste auswählst oder die NFC-Tags scannst.\n\n5. Speichere den Einsatz durch Tippen auf "Einsatz speichern".\n\nNach einem Einsatz kannst du bei Bedarf den Status der verwendeten Einsatzkleidung auf "In der Reinigung" ändern.'
    },
    {
      'question': 'Was bedeuten die verschiedenen Status?',
      'answer': 'Die App verwendet folgende Status für die Einsatzkleidung:\n\n- Einsatzbereit: Die Kleidung ist geprüft und kann eingesetzt werden.\n\n- In der Reinigung: Die Kleidung befindet sich aktuell in der Reinigung.\n\n- In Reparatur: Die Kleidung wird derzeit repariert.\n\n- Ausgemustert: Die Kleidung ist nicht mehr im Einsatz.\n\nDer Status wird durch verschiedene Farben und Symbole in der App visualisiert.'
    },
    {
      'question': 'Wie ändere ich mein Passwort?',
      'answer': 'Um dein Passwort zu ändern:\n\n1. Gehe zu "Einstellungen".\n\n2. Tippe auf "Passwort ändern".\n\n3. Gib dein aktuelles Passwort ein.\n\n4. Gib dein neues Passwort zweimal ein.\n\n5. Tippe auf "Passwort ändern".\n\nAus Sicherheitsgründen solltest du ein starkes Passwort verwenden, das Groß- und Kleinbuchstaben, Zahlen und Sonderzeichen enthält.'
    },
    {
      'question': 'Wie erstelle ich einen Reinigungsschein?',
      'answer': 'Nach einem Einsatz kannst du einen Reinigungsschein erstellen:\n\n1. Gehe zum entsprechenden Einsatz und öffne dessen Details.\n\n2. Tippe auf "In die Reinigung senden".\n\n3. Wähle die Einsatzkleidung aus, die gereinigt werden soll.\n\n4. Tippe auf "In die Reinigung senden und PDF erstellen".\n\n5. Das generierte PDF kann anschließend geteilt, gespeichert oder ausgedruckt werden.\n\nDie ausgewählte Einsatzkleidung wird automatisch auf den Status "In der Reinigung" gesetzt.'
    }
  ];

  @override
  void initState() {
    super.initState();
    _loadAppInfo();
  }

  Future<void> _loadAppInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appName = packageInfo.appName;
        _appVersion = packageInfo.version;
      });
    } catch (e) {
      // Fehler beim Abrufen der App-Informationen
    }
  }

  Future<void> _sendSupportEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: _emailSupport,
      query: 'subject=Support Anfrage: $_appName&body=App-Version: $_appVersion\n\nBeschreibung des Problems:\n\n',
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      // E-Mail konnte nicht geöffnet werden
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('E-Mail-App konnte nicht geöffnet werden.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _callSupport() async {
    final Uri phoneUri = Uri(
      scheme: 'tel',
      path: _phoneSupport.replaceAll(' ', ''),
    );

    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      // Telefon konnte nicht geöffnet werden
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Telefon-App konnte nicht geöffnet werden.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hilfe & Support'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hilfe-Header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.help_outline,
                          size: 32,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hilfe & Support für $_appName',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Version: $_appVersion',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.secondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Hier findest du Antworten auf häufig gestellte Fragen und kannst bei Problemen mit der App Kontakt mit unserem Support-Team aufnehmen.',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Kontakt-Optionen
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Kontakt',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.blue,
                        child: Icon(Icons.email, color: Colors.white),
                      ),
                      title: const Text('Support per E-Mail'),
                      subtitle: Text(_emailSupport),
                      onTap: _sendSupportEmail,
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.green,
                        child: Icon(Icons.phone, color: Colors.white),
                      ),
                      title: const Text('Telefonischer Support'),
                      subtitle: Text(_phoneSupport),
                      onTap: _callSupport,
                    ),
                    if (user != null) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      Text(
                        'Deine Account-Informationen:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('E-Mail: ${user.email}'),
                      Text('Account-ID: ${user.uid}'),
                      const SizedBox(height: 8),
                      const Text(
                        'Bitte gib diese Informationen an, wenn du den Support kontaktierst.',
                        style: TextStyle(fontStyle: FontStyle.italic),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Video-Tutorials
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Video-Tutorials',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTutorialItem(
                      'Erste Schritte mit der App',
                      'Grundlegende Einführung in die Funktionen der App',
                      Icons.play_circle_outline,
                      Colors.blue,
                    ),
                    _buildTutorialItem(
                      'NFC-Tags scannen',
                      'So scannst du NFC-Tags korrekt',
                      Icons.nfc,
                      Colors.orange,
                    ),
                    _buildTutorialItem(
                      'Prüfungen durchführen',
                      'Schritt-für-Schritt Anleitung zu Prüfungen',
                      Icons.check_circle_outline,
                      Colors.green,
                    ),
                    _buildTutorialItem(
                      'Einsätze dokumentieren',
                      'Einsätze richtig erfassen und dokumentieren',
                      Icons.assignment,
                      Colors.purple,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // FAQ-Sektion
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Häufig gestellte Fragen (FAQ)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _faqItems.length,
                      itemBuilder: (context, index) {
                        return _buildFaqItem(_faqItems[index]['question'], _faqItems[index]['answer']);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Fehlerbehebung
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Fehlerbehebung',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTroubleshootingItem(
                      'NFC funktioniert nicht',
                      '''
1. Stelle sicher, dass NFC in den Geräteeinstellungen aktiviert ist.
2. Halte das Gerät näher an den NFC-Tag.
3. Bewege das Gerät langsam über den Tag.
4. Versuche, den Tag an verschiedenen Stellen des Geräts zu halten.
5. Überprüfe, ob der Tag beschädigt ist.
6. Starte die App neu und versuche es erneut.''',
                    ),
                    _buildTroubleshootingItem(
                      'App stürzt ab oder reagiert nicht',
                      '''
1. Starte die App neu.
2. Prüfe, ob Updates für die App verfügbar sind.
3. Starte dein Gerät neu.
4. Stelle sicher, dass dein Gerät genügend freien Speicherplatz hat.
5. Überprüfe deine Internetverbindung.
6. Wenn das Problem weiterhin besteht, kontaktiere den Support.''',
                    ),
                    _buildTroubleshootingItem(
                      'Anmeldung funktioniert nicht',
                      '''
1. Überprüfe deine E-Mail-Adresse und dein Passwort.
2. Stelle sicher, dass du eine aktive Internetverbindung hast.
3. Prüfe, ob dein Konto bereits freigeschaltet wurde.
4. Falls du dein Passwort vergessen hast, nutze die "Passwort vergessen" Funktion.
5. Kontaktiere einen Administrator, wenn dein Konto noch nicht freigegeben wurde.''',
                    ),
                    _buildTroubleshootingItem(
                      'Daten werden nicht aktualisiert',
                      '''
1. Überprüfe deine Internetverbindung.
2. Ziehe die Liste nach unten, um sie manuell zu aktualisieren.
3. Starte die App neu.
4. Prüfe, ob du die erforderlichen Berechtigungen für die Daten hast.
5. Wenn das Problem weiterhin besteht, kontaktiere den Support.''',
                    ),
                  ],
                ),
              ),
            ),

            // Feedback-Bereich
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Feedback geben',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Wir freuen uns über dein Feedback zur App. Deine Meinung hilft uns, die App kontinuierlich zu verbessern.',
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Hier zur Feedback-Seite navigieren oder Dialog öffnen
                        _showFeedbackDialog(context);
                      },
                      icon: const Icon(Icons.feedback),
                      label: const Text('Feedback geben'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTutorialItem(String title, String description, IconData icon, Color color) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.2),
        child: Icon(icon, color: color),
      ),
      title: Text(title),
      subtitle: Text(description),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {
        // Hier zum Video-Tutorial navigieren
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Video wird geladen...'),
          ),
        );
      },
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return ExpansionTile(
      title: Text(
        question,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(answer),
        ),
      ],
    );
  }

  Widget _buildTroubleshootingItem(String problem, String solution) {
    return ExpansionTile(
      leading: const Icon(Icons.error_outline, color: Colors.red),
      title: Text(
        problem,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(solution),
        ),
      ],
    );
  }

  void _showFeedbackDialog(BuildContext context) {
    final TextEditingController _feedbackController = TextEditingController();
    int _rating = 3;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Feedback geben'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Wie bewertest du die App?'),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < _rating ? Icons.star : Icons.star_border,
                      color: index < _rating ? Colors.amber : Colors.grey,
                      size: 32,
                    ),
                    onPressed: () {
                      // setState in Dialog funktioniert nur mit StatefulBuilder
                      (context as Element).markNeedsBuild();
                      _rating = index + 1;
                    },
                  );
                }),
              ),
              const SizedBox(height: 16),
              const Text('Dein Feedback:'),
              const SizedBox(height: 8),
              TextField(
                controller: _feedbackController,
                decoration: const InputDecoration(
                  hintText: 'Was gefällt dir, was können wir verbessern?',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () {
              // Hier das Feedback senden
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Vielen Dank für dein Feedback!'),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.pop(context);
            },
            child: const Text('Senden'),
          ),
        ],
      ),
    );
  }
}