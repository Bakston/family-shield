import 'package:flutter/material.dart';

class ChildPanelScreen extends StatelessWidget {
  final String childName;

  const ChildPanelScreen({
    super.key,
    this.childName = 'Ребёнок',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Панель Ребёнка'),
        automaticallyImplyLeading: false, // Запрещаем возвращаться назад кнопкой "назад"
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.verified_user, size: 80, color: Colors.green),
              const SizedBox(height: 24),
              Text(
                'Привет, $childName!',
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Устройство успешно привязано к семье.\nЗащита активна.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}