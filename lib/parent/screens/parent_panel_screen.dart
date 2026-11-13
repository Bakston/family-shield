import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/initial_session_wrapper.dart';
import 'generate_parent_qr_screen.dart';
import 'scan_second_parent_screen.dart';
import 'add_child_screen.dart';
import 'child_detail_screen.dart';
import 'child_qr_display_screen.dart';
import 'parent_profile_screen.dart';

import '../../core/app_theme.dart';
import '../../core/services/github_update_service.dart';
import '../../features/widgets/app_version_widget.dart';
import '../../features/widgets/user_avatar_widget.dart';

// Глобальные дизайн-константы в стиле стекломорфизма
const Color parentGlassPanel = Color(0x33FFFFFF);
const Color parentTextPrimary = Colors.white;

class ParentPanelScreen extends StatefulWidget {
  const ParentPanelScreen({super.key});

  @override
  State<ParentPanelScreen> createState() => _ParentPanelScreenState();
}

class _ParentPanelScreenState extends State<ParentPanelScreen> {
  String _currentUid = '';
  String _localName = 'Вы';
  String _localRole = 'Родитель';
  String _localBirthDate = '';
  String _localAvatarHash = '';

  late Timer _clockTimer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadLocalProfile();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    super.dispose();
  }

  Future<void> _loadLocalProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('user_uid') ?? '';
    final name = prefs.getString('user_name') ?? 'Вы';
    final role = prefs.getString('user_role') ?? 'Родитель';
    final birthDate = prefs.getString('user_birth_date') ?? '';
    final avatarHash = prefs.getString('user_avatar_hash') ?? '';

    if (uid.isNotEmpty) {
      await prefs.setBool('parent_profile_ready_$uid', true);
    }

    if (!mounted) return;
    setState(() {
      _currentUid = uid;
      _localName = name;
      _localRole = role;
      _localBirthDate = birthDate;
      _localAvatarHash = avatarHash;
    });
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String _formatRussianDate(DateTime dt) {
    const weekdays = [
      'Понедельник',
      'Вторник',
      'Среда',
      'Четверг',
      'Пятница',
      'Суббота',
      'Воскресенье',
    ];
    const months = [
      'января',
      'февраля',
      'марта',
      'апреля',
      'мая',
      'июня',
      'июля',
      'августа',
      'сентября',
      'октября',
      'ноября',
      'декабря',
    ];
    final weekday = weekdays[dt.weekday - 1];
    final month = months[dt.month - 1];
    return '$weekday, ${dt.day} $month ${dt.year}';
  }

  /// Запрос камеры перед открытием сканера второго родителя
  Future<void> _handleScanButtonTap() async {
    PermissionStatus cameraStatus = await Permission.camera.request();

    if (!mounted) return;

    if (cameraStatus.isGranted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ScanSecondParentScreen()),
      );
    } else if (cameraStatus.isPermanentlyDenied) {
      _showSettingsDialog();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Для сканирования QR-кода необходим доступ к камере.'),
        ),
      );
    }
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Требуется доступ к камере'),
        content: const Text(
          'Доступ к камере заблокирован в настройках устройства. Пожалуйста, разрешите доступ в настройках приложения для сканирования QR-кода.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              openAppSettings();
            },
            child: const Text('Открыть настройки'),
          ),
        ],
      ),
    );
  }

  /// Модальное окно выбора способа добавления второго члена семьи
  void _showAddSecondMemberSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Добавить второго члена семьи',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(60),
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: parentTextPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                icon: const Icon(Icons.qr_code),
                label: const Text('ДЛЯ ПОДКЛЮЧЕНИЯ'),
                onPressed: () {
                  Navigator.pop(sheetContext);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const GenerateParentQrScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(60),
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: parentTextPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('ДЛЯ ВСТУПЛЕНИЯ'),
                onPressed: () {
                  Navigator.pop(sheetContext);
                  _handleScanButtonTap();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Отображение карточки взрослого члена семьи при клике
  void _showMemberInfoDialog({
    required String name,
    required String role,
    required String birthDate,
    required String avatarHash,
    required bool isMe,
  }) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            UserAvatarWidget(
              avatarBase64: avatarHash,
              radius: 20,
              fallbackIcon: Icons.person,
              fallbackBackgroundColor:
                  isMe ? Colors.blue.shade50 : Colors.green.shade50,
              fallbackIconColor: isMe ? Colors.blue : Colors.green,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text('$role $name')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Статус: ${isMe ? "Ваш профиль" : "Второй родитель"}'),
            const SizedBox(height: 8),
            Text(
              'Дата рождения: ${birthDate.isNotEmpty ? birthDate : "Не указана"}',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  /// Подтверждение и покидание семьи (удаление привязки в БД с сохранением сессии)
  void _confirmLeaveFamily() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Покинуть семью?'),
        content: const Text(
          'Вы уверены, что хотите разорвать семейные связи на этом устройстве? Ваш профиль останется активным.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade800,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(dialogContext);
              _performLeaveFamily();
            },
            child: const Text('Покинуть'),
          ),
        ],
      ),
    );
  }

  Future<void> _performLeaveFamily() async {
    if (_currentUid.isEmpty) return;

    try {
      final db = FirebaseDatabase.instance.ref();
      final userSnapshot = await db.child('users/$_currentUid').get();
      if (userSnapshot.exists && userSnapshot.value != null) {
        final userData = Map<dynamic, dynamic>.from(userSnapshot.value as Map);
        final linkedParentUid = userData['linkedParent'];

        if (linkedParentUid != null) {
          await db.child('users/$linkedParentUid/linkedParent').remove();
        }
      }

      await db.child('users/$_currentUid/linkedParent').remove();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Вы успешно покинули семью')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка при выходе из семьи: $e')));
    }
  }

  /// Закрытие текущей сессии (ВЫХОД) с сохранением привязки устройства для быстрого ПИН-кода
  Future<void> _performLogout() async {
    final prefs = await SharedPreferences.getInstance();
    if (_currentUid.isNotEmpty) {
      await prefs.setString('saved_device_uid', _currentUid);
    }
    await prefs.remove('user_type');
    await prefs.remove('user_uid');
    await prefs.remove('user_avatar_hash');

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const InitialSessionWrapper()),
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
            errorBuilder: (context, error, stackTrace) {
              debugPrint('ОШИБКА ЗАГРУЗКИ ФОНА: $error');
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.blueGrey.shade900, Colors.blue.shade900],
                  ),
                ),
              );
            },
          ),
        ),
        Positioned.fill(
          child: Container(color: Colors.black.withValues(alpha: 0.4)),
        ),
        StreamBuilder<DatabaseEvent>(
          stream: _currentUid.isEmpty
              ? const Stream.empty()
              : FirebaseDatabase.instance.ref('users/$_currentUid').onValue,
          builder: (context, userSnapshot) {
            Map<dynamic, dynamic> myData = {};
            if (userSnapshot.hasData &&
                userSnapshot.data!.snapshot.value != null) {
              myData = Map<dynamic, dynamic>.from(
                userSnapshot.data!.snapshot.value as Map,
              );
            }

            final myName = myData['name']?.toString() ?? _localName;
            final myRole = myData['familyRole']?.toString() ?? _localRole;
            final myBirthDate =
                myData['birthDate']?.toString() ?? _localBirthDate;
            final myAvatarHash =
                myData['avatarHash']?.toString() ?? _localAvatarHash;
            final linkedParentUid = myData['linkedParent'];
            final bool hasSecondParent = linkedParentUid != null;

            return StreamBuilder<DatabaseEvent>(
              stream: FirebaseDatabase.instance.ref('children').onValue,
              builder: (context, childrenSnapshot) {
                bool hasFamilyChildren = false;
                List<MapEntry<String, Map<dynamic, dynamic>>> familyChildren = [];

                if (childrenSnapshot.hasData &&
                    childrenSnapshot.data!.snapshot.value != null) {
                  final childrenMap = Map<dynamic, dynamic>.from(
                    childrenSnapshot.data!.snapshot.value as Map,
                  );

                  childrenMap.forEach((key, value) {
                    final childData = Map<dynamic, dynamic>.from(value);
                    final childParentUid = childData['parentUid'];

                    final bool isFamilyChild =
                        (childParentUid == _currentUid) ||
                            (linkedParentUid != null &&
                                childParentUid == linkedParentUid);

                    if (isFamilyChild) {
                      hasFamilyChildren = true;
                      familyChildren.add(MapEntry(key.toString(), childData));
                    }
                  });
                }

                final bool isInFamily = hasSecondParent || hasFamilyChildren;

                return Scaffold(
                  backgroundColor: Colors.transparent,
                  appBar: AppBar(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    title: const Text(
                      'Панель Родителя',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    iconTheme: const IconThemeData(color: Colors.white),
                    actions: [
                      // Меню настроек с аватаркой в строке «Профиль»
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.settings, color: Colors.white),
                        tooltip: 'Настройки',
                        onSelected: (value) async {
                          if (value == 'profile') {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ParentProfileScreen(),
                              ),
                            );
                            _loadLocalProfile();
                          } else if (value == 'update') {
                            GithubUpdateService.checkForUpdates(
                              context,
                              silent: false,
                            );
                          } else if (value == 'leave_family') {
                            _confirmLeaveFamily();
                          } else if (value == 'logout') {
                            _performLogout();
                          }
                        },
                        itemBuilder: (BuildContext context) =>
                            <PopupMenuEntry<String>>[
                          PopupMenuItem<String>(
                            value: 'profile',
                            child: Row(
                              children: [
                                UserAvatarWidget(
                                  avatarBase64: myAvatarHash,
                                  radius: 13,
                                  fallbackIcon: Icons.account_circle,
                                  fallbackBackgroundColor: Colors.blue.shade50,
                                  fallbackIconColor: Colors.blue,
                                ),
                                const SizedBox(width: 12),
                                const Text('Профиль'),
                              ],
                            ),
                          ),
                          const PopupMenuItem<String>(
                            value: 'update',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.system_update,
                                  color: Colors.blueGrey,
                                ),
                                SizedBox(width: 12),
                                Text('Проверить обновления'),
                              ],
                            ),
                          ),
                          if (isInFamily)
                            PopupMenuItem<String>(
                              value: 'leave_family',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.exit_to_app,
                                    color: Colors.orange.shade800,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Покинуть семью',
                                    style: TextStyle(
                                      color: Colors.orange.shade800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const PopupMenuItem<String>(
                            value: 'logout',
                            child: Row(
                              children: [
                                Icon(Icons.logout, color: Colors.redAccent),
                                SizedBox(width: 12),
                                Text('Выход'),
                              ],
                            ),
                          ),
                          const PopupMenuDivider(),
                          const PopupMenuItem<String>(
                            enabled: false,
                            child: Center(child: AppVersionWidget()),
                          ),
                        ],
                      ),
                    ],
                  ),
                  body: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // БЛОК 1: ПАНЕЛЬ ВРЕМЕНИ И ДАТЫ
                          Card(
                            elevation: 4,
                            color: Colors.white.withValues(alpha: 0.9),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 14.0,
                                horizontal: 20.0,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _formatTime(_now),
                                        style: const TextStyle(
                                          fontSize: 36,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _formatRussianDate(_now),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.access_time_filled,
                                      size: 28,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // БЛОК 2: ПАНЕЛЬ СО СТАТИСТИКОЙ
                          Card(
                            elevation: 4,
                            color: Colors.white.withValues(alpha: 0.9),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(14.0),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.shield_rounded,
                                      size: 36,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                'Уровень защиты семьи',
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              '85%',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.green,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: LinearProgressIndicator(
                                            value: 0.85,
                                            minHeight: 8,
                                            backgroundColor:
                                                Colors.grey.shade300,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              Colors.green.shade600,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        const Text(
                                          'Мониторинг активен • Сводка за сегодня в норме',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // БЛОК 3: ЭКРАН СОСТАВА СЕМЬИ С АВАТАРКАМИ
                          Expanded(
                            child: Card(
                              elevation: 6,
                              color: Colors.white.withValues(alpha: 0.92),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(14.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Состав семьи',
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const Divider(),
                                    Expanded(
                                      child: _currentUid.isEmpty
                                          ? const Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            )
                                          : ListView(
                                              children: [
                                                // 1. Текущий родитель
                                                ListTile(
                                                  dense: true,
                                                  leading: UserAvatarWidget(
                                                    avatarBase64: myAvatarHash,
                                                    radius: 18,
                                                    fallbackIcon: Icons.person,
                                                    fallbackBackgroundColor:
                                                        Colors.blue.shade50,
                                                    fallbackIconColor:
                                                        Colors.blue,
                                                  ),
                                                  title: Text(
                                                    '$myRole $myName (Вы)',
                                                    style: const TextStyle(
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  subtitle:
                                                      myBirthDate.isNotEmpty
                                                          ? Text(
                                                              'Дата рождения: $myBirthDate',
                                                            )
                                                          : null,
                                                  trailing: const Icon(
                                                    Icons.info_outline,
                                                    size: 20,
                                                    color: Colors.blueGrey,
                                                  ),
                                                  onTap: () =>
                                                      _showMemberInfoDialog(
                                                    name: myName,
                                                    role: myRole,
                                                    birthDate: myBirthDate,
                                                    avatarHash: myAvatarHash,
                                                    isMe: true,
                                                  ),
                                                ),

                                                // 2. Второй родитель (если привязан)
                                                if (hasSecondParent)
                                                  FutureBuilder<DataSnapshot>(
                                                    future: FirebaseDatabase
                                                        .instance
                                                        .ref(
                                                          'users/$linkedParentUid',
                                                        )
                                                        .get(),
                                                    builder: (
                                                      context,
                                                      parentSnapshot,
                                                    ) {
                                                      if (!parentSnapshot
                                                              .hasData ||
                                                          parentSnapshot
                                                                  .data!
                                                                  .value ==
                                                              null) {
                                                        return const ListTile(
                                                          dense: true,
                                                          leading: Icon(
                                                            Icons
                                                                .person_outline,
                                                            color: Colors.grey,
                                                          ),
                                                          title: Text(
                                                            'Загрузка второго члена семьи...',
                                                          ),
                                                        );
                                                      }

                                                      final partnerData = Map<
                                                          dynamic,
                                                          dynamic>.from(
                                                        parentSnapshot
                                                                .data!
                                                                .value
                                                            as Map,
                                                      );

                                                      final partnerName =
                                                          partnerData['name']
                                                                  ?.toString() ??
                                                              'Родитель';
                                                      final partnerRole =
                                                          partnerData['familyRole']
                                                                  ?.toString() ??
                                                              'Родитель';
                                                      final partnerBirth =
                                                          partnerData['birthDate']
                                                                  ?.toString() ??
                                                              '';
                                                      final partnerAvatar =
                                                          partnerData['avatarHash']
                                                                  ?.toString() ??
                                                              '';

                                                      return ListTile(
                                                        dense: true,
                                                        leading:
                                                            UserAvatarWidget(
                                                          avatarBase64:
                                                              partnerAvatar,
                                                          radius: 18,
                                                          fallbackIcon:
                                                              Icons.person,
                                                          fallbackBackgroundColor:
                                                              Colors.green
                                                                  .shade50,
                                                          fallbackIconColor:
                                                              Colors.green,
                                                        ),
                                                        title: Text(
                                                          '$partnerRole $partnerName',
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 15,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                        ),
                                                        trailing: const Icon(
                                                          Icons.chevron_right,
                                                          color: Colors.grey,
                                                        ),
                                                        onTap: () =>
                                                            _showMemberInfoDialog(
                                                          name: partnerName,
                                                          role: partnerRole,
                                                          birthDate:
                                                              partnerBirth,
                                                          avatarHash:
                                                              partnerAvatar,
                                                          isMe: false,
                                                        ),
                                                      );
                                                    },
                                                  ),

                                                // 3. Дети
                                                ...familyChildren.map((entry) {
                                                  final childId = entry.key;
                                                  final childData = entry.value;
                                                  final childName =
                                                      childData['name']
                                                              ?.toString() ??
                                                          'Ребёнок';
                                                  final familyRole =
                                                      childData['familyRole']
                                                              ?.toString() ??
                                                          'Ребёнок';
                                                  final childAvatar =
                                                      childData['avatarHash']
                                                              ?.toString() ??
                                                          '';
                                                  final isLinked =
                                                      childData['isLinked'] ==
                                                          true;

                                                  return ListTile(
                                                    dense: true,
                                                    leading: UserAvatarWidget(
                                                      avatarBase64: childAvatar,
                                                      radius: 18,
                                                      fallbackIcon: isLinked
                                                          ? Icons.child_care
                                                          : Icons.hourglass_top,
                                                      fallbackBackgroundColor:
                                                          isLinked
                                                              ? Colors
                                                                  .purple.shade50
                                                              : Colors.orange
                                                                  .shade50,
                                                      fallbackIconColor: isLinked
                                                          ? Colors.purple
                                                          : Colors
                                                              .orange.shade800,
                                                    ),
                                                    title: Text(
                                                      '$familyRole $childName',
                                                      style: const TextStyle(
                                                        fontSize: 15,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                    subtitle: Text(
                                                      isLinked
                                                          ? 'Устройство привязано'
                                                          : 'Ожидает привязки...',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: isLinked
                                                            ? Colors
                                                                .green.shade700
                                                            : Colors.orange
                                                                .shade800,
                                                        fontWeight: isLinked
                                                            ? FontWeight.normal
                                                            : FontWeight.w500,
                                                      ),
                                                    ),
                                                    trailing: const Icon(
                                                      Icons.chevron_right,
                                                      color: Colors.grey,
                                                    ),
                                                    onTap: () {
                                                      if (isLinked) {
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (context) =>
                                                                ChildDetailScreen(
                                                              childId: childId,
                                                              childName:
                                                                  childName,
                                                            ),
                                                          ),
                                                        );
                                                      } else {
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (context) =>
                                                                ChildQrDisplayScreen(
                                                              childId: childId,
                                                              childName:
                                                                  childName,
                                                            ),
                                                          ),
                                                        );
                                                      }
                                                    },
                                                  );
                                                }),
                                              ],
                                            ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // БЛОК 4: НИЖНИЕ КНОПКИ УПРАВЛЕНИЯ
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(60),
                                  backgroundColor: parentGlassPanel,
                                  foregroundColor: parentTextPrimary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                    side: BorderSide(
                                      color: Colors.white.withValues(
                                        alpha: 0.3,
                                      ),
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                                icon: const Icon(Icons.child_care),
                                label: const Text(
                                  'ДОБАВИТЬ РЕБЁНКА',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const AddChildScreen(),
                                    ),
                                  );
                                },
                              ),
                              if (!hasSecondParent) ...[
                                const SizedBox(height: 8),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: const Size.fromHeight(60),
                                    backgroundColor: parentGlassPanel,
                                    foregroundColor: parentTextPrimary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                      side: BorderSide(
                                        color: Colors.white.withValues(
                                          alpha: 0.3,
                                        ),
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                  icon: const Icon(Icons.person_add),
                                  label: const Text(
                                    'ВТОРОЙ РОДИТЕЛЬ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  onPressed: _showAddSecondMemberSheet,
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}