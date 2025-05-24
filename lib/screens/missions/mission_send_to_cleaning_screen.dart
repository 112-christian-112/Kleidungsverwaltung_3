// screens/missions/mission_send_to_cleaning_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/mission_model.dart';
import '../../models/equipment_model.dart';
import '../../services/mission_service.dart';
import '../../services/equipment_service.dart';

class MissionSendToCleaningScreen extends StatefulWidget {
  final String missionId;
  final String missionName;

  const MissionSendToCleaningScreen({
    Key? key,
    required this.missionId,
    required this.missionName,
  }) : super(key: key);

  @override
  State<MissionSendToCleaningScreen> createState() => _MissionSendToCleaningScreenState();
}

class _MissionSendToCleaningScreenState extends State<MissionSendToCleaningScreen> {
  final MissionService _missionService = MissionService();
  final EquipmentService _equipmentService = EquipmentService();

  bool _isLoading = true;
  bool _isProcessing = false;
  List<EquipmentModel> _equipmentList = [];
  List<EquipmentModel> _selectedEquipment = [];
  MissionModel? _mission;

  int _jacketCount = 0;
  int _pantsCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Einsatzdaten laden
      final mission = await _missionService.getMissionById(widget.missionId);
      if (mission == null) {
        throw Exception('Einsatz nicht gefunden');
      }

      // Ausrüstung für den Einsatz laden
      final equipmentList = await _missionService.getEquipmentForMission(widget.missionId);

      // Standardmäßig alle Kleidungsstücke auswählen, die noch nicht in der Reinigung sind
      final selectedEquipment = equipmentList
          .where((item) => item.status != EquipmentStatus.cleaning)
          .toList();

      // Zählen der Jacken und Hosen
      int jacketCount = 0;
      int pantsCount = 0;

      for (var item in selectedEquipment) {
        if (item.type == 'Jacke') {
          jacketCount++;
        } else if (item.type == 'Hose') {
          pantsCount++;
        }
      }

