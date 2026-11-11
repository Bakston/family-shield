import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'child_qr_scanner_screen.dart';
import 'child_panel_screen.dart';

class ChildJoinScreen extends StatefulWidget {
  const ChildJoinScreen({super.key});

  @override
  State<ChildJoinScreen> createState() => _ChildJoinScreenState();
}

class _ChildJoinScreenState extends State<ChildJoinScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _isProcessing = false;

  // Канал для связи с нативным кодом Android (защита от удаления и доступность)
  static const platform = MethodChannel('com.example.family_shield/device_admin');

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  /// Запрос прав администратора устройства и службы доступности
  Future<void> _requestPermissions() async {
    try {
      await platform.invokeMethod('requestDeviceAdmin');
      await Future.delayed(const Duration(milliseconds: 500));
      await platform.invokeMethod('requestAccessibility');
    } on PlatformException catch (e) {
      _showError('Ошибка запроса разрешений: ${e.message}');
    }
  }

  /// Обработка и привязка по текстовому коду (childId)
  Future<void> _processChildId(String childId) async {
    final trimmedId = childId.trim();
    if (trimmedId.isEmpty) return;

    setState(() => _isProcessing = true);
    try {
      final childRef = FirebaseDatabase.instance.ref('children/$trimmedId');
      final snapshot = await childRef.get();

      if (!snapshot.exists || snapshot.value == null) {
        _showError('Код недействителен или ребенок не найден в базе.');
        return;
      }

      // Получаем данные ребенка для приветствия
      final childData = Map<dynamic, dynamic>.from(snapshot.value as Map);
      final childName = childData['name']?.toString() ?? 'Ребёнок';

      // Обновляем статус привязки в базе
      await childRef.update({
        'isLinked': true,
        'linkedAt': ServerValue.timestamp,
      });

      // Сохраняем сессию ребенка локально в SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_child_id', trimmedId);
      await prefs.setString('saved_child_name', childName);

      // Запрашиваем необходимые системные разрешения
      await _requestPermissions();

      if (!mounted) return;

      // Успешно привязано! Очищаем весь стек навигации и открываем панель ребенка
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

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
    setState(() => _isProcessing = false);
  }

  /// Диалог для ручного ввода текстового кода
  void _showManualEntryDialog() {
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

  /// Метод для проверки и запроса доступа к камере перед открытием сканера
  Future<void> _handleScanButtonTap(BuildContext context) async {
    PermissionStatus cameraStatus = await Permission.camera.request();

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
      appBar: AppBar(
        title: const Text('Вход для ребенка'),
        actions: [
          IconButton(
            icon: const Icon(Icons.keyboard),
            tooltip: 'Ввести код текстом',
            onPressed: _showManualEntryDialog,
          ),
        ],
      ),
      body: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.qr_code_scanner, size: 80, color: Colors.blue),
                  const SizedBox(height: 24),
                  const Text(
                    'Отсканируйте QR-код с телефона родителя или введите код вручную',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(60),
                    ),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('СКАНИРОВАТЬ QR-КОД', style: TextStyle(fontSize: 18)),
                    onPressed: () => _handleScanButtonTap(context),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(60),
                    ),
                    icon: const Icon(Icons.keyboard),
                    label: const Text('ВВЕСТИ КОД ТЕКСТОМ', style: TextStyle(fontSize: 18)),
                    onPressed: _showManualEntryDialog,
                  ),
                ],
              ),
            ),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}