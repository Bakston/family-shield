import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:qr_flutter/qr_flutter.dart';


import '../../core/app_theme.dart';

const Color parentGlassPanel = Color(0x33FFFFFF);
const Color parentTextPrimary = Colors.white;

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
    return Stack(
      children: [
        // 1. Фирменный фоновый рисунок
        Positioned.fill(
          child: Image.asset(
            AppTheme.parentBackgroundAsset,
            fit: BoxFit.cover,
          ),
        ),
        // 2. Полупрозрачная вуаль
        Positioned.fill(
          child: Container(
            color: Colors.black.withValues(alpha: 0.45),
          ),
        ),
        // 3. Основной контент экрана
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: const IconThemeData(color: parentTextPrimary),
            title: Text(
              'Привязка: ${widget.childName}',
              style: const TextStyle(color: parentTextPrimary, fontWeight: FontWeight.bold),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Отсканируйте этот QR-код с помощью устройства ребёнка',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: parentTextPrimary),
                ),
                const SizedBox(height: 32),
                
                // Карточка с QR-кодом
                Center(
                  child: Card(
                    elevation: 8,
                    color: Colors.white.withValues(alpha: 0.92),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: QrImageView(
                        data: widget.childId, // Зашиваем уникальный ID ребенка
                        version: QrVersions.auto,
                        size: 240.0,
                        gapless: false,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                
                // Индикатор ожидания привязки в реальном времени
                StreamBuilder<DatabaseEvent>(
                  stream: FirebaseDatabase.instance.ref('children/${widget.childId}/isLinked').onValue,
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data!.snapshot.value == true) {
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
                          child: CircularProgressIndicator(strokeWidth: 2, color: parentTextPrimary),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Ожидание привязки устройства...',
                          style: TextStyle(color: parentTextPrimary, fontSize: 15),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 40),

                // Кнопка возврата назад
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    foregroundColor: parentTextPrimary,
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Назад на панель',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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