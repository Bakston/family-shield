import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ScanSecondParentScreen extends StatefulWidget {
  const ScanSecondParentScreen({super.key});

  @override
  State<ScanSecondParentScreen> createState() => _ScanSecondParentScreenState();
}

class _ScanSecondParentScreenState extends State<ScanSecondParentScreen> {
  bool _isProcessing = false;

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? scannedParentUid = barcodes.first.rawValue;
    if (scannedParentUid == null || scannedParentUid.trim().isEmpty) return;

    setState(() => _isProcessing = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final myUid = prefs.getString('user_uid');

      if (myUid == null || myUid.isEmpty) {
        throw Exception('Ваш профиль не найден');
      }

      if (myUid == scannedParentUid) {
        throw Exception('Нельзя привязать свой собственный QR-код');
      }

      final db = FirebaseDatabase.instance.ref('users');
      // Двусторонняя привязка родителей друг к другу
      await db.child('$myUid/linkedParent').set(scannedParentUid);
      await db.child('$scannedParentUid/linkedParent').set(myUid);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Второй член семьи успешно подключён!')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка привязки: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Сканирование QR-кода'),
      ),
      body: MobileScanner(
        onDetect: _onDetect,
      ),
    );
  }
}