import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'child_panel_screen.dart';

class ChildQrScannerScreen extends StatefulWidget {
  const ChildQrScannerScreen({super.key});

  @override
  State<ChildQrScannerScreen> createState() => _ChildQrScannerScreenState();
}

class _ChildQrScannerScreenState extends State<ChildQrScannerScreen> {
  bool _isProcessing = false;
  final MobileScannerController _controller = MobileScannerController();

  // Канал для связи с нативным кодом Android (защита от удаления и доступность)
  static const platform = MethodChannel('com.example.family_shield/device_admin');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Запрос прав администратора устройства и службы доступности
  Future<void> _requestPermissions() async {
    try {
      // 1. Запрос прав администратора устройства (защита от удаления)
      await platform.invokeMethod('requestDeviceAdmin');
      
      // Небольшая пауза между системными диалогами
      await Future.delayed(const Duration(milliseconds: 500));

      // 2. Запрос службы доступности (полный контроль)
      await platform.invokeMethod('requestAccessibility');
    } on PlatformException catch (e) {
      _showError('Ошибка запроса разрешений: ${e.message}');
    }
  }

  /// Обработка успешного сканирования QR-кода
  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final String? childId = barcode.rawValue;
      if (childId == null || childId.isEmpty) continue;

      setState(() => _isProcessing = true);
      _controller.stop(); // Останавливаем камеру

      try {
        // Проверяем существование ребенка в базе данных
        final childRef = FirebaseDatabase.instance.ref('children/$childId');
        final snapshot = await childRef.get();

        if (!snapshot.exists) {
          _showError('QR-код недействителен или ребенок не найден в базе.');
          return;
        }

        // Обновляем статус привязки в базе
        await childRef.update({
          'isLinked': true,
          'linkedAt': ServerValue.timestamp,
        });

        // Запрашиваем необходимые системные разрешения
        await _requestPermissions();

        // Получаем данные ребенка для приветствия
        final childData = Map<dynamic, dynamic>.from(snapshot.value as Map);
        final childName = childData['name'] ?? 'Ребёнок';

        if (!mounted) return;

        // Успешно привязано! Переходим на панель ребенка с передачей имени
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ChildPanelScreen(childName: childName),
          ),
        );
      } catch (e) {
        _showError('Ошибка привязки: $e');
      }
      break; // Обрабатываем только первый найденный код
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
    setState(() => _isProcessing = false);
    _controller.start(); // Перезапуск сканера при ошибке
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Сканирование QR-кода родителя')),
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
          // Рамка подсказки посередине
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
          const Positioned(
            bottom: 50,
            left: 24,
            right: 24,
            child: Text(
              'Наведите камеру на QR-код с телефона родителя',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                backgroundColor: Colors.black45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}