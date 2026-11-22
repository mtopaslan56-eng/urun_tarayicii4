import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'analiz.dart';
import 'gecmis_ayarlar.dart';
import 'icerik_okuma_ekrani.dart';
import 'oneri_carki_ekrani.dart';
import 'servis.dart';
import 'sonuc_gorunumu.dart';
import 'tarama_ekrani.dart';
import 'ui_ortak.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const UrunTarayiciApp());
}

class UrunTarayiciApp extends StatefulWidget {
  const UrunTarayiciApp({super.key});

  @override
  State<UrunTarayiciApp> createState() => _UrunTarayiciAppState();
}

class _UrunTarayiciAppState extends State<UrunTarayiciApp> {
  bool _koyuMod = false;

  @override
  void initState() {
    super.initState();
    _temaYukle();
  }

  Future<void> _temaYukle() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _koyuMod = prefs.getBool('darkMode') ?? false;
    });
  }

  Future<void> _temaDegistir(bool deger) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', deger);
    if (!mounted) return;
    setState(() {
      _koyuMod = deger;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sağlık Tarayıcı',
      themeMode: _koyuMod ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Renk.ana,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF4F8F7),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Renk.ana,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0B1413),
      ),
      home: AnaEkran(
        koyuMod: _koyuMod,
        onTemaDegistir: _temaDegistir,
      ),
    );
  }
}

class AnaEkran extends StatefulWidget {
  final bool koyuMod;
  final ValueChanged<bool> onTemaDegistir;

  const AnaEkran({
    super.key,
    required this.koyuMod,
    required this.onTemaDegistir,
  });

  @override
  State<AnaEkran> createState() => _AnaEkranState();
}

class _AnaEkranState extends State<AnaEkran> {
  int _seciliSekme = 0;

  void _ayarlariAc() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => AyarlarSekmesi(
          koyuMod: widget.koyuMod,
          onDegisti: widget.onTemaDegistir,
        ),
      ),
    );
  }

  void _icerikSekmesineGec() {
    setState(() => _seciliSekme = 1);
  }

  @override
  Widget build(BuildContext context) {
    final sayfalar = <Widget>[
      BarkodSekmesi(
        onAyarlarTiklandi: _ayarlariAc,
        onIcerikSekmesineGec: _icerikSekmesineGec,
      ),
      IcerikOkumaSekmesi(onAyarlarTiklandi: _ayarlariAc),
      OneriCarkiSekmesi(onAyarlarTiklandi: _ayarlariAc),
      GecmisSekmesi(onAyarlarTiklandi: _ayarlariAc),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _seciliSekme,
        children: sayfalar,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _seciliSekme,
        onDestinationSelected: (index) => setState(() => _seciliSekme = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.qr_code_scanner_outlined),
            selectedIcon: Icon(Icons.qr_code_scanner_rounded),
            label: 'Barkod',
          ),
          NavigationDestination(
            icon: Icon(Icons.article_outlined),
            selectedIcon: Icon(Icons.article_rounded),
            label: 'İçerik',
          ),
          NavigationDestination(
            icon: Icon(Icons.casino_outlined),
            selectedIcon: Icon(Icons.casino_rounded),
            label: 'Çark',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history_rounded),
            label: 'Geçmiş',
          ),
        ],
      ),
    );
  }
}

class BarkodSekmesi extends StatefulWidget {
  final VoidCallback onAyarlarTiklandi;
  final VoidCallback onIcerikSekmesineGec;

  const BarkodSekmesi({
    super.key,
    required this.onAyarlarTiklandi,
    required this.onIcerikSekmesineGec,
  });

  @override
  State<BarkodSekmesi> createState() => _BarkodSekmesiState();
}

class _BarkodSekmesiState extends State<BarkodSekmesi> {
  bool _yukleniyor = false;
  String? _sonBarkod;
  String? _hataMesaji;
  UrunBilgisi? _urun;
  AnalizSonucu? _analiz;

