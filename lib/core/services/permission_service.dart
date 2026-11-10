import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  /// Запрос доступа к камере и геолокации при первом запуске или по необходимости
  static Future<bool> requestCameraAndLocationPermissions() async {
    // Запрашиваем камеру и точную геолокацию одновременно
    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      Permission.location,
    ].request();

    // Проверяем, оба ли разрешения были предоставлены
    bool isCameraGranted = statuses[Permission.camera]?.isGranted ?? false;
    bool isLocationGranted = statuses[Permission.location]?.isGranted ?? false;

    return isCameraGranted && isLocationGranted;
  }

  /// Проверка, выданы ли разрешения ранее
  static Future<bool> checkPermissions() async {
    var cameraStatus = await Permission.camera.status;
    var locationStatus = await Permission.location.status;

    return cameraStatus.isGranted && locationStatus.isGranted;
  }
}