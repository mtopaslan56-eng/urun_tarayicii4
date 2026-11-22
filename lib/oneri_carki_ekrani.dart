import 'dart:math';
import 'package:flutter/material.dart';
import 'ui_ortak.dart';

class HealthyItem {
  final String name;
  final String kisaAd;
  final IconData ikon;
  final String benefit;
  final String sporNotu;
  final String diyetNotu;
  final String kategori;
  final Color color;

  const HealthyItem({
    required this.name,
    required this.kisaAd,
    required this.ikon,
    required this.benefit,
    required this.sporNotu,
    required this.diyetNotu,
    required this.kategori,
    required this.color,
  });
}

const List<HealthyItem> _tumOneriler = [
  HealthyItem(
    name: 'Sade Kefir',
    kisaAd: 'Kefir',
    ikon: Icons.water_drop_outlined,
    benefit: 'Probiyotik içeriğiyle bağırsak sağlığını ve sindirimi destekler.',
    sporNotu: 'Antrenman sonrası sıvı ve protein desteği sağlar.',
    diyetNotu: 'Düşük kalorili ve uzun süre tok tutmaya yardımcıdır.',
    kategori: 'Sindirim',
    color: Color(0xFF0284C7),
  ),
  HealthyItem(
    name: 'Yulaf Ezmesi',
    kisaAd: 'Yulaf',
    ikon: Icons.spa_outlined,
    benefit: 'Beta-glukan lifi ve kompleks karbonhidrat kaynağıdır.',
    sporNotu: 'Antrenman öncesi dengeli ve kalıcı enerji verir.',
    diyetNotu: 'Yüksek lif oranı sayesinde açlık krizlerini azaltır.',
    kategori: 'Sporcu',
    color: Color(0xFF0D9488),
  ),
  HealthyItem(
    name: 'Çiğ Badem',
    kisaAd: 'Badem',
    ikon: Icons.grain_outlined,
    benefit: 'E vitamini, doymamış yağlar ve mineral açısından zengindir.',
    sporNotu: 'Enerji yoğunluğu yüksek, iyi bir ara öğün alternatifidir.',
    diyetNotu: 'Porsiyonu kontrol ederek tok kalmaya yardımcı olur.',
    kategori: 'Kilo Verme',
    color: Color(0xFFD97706),
  ),
  HealthyItem(
    name: 'Şekersiz Yeşil Çay',
    kisaAd: 'Yeşil Çay',
    ikon: Icons.local_cafe_outlined,
    benefit: 'Polifenol ve antioksidan açısından zengindir.',
    sporNotu: 'Hafif kafein içeriğiyle odaklanmayı destekleyebilir.',
    diyetNotu: 'Neredeyse sıfır kalorilidir; şekerli içecekler yerine idealdir.',
    kategori: 'Kilo Verme',
    color: Color(0xFF16A34A),
  ),
  HealthyItem(
    name: 'Süzme Yoğurt',
    kisaAd: 'Süzme Yoğurt',
    ikon: Icons.restaurant_outlined,
    benefit: 'Yüksek protein ve kalsiyum kaynağıdır.',
    sporNotu: 'Kas onarımı ve toparlanma için güçlü protein desteği sunar.',
    diyetNotu: 'Yüksek tokluk etkisiyle diyet öğünlerinde çok uygundur.',
    kategori: 'Sporcu',
    color: Color(0xFF2563EB),
  ),
  HealthyItem(
    name: 'Chia & Kefir',
    kisaAd: 'Chia',
    ikon: Icons.eco_outlined,
    benefit: 'Lif, omega-3 ve probiyotik bileşenlerini bir araya getirir.',
    sporNotu: 'Sindirimi rahatlatır ve dengeli enerji sunar.',
    diyetNotu: 'Yüksek lifiyle tokluk hissini artırmaya destek olur.',
    kategori: 'Sindirim',
    color: Color(0xFF7C3AED),
  ),
];

