import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ConnectionTestScreen extends StatefulWidget {
  const ConnectionTestScreen({super.key});

  @override
  State<ConnectionTestScreen> createState() =>
      _ConnectionTestScreenState();
}

class _ConnectionTestScreenState
    extends State<ConnectionTestScreen> {
  String message = 'Not connected yet';
  bool loading = false;

  Future<void> testConnection() async {
    setState(() {
      loading = true;
      message = 'Connecting...';
    });

    try {
      final result = await ApiService.testConnection();

      if (!mounted) return;
      setState(() {
        message = 'Connected successfully!\n$result';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        message = 'Connection failed:\n$e';
      });
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Backend Connection')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: loading ? null : testConnection,
                child: Text(
                  loading ? 'Connecting...' : 'Test Connection',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}