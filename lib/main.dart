import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'tarama_ekrani.dart';

// --- BARKODOKU.COM API ANAHTARLARI ---
const String BARKODOKU_USER_KEY = 'cTg8XiX4QPvYT37_n8In2KwHiBmhsjui';
const String BARKODOKU_API_KEY = 'UvCDBwMAHAkSMN4i1BNa8CwXXwq8OVqG-WRREBpIl08-sz7Nbcsri0ZqWOSQ21u7o';

// --- ZARARLI MADDE SÖZLÜĞÜ ---
final Map<String, String> maddeBilgileri = {
  'şeker': 'Kan şekerini hızla yükseltir, diyabet ve obezite riskini artırır.',
  'sugar': 'Kan şekerini hızla yükseltir, diyabet ve obezite riskini artırır.',
  'glikoz şurubu': 'Yüksek fruktoz içerir, karaciğer yağlanmasına yol açar.',
  'glucose syrup': 'Yüksek fruktoz içerir, karaciğer yağlanmasına yol açar.',
  'fruktoz': 'Meyve şekeri olsa da ilave edildiğinde karaciğere zarar verir.',
  'fructose': 'Meyve şekeri olsa da ilave edildiğinde karaciğere zarar verir.',
  'palm yağı': 'Doymuş yağ oranı yüksektir, kolesterolü ve kalp hastalığı riskini artırır.',
  'palm oil': 'Doymuş yağ oranı yüksektir, kolesterolü ve kalp hastalığı riskini artırır.',
  'aspartam': 'Yapay tatlandırıcıdır. Aşırı tüketimi baş ağrısı ve migreni tetikleyebilir.',
  'aspartame': 'Yapay tatlandırıcıdır. Aşırı tüketimi baş ağrısı ve migreni tetikleyebilir.',
  'msj': 'MSG (Monosodyum Glutamat) iştahı açar ve doğal olmayan bir lezzet verir.',
  'msg': 'MSG (Monosodyum Glutamat) iştahı açar ve doğal olmayan bir lezzet verir.',
  'monosodyum glutamat': 'MSG (Monosodyum Glutamat) iştahı açar ve doğal olmayan bir lezzet verir.',
  'sodyum nitrat': 'İşlenmiş etlerde bulunur, kanserojen riski taşır.',
  'sodium nitrite': 'İşlenmiş etlerde bulunur, kanserojen riski taşır.',
  'kafein': 'Uyarıcıdır. Aşırı tüketimi uykusuzluk, çarpıntı ve anksiyete yapabilir.',
  'caffeine': 'Uyarıcıdır. Aşırı tüketimi uykusuzluk, çarpıntı ve anksiyete yapabilir.',
  'fosforik asit': 'Kolalarda bulunur, vücuttaki kalsiyumu çözer ve kemik erimesine yol açar.',
  'phosphoric acid': 'Kolalarda bulunur, vücuttaki kalsiyumu çözer ve kemik erimesine yol açar.',
  'tuz': 'Aşırı tuz tüketimi yüksek tansiyona ve böbrek hastalıklarına yol açar.',
  'salt': 'Aşırı tuz tüketimi yüksek tansiyona ve böbrek hastalıklarına yol açar.',
  'e621': 'MSG türevi lezzet artırıcıdır, alerjik reaksiyonlara neden olabilir.',
  'e951': 'Aspartam (yapay tatlandırıcı), fenilketonüri hastaları için tehlikelidir.',
  'e338': 'Fosforik asit, mide asidini artırır ve diş minesine zarar verebilir.',
  'sitrik asit': 'Genelde güvenli kabul edilir ancak mideyi rahatsız edebilir.',
  'e330': 'Sitrik asit, mideyi rahatsız edebilir.',
};

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
  bool isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  _loadTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isDarkMode = prefs.getBool('darkMode') ?? false;
    });
  }

  void toggleTheme(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isDarkMode = value;
      prefs.setBool('darkMode', value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sağlık Tarayıcı',
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00897B)),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00897B), brightness: Brightness.dark),
        useMaterial3: true,
      ),
      home: MainScreen(isDarkMode: isDarkMode, onThemeChanged: toggleTheme),
    );
  }
}

