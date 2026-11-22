import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'analiz.dart';
import 'sonuc_gorunumu.dart';
import 'ui_ortak.dart';

class ScannedProduct {
  final String barcode;
  final String name;
  final String status;
  final String imageUrl;
  final DateTime date;
  final String? ingredients;
  final String? source;
  final Besin? besin;
  final String? nutriscore;
  final int? nova;

  ScannedProduct({
    required this.barcode,
    required this.name,
    required this.status,
    required this.imageUrl,
    required this.date,
    this.ingredients,
    this.source,
    this.besin,
    this.nutriscore,
    this.nova,
  });

  Map<String, dynamic> toJson() => {
        'barcode': barcode,
        'name': name,
        'status': status,
        'imageUrl': imageUrl,
        'date': date.toIso8601String(),
        'ingredients': ingredients,
        'source': source,
        'besin': besin?.toJson(),
        'nutriscore': nutriscore,
        'nova': nova,
      };

  factory ScannedProduct.fromJson(Map<String, dynamic> json) => ScannedProduct(
        barcode: json['barcode']?.toString() ?? '',
        name: json['name']?.toString() ?? 'İsimsiz Ürün',
        status: json['status']?.toString() ?? '',
        imageUrl: json['imageUrl']?.toString() ?? '',
        date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
        ingredients: json['ingredients']?.toString(),
        source: json['source']?.toString(),
        besin: json['besin'] is Map<String, dynamic>
            ? Besin.fromJson(json['besin'] as Map<String, dynamic>)
            : null,
        nutriscore: json['nutriscore']?.toString(),
        nova: (json['nova'] as num?)?.toInt(),
      );
}

class GecmisDeposu {
  static final ValueNotifier<int> degisti = ValueNotifier<int>(0);

  static Future<List<ScannedProduct>> oku() async {
    final prefs = await SharedPreferences.getInstance();
    final ham = prefs.getStringList('gecmis') ?? [];
    final liste = <ScannedProduct>[];
    for (final e in ham) {
      try {
        liste.add(ScannedProduct.fromJson(jsonDecode(e) as Map<String, dynamic>));
      } catch (_) {
        // Bozuk kayıtları atla
      }
    }
    return liste;
  }

  static Future<void> ekle(ScannedProduct urun) async {
    final prefs = await SharedPreferences.getInstance();
    final gecmis = prefs.getStringList('gecmis') ?? [];
    gecmis.insert(0, jsonEncode(urun.toJson()));
    if (gecmis.length > 50) gecmis.removeLast();
    await prefs.setStringList('gecmis', gecmis);
    degisti.value++;
  }

  static Future<void> temizle() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('gecmis');
    degisti.value++;
  }
}

String _tarih(DateTime d) {
  String iki(int n) => n.toString().padLeft(2, '0');
  return '${iki(d.day)}.${iki(d.month)}.${d.year}  ${iki(d.hour)}:${iki(d.minute)}';
}

class GecmisSekmesi extends StatefulWidget {
  final VoidCallback? onAyarlarTiklandi;

  const GecmisSekmesi({super.key, this.onAyarlarTiklandi});

  @override
  State<GecmisSekmesi> createState() => _GecmisSekmesiState();
}

class _GecmisSekmesiState extends State<GecmisSekmesi> {
  List<ScannedProduct> _liste = [];
  String _arama = '';

  @override
  void initState() {
    super.initState();
    _yukle();
    GecmisDeposu.degisti.addListener(_yukle);
  }

  @override
  void dispose() {
    GecmisDeposu.degisti.removeListener(_yukle);
    super.dispose();
  }

  Future<void> _yukle() async {
    final l = await GecmisDeposu.oku();
    if (!mounted) return;
    setState(() => _liste = l);
  }

