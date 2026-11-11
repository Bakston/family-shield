import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'child_panel_screen.dart';

class ChildPermissionsScreen extends StatefulWidget {
  final String childName;

  const ChildPermissionsScreen({
    super.key,
    required this.childName,
  });

  @override
  State<ChildPermissionsScreen> createState() => _ChildPermissionsScreenState();
}

class _ChildPermissionsScreenState extends State<ChildPermissionsScreen> with WidgetsBindingObserver {
  bool _locationGranted = false;
  bool _usageStatsGranted = false;

  static const platform = MethodChannel('com.example.family_shield/usage_stats');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Перепроверяем права, когда пользователь возвращается из системных настроек
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
    }
  }

  Future<void> _checkPermissions() async {
    final locStatus = await Permission.location.status;
    
    bool usageGranted = false;
    try {
      final bool? result = await platform.invokeMethod('checkUsagePermission');
      usageGranted = result ?? false;
    } catch (e) {
      debugPrint('Ошибка проверки UsageStats: $e');
    }

    setState(() {
      _locationGranted = locStatus.isGranted;
      _usageStatsGranted = usageGranted;
    });
  }

  Future<void> _requestLocationPermission() async {
    final status = await Permission.location.request();
    if (status.isGranted) {
      await Permission.locationAlways.request();
    } else if (status.isPermanentlyDenied) {
      openAppSettings();
    }
    _checkPermissions();
  }

  Future<void> _requestUsagePermission() async {
    try {
      await platform.invokeMethod('requestUsagePermission');
    } catch (e) {
      openAppSettings();
    }
  }

  void _proceedToPanel() {
    if (!_locationGranted || !_usageStatsGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Пожалуйста, предоставьте все необходимые разрешения для продолжения'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ChildPanelScreen(childName: widget.childName),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройка защиты устройства'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Для работы родительского контроля на этом устройстве необходимо предоставить системные разрешения.',
              style: TextStyle(fontSize: 15, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            
            // Карточка 1: Геолокация
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: Icon(
                  _locationGranted ? Icons.check_circle : Icons.location_on,
                  color: _locationGranted ? Colors.green : Colors.orange,
                  size: 32,
                ),
                title: const Text('Геолокация (Всегда)', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Необходимо для отслеживания местоположения ребёнка в реальном времени.'),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _locationGranted ? Colors.green[50] : Colors.blue,
                    foregroundColor: _locationGranted ? Colors.green : Colors.white,
                  ),
                  onPressed: _requestLocationPermission,
                  child: Text(_locationGranted ? 'Готово' : 'Включить'),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Карточка 2: Статистика использования
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: Icon(
                  _usageStatsGranted ? Icons.check_circle : Icons.bar_chart,
                  color: _usageStatsGranted ? Colors.green : Colors.indigo,
                  size: 32,
                ),
                title: const Text('Статистика использования', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Нужно для анализа экранного времени и заблокированных приложений.'),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _usageStatsGranted ? Colors.green[50] : Colors.blue,
                    foregroundColor: _usageStatsGranted ? Colors.green : Colors.white,
                  ),
                  onPressed: _requestUsagePermission,
                  child: Text(_usageStatsGranted ? 'Готово' : 'Настроить'),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Карточка 3: Наложение поверх других окон
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: const Icon(Icons.layers, color: Colors.purple, size: 32),
                title: const Text('Поверх других окон', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Требуется для блокировки экрана при ограничениях.'),
                trailing: ElevatedButton(
                  onPressed: () {
                    openAppSettings();
                  },
                  child: const Text('Настроить'),
                ),
              ),
            ),

            const Spacer(),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(55),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              onPressed: _proceedToPanel,
              child: const Text(
                'ПРОДОЛЖИТЬ',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}