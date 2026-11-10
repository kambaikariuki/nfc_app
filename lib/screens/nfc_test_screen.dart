import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager_android.dart';

class NfcTestScreen extends StatefulWidget {
  const NfcTestScreen({super.key});

  @override
  State<NfcTestScreen> createState() => _NfcTestScreenState();
}

class _NfcTestScreenState extends State<NfcTestScreen> {
  String _status = 'Checking NFC...';
  String? _cardUid;

  bool _isAvailable = false;
  bool _isScanning = false;
  bool _isReading = false;

  @override
  void initState() {
    super.initState();
    _checkNfc();
  }

  Future<void> _checkNfc() async {
    final available = await NfcManager.instance.isAvailable();

    if (!mounted) return;

    setState(() {
      _isAvailable = available;
      _status = available
          ? 'NFC is available. Ready to scan.'
          : 'NFC is unavailable or disabled.';
    });
  }

  Future<void> _startScan() async {
    if (!_isAvailable || _isScanning) return;

    setState(() {
      _cardUid = null;
      _status = 'Hold your card near the phone...';
      _isScanning = true;
      _isReading = true;
    });

    try {
      await NfcManager.instance.startSession(
        pollingOptions: {NfcPollingOption.iso14443},
        onDiscovered: (NfcTag tag) async {
          try {
            final androidTag = NfcTagAndroid.from(tag);

            if (androidTag == null) {
              throw Exception('Unable to read Android NFC tag.');
            }

            final uid = androidTag.id
                .map(
                  (byte) => byte
                      .toRadixString(16)
                      .padLeft(2, '0'),
                )
                .join()
                .toUpperCase();

            await NfcManager.instance.stopSession();

            if (!mounted) return;

            setState(() {
              _cardUid = uid;
              _status = 'Card successfully detected!';
              _isScanning = false;
              _isReading = false;
            });
          } catch (e) {
            await NfcManager.instance.stopSession();

            if (!mounted) return;

            setState(() {
              _status = 'Error reading card: $e';
              _isScanning = false;
              _isReading = false;
            });
          }
        },
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _status = 'Could not start NFC scanning: $e';
        _isScanning = false;
        _isReading = false;
      });
    }
  }

  Future<void> _stopScan() async {
    if (_isScanning) {
      await NfcManager.instance.stopSession();
    }

    if (!mounted) return;

    setState(() {
      _isScanning = false;
      _isReading = false;
      _status = 'Scanning stopped.';
    });
  }

  @override
  void dispose() {
    if (_isScanning) {
      NfcManager.instance.stopSession();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NFC Test'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              _cardUid != null
                  ? Icons.check_circle
                  : Icons.nfc,
              size: 100,
              color: _cardUid != null
                  ? Colors.green
                  : Colors.blue,
            ),

            const SizedBox(height: 24),

            Text(
              _status,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 32),

            if (_cardUid != null) ...[
              const Text(
                'CARD UID',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  letterSpacing: 2,
                ),
              ),

              const SizedBox(height: 12),

              SelectableText(
                _cardUid!,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 3,
                ),
              ),

              const SizedBox(height: 24),
            ],

            if (_isReading)
              const CircularProgressIndicator(),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: !_isAvailable || _isScanning
                    ? null
                    : _startScan,
                child: const Text('Scan NFC Card'),
              ),
            ),

            if (_isScanning) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: _stopScan,
                  child: const Text('Stop Scanning'),
                ),
              ),
            ],

            const SizedBox(height: 16),

            TextButton(
              onPressed: _checkNfc,
              child: const Text('Check NFC availability again'),
            ),
          ],
        ),
      ),
    );
  }
}