String? _fixImageUrl(String? url) {
  if (url == null || url.isEmpty) return null;
  if (url.startsWith('http://')) return url.replaceFirst('http://', 'https://');
  return url;
}

class AppLogo extends StatelessWidget {
  final double size;
  const AppLogo({super.key, this.size = 100});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00897B), Color(0xFF26A69A)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * 0.3),
        boxShadow: [
          BoxShadow(color: const Color(0xFF00897B).withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10))
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.qr_code_scanner, size: size * 0.6, color: Colors.white),
          Positioned(
            bottom: size * 0.2, right: size * 0.2,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle),
              child: Icon(Icons.eco, size: size * 0.15, color: Colors.black),
            ),
          )
        ],
      ),
    );
  }
}

class ScannedProduct {
  final String barcode;
  final String name;
  final String status;
  final String imageUrl;
  final DateTime date;

  ScannedProduct({required this.barcode, required this.name, required this.status, required this.imageUrl, required this.date});

  Map<String, dynamic> toJson() => {'barcode': barcode, 'name': name, 'status': status, 'imageUrl': imageUrl, 'date': date.toIso8601String()};

  factory ScannedProduct.fromJson(Map<String, dynamic> json) => ScannedProduct(
    barcode: json['barcode'], name: json['name'], status: json['status'], imageUrl: json['imageUrl'], date: DateTime.parse(json['date']),
  );
}

class HealthyItem {
  final String name;
  final String emoji;
  final String benefit;
  final Color color;
  HealthyItem(this.name, this.emoji, this.benefit, this.color);
}

final List<HealthyItem> healthyItems = [
  HealthyItem('Sütaş Kefir', '🥛', 'Probiyotik deposudur, bağırsak florasını düzenler.', Colors.blue.shade300),
  HealthyItem('Eti Form Bisküvi', '🍪', 'Tam buğday unu içerir, lif kaynağıdır.', Colors.brown.shade300),
  HealthyItem('Torku Tam Buğday', '🍞', 'Rafine şeker içermez, uzun süre tok tutar.', Colors.orange.shade400),
  HealthyItem('Dimes Şekersiz Su', '🧃', 'İlave şeker içermez, doğal vitaminlerle doludur.', Colors.purple.shade300),
  HealthyItem('Pınar Süt', '🥛', 'Kalsiyum ve D vitamini kaynağıdır.', Colors.grey.shade400),
  HealthyItem('Tadım Badem', '🌰', 'E vitamini ve sağlıklı yağlar açısından zengindir.', Colors.amber.shade600),
  HealthyItem('Doğadan Yeşil Çay', '🍵', 'Güçlü antioksidanlar içerir, metabolizmayı hızlandırır.', Colors.green.shade400),
  HealthyItem('Sek Kefir', '🍶', 'Bağışıklık sistemini güçlendirir.', Colors.teal.shade300),
];

class MainScreen extends StatefulWidget {
  final bool isDarkMode;
  final Function(bool) onThemeChanged;
  const MainScreen({super.key, required this.isDarkMode, required this.onThemeChanged});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> tabs = [
      const HomeTab(),
      const HealthyWheelTab(),
      const HistoryTab(),
      SettingsTab(isDarkMode: widget.isDarkMode, onThemeChanged: widget.onThemeChanged),
    ];

