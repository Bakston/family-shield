import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:battery_plus/battery_plus.dart';

class LocationService {
  static StreamSubscription<Position>? _positionSubscription;
  static bool _isTracking = false;
  static final Battery _battery = Battery();

  static bool get isTracking => _isTracking;

  /// Проверка включенного GPS и запрос разрешений на геолокацию
  static Future<bool> checkAndRequestPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      return false;
    }

    return true;
  }

  /// Запуск отслеживания и отправки координат и статуса батареи в Firebase
  static Future<bool> startChildLocationTracking({String? childId}) async {
    if (_isTracking) return true;

    String? targetChildId = childId;
    if (targetChildId == null || targetChildId.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      targetChildId = prefs.getString('saved_child_id');
    }

    if (targetChildId == null || targetChildId.isEmpty) {
      debugPrint('[LocationService] Ошибка: saved_child_id не найден.');
      return false;
    }

    final hasPermission = await checkAndRequestPermissions();
    if (!hasPermission) {
      debugPrint('[LocationService] Нет разрешений на геолокацию.');
      return false;
    }

    // 1. Сразу отправляем стартовую позицию и заряд батареи
    try {
      final initialPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      await _sendDataToFirebase(targetChildId, initialPosition);
    } catch (e) {
      debugPrint('[LocationService] Ошибка получения стартовой позиции: $e');
    }

    // 2. Настраиваем поток координат
    late LocationSettings locationSettings;

    if (defaultTargetPlatform == TargetPlatform.android) {
      locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 15,
        intervalDuration: const Duration(seconds: 30),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'Family Shield активен',
          notificationText: 'Передача геопозиции и состояния устройства',
          enableWakeLock: true,
        ),
      );
    } else {
      locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 15,
      );
    }

    await _positionSubscription?.cancel();
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) {
        _sendDataToFirebase(targetChildId!, position);
      },
      onError: (error) {
        debugPrint('[LocationService] Ошибка потока геолокации: $error');
      },
    );

    _isTracking = true;
    return true;
  }

  /// Запись координат и параметров батареи в Firebase
  static Future<void> _sendDataToFirebase(
    String childId,
    Position position,
  ) async {
    try {
      int batteryLevel = 100;
      bool isCharging = false;
      
      try {
        batteryLevel = await _battery.batteryLevel;
        final batteryState = await _battery.batteryState;
        isCharging = batteryState == BatteryState.charging ||
                    batteryState == BatteryState.full;
      } catch (e) {
        debugPrint('[LocationService] Ошибка чтения батареи: $e');
      }

      await FirebaseDatabase.instance
          .ref('children/$childId/location')
          .update({
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'speed': position.speed,
        'batteryLevel': batteryLevel,
        'isCharging': isCharging,
        'timestamp': ServerValue.timestamp,
      });
    } catch (e) {
      debugPrint('[LocationService] Ошибка записи в БД: $e');
    }
  }

  /// Остановка отслеживания
  static Future<void> stopTracking() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    _isTracking = false;
  }
}