class OneriCarkiSekmesi extends StatefulWidget {
  final VoidCallback? onAyarlarTiklandi;

  const OneriCarkiSekmesi({super.key, this.onAyarlarTiklandi});

  @override
  State<OneriCarkiSekmesi> createState() => _OneriCarkiSekmesiState();
}

class _OneriCarkiSekmesiState extends State<OneriCarkiSekmesi> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Animation<double> _animation = const AlwaysStoppedAnimation<double>(0);
  String _seciliKategori = 'Tümü';
  bool _donuyor = false;
  HealthyItem? _sonOneri;
  double _mevcutAci = 0;

  static const List<String> _kategoriler = ['Tümü', 'Sporcu', 'Kilo Verme', 'Sindirim'];

  List<HealthyItem> get _aktifListe {
    if (_seciliKategori == 'Tümü') return _tumOneriler;
    final filtreli = _tumOneriler.where((x) => x.kategori == _seciliKategori).toList();
    return filtreli.isEmpty ? _tumOneriler : filtreli;
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3800),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _carkiCevir() {
    if (_donuyor) return;
    final liste = _aktifListe;
    if (liste.isEmpty) return;

    final rng = Random();
    final turlar = 5 + rng.nextInt(4);
    final hedefAci = _mevcutAci + (turlar * 2 * pi) + (rng.nextDouble() * 2 * pi);

    setState(() => _donuyor = true);

    _animation = Tween<double>(begin: _mevcutAci, end: hedefAci).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _controller
      ..reset()
      ..forward().whenComplete(() {
        if (!mounted) return;
        _mevcutAci = hedefAci % (2 * pi);

        final dilimAci = (2 * pi) / liste.length;
        final ibreAcisi = ((3 * pi / 2) - _mevcutAci) % (2 * pi);
        final secilenIndeks = (ibreAcisi / dilimAci).floor() % liste.length;
        final secilen = liste[secilenIndeks];

        setState(() {
          _donuyor = false;
          _sonOneri = secilen;
        });
        _oneriKartiGoster(secilen);
      });
  }

  void _oneriKartiGoster(HealthyItem item) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(22, 6, 22, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 68,
                height: 68,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: item.color.o(0.14),
                  shape: BoxShape.circle,
                  border: Border.all(color: item.color.o(0.35)),
                ),
                child: Icon(item.ikon, color: item.color, size: 32),
              ),
              const SizedBox(height: 12),
              Text(
                item.name,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                item.benefit,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14.5, height: 1.4),
              ),
              const SizedBox(height: 14),
              _bilgiSatiri(Icons.fitness_center_rounded, Renk.ana, 'Sporcular', item.sporNotu),
              const SizedBox(height: 8),
              _bilgiSatiri(Icons.monitor_weight_outlined, Renk.iyi, 'Kilo Verme', item.diyetNotu),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: FilledButton.styleFrom(
                    backgroundColor: item.color,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Tamam'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _bilgiSatiri(IconData ikon, Color renk, String etiket, String metin) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: renk.o(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: renk.o(0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(ikon, color: renk, size: 19),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 13,
                  height: 1.35,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                children: [
                  TextSpan(text: '$etik: ', style: const TextStyle(fontWeight: FontWeight.w800)),
                  TextSpan(text: metin),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final liste = _aktifListe;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Öneri Çarkı'),
        actions: [
          if (widget.onAyarlarTiklandi != null)
            IconButton(
              tooltip: 'Ayarlar',
              onPressed: widget.onAyarlarTiklandi,
              icon: const Icon(Icons.settings_outlined),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        child: Column(
          children: [
            const Text(
              'Bugün ne tüketelim?',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.3),
            ),
            const SizedBox(height: 4),
            Text(
              'Hedefini seç ve sağlıklı bir alternatif bulmak için çarkı çevir.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.5, color: cs.onSurface.o(0.65)),
            ),
            const SizedBox(height: 14),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _kategoriler.map((kat) {
                  final secili = _seciliKategori == kat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(kat),
                      selected: secili,
                      onSelected: _donuyor
                          ? null
                          : (_) {
                              setState(() {
                                _seciliKategori = kat;
                                _sonOneri = null;
                              });
                            },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: 316,
              height: 332,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 308,
                    height: 308,
                    margin: const EdgeInsets.only(top: 16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Renk.ana.o(0.18),
                          blurRadius: 28,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: AnimatedBuilder(
                      animation: _animation,
                      builder: (context, _) {
                        return Transform.rotate(
                          angle: _animation.value,
                          child: CustomPaint(
                            size: const Size(308, 308),
                            painter: _EstetikCarkRessami(liste),
                          ),
                        );
                      },
                    ),
                  ),
                  Positioned(
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: cs.surface,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black.o(0.16), blurRadius: 8),
                        ],
                      ),
                      child: const Icon(Icons.arrow_drop_down_rounded, size: 42, color: Renk.kotu),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Material(
                      color: cs.surface,
                      shape: const CircleBorder(
                        side: BorderSide(color: Renk.ana, width: 4),
                      ),
                      elevation: 6,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: _donuyor ? null : _carkiCevir,
                        child: SizedBox(
                          width: 76,
                          height: 76,
                          child: Center(
                            child: _donuyor
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(strokeWidth: 2.8, color: Renk.ana),
                                  )
                                : const Text(
                                    'ÇEVİR',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 13.5,
                                      letterSpacing: 0.6,
                                      color: Renk.ana,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            if (_sonOneri != null)
              Kart(
                kenar: _sonOneri!.color.o(0.45),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _sonOneri!.color.o(0.14),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(_sonOneri!.ikon, color: _sonOneri!.color, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _sonOneri!.name,
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                              ),
                              Text(
                                _sonOneri!.kategori,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: _sonOneri!.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () => _oneriKartiGoster(_sonOneri!),
                          child: const Text('Detay'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(_sonOneri!.benefit, style: const TextStyle(fontSize: 13.5, height: 1.38)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EstetikCarkRessami extends CustomPainter {
  final List<HealthyItem> items;
  const _EstetikCarkRessami(this.items);

  @override
  void paint(Canvas canvas, Size size) {
    if (items.isEmpty) return;
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final dilimAci = (2 * pi) / items.length;

    final dilimBoya = Paint()..style = PaintingStyle.fill;
    final cizgiBoya = Paint()
      ..color = Colors.white.withAlpha(220)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    for (var i = 0; i < items.length; i++) {
      final basAci = i * dilimAci;
      dilimBoya.color = items[i].color.withAlpha(228);
      canvas.drawArc(rect, basAci, dilimAci, true, dilimBoya);
      canvas.drawLine(
        center,
        Offset(center.dx + radius * cos(basAci), center.dy + radius * sin(basAci)),
        cizgiBoya,
      );

      final ortaAci = basAci + (dilimAci / 2);
      final labelPainter = TextPainter(
        text: TextSpan(
          text: items[i].kisaAd,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            shadows: [
              Shadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 1)),
            ],
          ),
        ),
        textAlign: TextAlign.center,
        maxLines: 2,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 84);

      final textRadius = radius * 0.68;
      final tx = center.dx + textRadius * cos(ortaAci);
      final ty = center.dy + textRadius * sin(ortaAci);

      canvas.save();
      canvas.translate(tx, ty);
      var rot = ortaAci;
      if (cos(ortaAci) < 0) {
        rot += pi;
      }
      canvas.rotate(rot);
      labelPainter.paint(
        canvas,
        Offset(-labelPainter.width / 2, -labelPainter.height / 2),
      );
      canvas.restore();
    }

    final disCember = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;
    canvas.drawCircle(center, radius - 3, disCember);
  }

  @override
  bool shouldRepaint(covariant _EstetikCarkRessami oldDelegate) => oldDelegate.items != items;
}