      if (mounted) {
        setState(() {
          _mission = mission;
          _equipmentList = equipmentList;
          _selectedEquipment = selectedEquipment;
          _jacketCount = jacketCount;
          _pantsCount = pantsCount;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Fehler beim Laden der Daten: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _toggleSelection(EquipmentModel equipment) {
    setState(() {
      if (_selectedEquipment.contains(equipment)) {
        _selectedEquipment.remove(equipment);
        if (equipment.type == 'Jacke') {
          _jacketCount--;
        } else if (equipment.type == 'Hose') {
          _pantsCount--;
        }
      } else {
        _selectedEquipment.add(equipment);
        if (equipment.type == 'Jacke') {
          _jacketCount++;
        } else if (equipment.type == 'Hose') {
          _pantsCount++;
        }
      }
    });
  }

  void _selectAll() {
    setState(() {
      _selectedEquipment = _equipmentList
          .where((item) => item.status != EquipmentStatus.cleaning)
          .toList();

      // Neu zählen
      _jacketCount = 0;
      _pantsCount = 0;

      for (var item in _selectedEquipment) {
        if (item.type == 'Jacke') {
          _jacketCount++;
        } else if (item.type == 'Hose') {
          _pantsCount++;
        }
      }
    });
  }

  void _deselectAll() {
    setState(() {
      _selectedEquipment = [];
      _jacketCount = 0;
      _pantsCount = 0;
    });
  }

  Future<void> _sendToCleaningAndGeneratePdf() async {
    if (_selectedEquipment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bitte wählen Sie mindestens ein Kleidungsstück aus'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Status aller ausgewählten Kleidungsstücke auf "In der Reinigung" setzen
      for (var equipment in _selectedEquipment) {
        await _equipmentService.updateStatus(equipment.id, EquipmentStatus.cleaning);
      }

      // PDF generieren
      final pdfFile = await _generatePdf();

      if (mounted) {
        setState(() {
          _isProcessing = false;
        });

        // PDF anzeigen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => _PdfPreviewScreen(
              pdfPath: pdfFile.path,
              mission: _mission!,
              jacketCount: _jacketCount,
              pantsCount: _pantsCount,
            ),
          ),
        );
      }
    } catch (e) {
      print('Fehler beim Senden zur Reinigung: $e');
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<File> _generatePdf() async {
    if (_mission == null) {
      throw Exception('Keine Einsatzdaten verfügbar');
    }

    // PDF Dokument erstellen
    final pdf = pw.Document();

    // Formatiertes Datum für den Einsatz
    final missionDateFormatted = DateFormat('dd.MM.yyyy').format(_mission!.startTime);
    final missionTimeFormatted = DateFormat('HH:mm').format(_mission!.startTime);

    // Formatiertes aktuelles Datum für den PDF-Titel
    final now = DateTime.now();
    final currentDateFormatted = DateFormat('dd.MM.yyyy').format(now);

    // Icon für den Einsatztyp
    String missionTypeText;
    switch (_mission!.type) {
      case 'fire':
        missionTypeText = 'Brandeinsatz';
        break;
      case 'technical':
        missionTypeText = 'Technische Hilfeleistung';
        break;
      case 'hazmat':
        missionTypeText = 'Gefahrguteinsatz';
        break;
      case 'water':
        missionTypeText = 'Wasser/Hochwasser';
        break;
      case 'training':
        missionTypeText = 'Übung';
        break;
      default:
        missionTypeText = 'Sonstiger Einsatz';
        break;
    }

    // PDF-Inhalt
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Titel
              pw.Center(
                child: pw.Text(
                  'Wäschereischein',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Center(
                child: pw.Text(
                  'Feuerwehr ${_mission!.fireStation}',
                  style: pw.TextStyle(
                    fontSize: 18,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),

              // Einsatzdetails
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Einsatzdetails:',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Row(
                      children: [
                        pw.SizedBox(
                          width: 120,
                          child: pw.Text('Einsatzname:'),
                        ),
                        pw.Expanded(
                          child: pw.Text(
                            _mission!.name,
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 5),
                    pw.Row(
                      children: [
                        pw.SizedBox(
                          width: 120,
                          child: pw.Text('Einsatztyp:'),
                        ),
                        pw.Expanded(
                          child: pw.Text(missionTypeText),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 5),
                    pw.Row(
                      children: [
                        pw.SizedBox(
                          width: 120,
                          child: pw.Text('Datum:'),
                        ),
                        pw.Expanded(
                          child: pw.Text(missionDateFormatted),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 5),
                    pw.Row(
                      children: [
                        pw.SizedBox(
                          width: 120,
                          child: pw.Text('Uhrzeit:'),
                        ),
                        pw.Expanded(
                          child: pw.Text('$missionTimeFormatted Uhr'),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 5),
                    pw.Row(
                      children: [
                        pw.SizedBox(
                          width: 120,
                          child: pw.Text('Ort:'),
                        ),
                        pw.Expanded(
                          child: pw.Text(_mission!.location),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Zusammenfassung der Kleidungsstücke
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Zusammenfassung:',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Row(
                      children: [
                        pw.Expanded(
                          child: pw.Text(
                            'Anzahl Jacken:',
                            style: pw.TextStyle(fontSize: 14),
                          ),
                        ),
                        pw.Text(
                          '$_jacketCount',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 5),
                    pw.Row(
                      children: [
                        pw.Expanded(
                          child: pw.Text(
                            'Anzahl Hosen:',
                            style: pw.TextStyle(fontSize: 14),
                          ),
                        ),
                        pw.Text(
                          '$_pantsCount',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 5),
                    pw.Row(
                      children: [
                        pw.Expanded(
                          child: pw.Text(
                            'Gesamtzahl:',
                            style: pw.TextStyle(fontSize: 14),
                          ),
                        ),
                        pw.Text(
                          '${_jacketCount + _pantsCount}',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Detaillierte Liste der Kleidungsstücke
              pw.Text(
                'Detaillierte Liste:',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),

              // Tabelle mit den Kleidungsstücken
              pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: const pw.FlexColumnWidth(1),
                  1: const pw.FlexColumnWidth(3),
                  2: const pw.FlexColumnWidth(1),
                  3: const pw.FlexColumnWidth(2),
                },
                children: [
                  // Tabellenkopf
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          'Typ',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          'Artikel',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          'Größe',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          'Besitzer',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                    ],
                  ),

                  // Tabellenzeilen für jedes Kleidungsstück
                  ..._selectedEquipment.map((equipment) {
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(equipment.type),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(equipment.article),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(equipment.size),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(equipment.owner),
                        ),
                      ],
                    );
                  }).toList(),
                ],
              ),

              pw.SizedBox(height: 40),

              // Unterschriftszeile
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Container(
                        width: 200,
                        height: 1,
                        color: PdfColors.black,
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text('Datum, Unterschrift (Übergabe)'),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Container(
                        width: 200,
                        height: 1,
                        color: PdfColors.black,
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text('Datum, Unterschrift (Annahme)'),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 40),

              // Fußzeile
              pw.Center(
                child: pw.Text(
                  'Generiert am $currentDateFormatted',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey700,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    // Temporäres Verzeichnis für die PDF-Datei
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/reinigung_${DateFormat('yyyyMMdd_HHmmss').format(now)}.pdf');

    // PDF-Datei speichern
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('In die Reinigung senden'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('In die Reinigung senden'),
        actions: [
          // Auswahloptionen
          IconButton(
            icon: const Icon(Icons.select_all),
            onPressed: _selectAll,
            tooltip: 'Alle auswählen',
          ),
          IconButton(
            icon: const Icon(Icons.deselect),
            onPressed: _deselectAll,
            tooltip: 'Alle abwählen',
          ),
        ],
      ),
      body: Column(
        children: [
          // Zusammenfassung der Einsatzinformationen
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Einsatz: ${_mission?.name ?? widget.missionName}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_mission != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Datum: ${DateFormat('dd.MM.yyyy').format(_mission!.startTime)}',
                    ),
                    Text(
                      'Ort: ${_mission!.location}',
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Zusammenfassung der ausgewählten Gegenstände
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Text(
                        'Jacken',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$_jacketCount',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      const Text(
                        'Hosen',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$_pantsCount',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      const Text(
                        'Gesamt',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_jacketCount + _pantsCount}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Überschrift für die Liste
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Ausrüstung zur Reinigung',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_selectedEquipment.length} von ${_equipmentList.length} ausgewählt',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ),

          // Liste der Ausrüstungsgegenstände
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _equipmentList.length,
              itemBuilder: (context, index) {
                final equipment = _equipmentList[index];
                final isSelected = _selectedEquipment.contains(equipment);
                final isInCleaning = equipment.status == EquipmentStatus.cleaning;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: CheckboxListTile(
                    title: Text(
                      equipment.article,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isInCleaning ? Colors.grey : null,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Besitzer: ${equipment.owner} | Größe: ${equipment.size}'),
                        if (isInCleaning)
                          Row(
                            children: [
                              Icon(
                                Icons.info,
                                size: 16,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Bereits in der Reinigung',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.secondary,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    value: isSelected,
                    onChanged: isInCleaning
                        ? null
                        : (value) {
                      if (value != null) {
                        _toggleSelection(equipment);
                      }
                    },
                    secondary: CircleAvatar(
                      backgroundColor: equipment.type == 'Jacke' ? Colors.blue : Colors.amber,
                      child: Icon(
                        equipment.type == 'Jacke'
                            ? Icons.accessibility_new
                            : Icons.airline_seat_legroom_normal,
                        color: Colors.white,
                      ),
                    ),
                    activeColor: Theme.of(context).colorScheme.primary,
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: _isProcessing
              ? null
              : _sendToCleaningAndGeneratePdf,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: _isProcessing
              ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : const Text(
            'In die Reinigung senden und PDF erstellen',
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}

// Bildschirm zur Vorschau und zum Teilen des PDFs
class _PdfPreviewScreen extends StatelessWidget {
  final String pdfPath;
  final MissionModel mission;
  final int jacketCount;
  final int pantsCount;

  const _PdfPreviewScreen({
    required this.pdfPath,
    required this.mission,
    required this.jacketCount,
    required this.pantsCount,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reinigungsschein'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              _sharePdf();
            },
            tooltip: 'Teilen',
          ),
        ],
      ),
      body: Column(
        children: [
          // Zusammenfassung
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Zusammenfassung',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow('Einsatz:', mission.name),
                  _buildInfoRow('Datum:', DateFormat('dd.MM.yyyy').format(mission.startTime)),
                  _buildInfoRow('Jacken:', '$jacketCount'),
                  _buildInfoRow('Hosen:', '$pantsCount'),
                  _buildInfoRow('Gesamt:', '${jacketCount + pantsCount}'),
                ],
              ),
            ),
          ),

          // PDF-Vorschau
          Expanded(
            child: PdfPreview(
              build: (format) => File(pdfPath).readAsBytesSync(),
              allowPrinting: true,
              allowSharing: true,
              initialPageFormat: PdfPageFormat.a4,
              pdfFileName: 'reinigung_${DateFormat('yyyyMMdd').format(mission.startTime)}.pdf',
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Printing.layoutPdf(
                    onLayout: (format) => File(pdfPath).readAsBytesSync(),
                    name: 'Reinigungsschein für ${mission.name}',
                  );
                },
                icon: const Icon(Icons.print),
                label: const Text('Drucken'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.popUntil(
                    context,
                        (route) => route.isFirst || route.settings.name == '/missions',
                  );
                },
                icon: const Icon(Icons.check),
                label: const Text('Fertig'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sharePdf() async {
    await Share.shareXFiles(
      [XFile(pdfPath)],
      text: 'Reinigungsschein für ${mission.name} vom ${DateFormat('dd.MM.yyyy').format(mission.startTime)}',
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
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
}