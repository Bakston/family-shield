import 'package:flutter/material.dart';
import 'package:battery_plus/battery_plus.dart';
import '../../core/app_theme.dart';
import '../../core/services/location_service.dart';
import '../../core/services/app_control_service.dart';
import '../../features/widgets/app_version_widget.dart';

class ChildPanelScreen extends StatefulWidget {
  final String childName;
  final String gender; // 'boy' или 'girl'

  const ChildPanelScreen({
    super.key,
    this.childName = 'Ребёнок',
    this.gender = 'boy',
  });

  @override
  State<ChildPanelScreen> createState() => _ChildPanelScreenState();
}

class _ChildPanelScreenState extends State<ChildPanelScreen> {
  final Battery _battery = Battery();
  bool _locationActive = false;
  int _batteryLevel = 100;
  bool _isCharging = false;
  
  // Индекс активной вкладки нижней панели
  // 0: Приложения, 1: Камера, (2: Телефон - по центру), 3: Чат, 4: Дашборд
  int _currentIndex = 4; // По умолчанию открыт Дашборд

  @override
  void initState() {
    super.initState();
    _initDeviceStatus();
  }

  Future<void> _initDeviceStatus() async {
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
    await AppControlService.syncInstalledApps();

    if (!mounted) return;
    setState(() {
      _locationActive = started;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Получаем палитру в зависимости от пола ребёнка
    final palette = AppTheme.getPalette('child', gender: widget.gender);

    return PopScope(
      canPop: false, // Запрещаем выход назад, так как это лаунчер
      child: Scaffold(
        backgroundColor: palette.background,
        appBar: AppBar(
          backgroundColor: palette.glassPanel,
          title: Row(
            children: [
              Icon(
                _locationActive ? Icons.shield : Icons.gpp_bad, 
                color: _locationActive ? palette.primaryAccent : AppTheme.warningColor, 
                size: 24,
              ),
              const SizedBox(width: 8),
              Text('Семейный Щит: ${widget.childName}', style: TextStyle(fontSize: 16, color: palette.textPrimary)),
              const Spacer(),
              Text(
                '$_batteryLevel%',
                style: TextStyle(
                  fontSize: 14, 
                  color: _batteryLevel > 20 ? AppTheme.successColor : AppTheme.errorColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                _isCharging ? Icons.battery_charging_full : Icons.battery_full,
                color: _batteryLevel > 20 ? AppTheme.successColor : AppTheme.errorColor,
                size: 20,
              ),
            ],
          ),
        ),
        body: SafeArea(
          child: _buildCurrentTabContent(palette),
        ),
        // Кастомная нижняя панель навигации (ButtonMenuBar)
        bottomNavigationBar: Container(
          height: 80,
          decoration: BoxDecoration(
            color: palette.glassPanel,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: const [
              BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, -4)),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.grid_view_rounded, 'Приложения', palette),
              _buildNavItem(1, Icons.camera_alt_rounded, 'Камера', palette),
              // Центральная большая кнопка телефона
              Transform.translate(
                offset: const Offset(0, -12),
                child: GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Вызов родителей...')),
                    );
                  },
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppTheme.successColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.successColor.withValues(alpha: 0.3),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.phone, color: Colors.white, size: 32),
                  ),
                ),
              ),
              _buildNavItem(3, Icons.chat_bubble_rounded, 'Чат', palette),
              _buildNavItem(4, Icons.star_rounded, 'Дашборд', palette),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, AppPalette palette) {
    final isSelected = _currentIndex == index;
    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? palette.primaryAccent : palette.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? palette.primaryAccent : palette.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentTabContent(AppPalette palette) {
    switch (_currentIndex) {
      case 0:
        return Center(child: Text('Раздел: Приложения', style: TextStyle(color: palette.textPrimary, fontSize: 18)));
      case 1:
        return Center(child: Text('Камера', style: TextStyle(color: palette.textPrimary, fontSize: 18)));
      case 3:
        return Center(child: Text('Семейный Чат', style: TextStyle(color: palette.textPrimary, fontSize: 18)));
      case 4:
      default:
        return _buildDashboardTab(palette);
    }
  }

  Widget _buildDashboardTab(AppPalette palette) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Виджет цели и баллов
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: palette.glassPanel,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: palette.primaryAccent.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Моя цель: Новый Скин', style: TextStyle(color: palette.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.warningColor.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('4500 / 7000 Б', style: TextStyle(color: AppTheme.warningColor, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: 4500 / 7000,
                    minHeight: 10,
                    backgroundColor: Colors.black26,
                    valueColor: AlwaysStoppedAnimation<Color>(palette.primaryAccent),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Экранное время сегодня
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: palette.glassPanel,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Экранное время сегодня', style: TextStyle(color: palette.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _buildTimeStatRow('Игры', '1.5 ч', 0.5, palette.primaryAccent, palette),
                const SizedBox(height: 8),
                _buildTimeStatRow('Соцсети', '0.5 ч', 0.2, palette.secondaryAccent, palette),
                const SizedBox(height: 8),
                _buildTimeStatRow('Учёба', '1.0 ч', 0.35, AppTheme.successColor, palette),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Активные задания
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: palette.glassPanel,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Активные задания', style: TextStyle(color: palette.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                CheckboxListTile(
                  title: Text('Сделать уроки', style: TextStyle(color: palette.textPrimary)),
                  value: false,
                  onChanged: (val) {},
                  controlAffinity: ListTileControlAffinity.trailing,
                ),
                CheckboxListTile(
                  title: Text('Убрать комнату', style: TextStyle(color: palette.textPrimary)),
                  value: false,
                  onChanged: (val) {},
                  controlAffinity: ListTileControlAffinity.trailing,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Center(child: AppVersionWidget()),
        ],
      ),
    );
  }

  Widget _buildTimeStatRow(String category, String time, double progress, Color color, AppPalette palette) {
    return Row(
      children: [
        SizedBox(width: 70, child: Text(category, style: TextStyle(color: palette.textSecondary, fontSize: 13))),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.black26,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(time, style: TextStyle(color: palette.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }
}