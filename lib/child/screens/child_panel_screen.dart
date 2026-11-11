import 'package:flutter/material.dart';
import 'package:battery_plus/battery_plus.dart';
import '../../core/services/github_update_service.dart';
import '../../core/services/location_service.dart';
import '../../core/services/app_control_service.dart';
import '../../features/widgets/app_version_widget.dart';

class ChildPanelScreen extends StatefulWidget {
  final String childName;

  const ChildPanelScreen({
    super.key,
    this.childName = 'Ребёнок',
  });

  @override
  State<ChildPanelScreen> createState() => _ChildPanelScreenState();
}

class _ChildPanelScreenState extends State<ChildPanelScreen> {
  final Battery _battery = Battery();
  bool _locationActive = false;
  bool _checkingLocation = true;
  int _batteryLevel = 100;
  bool _isCharging = false;

  @override
  void initState() {
    super.initState();
    _initDeviceStatus();
  }

  Future<void> _initDeviceStatus() async {
    setState(() => _checkingLocation = true);
    
    try {
      final level = await _battery.batteryLevel;
      final state = await _battery.batteryState;
      if (mounted) {
        setState(() {
          _batteryLevel = level;
          _isCharging = state == BatteryState.charging || state == BatteryState.full;
        });
      }
    } catch (_) {}

    final started = await LocationService.startChildLocationTracking();
    
    // Автоматическая синхронизация списка приложений и статистики в Firebase
    await AppControlService.syncInstalledApps();

    if (!mounted) return;
    setState(() {
      _locationActive = started;
      _checkingLocation = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Панель Ребёнка'),
          automaticallyImplyLeading: false,
          actions: [
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Row(
                  children: [
                    Icon(
                      _isCharging
                          ? Icons.battery_charging_full
                          : _batteryLevel > 20
                              ? Icons.battery_full
                              : Icons.battery_alert,
                      color: _batteryLevel > 20 ? Colors.green : Colors.red,
                      size: 22,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$_batteryLevel%',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.system_update),
              tooltip: 'Проверить обновления',
              onPressed: () {
                GithubUpdateService.checkForUpdates(context, silent: false);
              },
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const Spacer(),
                Icon(
                  _locationActive ? Icons.verified_user : Icons.location_off,
                  size: 80,
                  color: _locationActive ? Colors.green : Colors.orange,
                ),
                const SizedBox(height: 24),
                Text(
                  'Привет, ${widget.childName}!',
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  _checkingLocation
                      ? 'Подключение геолокации...'
                      : _locationActive
                          ? 'Устройство успешно привязано к семье.\nЗащита и геолокация активны.'
                          : 'Геолокация отключена.\nРазрешите доступ к местоположению для работы защиты.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: _locationActive ? Colors.grey[700] : Colors.orange[800],
                  ),
                ),
                if (!_checkingLocation && !_locationActive) ...[
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _initDeviceStatus,
                    icon: const Icon(Icons.my_location),
                    label: const Text('ВКЛЮЧИТЬ ГЕОЛОКАЦИЮ'),
                  ),
                ],
                const Spacer(),
                const AppVersionWidget(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}