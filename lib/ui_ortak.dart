import 'package:flutter/material.dart';
import 'analiz.dart';

extension RenkEk on Color {
  Color o(double opacity) => withAlpha((opacity.clamp(0.0, 1.0) * 255).round());
}

class Renk {
  static const Color ana = Color(0xFF0D9488);
  static const Color anaKoyu = Color(0xFF0F766E);
  static const Color vurgu = Color(0xFF14B8A6);
  static const Color iyi = Color(0xFF16A34A);
  static const Color orta = Color(0xFFD97706);
  static const Color kotu = Color(0xFFDC2626);
  static const Color notr = Color(0xFF64748B);
}

Color seviyeRengi(Seviye s) => switch (s) {
      Seviye.iyi => Renk.iyi,
      Seviye.orta => Renk.orta,
      Seviye.kotu => Renk.kotu,
      Seviye.bilinmiyor => Renk.notr,
    };

class Kart extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? renk;
  final Color? kenar;

  const Kart({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.renk,
    this.kenar,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final koyu = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: renk ?? (koyu ? Color.alphaBlend(cs.primary.o(0.07), cs.surface) : Colors.white),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: kenar ?? (koyu ? cs.outlineVariant.o(0.45) : const Color(0xFFE2ECEA)),
        ),
        boxShadow: koyu
            ? null
            : [
                BoxShadow(
                  color: const Color(0xFF0F172A).o(0.045),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: child,
    );
  }
}

class BolumBasligi extends StatelessWidget {
  final String metin;
  final String? altMetin;

  const BolumBasligi(this.metin, {super.key, this.altMetin});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          metin,
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
            color: cs.onSurface,
          ),
        ),
        if (altMetin != null) ...[
          const SizedBox(height: 2),
          Text(
            altMetin!,
            style: TextStyle(fontSize: 12.5, color: cs.onSurface.o(0.6)),
          ),
        ],
      ],
    );
  }
}

class AppLogo extends StatelessWidget {
  final double size;
  final bool acik;

  const AppLogo({super.key, this.size = 104, this.acik = false});

  @override
  Widget build(BuildContext context) {
    final ikonRenk = acik ? Renk.ana : Colors.white;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: acik ? Colors.white : null,
        gradient: acik
            ? null
            : const LinearGradient(
                colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            color: (acik ? Colors.black : Renk.ana).o(acik ? 0.18 : 0.35),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.qr_code_scanner_rounded, size: size * 0.54, color: ikonRenk),
          Positioned(
            bottom: size * 0.14,
            right: size * 0.14,
            child: Container(
              padding: EdgeInsets.all(size * 0.055),
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Icon(Icons.eco_rounded, size: size * 0.14, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
