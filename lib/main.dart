import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'tarama_ekrani.dart';

// --- BARKODOKU.COM API ANAHTARLARI ---
const String BARKODOKU_USER_KEY = 'cTg8XiX4QPvYT37_n8In2KwHiBmhsjui';
const String BARKODOKU_API_KEY = 'UvCDBwMAHAkSMN4i1BNa8CwXXwq8OVqG-WRREBpIl08-sz7Nbcsri0ZqWOSQ21u7o';

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
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00897B), brightness: Brightness.dark),
        useMaterial3: true,
      ),
      home: MainScreen(isDarkMode: isDarkMode, onThemeChanged: toggleTheme),
    );
  }
}

// --- iOS İÇİN RESİM LİNKİ DÜZELTİCİ ---
String? _fixImageUrl(String? url) {
  if (url == null || url.isEmpty) return null;
  if (url.startsWith('http://')) return url.replaceFirst('http://', 'https://');
  return url;
}

// --- ÖZEL LOGO ---
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

// --- ÜRÜN MODELİ ---
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

// --- SAĞLIKLI ÜRÜN MODELİ (Çark İçin) ---
class HealthyItem {
  final String name;
  final String emoji;
  final String benefit;
  final Color color;

  HealthyItem(this.name, this.emoji, this.benefit, this.color);
}

final List<HealthyItem> healthyItems = [
  HealthyItem('Yeşil Elma', '🍏', 'Lif kaynağıdır, sindirimi rahatlatır ve bağışıklığı güçlendirir.', Colors.green.shade400),
  HealthyItem('Muz', '🍌', 'Potasyum deposudur, kas sağlığını destekler ve enerji verir.', Colors.yellow.shade600),
  HealthyItem('Yulaf', '🥣', 'Beta-glukan içerir, kolesterolü dengeler ve uzun süre tok tutar.', Colors.brown.shade300),
  HealthyItem('Badem', '🌰', 'E vitamini ve sağlıklı yağlar açısından zengindir, kalbi korur.', Colors.orange.shade400),
  HealthyItem('Kefir', '🥛', 'Probiyotik deposudur, bağırsak florasını mükemmel şekilde düzenler.', Colors.blue.shade300),
  HealthyItem('Yeşil Çay', '🍵', 'Güçlü antioksidanlar içerir, metabolizmayı hızlandırır.', Colors.teal.shade400),
  HealthyItem('Ispanak', '🥬', 'Demir ve magnezyum kaynağıdır, kan yapımını destekler.', Colors.green.shade700),
  HealthyItem('Yaban Mersini', '🫐', 'Hafızayı güçlendiren antioksidanlar bakımından çok zengindir.', Colors.indigo.shade400),
];

// --- ANA EKRAN ---
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

