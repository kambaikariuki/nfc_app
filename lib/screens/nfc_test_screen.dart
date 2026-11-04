import 'package:flutter/material.dart';
import 'package:nfc_app/services/nfc_service.dart';

class NfcTestScreen extends StatefulWidget {
  const NfcTestScreen({super.key});

  @override
  State<NfcTestScreen> createState() => _NfcTestScreenState();
}

class _NfcTestScreenState extends State<NfcTestScreen> {
  String? cardUid;
  bool isScanning = false;
  String? errorMessage;

  Future<void> scanCard() async {
    setState(() {
      isScanning = true;
      cardUid = null;
      errorMessage = null;
    });

    try {
      final uid = await NfcService.readCardUid();

      if (!mounted) return;

      setState(() {
        cardUid = uid;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => isScanning = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('NFC Card Reader')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.nfc, size: 90),
              const SizedBox(height: 24),

              Text(
                isScanning
                    ? 'Hold your card near the phone...'
                    : 'Ready to scan',
                style: const TextStyle(fontSize: 18),
              ),

              const SizedBox(height: 24),

              if (cardUid != null) ...[
                const Text(
                  'Card UID:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SelectableText(cardUid!, style: const TextStyle(fontSize: 20)),
              ],

              if (errorMessage != null)
                Text(
                  errorMessage!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: isScanning ? null : scanCard,
                child: Text(isScanning ? 'Scanning...' : 'Scan NFC Card'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
