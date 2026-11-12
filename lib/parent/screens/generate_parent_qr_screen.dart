import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

const Color parentGlassPanel = Color(0x33FFFFFF);
const Color parentTextPrimary = Colors.white;

class GenerateParentQrScreen extends StatefulWidget {
  const GenerateParentQrScreen({super.key});

  @override
  State<GenerateParentQrScreen> createState() => _GenerateParentQrScreenState();
}

class _GenerateParentQrScreenState extends State<GenerateParentQrScreen> {
  String? _currentUid;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUid();
  }

  Future<void> _loadUid() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _currentUid = prefs.getString('user_uid');
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. Фирменный фоновый рисунок
        Positioned.fill(
          child: Image.asset(
            'assets/images/background_0002_001.jpg',
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
            title: const Text(
              'Пригласить второго родителя',
              style: TextStyle(color: parentTextPrimary, fontWeight: FontWeight.bold),
            ),
          ),
          body: Center(
            child: _isLoading
                ? const CircularProgressIndicator(color: parentTextPrimary)
                : (_currentUid == null || _currentUid!.isEmpty)
                    ? const Text(
                        'Ошибка: ID профиля не найден',
                        style: TextStyle(color: parentTextPrimary, fontSize: 16),
                      )
                    : Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Отсканируйте этот QR-код на телефоне второго родителя',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: parentTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Card(
                              elevation: 8,
                              color: Colors.white.withValues(alpha: 0.92),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: QrImageView(
                                  data: _currentUid!,
                                  version: QrVersions.auto,
                                  size: 240.0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
          ),
        ),
      ],
    );
  }
}