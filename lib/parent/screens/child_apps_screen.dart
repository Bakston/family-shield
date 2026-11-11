import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class ChildAppsScreen extends StatelessWidget {
  final String childId;
  final String childName;

  const ChildAppsScreen({
    super.key,
    required this.childId,
    required this.childName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Приложения: $childName'),
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: FirebaseDatabase.instance
            .ref('children/$childId/installedApps')
            .onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  'Список приложений еще не синхронизирован с устройством ребёнка.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),
            );
          }

          final appsMap = Map<dynamic, dynamic>.from(
            snapshot.data!.snapshot.value as Map,
          );

          // Исключаем служебные поля (например, _lastSyncTime)
          final keys = appsMap.keys
              .where((key) => !key.toString().startsWith('_'))
              .toList();

          if (keys.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  'Список приложений пуст.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),
            );
          }

          return ListView.builder(
            itemCount: keys.length,
            itemBuilder: (context, index) {
              final key = keys[index];
              final appData = Map<dynamic, dynamic>.from(appsMap[key]);
              final appName = appData['appName'] ?? 'Приложение';
              final packageName = appData['packageName'] ?? '';
              final timeMinutes = appData['timeSpentMinutes'] ?? 0;
              final isBlocked = appData['isBlocked'] == true;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: ListTile(
                  leading: const Icon(Icons.android, color: Colors.green, size: 36),
                  title: Text(appName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(packageName, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 4),
                      Text('Время сегодня: $timeMinutes мин.', style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                  trailing: Switch(
                    value: isBlocked,
                    onChanged: (val) {
                      FirebaseDatabase.instance
                          .ref('children/$childId/installedApps/$key')
                          .update({'isBlocked': val});
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}