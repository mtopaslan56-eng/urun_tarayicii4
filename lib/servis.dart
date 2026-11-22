import 'dart:convert';
import 'package:http/http.dart' as http;
import 'analiz.dart';
import 'anahtarlar.dart';

class UrunBilgisi {
  final String ad;
  final String icerik;
  final String? resimUrl;
  final String kaynak;
  final String? nutriscore;
  final int? nova;
  final Besin? besin;

  const UrunBilgisi({
    required this.ad,
    required this.icerik,
    required this.kaynak,
    this.resimUrl,
    this.nutriscore,
    this.nova,
    this.besin,
  });
}

class UrunSonuc {
  final UrunBilgisi? urun;
  final bool baglantiHatasi;
  const UrunSonuc(this.urun, this.baglantiHatasi);
}

class _Cevap {
  final Map<String, dynamic>? veri;
  final bool hata;
  const _Cevap(this.veri, this.hata);
}

String? resimUrlDuzelt(String? url) {
  if (url == null || url.isEmpty) return null;
  if (url.startsWith('http://')) return url.replaceFirst('http://', 'https://');
  return url;
}

class UrunServisi {
  static String _s(dynamic v) => v == null ? '' : v.toString().trim();

  static double? _sayi(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.replaceAll(',', '.'));
    return null;
  }

  static Future<UrunSonuc> sorgula(String barkod) async {
    final cevaplar = await Future.wait<_Cevap>([
      _barkodoku(barkod),
      _openFoodFacts(barkod),
    ]);
    final tr = cevaplar[0].veri;
    final off = cevaplar[1].veri;

    var ad = _s(tr?['urunAdi']);
    final trAdVar = ad.isNotEmpty;
    if (ad.isEmpty) ad = _s(off?['urunAdi']);
    if (ad.isEmpty) {
      return UrunSonuc(null, cevaplar[1].hata && tr == null);
    }

    var trIcerik = _s(tr?['icerik']);
    if (trIcerik.toLowerCase() == 'içerik yok' || trIcerik.toLowerCase() == 'icerik yok') {
      trIcerik = '';
    }
    final offIcerik = _s(off?['icerik']);

    var icerik = '';
    var offKullan = false;
    if (trIcerik.isNotEmpty && trIcerik.length >= offIcerik.length) {
      icerik = trIcerik;
    } else if (offIcerik.isNotEmpty) {
      icerik = offIcerik;
      offKullan = true;
    }

    String? resim;
    if (_s(tr?['resimUrl']).isNotEmpty) {
      resim = _s(tr?['resimUrl']);
    } else if (_s(off?['resimUrl']).isNotEmpty) {
      resim = _s(off?['resimUrl']);
    }

    final kuresel = offKullan || !trAdVar;

    return UrunSonuc(
      UrunBilgisi(
        ad: ad,
        icerik: icerik,
        kaynak: kuresel ? 'Küresel Veritabanı' : 'Türkiye Veritabanı',
        resimUrl: resimUrlDuzelt(resim),
        nutriscore: off?['nutriscore'] as String?,
        nova: off?['nova'] as int?,
        besin: off?['besin'] as Besin?,
      ),
      false,
    );
  }

  static Future<_Cevap> _barkodoku(String b) async {
    if (barkodokuUserKey.startsWith('BURAYA') || barkodokuApiKey.startsWith('BURAYA')) {
      return const _Cevap(null, false);
    }
    try {
      final tokenRes = await http
          .post(
            Uri.parse('https://www.barkodoku.com/api/auth/getToken'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'userKey': barkodokuUserKey, 'apiKey': barkodokuApiKey}),
          )
          .timeout(const Duration(seconds: 10));
      if (tokenRes.statusCode != 200) return const _Cevap(null, false);
      final token = jsonDecode(tokenRes.body)['token'];

      final barcodeRes = await http
          .post(
            Uri.parse('https://www.barkodoku.com/api/barcode'),
            headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
            body: jsonEncode({'barcode': b}),
          )
          .timeout(const Duration(seconds: 10));
      if (barcodeRes.statusCode != 200) return const _Cevap(null, false);

      final data = jsonDecode(barcodeRes.body);
      Map<String, dynamic>? urun;
      if (data is List && data.isNotEmpty) {
        urun = Map<String, dynamic>.from(data[0]);
      } else if (data is Map && data.containsKey('text')) {
        urun = Map<String, dynamic>.from(data);
      }
      if (urun == null) return const _Cevap(null, false);

      return _Cevap({
        'urunAdi': urun['text'] ?? urun['name'] ?? '',
        'icerik': urun['ingredients'] ?? urun['description'] ?? '',
        'resimUrl': urun['image'] ?? urun['imageUrl'] ?? '',
      }, false);
    } catch (_) {
      return const _Cevap(null, true);
    }
  }

  static Future<_Cevap> _openFoodFacts(String b) async {
    try {
      final res = await http
          .get(
            Uri.parse(
              'https://world.openfoodfacts.org/api/v2/product/$b.json'
              '?fields=product_name,nutriscore_grade,nova_group,ingredients_text_tr,ingredients_text,image_url,nutriments',
            ),
            headers: {'User-Agent': 'UrunTarayici/2.4 (Flutter)'},
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return const _Cevap(null, false);

      final data = jsonDecode(res.body);
      if (data['status'] != 1) return const _Cevap(null, false);
      final p = data['product'] as Map<String, dynamic>;

      final ns = _s(p['nutriscore_grade']).toLowerCase();
      final nutriments = p['nutriments'];
      Besin? besin;
      if (nutriments is Map) {
        final bs = Besin(
          kcal: _sayi(nutriments['energy-kcal_100g']),
          seker: _sayi(nutriments['sugars_100g']),
          yag: _sayi(nutriments['fat_100g']),
          doymusYag: _sayi(nutriments['saturated-fat_100g']),
          protein: _sayi(nutriments['proteins_100g']),
          lif: _sayi(nutriments['fiber_100g']),
          tuz: _sayi(nutriments['salt_100g']),
        );
        if (!bs.bos) besin = bs;
      }

      final trIcerik = _s(p['ingredients_text_tr']);
      return _Cevap({
        'urunAdi': _s(p['product_name']),
        'icerik': trIcerik.isNotEmpty ? trIcerik : _s(p['ingredients_text']),
        'resimUrl': _s(p['image_url']),
        'nutriscore': const ['a', 'b', 'c', 'd', 'e'].contains(ns) ? ns : null,
        'nova': _sayi(p['nova_group'])?.round(),
        'besin': besin,
      }, false);
    } catch (_) {
      return const _Cevap(null, true);
    }
  }
}