    return Scaffold(
      body: tabs[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.qr_code_scanner), label: 'Tara'),
          NavigationDestination(icon: Icon(Icons.casino), label: 'Öneri'),
          NavigationDestination(icon: Icon(Icons.history), label: 'Geçmiş'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Ayarlar'),
        ],
      ),
    );
  }
}

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});
  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  String? urunAdi;
  String? saglikDurumu;
  String? detay;
  String? icindekilerMetni;
  String? urunResmiUrl;
  String? barkod;
  Color durumRengi = Colors.black;
  bool yukleniyor = false;

  Future<void> urunSorgula(String b) async {
    setState(() { yukleniyor = true; urunAdi = null; barkod = b; });
    
    try {
      var trSonuc = await _barkodokuSorgula(b);
      var offSonuc = await _openFoodFactsSorgula(b);
      
      String? finalName;
      String? finalIngredients;
      String? finalImage;
      bool isOff = false;
      String? nutriscore;
      int? nova;

      // İsim seçimi
      if (trSonuc != null && trSonuc['urunAdi'].toString().isNotEmpty) {
        finalName = trSonuc['urunAdi'];
      } else if (offSonuc != null) {
        finalName = offSonuc['urunAdi'];
      }

      // İçerik seçimi (En uzun/detaylı içeriği seç)
      String trIcerik = trSonuc?['icerik'] ?? '';
      String offIcerik = offSonuc?['icerik'] ?? '';
      
      if (trIcerik.isNotEmpty && trIcerik != 'İçerik yok' && trIcerik.length >= offIcerik.length) {
        finalIngredients = trIcerik;
      } else if (offIcerik.isNotEmpty) {
        finalIngredients = offIcerik;
        isOff = true;
        nutriscore = offSonuc?['nutriscore'];
        nova = offSonuc?['nova'];
      }

      // Resim seçimi
      if (trSonuc != null && trSonuc['resimUrl'] != null && trSonuc['resimUrl'].toString().isNotEmpty) {
        finalImage = trSonuc['resimUrl'];
      } else if (offSonuc != null && offSonuc['resimUrl'] != null) {
        finalImage = offSonuc['resimUrl'];
      }

      if (finalName != null && finalName.isNotEmpty) {
        _sonucuIsle(finalName, finalIngredients, finalImage, isOff: isOff, nutriscore: nutriscore, nova: nova);
      } else {
        setState(() => urunAdi = 'Ürün Bulunamadı');
      }
    } catch (e) {
      setState(() => urunAdi = 'Bağlantı Hatası');
    } finally {
      setState(() => yukleniyor = false);
    }
  }

  Future<Map<String, dynamic>?> _barkodokuSorgula(String b) async {
    try {
      final tokenRes = await http.post(Uri.parse('https://www.barkodoku.com/api/auth/getToken'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'userKey': BARKODOKU_USER_KEY, 'apiKey': BARKODOKU_API_KEY})).timeout(const Duration(seconds: 10));
      if (tokenRes.statusCode != 200) return null;
      final token = jsonDecode(tokenRes.body)['token'];

      final barcodeRes = await http.post(Uri.parse('https://www.barkodoku.com/api/barcode'),
          headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
          body: jsonEncode({'barcode': b})).timeout(const Duration(seconds: 10));
      
      if (barcodeRes.statusCode != 200) return null;
      final data = jsonDecode(barcodeRes.body);
      
      Map<String, dynamic>? urun;
      if (data is List && data.isNotEmpty) {
        urun = Map<String, dynamic>.from(data[0]);
      } else if (data is Map && data.containsKey('text')) {
        urun = Map<String, dynamic>.from(data);
      }

      if (urun != null) {
        return {
          'urunAdi': urun['text'] ?? urun['name'] ?? '',
          'icerik': urun['ingredients'] ?? urun['description'] ?? '',
          'resimUrl': urun['image'] ?? urun['imageUrl'] ?? '',
        };
      }
    } catch (e) { return null; }
    return null;
  }

  Future<Map<String, dynamic>?> _openFoodFactsSorgula(String b) async {
    try {
      final res = await http.get(Uri.parse('https://world.openfoodfacts.org/api/v2/product/$b.json?fields=product_name,nutriscore_grade,nova_group,ingredients_text_tr,ingredients_text,image_url')).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['status'] == 1) {
          return {
            'urunAdi': data['product']['product_name'], 
            'icerik': data['product']['ingredients_text_tr'] ?? data['product']['ingredients_text'] ?? '', 
            'resimUrl': data['product']['image_url'], 
            'nutriscore': data['product']['nutriscore_grade'], 
            'nova': data['product']['nova_group']
          };
        }
      }
    } catch (e) { return null; }
    return null;
  }

  void _sonucuIsle(String? ad, String? icerik, String? resim, {required bool isOff, String? nutriscore, int? nova}) {
    String durum = ''; Color renk = Colors.grey;
    
    final analiz = icindekileriAnalizEt(icerik ?? '');
    int toplamMadde = analiz.length;
    int riskliMadde = analiz.where((e) => e['riskli'] == true).length;

    // Eğer içerik listesi varsa, KESİNLİKLE içeriğe göre karar ver.
    if (toplamMadde > 0) {
      double riskOrani = riskliMadde / toplamMadde;
      
      if (riskliMadde == 0) {
        durum = '✅ SAĞLIKLI'; renk = Colors.green;
      } else if (toplamMadde <= 5 && riskliMadde <= 1) {
        // Az maddeli (ekmek gibi) ve tek riskli (tuz) ise sağlıklı kabul et ama uyar
        durum = '✅ TÜKETİLEBİLİR'; renk = Colors.green;
      } else if (riskliMadde >= 3 || riskOrani > 0.4) {
        durum = '⛔ ZARARLI'; renk = Colors.red;
      } else {
        durum = '⚠️ DİKKATLİ TÜKET'; renk = Colors.orange;
      }
    } 
    // İçerik hiç yoksa, Open Food Facts'in Nutri-Score'una güven
    else if (isOff && nutriscore != null) {
      if (nutriscore == 'd' || nutriscore == 'e' || nova == 4) { durum = '⛔ ZARARLI'; renk = Colors.red; }
      else if (nutriscore == 'c' || nova == 3) { durum = '⚠️ DİKKATLİ TÜKET'; renk = Colors.orange; }
      else { durum = '✅ SAĞLIKLI'; renk = Colors.green; }
    } else {
      durum = 'ℹ️ VERİ YETERSİZ'; renk = Colors.grey;
    }

    setState(() {
      urunAdi = ad; 
      icindekilerMetni = icerik; 
      urunResmiUrl = _fixImageUrl(resim); 
      saglikDurumu = durum; 
      durumRengi = renk; 
      detay = isOff ? 'Küresel Veritabanı' : 'Türkiye Veritabanı';
    });
    _gecmiseKaydet(ad ?? 'İsimsiz', durum, _fixImageUrl(resim) ?? '');
  }

  List<Map<String, dynamic>> icindekileriAnalizEt(String metin) {
    if (metin.isEmpty || metin == 'İçerik yok') return [];
    List<String> parcalar = metin.split(RegExp(r'[,;]')).map((e) => e.trim()).toList();
    List<Map<String, dynamic>> analiz = [];
    
    for (var parca in parcalar) {
      if (parca.isEmpty) continue;
      String maddeKucuk = parca.toLowerCase();
      bool riskli = false;
      String aciklama = '';

      for (var key in maddeBilgileri.keys) {
        if (maddeKucuk.contains(key)) {
          riskli = true;
          aciklama = maddeBilgileri[key]!;
          break;
        }
      }
      analiz.add({'madde': parca, 'riskli': riskli, 'aciklama': aciklama});
    }
    return analiz;
  }

  _gecmiseKaydet(String ad, String durum, String resim) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> gecmis = prefs.getStringList('gecmis') ?? [];
    ScannedProduct urun = ScannedProduct(barcode: barkod!, name: ad, status: durum, imageUrl: resim, date: DateTime.now());
    gecmis.insert(0, jsonEncode(urun.toJson()));
    if (gecmis.length > 50) gecmis.removeLast();
    prefs.setStringList('gecmis', gecmis);
  }

  void _tara() async {
    final b = await Navigator.push<String>(context, MaterialPageRoute(builder: (context) => const TaramaEkrani()));
    if (b != null) await urunSorgula(b);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sağlık Tarayıcı', style: TextStyle(fontWeight: FontWeight.bold)), 
        backgroundColor: Colors.teal.shade700, foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: yukleniyor ? const Center(child: CircularProgressIndicator()) : urunAdi == null ? _buildBaslangic() : _buildSonuc(),
    );
  }

  Widget _buildBaslangic() {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const AppLogo(size: 130), const SizedBox(height: 30),
          Text('Ürünlerin içeriğini\nanında analiz edin', textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
          const SizedBox(height: 10),
          Text('Katkı maddelerini ve riskleri öğrenin', style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 16)),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            onPressed: _tara, icon: const Icon(Icons.qr_code_scanner, size: 28), label: const Text('Taramayı Başlat', style: TextStyle(fontSize: 20)),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20), backgroundColor: Colors.teal.shade700, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), elevation: 5),
          ),
        ],
      ),
    );
  }

  Widget _buildSonuc() {
    List<Map<String, dynamic>> analiz = icindekileriAnalizEt(icindekilerMetni ?? '');
    int riskli = analiz.where((e) => e['riskli'] == true).length;
    bool hasImage = urunResmiUrl != null && urunResmiUrl!.isNotEmpty;
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Column(
        children: [
          // ÜST KISIM
          Container(
            width: double.infinity, padding: const EdgeInsets.fromLTRB(24, 10, 24, 30),
            decoration: BoxDecoration(
              color: durumRengi.withOpacity(0.08), 
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
              border: Border(bottom: BorderSide(color: durumRengi.withOpacity(0.3), width: 2)),
            ),
            child: Column(
              children: [
                Container(
                  height: 160, width: 160,
                  decoration: BoxDecoration(
                    color: theme.cardColor, 
                    borderRadius: BorderRadius.circular(24), 
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 8))]
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: hasImage
                        ? Image.network(urunResmiUrl!, fit: BoxFit.contain, errorBuilder: (c, e, s) => Icon(Icons.shopping_bag, size: 80, color: theme.disabledColor))
                        : Icon(Icons.shopping_bag, size: 80, color: theme.disabledColor), 
                  ),
                ),
                const SizedBox(height: 20),
                Text(urunAdi!, textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: durumRengi, 
                    borderRadius: BorderRadius.circular(30), 
                    boxShadow: [BoxShadow(color: durumRengi.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 5))]
                  ),
                  child: Text(saglikDurumu ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                const SizedBox(height: 8),
                Text(detay ?? '', style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 13)),
              ],
            ),
          ),

          // İÇERİK ANALİZİ
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (riskli > 0)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.15), // Karanlık modda da belli olması için opaklık artırıldı
                      borderRadius: BorderRadius.circular(12), 
                      border: Border.all(color: Colors.red.withOpacity(0.3))
                    ),
                    child: Row(children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 30), 
                      const SizedBox(width: 12), 
                      Expanded(child: Text('Dikkat! İçeriğinde $riskli adet riskli madde bulundu. Detaylar aşağıda.', style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.bold)))
                    ]),
                  ),
                const SizedBox(height: 20),
                Text('İçindekiler ve Etkileri', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
                const SizedBox(height: 12),
                if (analiz.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Center(child: Text('Bu ürün için içerik bilgisi bulunamadı.', style: TextStyle(color: theme.disabledColor))),
                  ),
                ...analiz.map((e) => Card(
                  elevation: 0, 
                  margin: const EdgeInsets.only(bottom: 10),
                  color: e['riskli'] ? Colors.red.withOpacity(0.1) : theme.cardColor, // Kart rengi temaya uygun
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: e['riskli'] ? Colors.red.withOpacity(0.3) : theme.dividerColor)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(e['riskli'] ? Icons.dangerous : Icons.check_circle, color: e['riskli'] ? Colors.red : Colors.green),
                            const SizedBox(width: 10),
                            // Yazı rengi temaya uygun
                            Expanded(child: Text(e['madde'], style: TextStyle(fontSize: 16, fontWeight: e['riskli'] ? FontWeight.bold : FontWeight.w500, color: theme.textTheme.bodyLarge?.color))),
                          ],
                        ),
                        if (e['riskli'])
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0, left: 34),
                            child: Text(
                              e['aciklama'],
                              style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 14, fontStyle: FontStyle.italic),
                            ),
                          ),
                      ],
                    ),
                  ),
                )),
                const SizedBox(height: 30),
                SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: _tara, icon: const Icon(Icons.qr_code_scanner), label: const Text('Yeni Ürün Tara'), style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), backgroundColor: Colors.teal.shade700, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))))),
                const SizedBox(height: 40),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class HealthyWheelTab extends StatefulWidget {
  const HealthyWheelTab({super.key});
  @override
  State<HealthyWheelTab> createState() => _HealthyWheelTabState();
}

