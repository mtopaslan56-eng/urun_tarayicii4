import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class TaramaEkrani extends StatefulWidget {
  const TaramaEkrani({super.key});

  @override
  State<TaramaEkrani> createState() => _TaramaEkraniState();
}

class _TaramaEkraniState extends State<TaramaEkrani> {
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _islemYapildi = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Barkodu Okut'),
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
      ),
      body: MobileScanner(
        controller: controller,
        onDetect: (BarcodeCapture capture) {
          if (_islemYapildi) return;
          final List<Barcode> barkodlar = capture.barcodes;
          if (barkodlar.isNotEmpty) {
            final String? kod = barkodlar.first.rawValue;
            if (kod != null) {
              _islemYapildi = true;
              controller.stop();
              Navigator.pop(context, kod);
            }
          }
        },
      ),
    );
  }
}
