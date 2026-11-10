import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'child_qr_scanner_screen.dart'; // Подключаем реальный экран сканера

class ChildJoinScreen extends StatefulWidget {
  const ChildJoinScreen({super.key});

  @override
  State<ChildJoinScreen> createState() => _ChildJoinScreenState();
}

class _ChildJoinScreenState extends State<ChildJoinScreen> {
  /// Метод для проверки и запроса доступа к камере перед открытием сканера
  Future<void> _handleScanButtonTap(BuildContext context) async {
    PermissionStatus cameraStatus = await Permission.camera.request();

    if (!context.mounted) return;

    if (cameraStatus.isGranted) {
      // Переходим к сканированию QR-кода родителя
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ChildQrScannerScreen()),
      );
    } else if (cameraStatus.isPermanentlyDenied) {
      _showSettingsDialog(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Для сканирования QR-кода необходим доступ к камере.'),
        ),
      );
    }
  }

  /// Диалог перехода в системные настройки при блокировке разрешений
  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Требуется доступ к камере'),
        content: const Text(
          'Доступ к камере заблокирован в настройках устройства. Пожалуйста, разрешите доступ в настройках приложения для сканирования QR-кода родителя.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Открыть настройки'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Вход для ребенка')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.qr_code_scanner, size: 80, color: Colors.blue),
              const SizedBox(height: 24),
              const Text(
                'Для подключения к семье отсканируйте QR-код с телефона родителя',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(60),
                ),
                icon: const Icon(Icons.camera_alt),
                label: const Text('ВСТУПИТЬ В СЕМЬЮ', style: TextStyle(fontSize: 18)),
                onPressed: () => _handleScanButtonTap(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}