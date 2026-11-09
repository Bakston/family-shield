import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  bool _isScanned = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Сканирование QR-кода'),
        centerTitle: true,
      ),
      body: MobileScanner(
        onDetect: (capture) {
          if (_isScanned) return; // Защита от многократного срабатывания
          
          final List<Barcode> barcodes = capture.barcodes;
          for (final barcode in barcodes) {
            if (barcode.rawValue != null) {
              _isScanned = true;
              final scannedData = barcode.rawValue!;
              
              // Возвращаем считанные данные на предыдущий экран
              Navigator.pop(context, scannedData);
              break;
            }
          }
        },
      ),
    );
  }
}