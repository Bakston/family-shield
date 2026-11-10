import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ChildQrDisplayScreen extends StatefulWidget {
  final String childId;
  final String childName;

  const ChildQrDisplayScreen({
    super.key,
    required this.childId,
    required this.childName,
  });

  @override
  State<ChildQrDisplayScreen> createState() => _ChildQrDisplayScreenState();
}

class _ChildQrDisplayScreenState extends State<ChildQrDisplayScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Привязка: ${widget.childName}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
                'Отсканируйте этот QR-код с помощью телефона ребёнка на экране вступления в семью',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black87),
              ),
            const SizedBox(height: 32),
            
            // Карточка с QR-кодом
            Center(
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: QrImageView(
                    data: widget.childId, // Зашиваем уникальный ID ребенка
                    version: QrVersions.auto,
                    size: 240.0,
                    gapless: false,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Индикатор ожидания привязки в реальном времени
            StreamBuilder<DatabaseEvent>(
              stream: FirebaseDatabase.instance.ref('children/${widget.childId}/isLinked').onValue,
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.snapshot.value == true) {
                  // Как только ребенок сканирует код, статус изменится на true
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      _showSuccessDialog();
                    }
                  });
                }

                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Ожидание сканирования...',
                      style: TextStyle(color: Colors.grey, fontSize: 15),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 32),

            // Кнопка возврата назад
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('Назад на панель'),
            ),
          ],
        ),
      ),
    );
  }

  /// Показываем диалог успешной привязки
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Успешно!'),
        content: Text('Устройство ребёнка (${widget.childName}) успешно привязано к семье.'),
        actions: [
          ElevatedButton(
            onPressed: () {
              // Закрываем диалог и возвращаемся на Панель Родителя
              Navigator.pop(context); // закрыть диалог
              Navigator.pop(context); // закрыть экран QR
            },
            child: const Text('ОК'),
          ),
        ],
      ),
    );
  }
}