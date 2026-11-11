import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class ChildLocationMapScreen extends StatefulWidget {
  final String childId;
  final String childName;

  const ChildLocationMapScreen({
    super.key,
    required this.childId,
    required this.childName,
  });

  @override
  State<ChildLocationMapScreen> createState() => _ChildLocationMapScreenState();
}

class _ChildLocationMapScreenState extends State<ChildLocationMapScreen> {
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
        title: Text('Где ${widget.childName}?'),
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: FirebaseDatabase.instance
            .ref('children/${widget.childId}/location')
            .onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.location_searching, size: 72, color: Colors.orange),
                    const SizedBox(height: 16),
                    Text(
                      'Координаты от устройства «${widget.childName}» ещё не поступали.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Убедитесь, что на телефоне ребёнка открыто приложение Family Shield и разрешён доступ к геолокации.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          }

          final locData = Map<dynamic, dynamic>.from(
            snapshot.data!.snapshot.value as Map,
          );

          final double? lat = double.tryParse(locData['latitude'].toString());
          final double? lng = double.tryParse(locData['longitude'].toString());
          final double accuracy =
              double.tryParse(locData['accuracy']?.toString() ?? '0') ?? 0.0;
          final double speed =
              double.tryParse(locData['speed']?.toString() ?? '0') ?? 0.0;
          final dynamic timestamp = locData['timestamp'];

          if (lat == null || lng == null) {
            return const Center(child: Text('Некорректный формат координат'));
          }

          final LatLng childPosition = LatLng(lat, lng);

          // Автоматически перемещаем камеру к ребенку при получении первой точки
          if (!_hasCenteredInitially) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _mapController.move(childPosition, 16.0);
              _hasCenteredInitially = true;
            });
          }

          final speedKmh = (speed > 0 ? speed * 3.6 : 0.0).toStringAsFixed(1);

          return Stack(
            children: [
              FlutterMap(
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
                  // Круг точности сигнала GPS
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
                  // Маркер ребенка на карте
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: childPosition,
                        width: 110,
                        height: 85,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: Text(
                                widget.childName,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Icon(
                              Icons.location_on,
                              color: Colors.redAccent,
                              size: 44,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Нижняя информационная карточка
              Positioned(
                left: 16,
                right: 16,
                bottom: 24,
                child: Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.blueAccent,
                          child: Icon(Icons.child_care, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.childName,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Обновлено: ${_formatTimestamp(timestamp)}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                'Точность: ±${accuracy.toStringAsFixed(0)} м • Скорость: $speedKmh км/ч',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Центрировать на ребёнке',
                          icon: const Icon(Icons.my_location, color: Colors.blue, size: 28),
                          onPressed: () {
                            _mapController.move(childPosition, 16.5);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}