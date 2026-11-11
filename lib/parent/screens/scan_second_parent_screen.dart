import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/services/database_service.dart';
import 'parent_panel_screen.dart';

class ScanSecondParentScreen extends StatefulWidget {
  const ScanSecondParentScreen({super.key});

  @override
  State<ScanSecondParentScreen> createState() => _ScanSecondParentScreenState();
}

class _ScanSecondParentScreenState extends State<ScanSecondParentScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final TextEditingController _codeController = TextEditingController();
  
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );
  
  bool _isHandled = false;

  @override
  void dispose() {
    _controller.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _processParentUid(String primaryParentUid) async {
    final trimmedUid = primaryParentUid.trim();
    if (trimmedUid.isEmpty) return;

    setState(() => _isHandled = true);
    await _controller.stop();

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId != null) {
      try {
        await _databaseService.linkSecondParent(
          newParentUid: currentUserId,
          primaryParentUid: trimmedUid,
        );

        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Вы успешно присоединились к семье!')),
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const ParentPanelScreen()),
          (route) => false,
        );
      } catch (e) {
        if (!mounted) return;
        setState(() => _isHandled = false);
        try {
          _controller.start();
        } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка привязки: $e')),
        );
      }
    }
  }

  void _showManualEntryDialog() {
    _codeController.clear();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Ввод кода родителя'),
        content: TextField(
          controller: _codeController,
          decoration: const InputDecoration(
            labelText: 'Введите UID первого родителя',
            hintText: 'Например: abc123xyz...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _processParentUid(_codeController.text);
            },
            child: const Text('Подтвердить'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Привязка второго родителя'),
        actions: [
          IconButton(
            icon: const Icon(Icons.keyboard),
            tooltip: 'Ввести код текстом',
            onPressed: _showManualEntryDialog,
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (BarcodeCapture capture) async {
              if (_isHandled) return;
              final List<Barcode> barcodes = capture.barcodes;
              
              for (final barcode in barcodes) {
                final primaryParentUid = barcode.rawValue;
                if (primaryParentUid != null && primaryParentUid.isNotEmpty) {
                  await _processParentUid(primaryParentUid);
                  break;
                }
              }
            },
            errorBuilder: (context, error, child) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    'Не удалось запустить камеру: ${error.errorCode.name}\n\n'
                    'Убедитесь, что приложению предоставлен доступ к камере в настройках устройства.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                  ),
                ),
              );
            },
          ),
          Positioned(
            bottom: 40,
            left: 24,
            right: 24,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              onPressed: _showManualEntryDialog,
              icon: const Icon(Icons.keyboard),
              label: const Text(
                'ВВЕСТИ КОД ТЕКСТОМ',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}