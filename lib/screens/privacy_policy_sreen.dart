// screens/privacy_policy_screen.dart
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  String _appName = 'Einsatzkleidungsverwaltung';
  String _appVersion = '';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Datenschutzerklärung'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Datenschutzerklärung für $_appName',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Stand: ${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year}',
              style: const TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 24),

            _buildSection(
                'Einleitung',
                'Diese Datenschutzerklärung informiert Sie über die Art, den Umfang und Zweck der Verarbeitung von personenbezogenen Daten innerhalb unserer App $_appName (nachfolgend "App" genannt).'
            ),

            _buildSection(
                'Verantwortliche Stelle',
                '''
Verantwortlich für die Datenverarbeitung ist:

[Name der Feuerwehr / Organisation]
[Adresse]
[PLZ, Ort]
[Land]

E-Mail: [Kontakt-E-Mail]
Telefon: [Telefonnummer]
'''
            ),

            _buildSection(
                'Arten der verarbeiteten Daten',
                '''
- Bestandsdaten (z.B. Namen, Ortsfeuerwehrzugehörigkeit)
- Kontaktdaten (z.B. E-Mail, Telefonnummer)
- Inhaltsdaten (z.B. Texteingaben, Fotografien, NFC-Tag-IDs)
- Nutzungsdaten (z.B. Besuchte Seiten, Interesse an Inhalten)
- Meta-/Kommunikationsdaten (z.B. Geräte-Informationen, IP-Adressen)
'''
            ),

            _buildSection(
                'Kategorien betroffener Personen',
                '''
- Nutzerinnen und Nutzer der App (Mitglieder der Feuerwehr)
- Personen, deren Daten in der App erfasst werden (z.B. Besitzer von Einsatzkleidung)
'''
            ),

            _buildSection(
                'Zweck der Verarbeitung',
                '''
- Zurverfügungstellung der App, ihrer Funktionen und Inhalte
- Verwaltung von Einsatzkleidung und zugehörigen Informationen
- Dokumentation von Einsätzen und Prüfungen
- Sicherstellung der ordnungsgemäßen Nutzung der Einsatzkleidung
- Gewährleistung der Sicherheit der Feuerwehrmitglieder durch aktuellen Überblick über den Zustand der Einsatzkleidung
- Erfüllung gesetzlicher Verpflichtungen (z.B. Dokumentationspflichten)
'''
            ),

            _buildSection(
                'Verwendete Begrifflichkeiten',
                '''
"Personenbezogene Daten" sind alle Informationen, die sich auf eine identifizierte oder identifizierbare natürliche Person beziehen.

"Verarbeitung" ist jeder Vorgang im Zusammenhang mit personenbezogenen Daten, wie das Erheben, Erfassen, Organisieren, Ordnen, Speichern, Anpassen oder Verändern, Auslesen, Abfragen, Verwenden, Offenlegen, Verbreiten oder eine andere Form der Bereitstellung, den Abgleich oder die Verknüpfung, die Einschränkung, das Löschen oder die Vernichtung.

"Nutzer" sind alle Personen, die unsere App nutzen.
'''
            ),

            _buildSection(
                'Rechtsgrundlagen der Verarbeitung',
                '''
Die Verarbeitung der personenbezogenen Daten erfolgt auf Basis folgender Rechtsgrundlagen:

- Erfüllung eines Vertrages oder vorvertraglicher Maßnahmen (Art. 6 Abs. 1 lit. b DSGVO)
- Erfüllung einer rechtlichen Verpflichtung (Art. 6 Abs. 1 lit. c DSGVO)
- Wahrung berechtigter Interessen (Art. 6 Abs. 1 lit. f DSGVO)
- Einwilligung (Art. 6 Abs. 1 lit. a DSGVO)
'''
            ),

            _buildSection(
                'Sicherheitsmaßnahmen',
                '''
Wir treffen geeignete technische und organisatorische Maßnahmen, um ein dem Risiko angemessenes Schutzniveau zu gewährleisten:

- Passwortgeschützter Zugang zur App
- Verschlüsselung der Datenübertragung
- Zugangskontrolle und Zugriffsbeschränkungen
- Regelmäßige Datensicherungen
- Schulung der verantwortlichen Personen
'''
            ),

            _buildSection(
                'Firebase als Dienstleister',
                '''
Unsere App nutzt Dienste von Firebase, ein Angebot von Google LLC ("Google"). Firebase stellt uns verschiedene Funktionen bereit, insbesondere die Authentifizierung von Nutzern und die Speicherung von Daten.

Durch die Nutzung von Firebase werden bestimmte Daten an Google übertragen und dort verarbeitet. Die Datenschutzbestimmungen von Google/Firebase finden Sie unter: https://firebase.google.com/support/privacy

Firebase speichert und verarbeitet Daten weltweit in verschiedenen Rechenzentren. Wir haben mit Firebase Standardvertragsklauseln abgeschlossen, um einen angemessenen Schutz Ihrer Daten zu gewährleisten.
'''
            ),

            _buildSection(
                'Datenübermittlung',
                '''
Ihre Daten werden grundsätzlich nur innerhalb unserer Organisation verarbeitet und nicht an Dritte weitergegeben, es sei denn, dies ist für die Bereitstellung der App erforderlich oder wir sind gesetzlich dazu verpflichtet.

Ausnahmen:
- Firebase als technischer Dienstleister
- Übermittlung innerhalb der Feuerwehrorganisation gemäß dienstlicher Erfordernisse
'''
            ),

            _buildSection(
                'Dauer der Speicherung',
                '''
Wir speichern Ihre Daten nur so lange, wie es für die Zwecke erforderlich ist, für die sie erhoben wurden:

- Nutzerdaten: Für die Dauer der Mitgliedschaft in der Feuerwehr
- Einsatzkleidungsdaten: Gemäß den gesetzlichen Aufbewahrungsfristen (in der Regel 10 Jahre)
- Prüf- und Wartungsdaten: Gemäß den gesetzlichen Dokumentationspflichten
'''
            ),

            _buildSection(
                'Ihre Rechte',
                '''
Sie haben folgende Rechte bezüglich Ihrer Daten:

- Recht auf Auskunft (Art. 15 DSGVO)
- Recht auf Berichtigung (Art. 16 DSGVO)
- Recht auf Löschung (Art. 17 DSGVO)
- Recht auf Einschränkung der Verarbeitung (Art. 18 DSGVO)
- Recht auf Datenübertragbarkeit (Art. 20 DSGVO)
- Widerspruchsrecht (Art. 21 DSGVO)
- Recht auf Widerruf erteilter Einwilligungen (Art. 7 Abs. 3 DSGVO)
- Beschwerderecht bei der Aufsichtsbehörde (Art. 77 DSGVO)

Zur Ausübung Ihrer Rechte wenden Sie sich bitte an die oben genannte verantwortliche Stelle.
'''
            ),

            _buildSection(
                'Änderungen der Datenschutzerklärung',
                '''
Wir behalten uns vor, diese Datenschutzerklärung anzupassen, wenn sich die rechtlichen oder technischen Bedingungen ändern. 

Die aktuelle Version der Datenschutzerklärung ist jederzeit in der App unter Einstellungen > Datenschutzerklärung verfügbar.
'''
            ),

            _buildSection(
                'Kontakt',
                '''
Bei Fragen zum Datenschutz können Sie sich jederzeit an uns wenden:

[Name des Datenschutzbeauftragten / Verantwortlichen]
[Kontakt-E-Mail]
[Telefonnummer]
'''
            ),

            const SizedBox(height: 32),

            Text(
              'Version der App: $_appVersion',
              style: const TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}