import 'dart:async';
import 'package:firebase_database/firebase_database.dart';

class DatabaseService {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  /// 1. Сохранение профиля родителя после успешной SMS-авторизации
  Future<void> saveParentProfile({
    required String uid,
    required String phone,
    required String name,
    required String familyRole, // 'Мама' или 'Папа'
    String? birthDate,          // Дата рождения
  }) async {
    await _dbRef.child('users/$uid').set({
      'phone': phone,
      'name': name,
      'familyRole': familyRole,
      'birthDate': birthDate,
      'createdAt': ServerValue.timestamp,
    });
  }

  /// 2. Проверка, существует ли пользователь в базе (родитель)
  Future<bool> checkUserExists(String uid) async {
    final snapshot = await _dbRef.child('users/$uid').get();
    return snapshot.exists;
  }

  /// 3. Привязка детского устройства по отсканированному QR-коду родителя
  Future<void> pairChildDevice({
    required String childId,
    required String parentId,
    required String deviceName,
  }) async {
    await _dbRef.child('devices/$childId').set({
      'parentId': parentId,
      'deviceName': deviceName,
      'pairedAt': ServerValue.timestamp,
      'points': 0,
      'isOnline': true,
      'lastActive': ServerValue.timestamp,
    });

    await _dbRef.child('users/$parentId/children/$childId').set(true);
  }

  /// 4. Привязка второго родителя по семейному QR-коду
  Future<void> linkSecondParent({
    required String newParentUid,
    required String primaryParentUid,
  }) async {
    await _dbRef.child('users/$newParentUid/linkedParent').set(primaryParentUid);
    await _dbRef.child('users/$primaryParentUid/linkedParent').set(newParentUid);
  }

  /// 5. Получение потока данных о детях родителя
  Stream<DatabaseEvent> getChildrenStream(String parentId) {
    return _dbRef.child('users/$parentId/children').onValue;
  }

  /// 6. Получение данных конкретного устройства
  Future getDeviceData(String deviceId) async {
    final snapshot = await _dbRef.child('devices/$deviceId').get();
    if (snapshot.exists && snapshot.value != null) {
      return Map<dynamic, dynamic>.from(snapshot.value as Map);
    }
    return null;
  }
}