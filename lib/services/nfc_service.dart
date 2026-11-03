import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';

class NfcService {
  static Future<String> readCardUid() async {
    try {
      final tag = await FlutterNfcKit.poll(
        timeout: const Duration(seconds: 20),
      );

      return tag.id.toUpperCase();
    } finally {
      await FlutterNfcKit.finish();
    }
  }
}