  Future<void> _temizleSor() async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Geçmiş silinsin mi?'),
        content: const Text('Tüm tarama geçmişi kalıcı olarak silinecek.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sil')),
        ],
      ),
    );
    if (onay == true) await GecmisDeposu.temizle();
  }

  void _kaydiAc(ScannedProduct urun) {
    final icerik = urun.ingredients ?? '';
    if (icerik.isEmpty && (urun.besin == null || urun.besin!.bos) && urun.nutriscore == null && urun.nova == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bu eski kayıt için detaylı içerik verisi saklanmamış.')),
      );
      return;
    }

    final analiz = analizEt(
      icerik,
      besin: urun.besin,
      nutriscore: urun.nutriscore,
      nova: urun.nova,
    );

    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (ctx) => Scaffold(
          body: SonucGorunumu(
            baslik: urun.name,
            resimUrl: urun.imageUrl.isEmpty ? null : urun.imageUrl,
            kaynak: urun.source ?? (urun.barcode == 'icerik' ? 'İçerik Analizi' : 'Geçmiş Kaydı'),
            analiz: analiz,
            besin: urun.besin,
            nutriscore: urun.nutriscore,
            nova: urun.nova,
            yeniEtiketi: 'Geçmişe Dön',
            yeniIkonu: Icons.history_rounded,
            onYeni: () => Navigator.pop(ctx),
            onKapat: () => Navigator.pop(ctx),
          ),
        ),
      ),
    );
  }

  String _temizEtiket(String status) {
    return status
        .replaceAll(RegExp(r'[^\w\sĞğÜüŞşİıÖöÇç-]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  (Color, String) _durum(String status) {
    final temiz = _temizEtiket(status);
    if (temiz.contains('ZARARLI')) return (Renk.kotu, temiz);
    if (temiz.contains('DİKKATLİ') || temiz.contains('RİSKLİ')) return (Renk.orta, temiz);
    if (temiz.contains('VERİ')) return (Renk.notr, temiz);
    return (Renk.iyi, temiz);
  }

  List<ScannedProduct> get _filtrelenmis {
    if (_arama.trim().isEmpty) return _liste;
    final q = norm(_arama.trim());
    return _liste.where((u) {
      return norm(u.name).contains(q) || norm(u.status).contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final gorunen = _filtrelenmis;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Geçmiş'),
        actions: [
          if (_liste.isNotEmpty)
            IconButton(
              tooltip: 'Geçmişi temizle',
              onPressed: _temizleSor,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
          if (widget.onAyarlarTiklandi != null)
            IconButton(
              tooltip: 'Ayarlar',
              onPressed: widget.onAyarlarTiklandi,
              icon: const Icon(Icons.settings_outlined),
            ),
        ],
      ),
      body: _liste.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.history_rounded, size: 64, color: cs.onSurface.o(0.25)),
                    const SizedBox(height: 14),
                    Text(
                      'Henüz bir ürün veya içerik taramadınız.\nYaptığınız analizler burada listelenir.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: cs.onSurface.o(0.62), height: 1.4),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
                  child: TextField(
                    onChanged: (v) => setState(() => _arama = v),
                    decoration: InputDecoration(
                      hintText: 'Geçmişte ürün veya durum ara...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      filled: true,
                      fillColor: cs.surfaceContainerHighest.o(0.45),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: gorunen.length,
                    itemBuilder: (context, index) {
                      final urun = gorunen[index];
                      final (renk, etiket) = _durum(urun.status);
                      final etiketMi = urun.barcode == 'icerik' || urun.barcode == 'etiket';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(22),
                          onTap: () => _kaydiAc(urun),
                          child: Kart(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    color: cs.onSurface.o(0.06),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: urun.imageUrl.isNotEmpty
                                        ? Image.network(
                                            urun.imageUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                Icon(Icons.image_outlined, color: cs.onSurface.o(0.35)),
                                          )
                                        : Icon(
                                            etiketMi ? Icons.document_scanner_outlined : Icons.image_outlined,
                                            color: cs.onSurface.o(0.35),
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        urun.name,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _tarih(urun.date),
                                        style: TextStyle(fontSize: 12, color: cs.onSurface.o(0.55)),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: renk.o(0.13),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    etiket,
                                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: renk),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class AyarlarSekmesi extends StatelessWidget {
  final bool koyuMod;
  final ValueChanged<bool> onDegisti;

  const AyarlarSekmesi({
    super.key,
    required this.koyuMod,
    required this.onDegisti,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
        children: [
          Kart(
            child: Row(
              children: [
                const Icon(Icons.dark_mode_rounded, color: Renk.ana),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Karanlık mod', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      const SizedBox(height: 2),
                      Text('Göz yormayan karanlık tema', style: TextStyle(fontSize: 13, color: cs.onSurface.o(0.65))),
                    ],
                  ),
                ),
                Switch(value: koyuMod, onChanged: onDegisti),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Kart(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded, color: Renk.ana),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Sağlık Tarayıcı v2.5', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      const SizedBox(height: 6),
                      Text(
                        'Barkod/QR okutarak veya barkod olmadan doğrudan içindekiler metnini/etiketini okuyarak '
                        'ürün içeriğini analiz eder; sporcular ve kilo vermek isteyenler için uygunluğu değerlendirir.',
                        style: TextStyle(fontSize: 13, height: 1.4, color: cs.onSurface.o(0.75)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Kart(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.health_and_safety_outlined, color: Renk.ana),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Değerlendirmeler bilgilendirme amaçlıdır ve tıbbi tavsiye yerine geçmez. '
                    'Alerjiniz veya sağlık sorununuz varsa ürün etiketini ve doktorunuzu esas alın.',
                    style: TextStyle(fontSize: 13, height: 1.4, color: cs.onSurface.o(0.75)),
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
