import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:device_apps_ng/device_apps_ng.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppControlService {
  static const platform = MethodChannel('com.example.family_shield/usage_stats');

  /// Получение списка установленных приложений и статистики через нативный канал
  static Future<void> syncInstalledApps() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final childId = prefs.getString('saved_child_id');
      if (childId == null || childId.isEmpty) return;

      // 1. Получаем список установленных сторонних приложений
      List<Application> apps = await DeviceApps.getInstalledApplications(
        includeAppIcons: false,
        includeSystemApps: false,
        onlyAppsWithLaunchIntent: true,
      );

      // 2. Запрашиваем статистику использования с нативной стороны Android
      Map<String, int> usageMap = {};
      try {
        final Map<dynamic, dynamic>? rawUsage = await platform.invokeMethod('getUsageStats');
        if (rawUsage != null) {
          usageMap = rawUsage.map((key, value) => MapEntry(
                key.toString(),
                int.tryParse(value.toString()) ?? 0,
              ));
        }
      } catch (e) {
        debugPrint('[AppControl] Ошибка получения UsageStats из Kotlin: $e');
      }

      // 3. Формируем структуру данных для отправки в Firebase
      Map<String, dynamic> appsData = {};
      for (var app in apps) {
        // Убрали проверку ApplicationWithIcon, чтобы обрабатывать все полученные приложения
        int timeSpentMs = usageMap[app.packageName] ?? 0;
        
        appsData[app.packageName.replaceAll('.', '_')] = {
          'appName': app.appName,
          'packageName': app.packageName,
          'timeSpentMinutes': (timeSpentMs / (1000 * 60)).round(),
          'isBlocked': false,
        };
      }

      // Добавим метку времени последней синхронизации
      appsData['_lastSyncTime'] = ServerValue.timestamp;

      // 4. Отправляем в Firebase
      await FirebaseDatabase.instance
          .ref('children/$childId/installedApps')
          .set(appsData);

      debugPrint('[AppControl] Список приложений и статистика успешно синхронизированы.');
    } catch (e) {
      debugPrint('[AppControl] Ошибка синхронизации приложений: $e');
    }
  }
}