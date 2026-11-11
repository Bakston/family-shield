import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'child_panel_screen.dart';

class ChildQrScannerScreen extends StatefulWidget {
  const ChildQrScannerScreen({super.key});

  @override
  State<ChildQrScannerScreen> createState() => _ChildQrScannerScreenState();
}

class _ChildQrScannerScreenState extends State<ChildQrScannerScreen> {
  bool _isProcessing = false;
  final MobileScannerController _controller = MobileScannerController();
  final TextEditingController _codeController = TextEditingController();

  static const platform = MethodChannel('com.example.family_shield/device_admin');

  @override
  void dispose() {
    _controller.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _requestPermissions() async {
    try {
      await platform.invokeMethod('requestDeviceAdmin');
      await Future.delayed(const Duration(milliseconds: 500));
      await platform.invokeMethod('requestAccessibility');
    } on PlatformException catch (e) {
      _showError('Ошибка запроса разрешений: ${e.message}');
    }
  }

  Future<void> _processChildId(String childId) async {
    final trimmedId = childId.trim();
    if (trimmedId.isEmpty) return;

    setState(() => _isProcessing = true);
    try {
      final childRef = FirebaseDatabase.instance.ref('children/$trimmedId');
      final snapshot = await childRef.get();

      if (!snapshot.exists || snapshot.value == null) {
        _showError('Код недействителен или ребёнок не найден в базе.');
        return;
      }

      final childData = Map<dynamic, dynamic>.from(snapshot.value as Map);
      final childName = childData['name']?.toString() ?? 'Ребёнок';

      // Обновляем статус привязки в базе данных
      await childRef.update({
        'isLinked': true,
        'linkedAt': ServerValue.timestamp,
      });

      // Сохраняем сессию и имя ребёнка локально
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_child_id', trimmedId);
      await prefs.setString('saved_child_name', childName);

      // Запрашиваем нативные разрешения с защитой от зависания на эмуляторе
      try {
        await _requestPermissions().timeout(
          const Duration(seconds: 3),
          onTimeout: () {},
        );
      } catch (_) {}

      if (!mounted) return;

      // Очищаем стек навигации, чтобы кнопкой «Назад» нельзя было выйти из панели ребёнка
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => ChildPanelScreen(childName: childName),
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

  void _saveManualEntry() {
    _codeController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ввод кода вручную'),
        content: TextField(
          controller: _codeController,
          decoration: const InputDecoration(
            labelText: 'Введите код привязки',
            hintText: 'Например: -Oabc123xyz...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _processChildId(_codeController.text);
            },
            child: const Text('Подтвердить'),
          ),
        ],
      ),
    );
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
      appBar: AppBar(
        title: const Text('Сканирование QR-кода'),
        actions: [
          IconButton(
            icon: const Icon(Icons.keyboard),
            tooltip: 'Ввести код текстом',
            onPressed: _saveManualEntry,
          ),
        ],
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
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 24,
            right: 24,
            child: Column(
              children: [
                const Text(
                  'Наведите камеру на QR-код с телефона родителя',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    backgroundColor: Colors.black45,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _saveManualEntry,
                  icon: const Icon(Icons.keyboard),
                  label: const Text(
                    'ВВЕСТИ КОД ТЕКСТОМ',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}