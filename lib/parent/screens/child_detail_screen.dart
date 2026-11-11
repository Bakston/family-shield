import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'child_apps_screen.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.childName),
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: FirebaseDatabase.instance
            .ref('children/${widget.childId}/location')
            .onValue,
        builder: (context, snapshot) {
          Map<dynamic, dynamic> locData = {};
          if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
            locData = Map<dynamic, dynamic>.from(
              snapshot.data!.snapshot.value as Map,
            );
          }

          final double? lat = double.tryParse(locData['latitude']?.toString() ?? '');
          final double? lng = double.tryParse(locData['longitude']?.toString() ?? '');
          final double accuracy = double.tryParse(locData['accuracy']?.toString() ?? '0') ?? 0.0;
          final double speed = double.tryParse(locData['speed']?.toString() ?? '0') ?? 0.0;
          final dynamic timestamp = locData['timestamp'];
          
          final int batteryLevel = int.tryParse(locData['batteryLevel']?.toString() ?? '100') ?? 100;
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

          return Column(
            children: [
              // 1. КАРТА
              Expanded(
                flex: 5,
                child: Stack(
                  children: [
                    lat == null || lng == null
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24.0),
                              child: Text(
                                'Ожидание геопозиции от устройства ребёнка...',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey, fontSize: 16),
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
                                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.example.family_shield',
                              ),
                              if (accuracy > 0)
                                CircleLayer(
                                  circles: [
                                    CircleMarker(
                                      point: childPosition,
                                      radius: accuracy,
                                      useRadiusInMeter: true,
                                      color: Colors.blue.withValues(alpha: 0.18),
                                      borderColor: Colors.blueAccent,
                                      borderStrokeWidth: 1.5,
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
                                      color: Colors.redAccent,
                                      size: 44,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                    if (lat != null && lng != null)
                      Positioned(
                        right: 16,
                        bottom: 16,
                        child: FloatingActionButton.small(
                          heroTag: 'center_map',
                          backgroundColor: Colors.white,
                          child: const Icon(Icons.my_location, color: Colors.blue),
                          onPressed: () {
                            _mapController.move(childPosition, 16.5);
                          },
                        ),
                      ),
                  ],
                ),
              ),

              // 2. СОСТОЯНИЕ УСТРОЙСТВА (БАТАРЕЯ И СВЯЗЬ)
              Container(
                padding: const EdgeInsets.all(16.0),
                color: Colors.grey[100],
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isCharging
                              ? Icons.battery_charging_full
                              : batteryLevel > 20
                                  ? Icons.battery_full
                                  : Icons.battery_alert,
                          color: batteryLevel > 20 ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$batteryLevel% ${isCharging ? '(зар.)' : ''}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.speed, color: Colors.blueGrey, size: 20),
                        const SizedBox(width: 6),
                        Text('$speedKmh км/ч'),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.access_time, color: Colors.blueGrey, size: 20),
                        const SizedBox(width: 6),
                        Text(_formatTimestamp(timestamp)),
                      ],
                    ),
                  ],
                ),
              ),

              // 3. МЕНЮ УПРАВЛЕНИЯ
              Expanded(
                flex: 4,
                child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    const Text(
                      'Управление и безопасность',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.fence, color: Colors.indigo),
                            title: const Text('Безопасные геозоны'),
                            subtitle: const Text('Школа, дом и уведомления о входе'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Раздел геозон в разработке')),
                              );
                            },
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.history, color: Colors.teal),
                            title: const Text('История перемещений'),
                            subtitle: const Text('Маршрут за сегодня'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('История маршрутов в разработке')),
                              );
                            },
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.phonelink_lock, color: Colors.orange),
                            title: const Text('Контроль приложений'),
                            subtitle: const Text('Настройка блокировок и лимитов'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChildAppsScreen(
                                    childId: widget.childId,
                                    childName: widget.childName,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}