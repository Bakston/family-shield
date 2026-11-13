import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'child_panel_screen.dart';

import '../../core/app_theme.dart';

class ChildPermissionsScreen extends StatefulWidget {
  final String childName;

  const ChildPermissionsScreen({
    super.key,
    required this.childName,
  });

  @override
  State<ChildPermissionsScreen> createState() => _ChildPermissionsScreenState();
}

class _ChildPermissionsScreenState extends State<ChildPermissionsScreen>
    with WidgetsBindingObserver {
  bool _locationAlwaysGranted = false;
  bool _usageStatsGranted = false;
  bool _overlayGranted = false;
  bool _batteryGranted = false;
  bool _deviceAdminGranted = false;
  bool _accessibilityGranted = false;
  bool _defaultLauncherGranted = false;

  static const _usageChannel =
      MethodChannel('com.example.family_shield/usage_stats');
  static const _adminChannel =
      MethodChannel('com.example.family_shield/device_admin');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkAllPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAllPermissions();
    }
  }

  Future<void> _checkAllPermissions() async {
    final locAlways = await Permission.locationAlways.isGranted;
    final overlay = await Permission.systemAlertWindow.isGranted;
    final battery = await Permission.ignoreBatteryOptimizations.isGranted;

    bool usage = false;
    bool admin = false;
    bool access = false;
    bool launcher = false;

    try {
      usage =
          await _usageChannel.invokeMethod<bool>('checkUsagePermission') ?? false;
    } catch (_) {}

    try {
      admin =
          await _adminChannel.invokeMethod<bool>('checkDeviceAdmin') ?? false;
    } catch (_) {}

    try {
      access =
          await _adminChannel.invokeMethod<bool>('checkAccessibility') ?? false;
    } catch (_) {}

    try {
      launcher =
          await _adminChannel.invokeMethod<bool>('checkDefaultLauncher') ??
              false;
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _locationAlwaysGranted = locAlways;
      _usageStatsGranted = usage;
      _overlayGranted = overlay;
      _batteryGranted = battery;
      _deviceAdminGranted = admin;
      _accessibilityGranted = access;
      _defaultLauncherGranted = launcher;
    });
  }

  Future<void> _requestLocation() async {
    final status = await Permission.location.request();
    if (status.isGranted) {
      await Permission.locationAlways.request();
    } else if (status.isPermanentlyDenied) {
      await openAppSettings();
    }
    await Permission.notification.request();
    _checkAllPermissions();
  }

  Future<void> _requestBattery() async {
    await Permission.ignoreBatteryOptimizations.request();
    _checkAllPermissions();
  }

  Future<void> _requestDeviceAdmin() async {
    try {
      await _adminChannel.invokeMethod('requestDeviceAdmin');
    } catch (_) {
      await openAppSettings();
    }
  }

  Future<void> _requestAccessibility() async {
    try {
      await _adminChannel.invokeMethod('requestAccessibility');
    } catch (_) {
      await openAppSettings();
    }
  }

  Future<void> _requestDefaultLauncher() async {
    try {
      await _adminChannel.invokeMethod('requestDefaultLauncher');
    } catch (_) {
      await openAppSettings();
    }
  }

  bool get _allRequiredGranted =>
      _locationAlwaysGranted &&
      _usageStatsGranted &&
      _overlayGranted &&
      _batteryGranted &&
      _deviceAdminGranted &&
      _accessibilityGranted &&
      _defaultLauncherGranted;

  void _proceedToPanel() {
    if (!_allRequiredGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Активируйте все 7 пунктов защиты перед продолжением'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => ChildPanelScreen(childName: widget.childName),
      ),
      (route) => false,
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
          child: Container(color: Colors.black.withValues(alpha: 0.45)),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: false,
            title: const Text(
              'Настройка защиты',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Для защиты от удаления и запуска детского рабочего стола активируйте все права:',
                    style: TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView(
                      children: [
                        _buildPermCard(
                          granted: _locationAlwaysGranted,
                          icon: Icons.location_on,
                          color: Colors.orange,
                          title: 'Геолокация (Всегда)',
                          subtitle: 'Фоновое отслеживание координат',
                          onTap: _requestLocation,
                        ),
                        _buildPermCard(
                          granted: _batteryGranted,
                          icon: Icons.battery_saver,
                          color: Colors.teal,
                          title: 'Работа без ограничений',
                          subtitle: 'Исключить из оптимизации батареи',
                          onTap: _requestBattery,
                        ),
                        _buildPermCard(
                          granted: _usageStatsGranted,
                          icon: Icons.bar_chart,
                          color: Colors.indigo,
                          title: 'Статистика использования',
                          subtitle: 'Контроль экранного времени',
                          onTap: () => _usageChannel
                              .invokeMethod('requestUsagePermission'),
                        ),
                        _buildPermCard(
                          granted: _overlayGranted,
                          icon: Icons.layers,
                          color: Colors.purple,
                          title: 'Поверх других окон',
                          subtitle: 'Экран блокировки при лимитах',
                          onTap: () async {
                            await Permission.systemAlertWindow.request();
                            _checkAllPermissions();
                          },
                        ),
                        _buildPermCard(
                          granted: _deviceAdminGranted,
                          icon: Icons.admin_panel_settings,
                          color: Colors.redAccent,
                          title: 'Администратор устройства',
                          subtitle: 'Запрет на удаление приложения',
                          onTap: _requestDeviceAdmin,
                        ),
                        _buildPermCard(
                          granted: _accessibilityGranted,
                          icon: Icons.accessibility_new,
                          color: Colors.blue,
                          title: 'Служба доступности',
                          subtitle: 'Защита настроек от отключения',
                          onTap: _requestAccessibility,
                        ),
                        _buildPermCard(
                          granted: _defaultLauncherGranted,
                          icon: Icons.home_filled,
                          color: Colors.deepPurple,
                          title: 'Лаунчер по умолчанию',
                          subtitle: 'Защищённый рабочий стол ребёнка',
                          onTap: _requestDefaultLauncher,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                      backgroundColor: _allRequiredGranted
                          ? Colors.green.shade600
                          : Colors.blue.shade700.withValues(alpha: 0.9),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: _proceedToPanel,
                    child: const Text(
                      'ЗАПУСТИТЬ РАБОЧИЙ СТОЛ',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPermCard({
    required bool granted,
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: Colors.white.withValues(alpha: 0.92),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: Icon(
          granted ? Icons.check_circle : icon,
          color: granted ? Colors.green : color,
          size: 30,
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor:
                granted ? Colors.green.shade50 : Colors.blue.shade700,
            foregroundColor: granted ? Colors.green.shade700 : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          onPressed: onTap,
          child: Text(granted ? 'Готово' : 'Включить'),
        ),
      ),
    );
  }
}