class _HealthyWheelTabState extends State<HealthyWheelTab> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool isSpinning = false;
  HealthyItem? selectedItem;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 4));
    _animation = Tween<double>(begin: 0, end: 0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _spinWheel() {
    if (isSpinning) return;
    setState(() { isSpinning = true; selectedItem = null; });

    int randomTurns = 5 + Random().nextInt(4);
    double randomAngle = Random().nextDouble() * 2 * pi;
    double targetAngle = (randomTurns * 2 * pi) + randomAngle;

    _animation = Tween<double>(begin: _animation.value, end: targetAngle).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic)
    );

    _controller.reset();
    _controller.forward().then((_) {
      double normalizedAngle = (2 * pi - (targetAngle % (2 * pi))) % (2 * pi);
      double sliceAngle = (2 * pi) / healthyItems.length;
      int selectedIndex = (normalizedAngle / sliceAngle).floor() % healthyItems.length;

      setState(() {
        selectedItem = healthyItems[selectedIndex];
        isSpinning = false;
      });
      _showResultDialog(selectedItem!);
    });
  }

  void _showResultDialog(HealthyItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: item.color.withOpacity(0.2), shape: BoxShape.circle),
              child: Text(item.emoji, style: const TextStyle(fontSize: 50)),
            ),
            const SizedBox(height: 16),
            Text(item.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text(item.benefit, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: item.color, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Harika, Kapat'),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Market Önerisi'), backgroundColor: Colors.teal.shade700, foregroundColor: Colors.white),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Bugün hangi sağlıklı\nürünü tüketelim?', textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
            const SizedBox(height: 10),
            Text('Çarkı çevir ve şansını dene!', style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 16)),
            const SizedBox(height: 30),
            SizedBox(
              width: 300, height: 300,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _animation.value,
                        child: CustomPaint(size: const Size(300, 300), painter: WheelPainter(healthyItems)),
                      );
                    },
                  ),
                  Positioned(top: -5, child: Icon(Icons.arrow_drop_down, size: 70, color: Colors.red.shade700)),
                  GestureDetector(
                    onTap: _spinWheel,
                    child: Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white, shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))],
                        border: Border.all(color: Colors.teal, width: 5)
                      ),
                      child: Center(
                        child: isSpinning 
                          ? const CircularProgressIndicator(color: Colors.teal)
                          : const Text('ÇEVİR', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal, fontSize: 16)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WheelPainter extends CustomPainter {
  final List<HealthyItem> items;
  WheelPainter(this.items);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final paint = Paint()..style = PaintingStyle.fill;
    final sliceAngle = (2 * pi) / items.length;

    for (int i = 0; i < items.length; i++) {
      paint.color = items[i].color;
      canvas.drawArc(rect, i * sliceAngle, sliceAngle, true, paint);
      final linePaint = Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 2;
      canvas.drawLine(center, Offset(center.dx + radius * cos(i * sliceAngle), center.dy + radius * sin(i * sliceAngle)), linePaint);

      final textPainter = TextPainter(textDirection: TextDirection.ltr);
      textPainter.text = TextSpan(text: items[i].emoji, style: const TextStyle(fontSize: 34));
      textPainter.layout();
      final angle = (i * sliceAngle) + (sliceAngle / 2);
      final x = center.dx + (radius * 0.65) * cos(angle) - (textPainter.width / 2);
      final y = center.dy + (radius * 0.65) * sin(angle) - (textPainter.height / 2);
      textPainter.paint(canvas, Offset(x, y));
    }
    paint.color = Colors.teal.shade700;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 12;
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class HistoryTab extends StatefulWidget {
  const HistoryTab({super.key});
  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  List<ScannedProduct> gecmisUrunler = [];

  @override
  void initState() {
    super.initState();
    _gecmisiYukle();
  }

  _gecmisiYukle() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? gecmis = prefs.getStringList('gecmis');
    if (gecmis != null) {
      setState(() { gecmisUrunler = gecmis.map((e) => ScannedProduct.fromJson(jsonDecode(e))).toList(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Tarama Geçmişi'), backgroundColor: Colors.teal.shade700, foregroundColor: Colors.white),
      body: gecmisUrunler.isEmpty
          ? Center(child: Text('Henüz bir ürün taramadınız.', style: TextStyle(color: theme.disabledColor)))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: gecmisUrunler.length,
              itemBuilder: (context, index) {
                final urun = gecmisUrunler[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  color: theme.cardColor,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(10),
                    leading: Container(
                      width: 55, height: 55, decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: theme.scaffoldBackgroundColor),
                      child: ClipRRect(borderRadius: BorderRadius.circular(8), child: (urun.imageUrl.isNotEmpty) ? Image.network(urun.imageUrl, fit: BoxFit.cover, errorBuilder: (c, e, s) => Icon(Icons.image, color: theme.disabledColor)) : Icon(Icons.image, color: theme.disabledColor)),
                    ),
                    title: Text(urun.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
                    subtitle: Text('${urun.date.day}/${urun.date.month}/${urun.date.year}', style: TextStyle(fontSize: 12, color: theme.textTheme.bodySmall?.color)),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: urun.status.contains('ZARARLI') ? Colors.red.withOpacity(0.1) : (urun.status.contains('RİSKLİ') || urun.status.contains('DİKKATLİ') ? Colors.orange.withOpacity(0.1) : Colors.green.withOpacity(0.1)),
                        borderRadius: BorderRadius.circular(8)
                      ),
                      child: Text(urun.status, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: urun.status.contains('ZARARLI') ? Colors.red : (urun.status.contains('RİSKLİ') || urun.status.contains('DİKKATLİ') ? Colors.orange.shade800 : Colors.green))),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class SettingsTab extends StatelessWidget {
  final bool isDarkMode;
  final Function(bool) onThemeChanged;

  const SettingsTab({super.key, required this.isDarkMode, required this.onThemeChanged});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar'), backgroundColor: Colors.teal.shade700, foregroundColor: Colors.white),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Karanlık Mod'),
            subtitle: const Text('Göz yormayan karanlık tema'),
            secondary: const Icon(Icons.dark_mode),
            value: isDarkMode,
            onChanged: onThemeChanged,
          ),
          const Divider(),
          const ListTile(leading: Icon(Icons.info), title: Text('Uygulama Hakkında'), subtitle: Text('Sağlık Tarayıcı v2.2\nİçerik analizi ve market önerileri.')),
        ],
      ),
    );
  }
}
