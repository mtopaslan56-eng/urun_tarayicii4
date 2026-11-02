import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'tarama_ekrani.dart';

// --- BARKODOKU.COM API ANAHTARLARI ---
const String BARKODOKU_USER_KEY = 'cTg8XiX4QPvYT37_n8In2KwHiBmhsjui';
const String BARKODOKU_API_KEY = 'UvCDBwMAHAkSMN4i1BNa8CwXXwq8OVqG-WRREBpIl08-sz7Nbcsri0ZqWOSQ21u7o';
// -------------------------------------

void main() {
  runApp(const UrunTarayiciApp());
}

class UrunTarayiciApp extends StatelessWidget {
  const UrunTarayiciApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ürün Sağlık Analizi',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const AnaEkran(),
    );
  }
}

class AnaEkran extends StatefulWidget {
  const AnaEkran({super.key});

  @override
  State<AnaEkran> createState() => _AnaEkranState();
}

class _AnaEkranState extends State<AnaEkran> {
  String? urunAdi;
  String? saglikDurumu;
  String? detay;
  String? icindekilerMetni;
  String? urunResmiUrl;
  Color durumRengi = Colors.black;
  bool yukleniyor = false;
  String? hataMesaji;

  // İçerikte aranacak riskli maddeler
  final List<String> riskliMaddeler = [
    'palm yağı', 'palm oil', 'glikoz şurubu', 'glucose syrup',
    'yüksek fruktozlu mısır şurubu', 'high fructose corn syrup',
    'aspartam', 'aspartame', 'msj', 'msg', 'monosodyum glutamat',
    'sodyum nitrat', 'sodium nitrite', 'e621', 'e951', 'e330', 'şeker', 'sugar'
  ];

  Future<void> urunSorgula(String barkod) async {
    setState(() {
      yukleniyor = true;
      urunAdi = null;
      saglikDurumu = null;
      detay = null;
      icindekilerMetni = null;
      urunResmiUrl = null;
      hataMesaji = null;
    });

    try {
      // 1. ÖNCE TÜRKİYE API'Sİ (Barkodoku.com)
      var trSonuc = await _barkodokuSorgula(barkod);
      if (trSonuc != null) {
        _sonucuIsle(trSonuc['urunAdi'], trSonuc['icerik'], trSonuc['resimUrl'], isOff: false);
        return;
      }

      // 2. YEDEK: OPEN FOOD FACTS
      var offSonuc = await _openFoodFactsSorgula(barkod);
      if (offSonuc != null) {
        _sonucuIsle(offSonuc['urunAdi'], offSonuc['icerik'], offSonuc['resimUrl'], 
            isOff: true, nutriscore: offSonuc['nutriscore'], nova: offSonuc['nova']);
      } else {
        setState(() {
          urunAdi = 'Ürün Bulunamadı';
          detay = 'Bu ürün veritabanlarında kayıtlı değil.';
          hataMesaji = null;
        });
      }
    } catch (e) {
      setState(() {
        hataMesaji = 'Bağlantı Hatası. Lütfen internetinizi kontrol edin.';
      });
    } finally {
      setState(() => yukleniyor = false);
    }
  }

  // --- Barkodoku.com API ---
  Future<Map<String, dynamic>?> _barkodokuSorgula(String barkod) async {
    try {
      final tokenUrl = Uri.parse('https://www.barkodoku.com/api/auth/getToken');
      final tokenResponse = await http.post(
        tokenUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userKey': BARKODOKU_USER_KEY,
          'apiKey': BARKODOKU_API_KEY,
        }),
      ).timeout(const Duration(seconds: 10));

      if (tokenResponse.statusCode != 200) return null;
      final tokenData = jsonDecode(tokenResponse.body);
      final token = tokenData['token'] ?? tokenData['data']?['token'];
      if (token == null) return null;

