import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'tarama_ekrani.dart';

void main() {
  runApp(const UrunTarayiciApp());
}

class UrunTarayiciApp extends StatelessWidget {
  const UrunTarayiciApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AnaEkran(),
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
  Color durumRengi = Colors.black;
  bool yukleniyor = false;

  Future<void> urunSorgula(String barkod) async {
    setState(() {
      yukleniyor = true;
      urunAdi = null;
      saglikDurumu = null;
      detay = null;
    });

    final url = Uri.parse(
      'https://world.openfoodfacts.org/api/v2/product/$barkod.json?fields=product_name,nutriscore_grade,nova_group,ingredients_text',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 1) {
          final product = data['product'];
          final nutriscore =
              (product['nutriscore_grade'] ?? '').toString().toLowerCase();
          final nova = product['nova_group'] ?? 0;

          final sonuc = saglikDurumuBelirle(nutriscore, nova);

          setState(() {
            urunAdi = product['product_name'] ?? 'Bilinmeyen Ürün';
            saglikDurumu = sonuc['mesaj'];
            detay =
                'Nutri-Score: ${nutriscore.isEmpty ? "?" : nutriscore.toUpperCase()}  |  NOVA Grubu: $nova';
            durumRengi = sonuc['renk'];
          });
        } else {
          setState(() {
            urunAdi = 'Ürün veritabanında bulunamadı.';
            saglikDurumu = null;
            detay = 'Bu ürün Open Food Facts veritabanında yok.';
          });
        }
      } else {
        setState(() => urunAdi = 'Bağlantı hatası oluştu.');
      }
    } catch (e) {
      setState(() => urunAdi = 'Hata: $e');
    } finally {
      setState(() => yukleniyor = false);
    }
  }

  Map<String, dynamic> saglikDurumuBelirle(String nutriscore, int nova) {
    if (nutriscore == 'd' || nutriscore == 'e' || nova == 4) {
      return {'mesaj': '⛔ TÜKETİLMESİ ZARARLI', 'renk': Colors.red};
    } else if (nutriscore == 'c' || nova == 3) {
      return {'mesaj': '⚠️ DİKKATLİ TÜKETİLMELİ', 'renk': Colors.orange};
    } else if (nutriscore == 'a' ||
        nutriscore == 'b' ||
        nova == 1 ||
        nova == 2) {
      return {'mesaj': '✅ TÜKETİLEBİLİR (Sağlıklı)', 'renk': Colors.green};
    } else {
      return {
        'mesaj': 'ℹ️ Yeterli veri yok',
        'renk': Colors.grey,
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ürün Sağlık Analizi'),
        backgroundColor: Colors.teal,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: yukleniyor
              ? const CircularProgressIndicator()
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (urunAdi != null) ...[
                      Text(
                        urunAdi!,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        detay ?? '',
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: durumRengi, width: 3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          saglikDurumu ?? '',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: durumRengi,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                    const SizedBox(height: 40),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final barkod = await Navigator.push<String>(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const TaramaEkrani()),
                        );
                        if (barkod != null) await urunSorgula(barkod);
                      },
                      icon: const Icon(Icons.qr_code_scanner),
                      label: const Text('Barkod Tara ve Analiz Et'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 16),
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
