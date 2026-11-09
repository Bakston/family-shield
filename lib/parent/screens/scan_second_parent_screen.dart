import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/services/database_service.dart';
import 'parent_panel_screen.dart';

class ScanSecondParentScreen extends StatefulWidget {
  const ScanSecondParentScreen({super.key});

  @override
  State<ScanSecondParentScreen> createState() => _ScanSecondParentScreenState();
}

class _ScanSecondParentScreenState extends State<ScanSecondParentScreen> {
  final DatabaseService _databaseService = DatabaseService();
  
  // Инициализируем контроллер для версии 6.x
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );
  
  bool _isHandled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Сканирование семейного QR')),
      body: MobileScanner(
        controller: _controller,
        onDetect: (BarcodeCapture capture) async {
          if (_isHandled) return;
          final List<Barcode> barcodes = capture.barcodes;
          
          for (final barcode in barcodes) {
            final primaryParentUid = barcode.rawValue;
            if (primaryParentUid != null && primaryParentUid.isNotEmpty) {
              _isHandled = true;
              
              // Останавливаем сканер перед вызовами асинхронных операций
              await _controller.stop();

              final currentUserId = FirebaseAuth.instance.currentUser?.uid;
              if (currentUserId != null) {
                try {
                  // Связываем аккаунты через наш метод в DatabaseService
                  await _databaseService.linkSecondParent(
                    newParentUid: currentUserId,
                    primaryParentUid: primaryParentUid,
                  );

                  if (!mounted) return;
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Вы успешно присоединились к семье!')),
                  );

                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const ParentPanelScreen()),
                    (route) => false,
                  );
                } catch (e) {
                  setState(() => _isHandled = false);
                  _controller.start(); // Перезапуск сканера при ошибке привязки
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Ошибка привязки: $e')),
                  );
                }
              }
              break;
            }
          }
        },
        // Перехватываем ошибки камеры, чтобы приложение не падало
        errorBuilder: (context, error, child) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                'Не удалось запустить камеру: ${error.errorCode.name}\n\n'
                'Убедитесь, что приложению предоставлен доступ к камере в настройках устройства.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 16),
              ),
            ),
          );
        },
      ),
    );
  }
}