      final barcodeUrl = Uri.parse('https://www.barkodoku.com/api/barcode');
      final barcodeResponse = await http.post(
        barcodeUrl,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'barcode': barkod}),
      ).timeout(const Duration(seconds: 10));

      if (barcodeResponse.statusCode != 200) return null;
      final data = jsonDecode(barcodeResponse.body);

      if (data is List && data.isNotEmpty) {
        var urun = data[0];
        return {
          'urunAdi': urun['text'] ?? urun['name'] ?? 'İsimsiz Ürün',
          'icerik': urun['ingredients'] ?? urun['description'] ?? 'İçindekiler bilgisi yok.',
          'resimUrl': urun['image'] ?? urun['imageUrl'],
        };
      } else if (data is Map && (data.containsKey('text') || data.containsKey('name'))) {
        return {
          'urunAdi': data['text'] ?? data['name'] ?? 'İsimsiz Ürün',
          'icerik': data['ingredients'] ?? data['description'] ?? 'İçindekiler bilgisi yok.',
          'resimUrl': data['image'] ?? data['imageUrl'],
        };
      }
    } catch (e) {
      return null; 
    }
    return null;
  }

  // --- Open Food Facts API ---
  Future<Map<String, dynamic>?> _openFoodFactsSorgula(String barkod) async {
    try {
      final url = Uri.parse(
        'https://world.openfoodfacts.org/api/v2/product/$barkod.json?fields=product_name,nutriscore_grade,nova_group,ingredients_text_tr,ingredients_text,image_url',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 1) {
          final product = data['product'];
          return {
            'urunAdi': product['product_name'] ?? 'İsimsiz Ürün',
            'icerik': product['ingredients_text_tr'] ?? product['ingredients_text'] ?? 'İçindekiler bilgisi yok.',
            'resimUrl': product['image_url'],
            'nutriscore': product['nutriscore_grade'],
            'nova': product['nova_group'],
          };
        }
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  void _sonucuIsle(String? ad, String? icerik, String? resim, {required bool isOff, String? nutriscore, int? nova}) {
    setState(() {
      urunAdi = ad ?? 'İsimsiz Ürün';
      icindekilerMetni = icerik ?? 'İçindekiler bilgisi bulunamadı.';
      urunResmiUrl = resim;
      
      if (isOff && nutriscore != null) {
        final sonuc = saglikDurumuBelirle(nutriscore, nova ?? 0);
        saglikDurumu = sonuc['mesaj'];
        durumRengi = sonuc['renk'];
        detay = 'Nutri-Score: ${nutriscore.isEmpty ? "?" : nutriscore.toUpperCase()} | NOVA: $nova';
      } else {
        final analiz = icindekileriAnalizEt(icindekilerMetni!);
        final riskliSayisi = analiz.where((e) => e['riskli'] == true).length;
        
        if (riskliSayisi > 0) {
          saglikDurumu = '⚠️ DİKKAT: $riskliSayisi Riskli Madde İçeriyor';
          durumRengi = Colors.orange.shade800;
        } else {
          saglikDurumu = '✅ TÜKETİLEBİLİR';
          durumRengi = Colors.green.shade700;
        }
        detay = 'Türkiye Barkod Veritabanı';
      }
    });
  }

  Map<String, dynamic> saglikDurumuBelirle(String nutriscore, int nova) {
    if (nutriscore == 'd' || nutriscore == 'e' || nova == 4) {
      return {'mesaj': '⛔ TÜKETİLMESİ ZARARLI', 'renk': Colors.red.shade700};
    } else if (nutriscore == 'c' || nova == 3) {
      return {'mesaj': '⚠️ DİKKATLİ TÜKETİLMELİ', 'renk': Colors.orange.shade800};
    } else if (nutriscore == 'a' || nutriscore == 'b' || nova == 1 || nova == 2) {
      return {'mesaj': '✅ TÜKETİLEBİLİR (Sağlıklı)', 'renk': Colors.green.shade700};
    } else {
      return {'mesaj': 'ℹ️ Yeterli Veri Yok', 'renk': Colors.grey.shade700};
    }
  }

  List<Map<String, dynamic>> icindekileriAnalizEt(String metin) {
    if (metin == 'İçindekiler bilgisi bulunamadı.' || metin.isEmpty) return [];
    List<String> parcalar = metin.split(',').map((e) => e.trim()).toList();
    List<Map<String, dynamic>> analiz = [];
    for (var parca in parcalar) {
      if (parca.isEmpty) continue;
      bool riskliMi = riskliMaddeler.any((risk) => parca.toLowerCase().contains(risk));
      analiz.add({'madde': parca, 'riskli': riskliMi});
    }
    return analiz;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ürün Sağlık Analizi', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: yukleniyor
          ? const Center(child: CircularProgressIndicator())
          : hataMesaji != null
              ? Center(child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(hataMesaji!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red, fontSize: 16)),
                ))
              : urunAdi == null
                  ? _buildBaslangicEkrani()
                  : _buildSonucEkrani(),
      floatingActionButton: urunAdi != null
          ? FloatingActionButton.extended(
              onPressed: _taramayiBaslat,
              backgroundColor: Colors.teal,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Yeni Ürün Tara'),
            )
          : null,
    );
  }

  void _taramayiBaslat() async {
    final barkod = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const TaramaEkrani()),
    );
    if (barkod != null) await urunSorgula(barkod);
  }

  Widget _buildBaslangicEkrani() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.document_scanner_outlined, size: 100, color: Colors.teal.shade200),
            const SizedBox(height: 24),
            const Text(
              'Ürünün barkodunu okutarak içeriğini ve sağlığa etkisini analiz edin.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: _taramayiBaslat,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Taramayı Başlat', style: TextStyle(fontSize: 18)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSonucEkrani() {
    List<Map<String, dynamic>> icerikAnalizi = icindekilerMetni != null ? icindekileriAnalizEt(icindekilerMetni!) : [];
    int riskliSayisi = icerikAnalizi.where((e) => e['riskli'] == true).length;

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 16, left: 20, right: 20, bottom: 24),
            decoration: BoxDecoration(
              color: Colors.teal.shade700,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                Container(
                  height: 120,
                  width: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: urunResmiUrl != null && urunResmiUrl!.isNotEmpty
                        ? Image.network(
                            urunResmiUrl!,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(child: CircularProgressIndicator());
                            },
                            errorBuilder: (context, error, stackTrace) => const Icon(
                              Icons.image_not_supported_outlined,
                              size: 50,
                              color: Colors.grey,
                            ),
                          )
                        : const Icon(
                            Icons.shopping_bag_outlined,
                            size: 60,
                            color: Colors.teal,
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  urunAdi!,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(detay ?? '', style: TextStyle(color: Colors.teal.shade100, fontSize: 14)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
                  ),
                  child: Text(
                    saglikDurumu ?? '',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: durumRengi),
                  ),
                ),
              ],
            ),
          ),
          
          const TabBar(
            labelColor: Colors.teal,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.teal,
            tabs: [
              Tab(text: 'İçindekiler Analizi', icon: Icon(Icons.science)),
              Tab(text: 'Tüm İçindekiler', icon: Icon(Icons.list_alt)),
            ],
          ),

          Expanded(
            child: TabBarView(
              children: [
                _buildAnalizSekmesi(icerikAnalizi, riskliSayisi),
                _buildTumIcerikSekmesi(icerikAnalizi),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalizSekmesi(List<Map<String, dynamic>> analiz, int riskliSayisi) {
    if (analiz.isEmpty) {
      return const Center(child: Text('İçindekiler listesi bulunamadı.'));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: riskliSayisi > 0 ? Colors.red.shade50 : Colors.green.shade50,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: riskliSayisi > 0 ? Colors.red.shade200 : Colors.green.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(
                  riskliSayisi > 0 ? Icons.warning_amber_rounded : Icons.verified_user,
                  color: riskliSayisi > 0 ? Colors.red : Colors.green,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    riskliSayisi > 0
                        ? 'Bu ürünün içeriğinde $riskliSayisi adet potansiyel riskli madde tespit edildi.'
                        : 'Harika! Bilinen yaygın riskli maddelerden hiçbiri bu üründe tespit edilmedi.',
                    style: TextStyle(
                      fontSize: 15,
                      color: riskliSayisi > 0 ? Colors.red.shade900 : Colors.green.shade900,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (riskliSayisi > 0) ...[
          const Text('⚠️ Tespit Edilen Riskli Maddeler:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          ...analiz.where((e) => e['riskli'] == true).map((e) => Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: Colors.red)),
                child: ListTile(
                  leading: const Icon(Icons.dangerous, color: Colors.red),
                  title: Text(e['madde'], style: const TextStyle(fontWeight: FontWeight.w500)),
                ),
              )),
        ] else ...[
           const Text('✅ İçerik Temiz Görünüyor:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
           const SizedBox(height: 8),
           ...analiz.take(5).map((e) => Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: Colors.green)),
                child: ListTile(
                  leading: const Icon(Icons.check_circle, color: Colors.green),
                  title: Text(e['madde'], style: const TextStyle(fontWeight: FontWeight.w500)),
                ),
              )),
        ]
      ],
    );
  }

  Widget _buildTumIcerikSekmesi(List<Map<String, dynamic>> analiz) {
    if (analiz.isEmpty) {
      return const Center(child: Text('İçindekiler listesi bulunamadı.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: analiz.length,
      itemBuilder: (context, index) {
        final madde = analiz[index];
        final isRiskli = madde['riskli'];
        return Card(
          elevation: 1,
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(
              isRiskli ? Icons.warning : Icons.check,
              color: isRiskli ? Colors.orange.shade800 : Colors.grey,
            ),
            title: Text(
              madde['madde'],
              style: TextStyle(
                fontWeight: isRiskli ? FontWeight.bold : FontWeight.normal,
                color: isRiskli ? Colors.orange.shade900 : Colors.black87,
              ),
            ),
          ),
        );
      },
    );
  }
}
