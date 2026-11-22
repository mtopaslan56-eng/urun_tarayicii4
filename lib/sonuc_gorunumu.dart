import 'package:flutter/material.dart';
import 'analiz.dart';
import 'ui_ortak.dart';

class SonucGorunumu extends StatefulWidget {
  final String baslik;
  final String? resimUrl;
  final String? kaynak;
  final AnalizSonucu analiz;
  final Besin? besin;
  final String? nutriscore;
  final int? nova;
  final VoidCallback onYeni;
  final String yeniEtiketi;
  final IconData yeniIkonu;
  final VoidCallback? onKapat;
  final Widget? ekstra;

  const SonucGorunumu({
    super.key,
    required this.baslik,
    required this.analiz,
    required this.onYeni,
    this.resimUrl,
    this.kaynak,
    this.besin,
    this.nutriscore,
    this.nova,
    this.yeniEtiketi = 'Yeni Ürün Tara',
    this.yeniIkonu = Icons.qr_code_scanner_rounded,
    this.onKapat,
    this.ekstra,
  });

  @override
  State<SonucGorunumu> createState() => _SonucGorunumuState();
}

class _SonucGorunumuState extends State<SonucGorunumu> {
  // 0: Tümü, 1: Riskli / Dikkat, 2: Olumlu
  int _filtreIndeks = 0;

  IconData _genelIkon(Seviye s) => switch (s) {
        Seviye.iyi => Icons.verified_user_rounded,
        Seviye.orta => Icons.warning_amber_rounded,
        Seviye.kotu => Icons.gpp_bad_rounded,
        Seviye.bilinmiyor => Icons.help_outline_rounded,
      };

  Color _puanRengi(int puan) {
    if (puan >= 70) return Renk.iyi;
    if (puan >= 45) return Renk.orta;
    return Renk.kotu;
  }