  Future<void> _taraVeSorgula() async {
    final barkod = await Navigator.push<String>(
      context,
      MaterialPageRoute<String>(builder: (_) => const TaramaEkrani()),
    );
    if (barkod == null || barkod.isEmpty) return;

    setState(() {
      _yukleniyor = true;
      _sonBarkod = barkod;
      _hataMesaji = null;
      _urun = null;
      _analiz = null;
    });

    final sonuc = await UrunServisi.sorgula(barkod);
    if (!mounted) return;

    if (sonuc.urun == null) {
      setState(() {
        _yukleniyor = false;
        _hataMesaji = sonuc.baglantiHatasi
            ? 'Bağlantı hatası oluştu. İnternet bağlantınızı kontrol edin.'
            : 'Bu barkod ($barkod) veritabanlarında bulunamadı.';
      });
      return;
    }

    final urun = sonuc.urun!;
    final analiz = analizEt(
      urun.icerik,
      besin: urun.besin,
      nutriscore: urun.nutriscore,
      nova: urun.nova,
    );

    setState(() {
      _yukleniyor = false;
      _urun = urun;
      _analiz = analiz;
    });

    await GecmisDeposu.ekle(
      ScannedProduct(
        barcode: barkod,
        name: urun.ad,
        status: analiz.genelEtiket,
        imageUrl: urun.resimUrl ?? '',
        date: DateTime.now(),
        ingredients: urun.icerik,
        source: urun.kaynak,
        besin: urun.besin,
        nutriscore: urun.nutriscore,
        nova: urun.nova,
      ),
    );
  }

  void _sifirla() {
    setState(() {
      _urun = null;
      _analiz = null;
      _hataMesaji = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_yukleniyor) {
      return Scaffold(
        appBar: AppBar(title: const Text('Sağlık Tarayıcı')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Renk.ana),
              const SizedBox(height: 16),
              Text(
                _sonBarkod != null ? 'Barkod sorgulanıyor: $_sonBarkod' : 'Ürün aranıyor...',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );
    }

    if (_urun != null && _analiz != null) {
      return Scaffold(
        body: SonucGorunumu(
          baslik: _urun!.ad,
          resimUrl: _urun!.resimUrl,
          kaynak: _urun!.kaynak,
          analiz: _analiz!,
          besin: _urun!.besin,
          nutriscore: _urun!.nutriscore,
          nova: _urun!.nova,
          onYeni: _taraVeSorgula,
          yeniEtiketi: 'Yeni Barkod Tara',
          onKapat: _sifirla,
        ),
      );
    }

    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sağlık Tarayıcı'),
        actions: [
          IconButton(
            tooltip: 'Ayarlar',
            onPressed: widget.onAyarlarTiklandi,
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const AppLogo(size: 122),
              const SizedBox(height: 28),
              const Text(
                'Ürün içeriğini saniyeler içinde analiz edin',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800, letterSpacing: -0.3, height: 1.2),
              ),
              const SizedBox(height: 10),
              Text(
                'Zararlı maddeleri, sporculara uygunluğu ve kilo verme diyetine etkisini görün.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14.5, height: 1.4, color: cs.onSurface.o(0.66)),
              ),
              if (_hataMesaji != null) ...[
                const SizedBox(height: 20),
                Kart(
                  kenar: Renk.orta.o(0.45),
                  renk: Renk.orta.o(0.08),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, color: Renk.orta),
                          const SizedBox(width: 10),
                          Expanded(child: Text(_hataMesaji!, style: const TextStyle(fontWeight: FontWeight.w600))),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: widget.onIcerikSekmesineGec,
                          icon: const Icon(Icons.article_outlined),
                          label: const Text('İçeriği Elle / Fotoğrafla Oku'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _taraVeSorgula,
                  icon: const Icon(Icons.qr_code_scanner_rounded, size: 24),
                  label: const Text('Barkod Taramayı Başlat', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    backgroundColor: Renk.ana,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: widget.onIcerikSekmesineGec,
                  icon: const Icon(Icons.document_scanner_outlined),
                  label: const Text('Barkodsuz İçerik Okumaya Geç'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
