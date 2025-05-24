// screens/missions/add_equipment_to_mission_nfc_screen.dart
import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import '../../models/equipment_model.dart';
import '../../services/equipment_service.dart';
import '../../services/mission_service.dart';
import '../../services/nfc_service.dart';

class AddEquipmentToMissionNfcScreen extends StatefulWidget {
  final String missionId;
  final List<String> alreadyAddedEquipmentIds;

  const AddEquipmentToMissionNfcScreen({
    Key? key,
    required this.missionId,
    required this.alreadyAddedEquipmentIds,
  }) : super(key: key);

  @override
  State<AddEquipmentToMissionNfcScreen> createState() =>
      _AddEquipmentToMissionNfcScreenState();
}

class _AddEquipmentToMissionNfcScreenState
    extends State<AddEquipmentToMissionNfcScreen> {
  final EquipmentService _equipmentService = EquipmentService();
  final MissionService _missionService = MissionService();
  final NfcService _nfcService = NfcService();

  bool _isScanning = false;
  bool _isNfcAvailable = false;
  String _statusMessage = 'Bereit zum Scannen';
  List<EquipmentModel> _scannedEquipment = [];
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _checkNfcAvailability();
  }

  Future<void> _checkNfcAvailability() async {
    final isAvailable = await _nfcService.isNfcAvailable();
    if (mounted) {
      setState(() {
        _isNfcAvailable = isAvailable;
        _statusMessage = isAvailable
            ? 'Bereit zum Scannen'
            : 'NFC ist auf diesem Gerät nicht verfügbar';
      });
    }
  }

  Future<void> _startNfcScan() async {
    if (!_isNfcAvailable) {
      setState(() {
        _statusMessage = 'NFC ist auf diesem Gerät nicht verfügbar';
      });
      return;
    }

    setState(() {
      _isScanning = true;
      _statusMessage = 'NFC-Tag scannen...';
    });

    try {
      final tagId = await _nfcService.readNfcTag();

      if (tagId == null) {
        setState(() {
          _isScanning = false;
          _statusMessage = 'Scan abgebrochen oder fehlgeschlagen';
        });
        return;
      }

      // Equipment anhand des NFC-Tags suchen
      final equipment = await _equipmentService.getEquipmentByNfcTag(tagId);

      if (equipment == null) {
        setState(() {
          _isScanning = false;
          _statusMessage = 'Keine Ausrüstung mit diesem NFC-Tag gefunden';
        });
        return;
      }

      // Prüfen, ob die Ausrüstung bereits hinzugefügt wurde
      if (widget.alreadyAddedEquipmentIds.contains(equipment.id)) {
        setState(() {
          _isScanning = false;
          _statusMessage = 'Diese Ausrüstung wurde bereits zum Einsatz hinzugefügt';
        });
        return;
      }

      // Prüfen, ob die Ausrüstung einsatzbereit ist
      if (equipment.status != EquipmentStatus.ready) {
        setState(() {
          _isScanning = false;
          _statusMessage = 'Diese Ausrüstung ist nicht einsatzbereit (Status: ${equipment.status})';
        });
        return;
      }

      // Ausrüstung zur Liste hinzufügen
      setState(() {
        _scannedEquipment.add(equipment);
        _isScanning = false;
        _statusMessage = 'Ausrüstung erfolgreich gescannt: ${equipment.article}';
      });
    } catch (e) {
      setState(() {
        _isScanning = false;
        _statusMessage = 'Fehler beim Scannen: $e';
      });
    }
  }

  Future<void> _saveScannedEquipment() async {
    if (_scannedEquipment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Keine Ausrüstung zum Hinzufügen gescannt'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // IDs der gescannten Ausrüstung extrahieren
      final List<String> equipmentIds = _scannedEquipment.map((e) => e.id).toList();

      // Zum Einsatz hinzufügen
      await _missionService.addEquipmentToMission(widget.missionId, equipmentIds);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ausrüstung erfolgreich zum Einsatz hinzugefügt'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // true zurückgeben als Erfolg-Indikator
      }
    } catch (e) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ausrüstung per NFC hinzufügen'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Statuskarte
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isScanning ? Icons.nfc : (_isNfcAvailable ? Icons.check_circle : Icons.error),
                          color: _isScanning
                              ? Colors.blue
                              : (_isNfcAvailable ? Colors.green : Colors.red),
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _statusMessage,
                            style: const TextStyle(
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isScanning || !_isNfcAvailable ? null : _startNfcScan,
                        icon: const Icon(Icons.nfc),
                        label: Text(_isScanning ? 'Scannen...' : 'NFC-Tag scannen'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Liste der gescannten Ausrüstung
            Text(
              'Gescannte Ausrüstung (${_scannedEquipment.length})',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _scannedEquipment.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Noch keine Ausrüstung gescannt',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Scannen Sie die NFC-Tags der Ausrüstung,\ndie Sie zum Einsatz hinzufügen möchten',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                itemCount: _scannedEquipment.length,
                itemBuilder: (context, index) {
                  final equipment = _scannedEquipment[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: equipment.type == 'Jacke' ? Colors.blue : Colors.amber,
                        child: Icon(
                          equipment.type == 'Jacke'
                              ? Icons.accessibility_new
                              : Icons.airline_seat_legroom_normal,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(equipment.article),
                      subtitle: Text('Besitzer: ${equipment.owner} | Größe: ${equipment.size}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.remove_circle, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            _scannedEquipment.removeAt(index);
                          });
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: _isProcessing || _scannedEquipment.isEmpty
              ? null
              : _saveScannedEquipment,
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
            'Ausrüstung zum Einsatz hinzufügen',
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}