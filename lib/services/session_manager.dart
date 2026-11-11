import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyUserRole = 'user_role'; // 'parent' или 'child'
  static const String _keyUserId = 'user_id';
  static const String _keyFamilyId = 'family_id';

  /// Сохранение сессии после успешного входа или привязки по QR-коду
  static Future<void> saveSession({
    required String role,
    required String userId,
    String? familyId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, true);
    await prefs.setString(_keyUserRole, role);
    await prefs.setString(_keyUserId, userId);
    if (familyId != null) {
      await prefs.setString(_keyFamilyId, familyId);
    }
  }

  /// Получение сохраненных данных при старте приложения
  static Future getSession() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
    final role = prefs.getString(_keyUserRole);
    final userId = prefs.getString(_keyUserId);
    final familyId = prefs.getString(_keyFamilyId);

    return {
      'isLoggedIn': isLoggedIn,
      'role': role,
      'userId': userId,
      'familyId': familyId,
    };
  }

  /// Очистка сессии при выходе из аккаунта (Logout)
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}