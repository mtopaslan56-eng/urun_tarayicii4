import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'ui_ortak.dart';

class TaramaEkrani extends StatefulWidget {
  const TaramaEkrani({super.key});

  @override
  State<TaramaEkrani> createState() => _TaramaEkraniState();
}

class _TaramaEkraniState extends State<TaramaEkrani> {
  final MobileScannerController _kontrol = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _islemYapildi = false;
  bool _fener = false;

  @override
  void dispose() {
    _kontrol.dispose();
    super.dispose();
  }

  void _algilandi(BarcodeCapture capture) {
    if (_islemYapildi) return;
    for (final barkod in capture.barcodes) {
      final kod = barkod.rawValue;
      if (kod != null && kod.isNotEmpty) {
        _islemYapildi = true;
        HapticFeedback.mediumImpact();
        Navigator.pop(context, kod);
        return;
      }
    }
  }

  Future<void> _fenerDegistir() async {
    await _kontrol.toggleTorch();
    if (mounted) setState(() => _fener = !_fener);
  }

  Widget _yuvarlakDugme(IconData ikon, VoidCallback onTap) {
    return Material(
      color: Colors.black.o(0.48),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(ikon, color: Colors.white, size: 25),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(controller: _kontrol, onDetect: _algilandi),
          CustomPaint(painter: _TaramaKaplamasi()),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    children: [
                      _yuvarlakDugme(Icons.close_rounded, () => Navigator.pop(context)),
                      const Spacer(),
                      _yuvarlakDugme(
                        _fener ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                        _fenerDegistir,
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  margin: const EdgeInsets.only(bottom: 48),
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.o(0.62),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Text(
                    'Barkod veya QR kodu çerçeveye hizalayın',
                    style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TaramaKaplamasi extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final genislik = size.width * 0.8;
    final yukseklik = genislik * 0.6;
    final pencere = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2 - 24),
      width: genislik,
      height: yukseklik,
    );
    final rrect = RRect.fromRectAndRadius(pencere, const Radius.circular(24));

    final karartma = Path.combine(
      PathOperation.difference,
      Path()..addRect(Offset.zero & size),
      Path()..addRRect(rrect),
    );
    canvas.drawPath(karartma, Paint()..color = Colors.black.o(0.56));

    final kose = Paint()
      ..color = Renk.vurgu
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    const l = 36.0;
    final r = pencere;
    canvas.drawPath(
      Path()
        ..moveTo(r.left, r.top + l)
        ..lineTo(r.left, r.top)
        ..lineTo(r.left + l, r.top),
      kose,
    );
    canvas.drawPath(
      Path()
        ..moveTo(r.right - l, r.top)
        ..lineTo(r.right, r.top)
        ..lineTo(r.right, r.top + l),
      kose,
    );
    canvas.drawPath(
      Path()
        ..moveTo(r.left, r.bottom - l)
        ..lineTo(r.left, r.bottom)
        ..lineTo(r.left + l, r.bottom),
      kose,
    );
    canvas.drawPath(
      Path()
        ..moveTo(r.right - l, r.bottom)
        ..lineTo(r.right, r.bottom)
        ..lineTo(r.right, r.bottom - l),
      kose,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
