import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'child_permissions_screen.dart';

class ChildQrScannerScreen extends StatefulWidget {
  const ChildQrScannerScreen({super.key});

  @override
  State<ChildQrScannerScreen> createState() => _ChildQrScannerScreenState();
}

class _ChildQrScannerScreenState extends State<ChildQrScannerScreen> {
  bool _isProcessing = false;
  final MobileScannerController _controller = MobileScannerController();

  static const platform = MethodChannel('com.example.family_shield/device_admin');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _requestPermissions() async {
    try {
      await platform.invokeMethod('requestDeviceAdmin').timeout(
            const Duration(seconds: 3),
            onTimeout: () {},
          );
      await Future.delayed(const Duration(milliseconds: 500));
      await platform.invokeMethod('requestAccessibility').timeout(
            const Duration(seconds: 3),
            onTimeout: () {},
          );
    } catch (_) {}
  }

  Future<void> _processChildId(String childId) async {
    final trimmedId = childId.trim();
    if (trimmedId.isEmpty) return;

    setState(() => _isProcessing = true);
    try {
      final childRef = FirebaseDatabase.instance.ref('children/$trimmedId');
      final snapshot = await childRef.get();

      if (!snapshot.exists || snapshot.value == null) {
        _showError('QR-код недействителен или профиль ребёнка не найден.');
        return;
      }

      final childData = Map<dynamic, dynamic>.from(snapshot.value as Map);
      final childName = childData['name']?.toString() ?? 'Ребёнок';

      await childRef.update({
        'isLinked': true,
        'linkedAt': ServerValue.timestamp,
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_type', 'child');
      await prefs.setString('saved_child_id', trimmedId);
      await prefs.setString('saved_child_name', childName);

      await _requestPermissions();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => ChildPermissionsScreen(childName: childName),
        ),
        (route) => false,
      );
    } catch (e) {
      _showError('Ошибка привязки: $e');
    }
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    for (final barcode in capture.barcodes) {
      final String? childId = barcode.rawValue;
      if (childId != null && childId.isNotEmpty) {
        try {
          _controller.stop();
        } catch (_) {}
        await _processChildId(childId);
        break;
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
    setState(() => _isProcessing = false);
    try {
      _controller.start();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.black45,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Сканирование QR-кода',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blueAccent, width: 3),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          Positioned(
            bottom: 48,
            left: 24,
            right: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'Наведите камеру на QR-код с телефона родителя',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}