  List<Bilesen> get _filtrelenmisBilesenler {
    if (_filtreIndeks == 1) {
      return widget.analiz.bilesenler.where((b) => b.risk > 0).toList();
    }
    if (_filtreIndeks == 2) {
      return widget.analiz.bilesenler.where((b) => b.olumlu).toList();
    }
    return widget.analiz.bilesenler;
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.besin;
    final riskli = widget.analiz.yuksek + widget.analiz.hafif;
    final cs = Theme.of(context).colorScheme;
    final liste = _filtrelenmisBilesenler;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _baslikAlani(context),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (riskli > 0) ...[
                  _riskBandi(context),
                  const SizedBox(height: 16),
                ],
                _kaliteVeTuketimKarti(context),
                if (widget.analiz.alerjenVeHassasiyetler.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _alerjenKarti(context),
                ],
                const SizedBox(height: 24),
                const BolumBasligi(
                  'Hedefe Göre Değerlendirme',
                  altMetin: 'Sporcular ve kilo vermek isteyenler için uygunluk',
                ),
                const SizedBox(height: 12),
                ProfilKarti(
                  ikon: Icons.fitness_center_rounded,
                  baslik: 'Sporcular İçin',
                  profil: widget.analiz.spor,
                ),
                const SizedBox(height: 12),
                ProfilKarti(
                  ikon: Icons.monitor_weight_outlined,
                  baslik: 'Kilo Vermek İsteyenler İçin',
                  profil: widget.analiz.diyet,
                ),
                if ((b != null && !b.bos) || widget.nutriscore != null || widget.nova != null) ...[
                  const SizedBox(height: 26),
                  const BolumBasligi('Besin Değerleri'),
                  const SizedBox(height: 12),
                  _besinAlani(context, b),
                ],
                const SizedBox(height: 26),
                const BolumBasligi(
                  'İçindekiler ve Etkileri',
                  altMetin: 'Tespit edilen maddeler ve sağlık etkileri',
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _filtreChip(0, 'Tümü (${widget.analiz.bilesenler.length})'),
                      const SizedBox(width: 8),
                      _filtreChip(1, 'Riskli / Dikkat ($riskli)'),
                      const SizedBox(width: 8),
                      _filtreChip(2, 'Olumlu (${widget.analiz.olumluSayisi})'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (liste.isEmpty)
                  Kart(
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded, color: cs.onSurface.o(0.5)),
                        const SizedBox(width: 12),
                        const Expanded(child: Text('Seçili filtreye uygun içerik maddesi bulunamadı.')),
                      ],
                    ),
                  )
                else
                  ...liste.map((x) => _bilesenKarti(context, x)),
                for (final n in widget.analiz.notlar)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.fiber_manual_record, size: 8, color: cs.onSurface.o(0.55)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            n,
                            style: TextStyle(fontSize: 13, color: cs.onSurface.o(0.72), height: 1.35),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (widget.ekstra != null) ...[
                  const SizedBox(height: 20),
                  widget.ekstra!,
                ],
                const SizedBox(height: 20),
                Kart(
                  padding: const EdgeInsets.all(14),
                  renk: cs.surfaceContainerHighest.o(0.35),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.shield_outlined, size: 18, color: cs.onSurface.o(0.65)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Bu değerlendirme yalnızca içindekiler listesine (ve varsa 100 g besin değerlerine) dayanan '
                          'bilgilendirme analizidir; tıbbi tavsiye yerine geçmez. Alerji, kronik rahatsızlık veya özel '
                          'diyet durumlarında ürün etiketini ve uzmana danışmayı esas alın.',
                          style: TextStyle(fontSize: 12, height: 1.4, color: cs.onSurface.o(0.65)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: widget.onYeni,
                    icon: Icon(widget.yeniIkonu),
                    label: Text(widget.yeniEtiketi),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Renk.ana,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filtreChip(int indeks, String etiket) {
    return ChoiceChip(
      label: Text(etiket),
      selected: _filtreIndeks == indeks,
      onSelected: (_) => setState(() => _filtreIndeks = indeks),
    );
  }

  Widget _baslikAlani(BuildContext context) {
    final renk = seviyeRengi(widget.analiz.genelSeviye);
    final resimVar = widget.resimUrl != null && widget.resimUrl!.isNotEmpty;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 8, 20, 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [renk, Color.alphaBlend(Colors.black.o(0.24), renk)],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(36)),
      ),
      child: Column(
        children: [
          if (widget.onKapat != null)
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: widget.onKapat,
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              ),
            )
          else
            const SizedBox(height: 12),
          Container(
            height: 140,
            width: 140,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(color: Colors.black.o(0.2), blurRadius: 22, offset: const Offset(0, 10)),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: resimVar
                  ? Image.network(
                      widget.resimUrl!,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.shopping_bag_outlined, size: 66, color: Colors.black26),
                    )
                  : const Icon(Icons.fact_check_outlined, size: 66, color: Colors.black26),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            widget.baslik,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800, color: Colors.white, height: 1.2),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(color: Colors.black.o(0.18), blurRadius: 12, offset: const Offset(0, 5)),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_genelIkon(widget.analiz.genelSeviye), color: renk, size: 19),
                const SizedBox(width: 8),
                Text(
                  widget.analiz.genelEtiket,
                  style: TextStyle(color: renk, fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 0.4),
                ),
              ],
            ),
          ),
          if (widget.kaynak != null) ...[
            const SizedBox(height: 10),
            Text(widget.kaynak!, style: TextStyle(color: Colors.white.o(0.88), fontSize: 12.5)),
          ],
        ],
      ),
    );
  }

  Widget _kaliteVeTuketimKarti(BuildContext context) {
    final puan = widget.analiz.kalitePuani;
    final puanRenk = _puanRengi(puan);
    final cs = Theme.of(context).colorScheme;

    return Kart(
      kenar: puanRenk.o(0.35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: puanRenk.o(0.12), borderRadius: BorderRadius.circular(14)),
                child: Icon(Icons.analytics_outlined, color: puanRenk, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'İçerik Kalite Puanı',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5),
                    ),
                    Text(
                      widget.analiz.tuketimOnerisi,
                      style: TextStyle(fontSize: 12.8, height: 1.35, color: cs.onSurface.o(0.75)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: puanRenk.o(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '$puan/100',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: puanRenk),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (puan / 100).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: cs.onSurface.o(0.08),
              valueColor: AlwaysStoppedAnimation<Color>(puanRenk),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _miniSayac('Yüksek Risk', widget.analiz.yuksek, Renk.kotu),
              _miniSayac('Dikkat', widget.analiz.hafif, Renk.orta),
              _miniSayac('Olumlu', widget.analiz.olumluSayisi, Renk.iyi),
            ],
          ),
        ],
      ),
    );
  }

  Widget _alerjenKarti(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Kart(
      kenar: Renk.ana.o(0.32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded, color: Renk.ana, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Tespit Edilen Bileşen ve Hassasiyet Notları',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.analiz.alerjenVeHassasiyetler
                .map(
                  (a) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest.o(0.55),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      a,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _miniSayac(String baslik, int adet, Color renk) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: renk.o(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: renk.o(0.25)),
      ),
      child: Text(
        '$baslik: $adet',
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: renk),
      ),
    );
  }

  Widget _riskBandi(BuildContext context) {
    final yuksekVar = widget.analiz.yuksek > 0;
    final renk = yuksekVar ? Renk.kotu : Renk.orta;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final parcalar = <String>[];
    if (widget.analiz.yuksek > 0) parcalar.add('${widget.analiz.yuksek} yüksek riskli');
    if (widget.analiz.hafif > 0) parcalar.add('${widget.analiz.hafif} dikkat edilmesi gereken');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: renk.o(0.11),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: renk.o(0.36)),
      ),
      child: Row(
        children: [
          Icon(
            yuksekVar ? Icons.gpp_bad_rounded : Icons.warning_amber_rounded,
            color: renk,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'İçeriğinde ${parcalar.join(' ve ')} madde tespit edildi. Detaylar aşağıda.',
              style: TextStyle(color: onSurface, fontWeight: FontWeight.w700, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }

  Widget _besinAlani(BuildContext context, Besin? b) {
    final kutular = <Widget>[];
    void kutuEkle(String ad, double? v, String birim) {
      if (v == null) return;
      final s = v.toStringAsFixed(v >= 10 ? 0 : 1).replaceAll(RegExp(r'\.0$'), '');
      kutular.add(_BesinKutusu(ad: ad, deger: '$s $birim'));
    }

    if (b != null) {
      kutuEkle('Kalori', b.kcal, 'kcal');
      kutuEkle('Şeker', b.seker, 'g');
      kutuEkle('Yağ', b.yag, 'g');
      kutuEkle('Doymuş yağ', b.doymusYag, 'g');
      kutuEkle('Protein', b.protein, 'g');
      kutuEkle('Lif', b.lif, 'g');
      kutuEkle('Tuz', b.tuz, 'g');
    }

    const nutriRenkleri = {
      'a': Color(0xFF1E8F4E),
      'b': Color(0xFF7AC547),
      'c': Color(0xFFF2C230),
      'd': Color(0xFFF08A24),
      'e': Color(0xFFE5484D),
    };
    final cs = Theme.of(context).colorScheme;

    return Kart(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (kutular.isNotEmpty) ...[
            Text('100 g başına', style: TextStyle(fontSize: 12.5, color: cs.onSurface.o(0.6))),
            const SizedBox(height: 10),
            Wrap(spacing: 10, runSpacing: 10, children: kutular),
          ],
          if (widget.nutriscore != null || widget.nova != null) ...[
            if (kutular.isNotEmpty) const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                if (widget.nutriscore != null)
                  _Rozet(
                    metin: 'Nutri-Score ${widget.nutriscore!.toUpperCase()}',
                    renk: nutriRenkleri[widget.nutriscore] ?? Renk.notr,
                  ),
                if (widget.nova != null)
                  _Rozet(
                    metin: 'NOVA ${widget.nova}',
                    renk: widget.nova == 4 ? Renk.kotu : (widget.nova == 3 ? Renk.orta : Renk.iyi),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _bilesenKarti(BuildContext context, Bilesen b) {
    final cs = Theme.of(context).colorScheme;
    final Color renk;
    final IconData ikon;
    if (b.risk == 2) {
      renk = Renk.kotu;
      ikon = Icons.dangerous_rounded;
    } else if (b.risk == 1) {
      renk = Renk.orta;
      ikon = Icons.warning_amber_rounded;
    } else if (b.olumlu) {
      renk = Renk.iyi;
      ikon = Icons.check_circle_rounded;
    } else {
      renk = Renk.notr;
      ikon = Icons.circle_outlined;
    }
    final aciklamali = b.eslesenler.where((m) => m.risk > 0 || m.olumlu).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: b.risk > 0 || b.olumlu ? renk.o(0.09) : null,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: b.risk > 0 || b.olumlu ? renk.o(0.32) : cs.outlineVariant.o(0.55),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(ikon, color: renk, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  b.metin,
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: b.risk > 0 ? FontWeight.w700 : FontWeight.w500,
                    height: 1.3,
                  ),
                ),
                for (final m in aciklamali)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      m.aciklama +
                          ((m.siraHassas && m.risk == 1 && b.risk == 2)
                              ? ' Listenin ilk sıralarında yer aldığı için üründe yüksek oranda bulunuyor.'
                              : ''),
                      style: TextStyle(fontSize: 13.5, height: 1.4, color: cs.onSurface.o(0.76)),
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

class ProfilKarti extends StatelessWidget {
  final IconData ikon;
  final String baslik;
  final Profil profil;

  const ProfilKarti({
    super.key,
    required this.ikon,
    required this.baslik,
    required this.profil,
  });

  @override
  Widget build(BuildContext context) {
    final renk = seviyeRengi(profil.seviye);
    final cs = Theme.of(context).colorScheme;

    Widget satir(IconData i, Color c, String metin) => Padding(
          padding: const EdgeInsets.only(bottom: 7),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(padding: const EdgeInsets.only(top: 2), child: Icon(i, size: 17, color: c)),
              const SizedBox(width: 9),
              Expanded(child: Text(metin, style: const TextStyle(fontSize: 13.5, height: 1.38))),
            ],
          ),
        );

    final listeVar = profil.iyi.isNotEmpty || profil.kotu.isNotEmpty || profil.notlar.isNotEmpty;

    return Kart(
      kenar: renk.o(0.42),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: renk.o(0.14), shape: BoxShape.circle),
                child: Icon(ikon, color: renk, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(baslik, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(
                      profil.seviyeEtiketi,
                      style: TextStyle(color: renk, fontWeight: FontWeight.w800, fontSize: 14.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (profil.ozet.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              profil.ozet,
              style: TextStyle(fontSize: 14, height: 1.35, color: cs.onSurface.o(0.86)),
            ),
          ],
          if (listeVar) const SizedBox(height: 12),
          for (final s in profil.iyi) satir(Icons.check_circle_rounded, Renk.iyi, s),
          for (final s in profil.kotu) satir(Icons.cancel_rounded, Renk.kotu, s),
          for (final s in profil.notlar) satir(Icons.info_rounded, Renk.notr, s),
        ],
      ),
    );
  }
}

class _BesinKutusu extends StatelessWidget {
  final String ad;
  final String deger;

  const _BesinKutusu({required this.ad, required this.deger});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Renk.ana.o(0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(deger, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 2),
          Text(ad, style: TextStyle(fontSize: 12, color: cs.onSurface.o(0.65))),
        ],
      ),
    );
  }
}

class _Rozet extends StatelessWidget {
  final String metin;
  final Color renk;

  const _Rozet({required this.metin, required this.renk});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(color: renk, borderRadius: BorderRadius.circular(20)),
      child: Text(metin, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
    );
  }
}