// --- SEKME 1: EV (TARAMA EKRANI) ---
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

  final List<String> riskliMaddeler = [
    'palm yağı', 'glikoz şurubu', 'yüksek fruktozlu mısır şurubu',
    'aspartam', 'msj', 'msg', 'sodyum nitrat', 'e621', 'e951', 'e330', 'şeker', 'sugar'
  ];

  Future<void> urunSorgula(String b) async {
    setState(() { yukleniyor = true; urunAdi = null; barkod = b; });
    try {
      var trSonuc = await _barkodokuSorgula(b);
      if (trSonuc != null) {
        _sonucuIsle(trSonuc['urunAdi'], trSonuc['icerik'], trSonuc['resimUrl'], isOff: false);
        return;
      }
      var offSonuc = await _openFoodFactsSorgula(b);
      if (offSonuc != null) {
        _sonucuIsle(offSonuc['urunAdi'], offSonuc['icerik'], offSonuc['resimUrl'], isOff: true, nutriscore: offSonuc['nutriscore'], nova: offSonuc['nova']);
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
      if (data is List && data.isNotEmpty) return {'urunAdi': data[0]['text'], 'icerik': data[0]['ingredients'] ?? 'İçerik yok', 'resimUrl': data[0]['image']};
      if (data is Map && data.containsKey('text')) return {'urunAdi': data['text'], 'icerik': data['ingredients'] ?? 'İçerik yok', 'resimUrl': data['image']};
    } catch (e) { return null; }
    return null;
  }

  Future<Map<String, dynamic>?> _openFoodFactsSorgula(String b) async {
    try {
      final res = await http.get(Uri.parse('https://world.openfoodfacts.org/api/v2/product/$b.json?fields=product_name,nutriscore_grade,nova_group,ingredients_text_tr,ingredients_text,image_url')).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['status'] == 1) return {'urunAdi': data['product']['product_name'], 'icerik': data['product']['ingredients_text_tr'] ?? data['product']['ingredients_text'] ?? 'İçerik yok', 'resimUrl': data['product']['image_url'], 'nutriscore': data['product']['nutriscore_grade'], 'nova': data['product']['nova_group']};
      }
    } catch (e) { return null; }
    return null;
  }

  void _sonucuIsle(String? ad, String? icerik, String? resim, {required bool isOff, String? nutriscore, int? nova}) {
    String durum = ''; Color renk = Colors.grey;
    if (isOff && nutriscore != null) {
      if (nutriscore == 'd' || nutriscore == 'e' || nova == 4) { durum = '⛔ ZARARLI'; renk = Colors.red; }
      else if (nutriscore == 'c' || nova == 3) { durum = '⚠️ DİKKATLİ TÜKET'; renk = Colors.orange; }
      else { durum = '✅ SAĞLIKLI'; renk = Colors.green; }
    } else {
      final analiz = icindekileriAnalizEt(icindekilerMetni ?? '');
      final risk = analiz.where((e) => e['riskli'] == true).length;
      if (risk > 0) { durum = '⚠️ $risk RİSKLİ MADDE'; renk = Colors.orange; } else { durum = '✅ TÜKETİLEBİLİR'; renk = Colors.green; }
    }
    setState(() {
      urunAdi = ad; icindekilerMetni = icerik; urunResmiUrl = _fixImageUrl(resim); 
      saglikDurumu = durum; durumRengi = renk; detay = isOff ? 'Küresel Veritabanı' : 'Türkiye Veritabanı';
    });
    _gecmiseKaydet(ad ?? 'İsimsiz', durum, _fixImageUrl(resim) ?? '');
  }

  List<Map<String, dynamic>> icindekileriAnalizEt(String metin) {
    if (metin.isEmpty) return [];
    return metin.split(',').where((e) => e.trim().isNotEmpty).map((e) {
      bool riskli = riskliMaddeler.any((r) => e.toLowerCase().contains(r));
      return {'madde': e.trim(), 'riskli': riskli};
    }).toList();
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
      appBar: AppBar(title: const Text('Sağlık Tarayıcı', style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Colors.teal.shade700, foregroundColor: Colors.white),
      body: yukleniyor ? const Center(child: CircularProgressIndicator()) : urunAdi == null ? _buildBaslangic() : _buildSonuc(),
    );
  }

  Widget _buildBaslangic() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const AppLogo(size: 120), const SizedBox(height: 30),
          const Text('Ürünlerin içeriğini\nanında analiz edin', textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            onPressed: _tara, icon: const Icon(Icons.qr_code_scanner, size: 28), label: const Text('Taramayı Başlat', style: TextStyle(fontSize: 20)),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20), backgroundColor: Colors.teal, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), elevation: 5),
          ),
        ],
      ),
    );
  }

  Widget _buildSonuc() {
    List<Map<String, dynamic>> analiz = icindekileriAnalizEt(icindekilerMetni ?? '');
    int riskli = analiz.where((e) => e['riskli'] == true).length;

    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            width: double.infinity, padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: durumRengi.withOpacity(0.1), borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
              border: Border.all(color: durumRengi.withOpacity(0.3), width: 2),
            ),
            child: Column(
              children: [
                Container(
                  height: 180, width: 180,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: durumRengi.withOpacity(0.2), blurRadius: 30, spreadRadius: 5, offset: const Offset(0, 10))]),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: (urunResmiUrl != null && urunResmiUrl!.isNotEmpty)
                        ? Image.network(urunResmiUrl!, fit: BoxFit.contain, errorBuilder: (c, e, s) => const Icon(Icons.shopping_bag, size: 80, color: Colors.grey))
                        : const Icon(Icons.shopping_bag, size: 80, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 20),
                Text(urunAdi!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(color: durumRengi, borderRadius: BorderRadius.circular(30)),
                  child: Text(saglikDurumu ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                const SizedBox(height: 8),
                Text(detay ?? '', style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (riskli > 0)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.shade200)),
                    child: Row(children: [const Icon(Icons.warning, color: Colors.red), const SizedBox(width: 10), Expanded(child: Text('Bu üründe $riskli adet riskli madde bulundu!', style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.bold)))]),
                  ),
                const SizedBox(height: 20),
                const Text('İçindekiler', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                ...analiz.map((e) => Card(
                  elevation: 0, color: e['riskli'] ? Colors.red.shade50 : Theme.of(context).cardColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: e['riskli'] ? Colors.red.shade200 : Colors.grey.shade300)),
                  child: ListTile(leading: Icon(e['riskli'] ? Icons.dangerous : Icons.check_circle, color: e['riskli'] ? Colors.red : Colors.green), title: Text(e['madde'], style: TextStyle(fontWeight: e['riskli'] ? FontWeight.bold : FontWeight.normal))),
                )),
                const SizedBox(height: 30),
                SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: _tara, icon: const Icon(Icons.qr_code_scanner), label: const Text('Yeni Ürün Tara'), style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), backgroundColor: Colors.teal, foregroundColor: Colors.white))),
                const SizedBox(height: 40),
              ],
            ),
          )
        ],
      ),
    );
  }
}

