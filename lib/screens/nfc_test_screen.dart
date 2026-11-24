import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';

class NfcTestScreen extends StatefulWidget {
  const NfcTestScreen({super.key});

  @override
  State<NfcTestScreen> createState() => _NfcTestScreenState();
}

class _NfcTestScreenState extends State<NfcTestScreen> {
  bool? _isAvailable;
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkNfc();
  }

  Future<void> _checkNfc() async {
    setState(() {
      _isChecking = true;
    });

    try {
      final available = await NfcManager.instance.isAvailable();

      if (!mounted) return;

      setState(() {
        _isAvailable = available;
        _isChecking = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isAvailable = false;
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NFC Availability'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _isChecking
                    ? Icons.nfc
                    : _isAvailable == true
                        ? Icons.check_circle
                        : Icons.cancel,
                size: 100,
                color: _isChecking
                    ? Colors.blue
                    : _isAvailable == true
                        ? Colors.green
                        : Colors.red,
              ),

              const SizedBox(height: 24),

              Text(
                _isChecking
                    ? 'Checking NFC availability...'
                    : _isAvailable == true
                        ? 'NFC is enabled'
                        : 'NFC is unavailable or disabled',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                _isChecking
                    ? 'Please wait.'
                    : _isAvailable == true
                        ? 'Your phone is ready to use NFC.'
                        : 'Enable NFC in your phone settings if your device supports it.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isChecking ? null : _checkNfc,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Check Again'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}