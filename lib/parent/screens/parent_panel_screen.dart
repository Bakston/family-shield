import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../main.dart';
import 'generate_parent_qr_screen.dart';
import 'scan_second_parent_screen.dart';
import 'add_child_screen.dart'; // Импортируем экран добавления ребенка
import '../../core/services/github_update_service.dart';

class ParentPanelScreen extends StatefulWidget {
  const ParentPanelScreen({super.key});

  @override
  State<ParentPanelScreen> createState() => _ParentPanelScreenState();
}

class _ParentPanelScreenState extends State<ParentPanelScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  /// Метод для проверки и запроса доступа к камере перед открытием сканера
  Future<void> _handleScanButtonTap(BuildContext context) async {
    PermissionStatus cameraStatus = await Permission.camera.request();

    if (!context.mounted) return;

    if (cameraStatus.isGranted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ScanSecondParentScreen()),
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
          'Доступ к камере заблокирован в настройках устройства. Пожалуйста, разрешите доступ в настройках приложения для сканирования QR-кода.',
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
    final currentUid = currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Панель Родителя'),
        actions: [
          // Меню настроек (шестеренка)
          PopupMenuButton<String>(
            icon: const Icon(Icons.settings),
            tooltip: 'Настройки',
            onSelected: (value) async {
              if (value == 'update') {
                GithubUpdateService.checkForUpdates(context, silent: false);
              } else if (value == 'logout') {
                await FirebaseAuth.instance.signOut();
                if (!context.mounted) return;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const AuthWrapper()),
                  (route) => false,
                );
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'update',
                child: Row(
                  children: [
                    Icon(Icons.system_update, color: Colors.grey),
                    SizedBox(width: 12),
                    Text('Проверить обновления'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Выйти', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // БЛОК ОТОБРАЖЕНИЯ «МОЯ СЕМЬЯ»
            Expanded(
              flex: 2,
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Моя семья',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const Divider(),
                      Expanded(
                        child: StreamBuilder<DatabaseEvent>(
                          stream: FirebaseDatabase.instance.ref('users/$currentUid').onValue,
                          builder: (context, userSnapshot) {
                            if (userSnapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }

                            if (!userSnapshot.hasData || userSnapshot.data!.snapshot.value == null) {
                              return const Center(child: Text('Профиль не найден'));
                            }

                            final myData = Map<dynamic, dynamic>.from(
                              userSnapshot.data!.snapshot.value as Map,
                            );
                            
                            final myName = myData['name'] ?? 'Вы';
                            final myRole = myData['familyRole'] ?? 'Родитель';
                            final linkedParentUid = myData['linkedParent'];

                            // Слушаем весь узел children для фильтрации по обоим родителям
                            return StreamBuilder<DatabaseEvent>(
                              stream: FirebaseDatabase.instance.ref('children').onValue,
                              builder: (context, childrenSnapshot) {
                                List<Widget> familyMembers = [];

                                // 1. Строка текущего пользователя
                                familyMembers.add(
                                  ListTile(
                                    dense: true,
                                    leading: const Icon(Icons.person, color: Colors.blue),
                                    title: Text(
                                      '$myRole $myName (Вы)',
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                );

                                // 2. Второй родитель (если есть)
                                if (linkedParentUid != null) {
                                  familyMembers.add(
                                    FutureBuilder<DataSnapshot>(
                                      future: FirebaseDatabase.instance.ref('users/$linkedParentUid').get(),
                                      builder: (context, parentSnapshot) {
                                        if (!parentSnapshot.hasData || parentSnapshot.data!.value == null) {
                                          return const ListTile(
                                            dense: true,
                                            leading: Icon(Icons.person_outline, color: Colors.grey),
                                            title: Text('Загрузка второго родителя...'),
                                          );
                                        }

                                        final partnerData = Map<dynamic, dynamic>.from(
                                          parentSnapshot.data!.value as Map,
                                        );
                                        
                                        final partnerName = partnerData['name'] ?? 'Второй родитель';
                                        final partnerRole = partnerData['familyRole'] ?? 'Родитель';

                                        return ListTile(
                                          dense: true,
                                          leading: const Icon(Icons.person, color: Colors.green),
                                          title: Text(
                                            '$partnerRole $partnerName',
                                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                }

                                // 3. Добавляем детей, принадлежащих любому из родителей в семье
                                bool hasChildren = false;
                                if (childrenSnapshot.hasData && childrenSnapshot.data!.snapshot.value != null) {
                                  final childrenMap = Map<dynamic, dynamic>.from(
                                    childrenSnapshot.data!.snapshot.value as Map,
                                  );

                                  childrenMap.forEach((key, value) {
                                    final childData = Map<dynamic, dynamic>.from(value);
                                    final childParentUid = childData['parentUid'];

                                    // Проверяем, принадлежит ли ребенок текущему родителю или его партнёру
                                    bool isFamilyChild = (childParentUid == currentUid) || 
                                                         (linkedParentUid != null && childParentUid == linkedParentUid);

                                    if (isFamilyChild) {
                                      hasChildren = true;
                                      final childName = childData['name'] ?? 'Ребёнок';
                                      final familyRole = childData['familyRole'] ?? 'Ребёнок';
                                      final isLinked = childData['isLinked'] == true;

                                      familyMembers.add(
                                        ListTile(
                                          dense: true,
                                          leading: Icon(
                                            Icons.child_care,
                                            color: isLinked ? Colors.purple : Colors.orange,
                                          ),
                                          title: Text(
                                            '$familyRole $childName',
                                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                                          ),
                                          subtitle: Text(
                                            isLinked ? 'Устройство привязано' : 'Ожидание сканирования...',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isLinked ? Colors.green : Colors.orange[800],
                                            ),
                                          ),
                                        ),
                                      );
                                    }
                                  });
                                }

                                // Если ни второго родителя, ни детей в семье нет
                                if (linkedParentUid == null && !hasChildren) {
                                  familyMembers.add(
                                    const Padding(
                                      padding: EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        'В семье пока нет других участников.',
                                        style: TextStyle(color: Colors.grey, fontSize: 13),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  );
                                }

                                return ListView(
                                  children: familyMembers,
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // КНОПКИ УПРАВЛЕНИЯ
            Expanded(
              flex: 3,
              child: StreamBuilder<DatabaseEvent>(
                stream: FirebaseDatabase.instance.ref('users/$currentUid/linkedParent').onValue,
                builder: (context, snapshot) {
                  final bool isParentLinked = snapshot.data?.snapshot.value != null;

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Кнопка добавления ребенка открывает анкету
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                        icon: const Icon(Icons.child_care),
                        label: const Text('ДОБАВИТЬ РЕБЁНКА'),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const AddChildScreen()),
                          );
                        },
                      ),
                      
                      // Кнопки добавления родителя показываются только если второй родитель еще НЕ привязан
                      if (!isParentLinked) ...[
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                          icon: const Icon(Icons.person_add),
                          label: const Text('ДОБАВИТЬ РОДИТЕЛЯ'),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const GenerateParentQrScreen()),
                            );
                          },
                        ),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                          icon: const Icon(Icons.qr_code_scanner),
                          label: const Text('ВСТУПИТЬ В СЕМЬЮ'),
                          onPressed: () => _handleScanButtonTap(context),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}