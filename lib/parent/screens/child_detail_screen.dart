import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';


import '../../core/app_theme.dart';
import '../../features/widgets/user_avatar_widget.dart';
import 'child_apps_screen.dart';
import 'child_profile_edit_screen.dart';

class ChildDetailScreen extends StatefulWidget {
  final String childId;
  final String childName;

  const ChildDetailScreen({
    super.key,
    required this.childId,
    required this.childName,
  });

  @override
  State<ChildDetailScreen> createState() => _ChildDetailScreenState();
}

class _ChildDetailScreenState extends State<ChildDetailScreen> {
  final MapController _mapController = MapController();
  bool _hasCenteredInitially = false;

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Неизвестно';
    final int? millis = int.tryParse(timestamp.toString());
    if (millis == null) return 'Неизвестно';

    final date = DateTime.fromMillisecondsSinceEpoch(millis);
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inSeconds < 60) {
      return 'Только что';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} мин. назад';
    } else {
      final hours = date.hour.toString().padLeft(2, '0');
      final minutes = date.minute.toString().padLeft(2, '0');
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      return '$day.$month в $hours:$minutes';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. ФИРМЕННЫЙ ФОН
        Positioned.fill(
          child: Image.asset(
            AppTheme.parentBackgroundAsset,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
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

        // 2. ОСНОВНОЙ ЭКРАН С ПОДПИСКОЙ НА ПРОФИЛЬ РЕБЁНКА
        StreamBuilder<DatabaseEvent>(
          stream: FirebaseDatabase.instance
              .ref('children/${widget.childId}')
              .onValue,
          builder: (context, childSnapshot) {
            Map<dynamic, dynamic> childData = {};
            if (childSnapshot.hasData &&
                childSnapshot.data!.snapshot.value != null) {
              childData = Map<dynamic, dynamic>.from(
                childSnapshot.data!.snapshot.value as Map,
              );
            }

            final currentChildName =
                childData['name']?.toString() ?? widget.childName;
            final childAvatarHash =
                childData['avatarHash']?.toString() ?? '';

            Map<dynamic, dynamic> locData = {};
            if (childData['location'] != null) {
              locData = Map<dynamic, dynamic>.from(childData['location'] as Map);
            }

            final double? lat =
                double.tryParse(locData['latitude']?.toString() ?? '');
            final double? lng =
                double.tryParse(locData['longitude']?.toString() ?? '');
            final double accuracy =
                double.tryParse(locData['accuracy']?.toString() ?? '0') ?? 0.0;
            final double speed =
                double.tryParse(locData['speed']?.toString() ?? '0') ?? 0.0;
            final dynamic timestamp = locData['timestamp'];

            final int batteryLevel =
                int.tryParse(locData['batteryLevel']?.toString() ?? '100') ??
                    100;
            final bool isCharging = locData['isCharging'] == true;

            final LatLng childPosition = (lat != null && lng != null)
                ? LatLng(lat, lng)
                : const LatLng(55.751244, 37.618423);

            if (lat != null && lng != null && !_hasCenteredInitially) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _mapController.move(childPosition, 16.0);
                _hasCenteredInitially = true;
              });
            }

            final speedKmh = (speed > 0 ? speed * 3.6 : 0.0).toStringAsFixed(1);

            return Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                iconTheme: const IconThemeData(color: Colors.white),
                title: Row(
                  children: [
                    UserAvatarWidget(
                      avatarBase64: childAvatarHash,
                      radius: 16,
                      fallbackIcon: Icons.child_care,
                      fallbackBackgroundColor: Colors.purple.shade400,
                      fallbackIconColor: Colors.white,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        currentChildName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                actions: [
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.settings, color: Colors.white),
                    tooltip: 'Управление и настройки',
                    onSelected: (value) {
                      if (value == 'profile') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChildProfileEditScreen(
                              childId: widget.childId,
                            ),
                          ),
                        );
                      } else if (value == 'geofences') {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Раздел геозон в разработке'),
                          ),
                        );
                      } else if (value == 'history') {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('История маршрутов в разработке'),
                          ),
                        );
                      } else if (value == 'apps') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChildAppsScreen(
                              childId: widget.childId,
                              childName: currentChildName,
                            ),
                          ),
                        );
                      }
                    },
                    itemBuilder: (BuildContext context) =>
                        <PopupMenuEntry<String>>[
                      PopupMenuItem<String>(
                        value: 'profile',
                        child: Row(
                          children: [
                            UserAvatarWidget(
                              avatarBase64: childAvatarHash,
                              radius: 13,
                              fallbackIcon: Icons.child_care,
                              fallbackBackgroundColor: Colors.purple.shade50,
                              fallbackIconColor: Colors.purple,
                            ),
                            const SizedBox(width: 12),
                            const Text('Профиль ребёнка'),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem<String>(
                        value: 'geofences',
                        child: Row(
                          children: [
                            Icon(Icons.fence, color: Colors.indigo),
                            SizedBox(width: 12),
                            Text('Безопасные геозоны'),
                          ],
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'history',
                        child: Row(
                          children: [
                            Icon(Icons.history, color: Colors.teal),
                            SizedBox(width: 12),
                            Text('История перемещений'),
                          ],
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'apps',
                        child: Row(
                          children: [
                            Icon(Icons.phonelink_lock, color: Colors.orange),
                            SizedBox(width: 12),
                            Text('Контроль приложений'),
                          ],
                        ),
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
                      // ВИДЖЕТ-ПАНЕЛЬ 1: ГЕОЛОКАЦИЯ
                      Expanded(
                        flex: 5,
                        child: Card(
                          elevation: 6,
                          color: Colors.white.withValues(alpha: 0.92),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(
                                          Icons.location_on,
                                          color: Colors.redAccent,
                                          size: 20,
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          'Геолокация',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      _formatTimestamp(timestamp),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Stack(
                                      children: [
                                        lat == null || lng == null
                                            ? Container(
                                                color: Colors.grey.shade100,
                                                child: const Center(
                                                  child: Padding(
                                                    padding:
                                                        EdgeInsets.all(20.0),
                                                    child: Text(
                                                      'Ожидание геопозиции от устройства ребёнка...',
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: TextStyle(
                                                        color: Colors.black54,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              )
                                            : FlutterMap(
                                                mapController: _mapController,
                                                options: MapOptions(
                                                  initialCenter: childPosition,
                                                  initialZoom: 16.0,
                                                ),
                                                children: [
                                                  TileLayer(
                                                    urlTemplate:
                                                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                                    userAgentPackageName:
                                                        'com.example.family_shield',
                                                  ),
                                                  if (accuracy > 0)
                                                    CircleLayer(
                                                      circles: [
                                                        CircleMarker(
                                                          point: childPosition,
                                                          radius: accuracy,
                                                          useRadiusInMeter:
                                                              true,
                                                          color: Colors.blue
                                                              .withValues(
                                                                  alpha: 0.18),
                                                          borderColor:
                                                              Colors.blueAccent,
                                                          borderStrokeWidth:
                                                              1.5,
                                                        ),
                                                      ],
                                                    ),
                                                  MarkerLayer(
                                                    markers: [
                                                      Marker(
                                                        point: childPosition,
                                                        width: 80,
                                                        height: 80,
                                                        child: const Icon(
                                                          Icons.location_on,
                                                          color:
                                                              Colors.redAccent,
                                                          size: 44,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                        if (lat != null && lng != null)
                                          Positioned(
                                            right: 10,
                                            bottom: 10,
                                            child: FloatingActionButton.small(
                                              heroTag: 'center_map',
                                              backgroundColor: Colors.white,
                                              child: const Icon(
                                                Icons.my_location,
                                                color: Colors.blue,
                                              ),
                                              onPressed: () {
                                                _mapController.move(
                                                  childPosition,
                                                  16.5,
                                                );
                                              },
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // ВИДЖЕТ-ПАНЕЛЬ 2: ТЕЛЕМЕТРИЯ
                      Card(
                        elevation: 4,
                        color: Colors.white.withValues(alpha: 0.9),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 14.0,
                            horizontal: 16.0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildMetricItem(
                                icon: isCharging
                                    ? Icons.battery_charging_full
                                    : batteryLevel > 20
                                        ? Icons.battery_full
                                        : Icons.battery_alert,
                                iconColor: batteryLevel > 20
                                    ? Colors.green
                                    : Colors.red,
                                label: 'Заряд',
                                value:
                                    '$batteryLevel%${isCharging ? ' ⚡' : ''}',
                              ),
                              _buildMetricItem(
                                icon: Icons.speed,
                                iconColor: Colors.blue.shade700,
                                label: 'Скорость',
                                value: '$speedKmh км/ч',
                              ),
                              _buildMetricItem(
                                icon: Icons.gps_fixed,
                                iconColor: Colors.indigo,
                                label: 'Точность',
                                value: accuracy > 0
                                    ? '${accuracy.toStringAsFixed(0)} м'
                                    : '—',
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // ВИДЖЕТ-ПАНЕЛЬ 3: СТАТИСТИКА УСТРОЙСТВА
                      Expanded(
                        flex: 3,
                        child: Card(
                          elevation: 4,
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
                                  'Статистика устройства',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const Divider(),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      _buildStatRow(
                                        icon: Icons.wifi_tethering,
                                        color: lat != null
                                            ? Colors.green
                                            : Colors.orange,
                                        title: 'Статус связи',
                                        value: lat != null
                                            ? 'В сети'
                                            : 'Ожидание сигнала',
                                      ),
                                      _buildStatRow(
                                        icon: Icons.shield_outlined,
                                        color: Colors.blue.shade700,
                                        title: 'Защита и контроль',
                                        value: 'Активны',
                                      ),
                                      _buildStatRow(
                                        icon: Icons.update,
                                        color: Colors.blueGrey,
                                        title: 'Последний отклик',
                                        value: _formatTimestamp(timestamp),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMetricItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: iconColor, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow({
    required IconData icon,
    required Color color,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}