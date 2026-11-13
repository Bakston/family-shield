import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:device_apps_ng/device_apps_ng.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/app_theme.dart';
import '../../core/services/location_service.dart';
import '../../core/services/app_control_service.dart';
import '../../features/widgets/user_avatar_widget.dart';
import '../../features/auth/initial_session_wrapper.dart';
import 'child_permissions_screen.dart';

class ChildPanelScreen extends StatefulWidget {
  final String childName;

  const ChildPanelScreen({
    super.key,
    required this.childName,
  });

  @override
  State<ChildPanelScreen> createState() => _ChildPanelScreenState();
}

class _ChildPanelScreenState extends State<ChildPanelScreen>
    with WidgetsBindingObserver {
  String _childId = '';
  String _cachedGender = 'boy';
  bool _isLocationActive = false;
  List<Application> _installedApps = [];
  bool _isLoadingApps = true;

  late Timer _clockTimer;
  Timer? _syncTimer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _now = DateTime.now());
      }
    });
    _initLauncher();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clockTimer.cancel();
    _syncTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _ensureServicesRunning();
      _loadDeviceApps();
    }
  }

  Future<void> _initLauncher() async {
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getString('saved_child_id') ?? '';
    final savedGender = prefs.getString('saved_child_gender') ?? 'boy';

    if (mounted) {
      setState(() {
        _childId = savedId;
        _cachedGender = savedGender;
      });
    }

    await _loadDeviceApps();

    if (savedId.isEmpty) return;

    await _ensureServicesRunning();

    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(minutes: 15), (_) async {
      await AppControlService.syncInstalledApps();
      await _loadDeviceApps();
    });
  }

  Future<void> _ensureServicesRunning() async {
    if (_childId.isEmpty) return;

    bool tracking = LocationService.isTracking;
    if (!tracking) {
      tracking = await LocationService.startChildLocationTracking(
        childId: _childId,
      );
    }

    await AppControlService.syncInstalledApps();

    if (!mounted) return;
    setState(() {
      _isLocationActive = tracking;
    });
  }

  Future<void> _loadDeviceApps() async {
    try {
      final apps = await DeviceApps.getInstalledApplications(
        includeAppIcons: true,
        includeSystemApps: true,
        onlyAppsWithLaunchIntent: true,
      );

      apps.removeWhere(
        (app) => AppControlService.restrictedSystemPackages
            .contains(app.packageName),
      );
      apps.sort(
        (a, b) => a.appName.toLowerCase().compareTo(b.appName.toLowerCase()),
      );

      if (!mounted) return;
      setState(() {
        _installedApps = apps;
        _isLoadingApps = false;
      });
    } catch (e) {
      debugPrint('Ошибка загрузки приложений: $e');
      if (mounted) setState(() => _isLoadingApps = false);
    }
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _formatRussianDate(DateTime dt) {
    const weekdays = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    const months = [
      'Января',
      'Февраля',
      'Марта',
      'Апреля',
      'Мая',
      'Июня',
      'Июля',
      'Августа',
      'Сентября',
      'Октября',
      'Ноября',
      'Декабря',
    ];
    return '${weekdays[dt.weekday - 1]}, ${dt.day} ${months[dt.month - 1]}';
  }

  void _launchDockAction(String keyword, List<Application> allowedApps) {
    for (final app in allowedApps) {
      final pkg = app.packageName.toLowerCase();
      final name = app.appName.toLowerCase();
      if (pkg.contains(keyword) || name.contains(keyword)) {
        DeviceApps.openApp(app.packageName);
        return;
      }
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Приложение недоступно или заблокировано')),
    );
  }

  void _showAppsDrawer(AppPalette palette, List<Application> allowedApps) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        height: MediaQuery.of(context).size.height * 0.78,
        decoration: BoxDecoration(
          color: palette.background.withValues(alpha: 0.96),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(
            color: palette.primaryAccent.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: palette.textSecondary.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Разрешённые приложения',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: palette.textPrimary,
                ),
              ),
            ),
            Expanded(
              child: _isLoadingApps
                  ? Center(
                      child: CircularProgressIndicator(
                        color: palette.primaryAccent,
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.78,
                      ),
                      itemCount: allowedApps.length,
                      itemBuilder: (context, index) {
                        final app = allowedApps[index];
                        return InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            Navigator.pop(sheetContext);
                            DeviceApps.openApp(app.packageName);
                          },
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 54,
                                height: 54,
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: palette.glassPanel,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: palette.primaryAccent
                                        .withValues(alpha: 0.25),
                                  ),
                                ),
                                child: app is ApplicationWithIcon
                                    ? Image.memory(
                                        app.icon,
                                        fit: BoxFit.contain,
                                      )
                                    : Icon(
                                        Icons.apps,
                                        color: palette.primaryAccent,
                                        size: 30,
                                      ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                app.appName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: palette.textPrimary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showParentAccessDialog(String parentUid) {
    final passController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.admin_panel_settings, color: Colors.blue),
            SizedBox(width: 8),
            Text('Доступ для родителя'),
          ],
        ),
        content: TextField(
          controller: passController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'Пароль родителя',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              final entered = passController.text.trim();
              if (entered.isEmpty) return;

              bool valid = false;
              if (parentUid.isNotEmpty) {
                final parentSnap = await FirebaseDatabase.instance
                    .ref('users/$parentUid')
                    .get();
                if (parentSnap.exists && parentSnap.value != null) {
                  final pData =
                      Map<dynamic, dynamic>.from(parentSnap.value as Map);
                  if (pData['password']?.toString() == entered) {
                    valid = true;
                  }
                }
              }

              if (!dialogContext.mounted) return;
              if (!valid) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Неверный пароль родителя'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              Navigator.pop(dialogContext);
              _showParentOptionsSheet();
            },
            child: const Text('Войти'),
          ),
        ],
      ),
    );
  }

  void _showParentOptionsSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Настройки устройства ребёнка',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.lock_open, color: Colors.orange),
                title: const Text('Разблокировать настройки на 5 минут'),
                subtitle: const Text(
                  'Временно отключает перехват системных настроек для обслуживания',
                ),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await AppControlService.adminChannel.invokeMethod(
                    'setParentBypass',
                    {'minutes': 5},
                  );
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Доступ к настройкам устройства открыт на 5 минут',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.verified_user, color: Colors.blue),
                title: const Text('Проверить системные разрешения'),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await AppControlService.adminChannel.invokeMethod(
                    'setParentBypass',
                    {'minutes': 5},
                  );
                  if (!mounted) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChildPermissionsScreen(
                        childName: widget.childName,
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.link_off, color: Colors.red),
                title: const Text(
                  'Отвязать устройство ребёнка',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await AppControlService.adminChannel.invokeMethod(
                    'setParentBypass',
                    {'minutes': 5},
                  );
                  await LocationService.stopTracking();
                  if (_childId.isNotEmpty) {
                    await FirebaseDatabase.instance
                        .ref('children/$_childId/isLinked')
                        .set(false);
                  }
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('user_type');
                  await prefs.remove('saved_child_id');
                  await prefs.remove('saved_child_name');
                  await prefs.remove('saved_child_gender');

                  if (!mounted) return;
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const InitialSessionWrapper(),
                    ),
                    (route) => false,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: StreamBuilder<DatabaseEvent>(
        stream: _childId.isEmpty
            ? const Stream.empty()
            : FirebaseDatabase.instance.ref('children/$_childId').onValue,
        builder: (context, snapshot) {
          Map<dynamic, dynamic> childData = {};
          if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
            childData = Map<dynamic, dynamic>.from(
              snapshot.data!.snapshot.value as Map,
            );
          }

          final familyRole = childData['familyRole']?.toString();
          final currentGender = familyRole != null
              ? AppTheme.resolveGenderFromRole(familyRole)
              : _cachedGender;

          final palette = AppTheme.getPalette('child', gender: currentGender);

          final currentName =
              childData['name']?.toString() ?? widget.childName;
          final avatarHash = childData['avatarHash']?.toString() ?? '';
          final parentUid = childData['parentUid']?.toString() ?? '';

          final goalMap = childData['goal'] is Map
              ? Map<dynamic, dynamic>.from(childData['goal'] as Map)
              : {};
          final goalTitle = goalMap['title']?.toString() ?? 'Новая цель';
          final int currentPoints =
              int.tryParse(goalMap['current']?.toString() ?? '4500') ?? 4500;
          final int targetPoints =
              int.tryParse(goalMap['target']?.toString() ?? '7000') ?? 7000;
          final double goalProgress = targetPoints > 0
              ? (currentPoints / targetPoints).clamp(0.0, 1.0)
              : 0.0;

          final Set<String> blockedPackages = {
            ...AppControlService.restrictedSystemPackages,
          };
          int totalMinutes = 0;
          if (childData['installedApps'] != null) {
            final appsMap = Map<dynamic, dynamic>.from(
              childData['installedApps'] as Map,
            );
            appsMap.forEach((key, val) {
              if (val is Map) {
                totalMinutes +=
                    int.tryParse(val['timeSpentMinutes']?.toString() ?? '0') ??
                        0;
                if (val['isBlocked'] == true) {
                  final pkg = val['packageName']?.toString() ?? '';
                  if (pkg.isNotEmpty) blockedPackages.add(pkg);
                }
              }
            });
          }

          // Обновляем список запрещённых пакетов в нативном AccessibilityService
          AppControlService.updateNativeBlockedPackages(
            blockedPackages.toList(),
          );

          final allowedApps = _installedApps
              .where((app) => !blockedPackages.contains(app.packageName))
              .toList();

          return Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  palette.backgroundAsset,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(color: palette.background);
                  },
                ),
              ),
              Positioned.fill(
                child: Container(
                  color: palette.background.withValues(alpha: 0.45),
                ),
              ),
              Scaffold(
                backgroundColor: Colors.transparent,
                body: SafeArea(
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                          children: [
                            // ВИДЖЕТ 1: ЧАСЫ, ДАТА И ПРОФИЛЬ РЕБЁНКА
                            _buildGlassCard(
                              palette: palette,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _formatTime(_now),
                                        style: TextStyle(
                                          fontSize: 42,
                                          fontWeight: FontWeight.bold,
                                          color: palette.textPrimary,
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                      Text(
                                        _formatRussianDate(_now),
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: palette.textSecondary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  GestureDetector(
                                    onLongPress: () =>
                                        _showParentAccessDialog(parentUid),
                                    child: Column(
                                      children: [
                                        UserAvatarWidget(
                                          avatarBase64: avatarHash,
                                          radius: 26,
                                          fallbackIcon: Icons.child_care,
                                          fallbackBackgroundColor: palette
                                              .secondaryAccent
                                              .withValues(alpha: 0.3),
                                          fallbackIconColor:
                                              palette.primaryAccent,
                                          borderWidth: 2,
                                          borderColor: _isLocationActive
                                              ? AppTheme.successColor
                                              : AppTheme.warningColor,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          currentName,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: palette.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),

                            // ВИДЖЕТ 2: МОЯ ЦЕЛЬ И БАЛЛЫ
                            _buildGlassCard(
                              palette: palette,
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 56,
                                    height: 56,
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        CircularProgressIndicator(
                                          value: goalProgress,
                                          strokeWidth: 6,
                                          backgroundColor: palette.textSecondary
                                              .withValues(alpha: 0.25),
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            palette.primaryAccent,
                                          ),
                                        ),
                                        Center(
                                          child: Text(
                                            '${(goalProgress * 100).round()}%',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: palette.textPrimary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Моя цель:',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: palette.textSecondary,
                                          ),
                                        ),
                                        Text(
                                          goalTitle,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: palette.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '$currentPoints / $targetPoints Б',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: palette.primaryAccent,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: palette.secondaryAccent
                                          .withValues(alpha: 0.25),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: palette.primaryAccent
                                            .withValues(alpha: 0.4),
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.emoji_events,
                                      color: palette.primaryAccent,
                                      size: 28,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),

                            // ВИДЖЕТ 3: ЭКРАННОЕ ВРЕМЯ СЕГОДНЯ
                            _buildGlassCard(
                              palette: palette,
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Экранное время сегодня',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: palette.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        '${(totalMinutes / 60).toStringAsFixed(1)} ч',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: palette.primaryAccent,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  _buildUsageRow(
                                    palette: palette,
                                    label: 'Игры',
                                    hoursText: '1,5ч',
                                    progress: 0.75,
                                    barColor: palette.primaryAccent,
                                  ),
                                  const SizedBox(height: 8),
                                  _buildUsageRow(
                                    palette: palette,
                                    label: 'Соцсети',
                                    hoursText: '0,5ч',
                                    progress: 0.30,
                                    barColor: palette.secondaryAccent,
                                  ),
                                  const SizedBox(height: 8),
                                  _buildUsageRow(
                                    palette: palette,
                                    label: 'Учёба',
                                    hoursText: '1,0ч',
                                    progress: 0.50,
                                    barColor: AppTheme.successColor,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),

                            // ВИДЖЕТ 4: АКТИВНЫЕ ЗАДАНИЯ
                            _buildGlassCard(
                              palette: palette,
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Активные задания',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: palette.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  _buildTaskItem(
                                    palette: palette,
                                    icon: Icons.menu_book,
                                    title: 'Сделать уроки',
                                    isDone: true,
                                  ),
                                  const SizedBox(height: 8),
                                  _buildTaskItem(
                                    palette: palette,
                                    icon: Icons.home_work,
                                    title: 'Уборка комнаты',
                                    isDone: false,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // НИЖНИЙ КАПСУЛЬНЫЙ ДОК-БАР
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: palette.glassPanel,
                            borderRadius: BorderRadius.circular(36),
                            border: Border.all(
                              color: palette.primaryAccent
                                  .withValues(alpha: 0.35),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildDockButton(
                                palette: palette,
                                icon: Icons.apps_rounded,
                                label: 'Приложения',
                                onTap: () =>
                                    _showAppsDrawer(palette, allowedApps),
                              ),
                              _buildDockButton(
                                palette: palette,
                                icon: Icons.camera_alt_rounded,
                                label: 'Камера',
                                onTap: () =>
                                    _launchDockAction('camera', allowedApps),
                              ),
                              GestureDetector(
                                onTap: () =>
                                    _launchDockAction('dialer', allowedApps),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 54,
                                      height: 54,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: palette.secondaryAccent
                                            .withValues(alpha: 0.35),
                                        border: Border.all(
                                          color: palette.primaryAccent,
                                          width: 2.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: palette.primaryAccent
                                                .withValues(alpha: 0.45),
                                            blurRadius: 12,
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        Icons.call_rounded,
                                        color: palette.primaryAccent,
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Телефон',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: palette.primaryAccent,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _buildDockButton(
                                palette: palette,
                                icon: Icons.chat_bubble_rounded,
                                label: 'Чат',
                                onTap: () =>
                                    _launchDockAction('messag', allowedApps),
                              ),
                              _buildDockButton(
                                palette: palette,
                                icon: Icons.shield_rounded,
                                label: 'Дашборд',
                                onTap: _ensureServicesRunning,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGlassCard({
    required AppPalette palette,
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: palette.glassPanel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: palette.primaryAccent.withValues(alpha: 0.25),
          width: 1.2,
        ),
      ),
      child: child,
    );
  }

  Widget _buildUsageRow({
    required AppPalette palette,
    required String label,
    required String hoursText,
    required double progress,
    required Color barColor,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 68,
          child: Text(
            label,
            style: TextStyle(fontSize: 13, color: palette.textPrimary),
          ),
        ),
        SizedBox(
          width: 38,
          child: Text(
            hoursText,
            style: TextStyle(fontSize: 12, color: palette.textSecondary),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: palette.textSecondary.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTaskItem({
    required AppPalette palette,
    required IconData icon,
    required String title,
    required bool isDone,
  }) {
    return Row(
      children: [
        Icon(icon, color: palette.primaryAccent, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: palette.textPrimary,
              decoration: isDone ? TextDecoration.lineThrough : null,
            ),
          ),
        ),
        Icon(
          isDone ? Icons.check_box : Icons.check_box_outline_blank,
          color: isDone ? palette.primaryAccent : palette.textSecondary,
          size: 22,
        ),
      ],
    );
  }

  Widget _buildDockButton({
    required AppPalette palette,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: palette.secondaryAccent.withValues(alpha: 0.25),
            ),
            child: Icon(icon, color: palette.primaryAccent, size: 22),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: palette.textPrimary),
          ),
        ],
      ),
    );
  }
}