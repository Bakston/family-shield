import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'child_qr_scanner_screen.dart';

import '../../core/app_theme.dart';

const Color childGlassPanel = Color(0x33FFFFFF);
const Color childTextPrimary = Colors.white;

class ChildJoinScreen extends StatelessWidget {
  const ChildJoinScreen({super.key});

  /// Проверка и запрос доступа к камере перед открытием сканера
  Future<void> _handleScanButtonTap(BuildContext context) async {
    final cameraStatus = await Permission.camera.request();

    if (!context.mounted) return;

    if (cameraStatus.isGranted) {
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            AppTheme.parentBackgroundAsset,
            fit: BoxFit.cover,
          ),
        ),
        Positioned.fill(
          child: Container(
            color: Colors.black.withValues(alpha: 0.45),
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
            title: const Text(
              'Вход для ребёнка',
              style: TextStyle(
                color: childTextPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 36.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: childGlassPanel,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.qr_code_scanner,
                          size: 76,
                          color: childTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Отсканируйте QR-код с телефона родителя, чтобы привязать устройство',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                          color: childTextPrimary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(60),
                      backgroundColor:
                          Colors.blue.shade700.withValues(alpha: 0.85),
                      foregroundColor: childTextPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.camera_alt, size: 26),
                    label: const Text(
                      'СКАНИРОВАТЬ QR-КОД',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () => _handleScanButtonTap(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}