import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'analiz.dart';
import 'gecmis_ayarlar.dart';
import 'sonuc_gorunumu.dart';
import 'ui_ortak.dart';

class IcerikOkumaSekmesi extends StatefulWidget {
  final String? baslangicMetni;
  final VoidCallback? onAyarlarTiklandi;

  const IcerikOkumaSekmesi({
    super.key,
    this.baslangicMetni,
    this.onAyarlarTiklandi,
  });

  @override
  State<IcerikOkumaSekmesi> createState() => _IcerikOkumaSekmesiState();
}

class _IcerikOkumaSekmesiState extends State<IcerikOkumaSekmesi> {
  final TextEditingController _urunAdiKontrol = TextEditingController();
  final TextEditingController _icerikKontrol = TextEditingController();
  final ImagePicker _secici = ImagePicker();

  bool _ocrCalisiyor = false;
  String? _seciliFotoYolu;
  AnalizSonucu? _sonuc;
  String _analizEdilenBaslik = '';
  String _analizEdilenIcerik = '';

  @override
  void initState() {
    super.initState();
    if (widget.baslangicMetni != null && widget.baslangicMetni!.isNotEmpty) {
      _icerikKontrol.text = widget.baslangicMetni!;
    }
  }

  @override
  void dispose() {
    _urunAdiKontrol.dispose();
    _icerikKontrol.dispose();
    super.dispose();
  }

  Future<void> _etiketFotografiSec(ImageSource kaynak) async {
    try {
      final XFile? foto = await _secici.pickImage(
        source: kaynak,
        imageQuality: 90,
      );
      if (foto == null) return;

      setState(() {
        _ocrCalisiyor = true;
        _seciliFotoYolu = foto.path;
      });

      final inputImage = InputImage.fromFilePath(foto.path);
      final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final recognized = await recognizer.processImage(inputImage);
      await recognizer.close();

      if (!mounted) return;
      final ayiklanan = icindekilerBolumunuAyikla(recognized.text);
      final metin = ayiklanan.metin.trim();

      setState(() {
        _ocrCalisiyor = false;
        if (metin.isNotEmpty) {
          _icerikKontrol.text = metin;
        }
      });

      if (metin.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fotoğrafta okunabilir içerik metni bulunamadı. Metni elle girebilirsiniz.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ayiklanan.baslikBulundu
                  ? 'İçindekiler bölümü otomatik ayrıştırıldı.'
                  : 'Etiket metni okundu; isterseniz düzenleyip analiz edin.',
            ),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _ocrCalisiyor = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Etiket okunurken bir sorun oluştu.')),
      );
    }
  }

  Future<void> _degerlendir() async {
    final hamIcerik = _icerikKontrol.text.trim();
    if (hamIcerik.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen ürünün içindekiler metnini girin veya etiket fotoğrafı okutun.')),
      );
      return;
    }

    final baslik = _urunAdiKontrol.text.trim().isEmpty
        ? 'İçerik Analizi'
        : _urunAdiKontrol.text.trim();
    final sonuc = analizEt(hamIcerik);

    setState(() {
      _sonuc = sonuc;
      _analizEdilenBaslik = baslik;
      _analizEdilenIcerik = hamIcerik;
    });

    await GecmisDeposu.ekle(
      ScannedProduct(
        barcode: 'icerik',
        name: baslik,
        status: sonuc.genelEtiket,
        imageUrl: '',
        date: DateTime.now(),
        ingredients: hamIcerik,
      ),
    );
  }

  void _sifirla() {
    setState(() {
      _sonuc = null;
      _seciliFotoYolu = null;
    });
  }

  void _ornekDoldur(String ad, String icerik) {
    setState(() {
      _urunAdiKontrol.text = ad;
      _icerikKontrol.text = icerik;
      _sonuc = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_sonuc != null) {
      return Scaffold(
        body: SonucGorunumu(
          baslik: _analizEdilenBaslik,
          kaynak: 'Doğrudan İçerik Değerlendirmesi',
          analiz: _sonuc!,
          onYeni: _sifirla,
          yeniEtiketi: 'Yeni İçerik Değerlendir',
          yeniIkonu: Icons.article_outlined,
          onKapat: _sifirla,
          ekstra: Kart(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Okunan / Girilen İçerik', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                const SizedBox(height: 6),
                Text(
                  _analizEdilenIcerik,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: Theme.of(context).colorScheme.onSurface.o(0.75),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('İçerik Oku'),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Kart(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Renk.ana.o(0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.document_scanner_rounded, color: Renk.ana, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Barkod Olmadan İçerik Analizi',
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Etiket fotoğrafından metin okuyun veya içindekileri doğrudan yapıştırın.',
                              style: TextStyle(fontSize: 12.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _ocrCalisiyor ? null : () => _etiketFotografiSec(ImageSource.camera),
                          icon: const Icon(Icons.photo_camera_rounded),
                          label: const Text('Etiket Çek'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _ocrCalisiyor ? null : () => _etiketFotografiSec(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library_outlined),
                          label: const Text('Galeriden Seç'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_ocrCalisiyor) ...[
                    const SizedBox(height: 14),
                    const LinearProgressIndicator(),
                    const SizedBox(height: 6),
                    Text('Etiket yazısı okunuyor...', style: TextStyle(fontSize: 12.5, color: cs.onSurface.o(0.65))),
                  ],
                  if (_seciliFotoYolu != null) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.file(
                        File(_seciliFotoYolu!),
                        height: 130,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            const BolumBasligi('İçindekiler Listesi'),
            const SizedBox(height: 10),
            Kart(
              child: Column(
                children: [
                  TextField(
                    controller: _urunAdiKontrol,
                    decoration: InputDecoration(
                      labelText: 'Ürün adı (isteğe bağlı)',
                      hintText: 'Örn: Yulaflı Bar, Bisküvi...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _icerikKontrol,
                    maxLines: 5,
                    decoration: InputDecoration(
                      labelText: 'İçindekiler metni',
                      hintText: 'Örn: Yulaf ezmesi, badem, hurma özü, tuz...',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _degerlendir,
                      icon: const Icon(Icons.health_and_safety_rounded),
                      label: const Text('İçeriği Değerlendir'),
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
            const SizedBox(height: 18),
            const BolumBasligi('Hızlı Test Örnekleri'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  label: const Text('Sporcu / Diyet Bar'),
                  onPressed: () => _ornekDoldur(
                    'Yulaflı Protein Bar',
                    'Yulaf ezmesi, whey protein konsantre, badem, chia tohumu, doğal aroma',
                  ),
                ),
                ActionChip(
                  label: const Text('Şekerli Atıştırmalık'),
                  onPressed: () => _ornekDoldur(
                    'Kremalı Gofret',
                    'Şeker, buğday unu, palm yağı, glikoz şurubu, peynir altı suyu tozu, yapay aroma',
                  ),
                ),
                ActionChip(
                  label: const Text('Yüksek Riskli Örnek'),
                  onPressed: () => _ornekDoldur(
                    'İşlenmiş Et Ürünü',
                    'Hindi eti, su, nişasta, tuz, sodyum nitrit (E250), titanyum dioksit (E171)',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
