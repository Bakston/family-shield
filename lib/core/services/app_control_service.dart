import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:device_apps_ng/device_apps_ng.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppControlService {
  static const platform = MethodChannel('com.example.family_shield/usage_stats');
  static const adminChannel = MethodChannel('com.example.family_shield/device_admin');

  /// Критические системные пакеты, которые по умолчанию заблокированы для ребёнка
  static const Set<String> restrictedSystemPackages = {
    'com.familyshield.family_shield',
    'com.android.settings',
    'com.android.vending',
    'com.google.android.packageinstaller',
    'com.android.packageinstaller',
    'com.miui.securitycenter',
    'com.coloros.safecenter',
    'com.huawei.systemmanager',
  };

  /// Синхронизация полного списка приложений для родителя с сохранением флагов блокировки
  static Future<void> syncInstalledApps() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final childId = prefs.getString('saved_child_id');
      if (childId == null || childId.isEmpty) return;

      // 1. Читаем текущие настройки блокировки, заданные родителем
      final existingSnap = await FirebaseDatabase.instance
          .ref('children/$childId/installedApps')
          .get();
      final Map<String, bool> existingBlockedMap = {};
      if (existingSnap.exists && existingSnap.value != null) {
        final oldMap = Map<dynamic, dynamic>.from(existingSnap.value as Map);
        oldMap.forEach((key, val) {
          if (val is Map && val.containsKey('isBlocked')) {
            existingBlockedMap[key.toString()] = val['isBlocked'] == true;
          }
        });
      }

      // 2. Получаем весь список приложений с лаунч-интентом (включая системные для родителя)
      final List<Application> apps = await DeviceApps.getInstalledApplications(
        includeAppIcons: false,
        includeSystemApps: true,
        onlyAppsWithLaunchIntent: true,
      );

      // 3. Запрашиваем статистику использования из Kotlin
      Map<String, int> usageMap = {};
      try {
        final Map<dynamic, dynamic>? rawUsage =
            await platform.invokeMethod('getUsageStats');
        if (rawUsage != null) {
          usageMap = rawUsage.map((key, value) => MapEntry(
                key.toString(),
                int.tryParse(value.toString()) ?? 0,
              ));
        }
      } catch (e) {
        debugPrint('[AppControl] Ошибка получения UsageStats из Kotlin: $e');
      }

      // 4. Формируем полный список для Firebase и актуальный чёрный список для Android
      final Map<String, dynamic> appsData = {};
      final List<String> blockedPackagesList = [...restrictedSystemPackages];

      for (final app in apps) {
        // Не показываем только сам Family Shield
        if (app.packageName == 'com.familyshield.family_shield') continue;

        final int timeSpentMs = usageMap[app.packageName] ?? 0;
        final String safeKey = app.packageName.replaceAll('.', '_');

        // Если родитель уже задавал флаг — берём его; иначе для опасных системных пакетов ставим true
        final bool isBlocked = existingBlockedMap.containsKey(safeKey)
            ? existingBlockedMap[safeKey]!
            : restrictedSystemPackages.contains(app.packageName);

        if (isBlocked) {
          blockedPackagesList.add(app.packageName);
        }

        appsData[safeKey] = {
          'appName': app.appName,
          'packageName': app.packageName,
          'timeSpentMinutes': (timeSpentMs / (1000 * 60)).round(),
          'isBlocked': isBlocked,
        };
      }

      appsData['_lastSyncTime'] = ServerValue.timestamp;

      await FirebaseDatabase.instance
          .ref('children/$childId/installedApps')
          .set(appsData);

      await updateNativeBlockedPackages(blockedPackagesList);
    } catch (e) {
      debugPrint('[AppControl] Ошибка синхронизации приложений: $e');
    }
  }

  /// Передача списка заблокированных пакетов в нативный слой Android
  static Future<void> updateNativeBlockedPackages(List<String> packages) async {
    try {
      final fullList = {...restrictedSystemPackages, ...packages}.toList();
      await adminChannel.invokeMethod('setBlockedPackages', {
        'packages': fullList,
      });
    } catch (e) {
      debugPrint('[AppControl] Ошибка передачи blockedPackages в Kotlin: $e');
    }
  }
}