import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../main.dart';
import 'generate_parent_qr_screen.dart';
import 'scan_second_parent_screen.dart';
import '../../core/services/github_update_service.dart';

class ParentPanelScreen extends StatefulWidget {
  const ParentPanelScreen({super.key});

  @override
  State<ParentPanelScreen> createState() => _ParentPanelScreenState();
}

class _ParentPanelScreenState extends State<ParentPanelScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    final currentUid = currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Панель Родителя'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const AuthWrapper()),
                (route) => false,
              );
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // БЛОК ОТОБРАЖЕНИЯ СОСТАВА СЕМЬИ
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
                        'Состав семьи',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const Divider(),
                      Expanded(
                        child: StreamBuilder<DatabaseEvent>(
                          stream: FirebaseDatabase.instance.ref('users/$currentUid').onValue,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }

                            if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                              return const Center(child: Text('Профиль не найден'));
                            }

                            final myData = Map<dynamic, dynamic>.from(
                              snapshot.data!.snapshot.value as Map,
                            );
                            
                            final myName = myData['name'] ?? 'Вы';
                            final myRole = myData['familyRole'] ?? 'Родитель';
                            final linkedParentUid = myData['linkedParent'];

                            return ListView(
                              children: [
                                // Строка текущего пользователя
                                ListTile(
                                  dense: true,
                                  leading: const Icon(Icons.person, color: Colors.blue),
                                  title: Text(
                                    '$myRole, $myName (Вы)',
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                                  ),
                                ),
                                
                                // Если есть привязанный второй родитель, подгружаем его данные
                                if (linkedParentUid != null)
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
                                          '$partnerRole, $partnerName',
                                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                                        ),
                                      );
                                    },
                                  )
                                else
                                  const Padding(
                                    padding: EdgeInsets.only(top: 12.0),
                                    child: Text(
                                      'Второй родитель еще не подключен.',
                                      style: TextStyle(color: Colors.grey, fontSize: 13),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                              ],
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
                  // Проверяем, привязан ли второй родитель
                  final bool isParentLinked = snapshot.data?.snapshot.value != null;

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                        icon: const Icon(Icons.child_care),
                        label: const Text('ДОБАВИТЬ РЕБЁНКА'),
                        onPressed: () {},
                      ),
                      
                      // Кнопка добавляется только если второй родитель ЕЩЕ НЕ привязан
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
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const ScanSecondParentScreen()),
                            );
                          },
                        ),
                      ],

                      TextButton.icon(
                        style: TextButton.styleFrom(minimumSize: const Size.fromHeight(45)),
                        icon: const Icon(Icons.system_update),
                        label: const Text('Проверить наличие обновлений'),
                        onPressed: () {
                          GithubUpdateService.checkForUpdates(context, silent: false);
                        },
                      ),
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