// --- SEKME 2: SAĞLIKLI ÖNERİ ÇARKI ---
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
            Text(item.emoji, style: const TextStyle(fontSize: 60)),
            const SizedBox(height: 16),
            Text(item.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text(item.benefit, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: Colors.grey)),
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
    return Scaffold(
      appBar: AppBar(title: const Text('Bugün Ne Yesem?'), backgroundColor: Colors.teal.shade700, foregroundColor: Colors.white),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Sağlıklı bir seçim için\nçarkı çevir!', textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 40),
            
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
                        child: CustomPaint(
                          size: const Size(300, 300),
                          painter: WheelPainter(healthyItems),
                        ),
                      );
                    },
                  ),
                  Positioned(
                    top: -10,
                    child: Icon(Icons.arrow_drop_down, size: 60, color: Colors.red.shade700),
                  ),
                  GestureDetector(
                    onTap: _spinWheel,
                    child: Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white, shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
                        border: Border.all(color: Colors.teal, width: 4)
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
            const SizedBox(height: 40),
            if (selectedItem != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(color: selectedItem!.color.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                child: Text('Bugünkü önerimiz: ${selectedItem!.name}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: selectedItem!.color)),
              )
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

      final textPainter = TextPainter(textDirection: TextDirection.ltr);
      textPainter.text = TextSpan(text: items[i].emoji, style: const TextStyle(fontSize: 30));
      textPainter.layout();
      
      final angle = (i * sliceAngle) + (sliceAngle / 2);
      final x = center.dx + (radius * 0.65) * cos(angle) - (textPainter.width / 2);
      final y = center.dy + (radius * 0.65) * sin(angle) - (textPainter.height / 2);
      
      textPainter.paint(canvas, Offset(x, y));
    }
    
    paint.color = Colors.teal.shade700;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 10;
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// --- SEKME 3: GEÇMİŞ ---
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
    return Scaffold(
      appBar: AppBar(title: const Text('Tarama Geçmişi'), backgroundColor: Colors.teal.shade700, foregroundColor: Colors.white),
      body: gecmisUrunler.isEmpty
          ? const Center(child: Text('Henüz bir ürün taramadınız.'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: gecmisUrunler.length,
              itemBuilder: (context, index) {
                final urun = gecmisUrunler[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: Container(
                      width: 50, height: 50, decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.grey.shade200),
                      child: ClipRRect(borderRadius: BorderRadius.circular(8), child: (urun.imageUrl.isNotEmpty) ? Image.network(urun.imageUrl, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.image)) : const Icon(Icons.image)),
                    ),
                    title: Text(urun.name, maxLines: 2, overflow: TextOverflow.ellipsis),
                    subtitle: Text('${urun.date.day}/${urun.date.month}/${urun.date.year}'),
                    trailing: Text(urun.status, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: urun.status.contains('ZARARLI') ? Colors.red : (urun.status.contains('RİSKLİ') ? Colors.orange : Colors.green))),
                  ),
                );
              },
            ),
    );
  }
}

// --- SEKME 4: AYARLAR ---
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
          const ListTile(leading: Icon(Icons.info), title: Text('Uygulama Hakkında'), subtitle: Text('Sağlık Tarayıcı v1.2\nİçerik analizi ve sağlıklı öneriler.')),
        ],
      ),
    );
  }
}
