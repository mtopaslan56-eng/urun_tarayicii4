enum Seviye { iyi, orta, kotu, bilinmiyor }

String norm(String s) {
  const kaynak = 'İIıÇçĞğÖöŞşÜü';
  const hedef = 'iiiccggoossuu';
  final sb = StringBuffer();
  for (final r in s.runes) {
    final ch = String.fromCharCode(r);
    final i = kaynak.indexOf(ch);
    sb.write(i >= 0 ? hedef[i] : ch);
  }
  return sb.toString().toLowerCase();
}

String _hazirla(String s) {
  return norm(s).replaceAllMapped(
    RegExp(r'(^|[^a-z0-9])e[\s\-]?(\d{3,4})'),
    (m) => '${m[1]}e${m[2]}',
  );
}

class Besin {
  final double? kcal;
  final double? seker;
  final double? yag;
  final double? doymusYag;
  final double? protein;
  final double? lif;
  final double? tuz;

  const Besin({
    this.kcal,
    this.seker,
    this.yag,
    this.doymusYag,
    this.protein,
    this.lif,
    this.tuz,
  });

  bool get bos =>
      kcal == null &&
      seker == null &&
      yag == null &&
      doymusYag == null &&
      protein == null &&
      lif == null &&
      tuz == null;

  Map<String, dynamic> toJson() => {
        'kcal': kcal,
        'seker': seker,
        'yag': yag,
        'doymusYag': doymusYag,
        'protein': protein,
        'lif': lif,
        'tuz': tuz,
      };

  factory Besin.fromJson(Map<String, dynamic> j) => Besin(
        kcal: (j['kcal'] as num?)?.toDouble(),
        seker: (j['seker'] as num?)?.toDouble(),
        yag: (j['yag'] as num?)?.toDouble(),
        doymusYag: (j['doymusYag'] as num?)?.toDouble(),
        protein: (j['protein'] as num?)?.toDouble(),
        lif: (j['lif'] as num?)?.toDouble(),
        tuz: (j['tuz'] as num?)?.toDouble(),
      );
}

class Madde {
  final String grup;
  final String ad;
  final List<String> anahtarlar;
  final List<String> haric;
  final int risk; // 0: nötr, 1: dikkat, 2: yüksek
  final bool olumlu;
  final bool siraHassas;
  final Set<String> etiketler;
  final String aciklama;

  Madde({
    required this.grup,
    required this.ad,
    required List<String> anahtarlar,
    List<String> haric = const [],
    this.risk = 0,
    this.olumlu = false,
    this.siraHassas = false,
    this.etiketler = const <String>{},
    required this.aciklama,
  })  : anahtarlar = anahtarlar.map(norm).toList(),
        haric = haric.map(norm).toList();
}

final List<Madde> maddeler = [
  // ---------- Yüksek riskli ----------
  Madde(
    grup: 'trans',
    ad: 'Hidrojenize yağ',
    anahtarlar: ['hidrojenize', 'hidrojene', 'hydrogenated'],
    risk: 2,
    etiketler: {'trans', 'doymus_yag'},
    aciklama: 'Trans yağ kaynağı olabilir; LDL kolesterolü yükseltir ve kalp-damar sağlığını olumsuz etkiler.',
  ),
  Madde(
    grup: 'nitrit',
    ad: 'Nitrit / nitrat',
    anahtarlar: ['nitrit', 'nitrat', 'nitrite', 'nitrate', 'e249', 'e250', 'e251', 'e252'],
    risk: 2,
    etiketler: {'nitrit', 'islenmis_et'},
    aciklama: 'İşlenmiş etlerde koruyucu olarak kullanılır; düzenli tüketimi sağlık açısından risklidir.',
  ),
  Madde(
    grup: 'e171',
    ad: 'Titanyum dioksit',
    anahtarlar: ['e171', 'titanyum dioksit', 'titanium dioxide'],
    risk: 2,
    etiketler: {'katki'},
    aciklama: "Beyazlatıcı katkı maddesidir; güvenlik endişeleri nedeniyle gıdalarda kullanımı sakıncalı görülür.",
  ),

  // ---------- Şeker ve hızlı karbonhidratlar ----------
  Madde(
    grup: 'seker',
    ad: 'Glikoz-fruktoz şurubu',
    anahtarlar: [
      'glikoz surubu', 'glukoz surubu', 'glikoz-fruktoz', 'glukoz-fruktoz', 'glikoz fruktoz',
      'fruktoz surubu', 'misir surubu', 'glucose syrup', 'glucose-fructose', 'fructose syrup',
      'high fructose', 'corn syrup', 'hfcs', 'invert seker',
    ],
    risk: 1,
    siraHassas: true,
    etiketler: {'seker', 'hizli_karb'},
    aciklama: 'Kan şekerini hızla yükseltir; fazlası kilo artışı ve karaciğer yağlanmasıyla ilişkilidir.',
  ),
  Madde(
    grup: 'seker',
    ad: 'Fruktoz',
    anahtarlar: ['fruktoz', 'fructose'],
    risk: 1,
    siraHassas: true,
    etiketler: {'seker', 'hizli_karb'},
    aciklama: 'İlave edildiğinde fazlası karaciğer yükünü ve kilo kontrolünde zorlanmayı artırabilir.',
  ),
  Madde(
    grup: 'seker',
    ad: 'Maltodekstrin / dekstroz',
    anahtarlar: ['maltodekstrin', 'maltodextrin', 'dekstroz', 'dextrose'],
    risk: 1,
    siraHassas: true,
    etiketler: {'seker', 'hizli_karb'},
    aciklama: 'Hızlı emilen karbonhidrattır; kan şekerini çabuk yükseltir.',
  ),
  Madde(
    grup: 'seker',
    ad: 'Şeker',
    anahtarlar: ['seker', 'sugar', 'sakaroz', 'sucrose'],
    haric: ['sekersiz', 'seker ilavesiz', 'sut sekeri', 'sugar free', 'sugar-free', 'no sugar', 'without sugar'],
    risk: 1,
    siraHassas: true,
    etiketler: {'seker', 'hizli_karb'},
    aciklama: 'İlave şeker kan şekerini hızla yükseltir; fazlası kilo kontrolü ve metabolik sağlık açısından risklidir.',
  ),

  // ---------- Yağlar ----------
  Madde(
    grup: 'palm',
    ad: 'Palm yağı',
    anahtarlar: ['palm', 'palm yag', 'palm oil', 'palmiye yag', 'palmolein', 'palm kernel', 'palmiste'],
    risk: 1,
    siraHassas: true,
    etiketler: {'doymus_yag'},
    aciklama: 'Doymuş yağ oranı yüksektir; fazla tüketimi kolesterol ve kalp sağlığı riskini artırabilir.',
  ),

  // ---------- Tatlandırıcılar ----------
  Madde(
    grup: 'aspartam',
    ad: 'Aspartam',
    anahtarlar: ['aspartam', 'aspartame', 'e951'],
    risk: 1,
    etiketler: {'yapay_tatli', 'tatlandirici'},
    aciklama: 'Yapay tatlandırıcıdır. Fenilketonüri (PKU) hastaları kullanmamalıdır; hassas kişilerde baş ağrısı tetikleyebilir.',
  ),
  Madde(
    grup: 'tatlandirici',
    ad: 'Yapay tatlandırıcı',
    anahtarlar: [
      'asesulfam', 'acesulfam', 'acesulfame', 'e950', 'sukraloz', 'sucralose', 'e955',
      'sakarin', 'saccharin', 'e954', 'siklamat', 'cyclamate', 'e952', 'neotam', 'e961',
    ],
    risk: 1,
    etiketler: {'yapay_tatli', 'tatlandirici'},
    aciklama: 'Kalorisiz yapay tatlandırıcıdır; düzenli ve yüksek miktarda tüketimi önerilmez.',
  ),
  Madde(
    grup: 'polyol',
    ad: 'Şeker alkolü',
    anahtarlar: [
      'maltitol', 'sorbitol', 'ksilitol', 'xylitol', 'eritritol', 'erythritol', 'izomalt', 'isomalt',
      'laktitol', 'e965', 'e420', 'e967', 'e968', 'e953', 'e966',
    ],
    risk: 1,
    etiketler: {'polyol', 'tatlandirici'},
    aciklama: 'Şeker alkolüdür; fazla tüketildiğinde gaz, şişkinlik ve sindirim hassasiyeti yapabilir.',
  ),

  // ---------- Katkı maddeleri & sodyum ----------
  Madde(
    grup: 'msg',
    ad: 'Monosodyum glutamat (MSG)',
    anahtarlar: ['monosodyum glutamat', 'monosodium glutamate', 'e621', 'msg'],
    risk: 1,
    etiketler: {'katki'},
    aciklama: 'Lezzet artırıcıdır; hassas kişilerde baş ağrısı veya çarpıntı gibi şikâyetler bildirilmiştir.',
  ),
  Madde(
    grup: 'boya',
    ad: 'Sentetik renklendirici',
    anahtarlar: [
      'e102', 'e104', 'e110', 'e122', 'e124', 'e129', 'tartrazin', 'tartrazine', 'sunset yellow',
      'gun batimi sari', 'allura', 'azorubin', 'ponceau', 'kinolin sari', 'quinoline yellow', 'carmoisine',
    ],
    risk: 1,
    etiketler: {'katki', 'boya'},
    aciklama: 'Sentetik gıda boyasıdır; özellikle çocuklarda dikkat ve hareketlilik üzerinde olumsuz etkilerle ilişkilendirilmiştir.',
  ),
  Madde(
    grup: 'benzoat',
    ad: 'Benzoat (koruyucu)',
    anahtarlar: ['benzoat', 'benzoate', 'e210', 'e211', 'e212', 'e213'],
    risk: 1,
    etiketler: {'katki', 'koruyucu'},
    aciklama: 'Koruyucu katkı maddesidir; sık ve yüksek miktarda tüketilmesi önerilmez.',
  ),
  Madde(
    grup: 'sulfit',
    ad: 'Sülfit (koruyucu)',
    anahtarlar: ['sulfit', 'sulfite', 'e220', 'e221', 'e222', 'e223', 'e224', 'e228'],
    risk: 1,
    etiketler: {'katki', 'koruyucu', 'sulfit'},
    aciklama: 'Astım veya sülfit hassasiyeti olan kişilerde reaksiyona yol açabilir.',
  ),
  Madde(
    grup: 'bha',
    ad: 'BHA / BHT (antioksidan)',
    anahtarlar: ['e320', 'e321', 'bha', 'bht', 'butilhidroksianisol'],
    risk: 1,
    etiketler: {'katki', 'koruyucu'},
    aciklama: 'Sentetik antioksidandır; uzun vadeli güvenlik tartışmaları nedeniyle dikkatli değerlendirilmelidir.',
  ),
  Madde(
    grup: 'fosforik',
    ad: 'Fosforik asit',
    anahtarlar: ['fosforik asit', 'phosphoric acid', 'e338'],
    risk: 1,
    etiketler: {'katki'},
    aciklama: 'Asitlik düzenleyicidir; fazla tüketimi diş minesini ve kemik mineral dengesini olumsuz etkileyebilir.',
  ),
  Madde(
    grup: 'aroma',
    ad: 'Yapay aroma',
    anahtarlar: ['yapay aroma', 'artificial flavor', 'artificial flavour'],
    risk: 1,
    etiketler: {'katki'},
    aciklama: 'İşlenmiş gıda göstergesidir; doğal bir bileşen değildir.',
  ),
  Madde(
    grup: 'kafein',
    ad: 'Kafein',
    anahtarlar: ['kafein', 'caffeine', 'guarana'],
    risk: 1,
    etiketler: {'kafein'},
    aciklama: 'Uyarıcıdır; antrenman öncesi performansı destekleyebilir ancak fazlası çarpıntı ve uykusuzluk yapabilir.',
  ),
  Madde(
    grup: 'tuz',
    ad: 'Tuz',
    anahtarlar: ['tuz', 'salt', 'sodyum klorur', 'sodium chloride'],
    haric: ['tuzsuz', 'tuz ilavesiz', 'salt free', 'unsalted'],
    risk: 1,
    etiketler: {'tuz'},
    aciklama: 'Fazlası tansiyon, ödem ve böbrek yükü açısından dikkat gerektirir.',
  ),

  // ---------- Nötr ama profil için bilgi taşıyanlar ----------
  Madde(
    grup: 'un',
    ad: 'Rafine un',
    anahtarlar: ['bugday unu', 'beyaz un', 'rafine un', 'wheat flour', 'enriched flour'],
    haric: ['tam bugday', 'tam tahil', 'whole', 'integral'],
    etiketler: {'rafine_un', 'gluten'},
    aciklama: '',
  ),

  // ---------- Olumlu içerikler ----------
  Madde(
    grup: 'sekersiz_notu',
    ad: 'Şekersiz / ilave şekersiz ibaresi',
    anahtarlar: ['sekersiz', 'seker ilavesiz', 'sugar free', 'sugar-free', 'no added sugar'],
    olumlu: true,
    etiketler: {'sekersiz'},
    aciklama: 'İlave şeker veya şekersiz formül göstergesidir; tatlandırıcı ve karbonhidrat değerine birlikte bakılmalıdır.',
  ),
  Madde(
    grup: 'tam_tahil',
    ad: 'Tam tahıl',
    anahtarlar: [
      'tam bugday', 'tam tahil', 'yulaf', 'oat', 'whole grain', 'wholegrain', 'whole wheat', 'integral',
      'cavdar', 'arpa', 'kinoa', 'quinoa', 'bulgur', 'karabugday', 'chia', 'keten tohumu',
    ],
    olumlu: true,
    etiketler: {'tam_tahil', 'lif'},
    aciklama: 'Lif ve kompleks karbonhidrat kaynağıdır; uzun süre tok tutar ve enerjiyi daha dengeli sağlar.',
  ),
  Madde(
    grup: 'lif',
    ad: 'Lif',
    anahtarlar: ['inulin', 'diyet lifi', 'fiber', 'psyllium', 'lif'],
    olumlu: true,
    etiketler: {'lif'},
    aciklama: 'Lif kaynağıdır; tokluk hissini artırır ve sindirimi destekler.',
  ),
  Madde(
    grup: 'baklagil',
    ad: 'Baklagil',
    anahtarlar: ['nohut', 'mercimek', 'fasulye', 'barbunya', 'chickpea', 'lentil'],
    olumlu: true,
    etiketler: {'protein', 'lif'},
    aciklama: 'Bitkisel protein ve lif kaynağıdır.',
  ),
  Madde(
    grup: 'kuruyemis',
    ad: 'Kuruyemiş',
    anahtarlar: [
      'badem', 'ceviz', 'findik', 'findigi', 'fistik', 'fistigi', 'kaju', 'almond', 'walnut', 'hazelnut', 'peanut',
      'cashew', 'pistachio',
    ],
    haric: ['hindistan ceviz', 'coconut', 'kokos'],
    olumlu: true,
    etiketler: {'saglikli_yag', 'protein', 'kuruyemis'},
    aciklama: 'Doymamış yağ, protein ve lif açısından zengindir.',
  ),
  Madde(
    grup: 'protein',
    ad: 'Protein kaynağı',
    anahtarlar: [
      'whey protein', 'peynir alti suyu protein', 'sut proteini', 'milk protein', 'kazein', 'casein',
      'protein izolat', 'protein isolate', 'protein konsantre', 'soya proteini', 'soy protein',
      'bezelye proteini', 'pea protein',
    ],
    olumlu: true,
    etiketler: {'protein'},
    aciklama: 'Protein kaynağıdır; kas onarımı ve tokluk için faydalıdır.',
  ),
  Madde(
    grup: 'probiyotik',
    ad: 'Probiyotik',
    anahtarlar: [
      'probiyotik', 'probiotic', 'lactobacillus', 'bifidobacterium', 'canli kultur', 'yogurt kulturu', 'kefir kulturu',
    ],
    olumlu: true,
    etiketler: {'probiyotik'},
    aciklama: 'Probiyotik içerir; bağırsak florasını destekleyebilir.',
  ),
];

const Set<String> _ekAlabilen = {'tuz', 'salt', 'lif', 'oat'};

bool _anahtarVar(String n, String anahtar) {
  if (anahtar.length <= 4) {
    final sag = _ekAlabilen.contains(anahtar) ? '' : r'($|[^a-z0-9])';
    return RegExp('(^|[^a-z0-9])${RegExp.escape(anahtar)}$sag').hasMatch(n);
  }
  return n.contains(anahtar);
}

List<String> icindekileriBol(String ham) {
  final metin = ham
      .replaceAll('_', '')
      .replaceAll(RegExp(r'[\r\n]+'), ' ')
      .replaceAll('•', ',')
      .replaceAll('·', ',');
  final parcalar = <String>[];
  final sb = StringBuffer();
  var derinlik = 0;

  void ekle() {
    var p = sb.toString().trim();
    sb.clear();
    p = p.replaceAll(RegExp(r'^[\s\.\-:]+|[\s\.\-:]+$'), '').trim();
    if (p.length > 1) parcalar.add(p);
  }

  for (final r in metin.runes) {
    final ch = String.fromCharCode(r);
    if (ch == '(' || ch == '[') derinlik++;
    if (ch == ')' || ch == ']') {
      if (derinlik > 0) derinlik--;
    }
    if ((ch == ',' || ch == ';') && (derinlik == 0 || sb.length > 160)) {
      ekle();
      derinlik = 0;
      continue;
    }
    sb.write(ch);
  }
  ekle();
  return parcalar;
}

class AyiklananMetin {
  final String metin;
  final bool baslikBulundu;
  const AyiklananMetin(this.metin, this.baslikBulundu);
}

AyiklananMetin icindekilerBolumunuAyikla(String ham) {
  final duz = ham.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (duz.isEmpty) return const AyiklananMetin('', false);

  final n = norm(duz);
  var bas = -1;
  var basUzunluk = 0;
  for (final isaret in ['icindekiler', 'ingredients', 'icerik:']) {
    final idx = n.indexOf(isaret);
    if (idx >= 0 && (bas < 0 || idx < bas)) {
      bas = idx;
      basUzunluk = isaret.length;
    }
  }
  if (bas < 0) return AyiklananMetin(duz, false);

  var baslangic = bas + basUzunluk;
  while (baslangic < duz.length && (duz[baslangic] == ':' || duz[baslangic] == ' ' || duz[baslangic] == '.')) {
    baslangic++;
  }

  var bitis = duz.length;
  const bitisIsaretleri = [
    'besin deger', 'besin ogesi', 'nutrition', 'ortalama', 'enerji', 'alerjen', 'alerji', 'allergen',
    'uretici', 'uretim', 'imalat', 'son tuketim', 'tavsiye edilen', 'saklama', 'saklayiniz',
    'ithalat', 'mensei', 'dagitim', 'best before', 'storage',
  ];
  final aramaBaslangici = (baslangic + 10).clamp(0, n.length);
  for (final isaret in bitisIsaretleri) {
    final idx = n.indexOf(isaret, aramaBaslangici);
    if (idx >= 0 && idx < bitis) bitis = idx;
  }
  if (bitis <= baslangic) return AyiklananMetin(duz.substring(baslangic).trim(), true);
  return AyiklananMetin(duz.substring(baslangic, bitis).trim(), true);
}

class Bilesen {
  final String metin;
  final List<Madde> eslesenler;
  final int risk;
  const Bilesen(this.metin, this.eslesenler, this.risk);

  bool get olumlu => risk == 0 && eslesenler.any((m) => m.olumlu);
}

class Profil {
  final Seviye seviye;
  final String ozet;
  final List<String> iyi;
  final List<String> kotu;
  final List<String> notlar;
  const Profil(this.seviye, this.ozet, this.iyi, this.kotu, this.notlar);

  String get seviyeEtiketi => switch (seviye) {
        Seviye.iyi => 'Uygun',
        Seviye.orta => 'Kısmen uygun',
        Seviye.kotu => 'Uygun değil',
        Seviye.bilinmiyor => 'Veri yok',
      };
}

class AnalizSonucu {
  final List<Bilesen> bilesenler;
  final int yuksek;
  final int hafif;
  final int olumluSayisi;
  final int kalitePuani; // 0-100
  final String genelEtiket;
  final String tuketimOnerisi;
  final List<String> alerjenVeHassasiyetler;
  final Seviye genelSeviye;
  final Profil spor;
  final Profil diyet;
  final List<String> notlar;

  const AnalizSonucu({
    required this.bilesenler,
    required this.yuksek,
    required this.hafif,
    required this.olumluSayisi,
    required this.kalitePuani,
    required this.genelEtiket,
    required this.tuketimOnerisi,
    required this.alerjenVeHassasiyetler,
    required this.genelSeviye,
    required this.spor,
    required this.diyet,
    required this.notlar,
  });
}

String _g(double v) {
  final s = v.toStringAsFixed(v >= 10 ? 0 : 1);
  return s.replaceAll(RegExp(r'\.0$'), '');
}

List<String> _alerjenleriTespitEt(String hamMetin, Set<String> etiketler) {
  final n = norm(hamMetin);
  final bulgular = <String>[];

  bool icerir(List<String> kelimeler) => kelimeler.any((k) => n.contains(norm(k)));

  if (icerir(['sut', 'süt', 'peynir', 'tereyag', 'tereyağ', 'yogurt', 'yoğurt', 'kefir', 'whey', 'kazein', 'laktoz', 'milk', 'dairy'])) {
    bulgular.add('Süt ve süt ürünleri (laktoz / süt proteini)');
  }
  if (etiketler.contains('gluten') || icerir(['bugday', 'buğday', 'arpa', 'cavdar', 'çavdar', 'yulaf', 'gluten', 'wheat'])) {
    bulgular.add('Glüten / tahıl');
  }
  if (etiketler.contains('kuruyemis') || icerir(['badem', 'ceviz', 'findik', 'fındık', 'fistik', 'fıstık', 'kaju', 'almond', 'walnut', 'hazelnut', 'peanut'])) {
    bulgular.add('Kuruyemiş / sert kabuklu yemiş');
  }
  if (icerir(['soya', 'soy'])) {
    bulgular.add('Soya');
  }
  if (icerir(['yumurta', 'egg'])) {
    bulgular.add('Yumurta');
  }
  if (icerir(['susam', 'sesame'])) {
    bulgular.add('Susam');
  }
  if (etiketler.contains('sulfit')) {
    bulgular.add('Sülfit bileşikleri');
  }
  if (etiketler.contains('tatlandirici')) {
    bulgular.add('Tatlandırıcı / poliol');
  }

  return bulgular;
}

int _kalitePuaniHesapla({
  required int toplam,
  required int yuksek,
  required int hafif,
  required int olumluSayisi,
  required Besin? besin,
  required String? nutriscore,
  required int? nova,
}) {
  if (toplam == 0 && (besin == null || besin.bos) && nutriscore == null && nova == null) {
    return 50;
  }

  var puan = 78;
  puan -= yuksek * 24;
  puan -= hafif * 9;
  puan += (olumluSayisi * 5).clamp(0, 15);

  if (nova == 4) puan -= 10;
  if (nova == 3) puan -= 4;
  if (nova == 1) puan += 6;

  if (nutriscore == 'a') puan += 8;
  if (nutriscore == 'b') puan += 4;
  if (nutriscore == 'd') puan -= 8;
  if (nutriscore == 'e') puan -= 14;

  if (besin != null) {
    if ((besin.seker ?? 0) > 15) puan -= 10;
    if ((besin.doymusYag ?? 0) > 8) puan -= 8;
    if ((besin.tuz ?? 0) > 2.0) puan -= 7;
    if ((besin.protein ?? 0) >= 12) puan += 5;
    if ((besin.lif ?? 0) >= 5) puan += 5;
  }

  return puan.clamp(5, 99);
}

AnalizSonucu analizEt(String ham, {Besin? besin, String? nutriscore, int? nova}) {
  final parcalar = icindekileriBol(ham);
  final bilesenler = <Bilesen>[];
  final etiketler = <String>{};
  var sekerOnde = false;

  for (var i = 0; i < parcalar.length; i++) {
    final metin = parcalar[i];
    final n = _hazirla(metin);
    final kullanilan = <String>{};
    final eslesen = <Madde>[];
    var risk = 0;
    for (final m in maddeler) {
      if (kullanilan.contains(m.grup)) continue;
      if (m.haric.any((h) => n.contains(h))) continue;
      if (!m.anahtarlar.any((a) => _anahtarVar(n, a))) continue;
      kullanilan.add(m.grup);
      eslesen.add(m);
      etiketler.addAll(m.etiketler);
      var r = m.risk;
      if (r == 1 && m.siraHassas && i < 3) {
        r = 2;
        if (m.etiketler.contains('seker')) sekerOnde = true;
      }
      if (r > risk) risk = r;
    }
    bilesenler.add(Bilesen(metin, eslesen, risk));
  }

  final toplam = bilesenler.length;
  final yuksek = bilesenler.where((b) => b.risk == 2).length;
  final hafif = bilesenler.where((b) => b.risk == 1).length;
  final olumluSayisi = bilesenler.where((b) => b.olumlu).length;
  final riskli = yuksek + hafif;
  final notlar = <String>[];

  String etiket;
  String tuketimOnerisi;
  Seviye sev;

  if (toplam == 0) {
    if (nutriscore != null && nutriscore.isNotEmpty) {
      if (nutriscore == 'd' || nutriscore == 'e' || nova == 4) {
        etiket = 'ZARARLI';
        sev = Seviye.kotu;
        tuketimOnerisi = 'Besin değeri profili olumsuz; günlük beslenmede sınırlandırılması önerilir.';
      } else if (nutriscore == 'c' || nova == 3) {
        etiket = 'DİKKATLİ TÜKET';
        sev = Seviye.orta;
        tuketimOnerisi = 'Orta düzey işlenmiş ürün; porsiyon kontrolü ile tüketilmesi uygundur.';
      } else {
        etiket = 'SAĞLIKLI';
        sev = Seviye.iyi;
        tuketimOnerisi = 'Genel besin profili olumlu; dengeli beslenmeye dahil edilebilir.';
      }
      notlar.add("İçerik listesi bulunamadı; değerlendirme Nutri-Score'a dayanıyor.");
    } else {
      etiket = 'VERİ YETERSİZ';
      sev = Seviye.bilinmiyor;
      tuketimOnerisi = 'İçerik veya besin değeri verisi bulunamadığı için etiket bilgisini inceleyin.';
    }
  } else if (riskli == 0) {
    etiket = 'SAĞLIKLI';
    sev = Seviye.iyi;
    tuketimOnerisi = 'Belirgin riskli katkı veya şeker yükü tespit edilmedi; günlük tüketime uygundur.';
  } else if (yuksek == 0 && hafif <= 1 && toplam <= 8) {
    etiket = 'TÜKETİLEBİLİR';
    sev = Seviye.iyi;
    tuketimOnerisi = 'Genel olarak tüketilebilir; içerikteki tekil uyarı notunu dikkate alın.';
  } else if (yuksek >= 2 || riskli >= 4 || (riskli >= 3 && riskli / toplam > 0.4)) {
    etiket = 'ZARARLI';
    sev = Seviye.kotu;
    tuketimOnerisi = 'Yüksek riskli veya yoğun katkı/şeker profili taşıyor; tüketiminden kaçınılması veya nadir tüketilmesi önerilir.';
  } else {
    etiket = 'DİKKATLİ TÜKET';
    sev = Seviye.orta;
    tuketimOnerisi = 'Dikkat gerektiren bileşenler bulunuyor; nadiren ve küçük porsiyonlarda tercih edin.';
  }

  if (toplam > 0 && sev == Seviye.iyi && (nutriscore == 'd' || nutriscore == 'e')) {
    etiket = 'DİKKATLİ TÜKET';
    sev = Seviye.orta;
    tuketimOnerisi = 'Katkı açısından temiz görünse de besin kalitesi düşük; ölçülü tüketilmeli.';
    notlar.add("Katkı açısından temiz görünse de Nutri-Score ${nutriscore?.toUpperCase()}; besin değeri düşük.");
  }

  final veriVar = toplam > 0 || (besin != null && !besin.bos);
  final kalitePuani = _kalitePuaniHesapla(
    toplam: toplam,
    yuksek: yuksek,
    hafif: hafif,
    olumluSayisi: olumluSayisi,
    besin: besin,
    nutriscore: nutriscore,
    nova: nova,
  );

  return AnalizSonucu(
    bilesenler: bilesenler,
    yuksek: yuksek,
    hafif: hafif,
    olumluSayisi: olumluSayisi,
    kalitePuani: kalitePuani,
    genelEtiket: etiket,
    tuketimOnerisi: tuketimOnerisi,
    alerjenVeHassasiyetler: _alerjenleriTespitEt(ham, etiketler),
    genelSeviye: sev,
    spor: _sporProfili(
      t: etiketler,
      sekerOnde: sekerOnde,
      b: besin,
      genel: sev,
      veriVar: veriVar,
      riskliSayi: riskli,
    ),
    diyet: _diyetProfili(
      t: etiketler,
      sekerOnde: sekerOnde,
      b: besin,
      nova: nova,
      genel: sev,
      veriVar: veriVar,
    ),
    notlar: notlar,
  );
}

Profil _sporProfili({
  required Set<String> t,
  required bool sekerOnde,
  required Besin? b,
  required Seviye genel,
  required bool veriVar,
  required int riskliSayi,
}) {
  if (!veriVar) {
    return const Profil(Seviye.bilinmiyor, 'Değerlendirme için yeterli veri yok.', [], [], []);
  }
  var puan = 0;
  final iyi = <String>[];
  final kotu = <String>[];
  final notlar = <String>[];

  final protein = b?.protein;
  if (t.contains('protein') || (protein != null && protein >= 10)) {
    puan += 2;
    iyi.add(protein != null && protein >= 10
        ? "100 g'da ${_g(protein)} g protein var; kas onarımı ve toparlanma için faydalı."
        : 'Protein kaynağı içeriyor; kas onarımı ve tokluk için faydalı.');
  }
  if (t.contains('tam_tahil')) {
    puan += 1;
    iyi.add('Tam tahıl/lif içeriyor; yavaş sindirilen karbonhidrat ile dengeli enerji sağlar.');
  }
  if (t.contains('saglikli_yag')) {
    puan += 1;
    iyi.add('Doymamış yağ kaynağı (kuruyemiş vb.) içeriyor.');
  }
  if (t.contains('probiyotik')) {
    puan += 1;
    iyi.add('Probiyotik içeriyor; sindirim sistemini destekler.');
  }

  final seker = b?.seker;
  if (t.contains('trans')) {
    puan -= 3;
    kotu.add('Trans yağ içeriyor; performans ve kalp-damar sağlığı için uygun değil.');
  }
  if (sekerOnde || (seker != null && seker > 15)) {
    puan -= 2;
    kotu.add(seker != null && seker > 15
        ? "100 g'da ${_g(seker)} g şeker var; yalnızca antrenman sırasında/sonrasında hızlı enerji için düşünülebilir."
        : 'Şeker ağırlıklı bir ürün; günlük sporcu atıştırmalığı olarak önerilmez.');
  } else if (t.contains('seker')) {
    puan -= 1;
    kotu.add('İlave şeker içeriyor.');
  }
  if (t.contains('islenmis_et')) {
    puan -= 2;
    kotu.add('İşlenmiş et ürünü; düzenli tüketimi sporcu beslenmesi için uygun değil.');
  }
  if (t.contains('doymus_yag') && !t.contains('trans')) {
    puan -= 1;
    kotu.add('Doymuş yağ (ör. palm yağı) içeriyor.');
  }
  if (riskliSayi >= 3) {
    puan -= 1;
    kotu.add('Çok sayıda riskli madde/katkı içeriyor.');
  }
  if (t.contains('kafein')) {
    notlar.add('Kafein içeriyor: antrenman öncesi performansı destekleyebilir; geç saatlerde uykuyu etkileyebilir.');
  }
  if (t.contains('yapay_tatli')) {
    notlar.add('Yapay tatlandırıcı içeriyor; kalorisizdir ama ölçülü tüketin.');
  }
  final tuz = b?.tuz;
  if (tuz != null && tuz > 1.5) {
    notlar.add("Tuz oranı yüksek (100 g'da ${_g(tuz)} g).");
  }

  var s = puan >= 2 ? Seviye.iyi : (puan <= -2 ? Seviye.kotu : Seviye.orta);
  if (genel == Seviye.kotu) {
    s = Seviye.kotu;
    if (kotu.isEmpty) kotu.add('Genel içerik değerlendirmesi olumsuz.');
  }
  final bos = iyi.isEmpty && kotu.isEmpty;
  final ozet = switch (s) {
    Seviye.iyi => 'Sporcular için uygun bir seçim.',
    Seviye.orta => bos ? 'Belirgin olumlu ya da olumsuz bir bileşen bulunamadı.' : 'Ölçülü ve antrenman durumuna göre tüketilebilir.',
    Seviye.kotu => 'Düzenli spor yapanlar için önerilmez.',
    Seviye.bilinmiyor => '',
  };
  return Profil(s, ozet, iyi, kotu, notlar);
}

Profil _diyetProfili({
  required Set<String> t,
  required bool sekerOnde,
  required Besin? b,
  required int? nova,
  required Seviye genel,
  required bool veriVar,
}) {
  if (!veriVar) {
    return const Profil(Seviye.bilinmiyor, 'Değerlendirme için yeterli veri yok.', [], [], []);
  }
  var puan = 0;
  final iyi = <String>[];
  final kotu = <String>[];
  final notlar = <String>[];

  final kcal = b?.kcal;
  final seker = b?.seker;
  final yag = b?.yag;
  final doymus = b?.doymusYag;
  final lif = b?.lif;
  final protein = b?.protein;

  if (sekerOnde || (seker != null && seker > 15)) {
    puan -= 3;
    kotu.add(seker != null && seker > 15
        ? "100 g'da ${_g(seker)} g şeker var; kilo verme sürecinde kalori açığını zorlar."
        : 'Şeker listenin başında; kilo kontrolünde dikkat edilmeli.');
  } else if (seker != null && seker > 8) {
    puan -= 2;
    kotu.add("100 g'da ${_g(seker)} g şeker var.");
  } else if (t.contains('seker')) {
    puan -= 1;
    kotu.add('İlave şeker içeriyor.');
  }

  if (kcal != null && kcal >= 400) {
    puan -= 2;
    kotu.add("Kalori yoğun (100 g'da ${_g(kcal)} kcal).");
  } else if (kcal != null && kcal >= 275) {
    puan -= 1;
    kotu.add("Kalorisi yüksek sayılır (100 g'da ${_g(kcal)} kcal).");
  } else if (kcal != null && kcal <= 100) {
    puan += 1;
    iyi.add("Düşük kalorili (100 g'da ${_g(kcal)} kcal).");
  }

  if ((yag != null && yag >= 20) || (doymus != null && doymus > 5) || t.contains('doymus_yag')) {
    puan -= 1;
    kotu.add('Yağ / doymuş yağ oranı yüksek.');
  }
  if (t.contains('trans')) {
    puan -= 2;
    kotu.add('Trans yağ içeriyor.');
  }
  if (t.contains('rafine_un') && !t.contains('tam_tahil')) {
    puan -= 1;
    kotu.add('Rafine un içeriyor; çabuk acıktırabilir.');
  }
  if (nova == 4) {
    puan -= 1;
    kotu.add('Ultra işlenmiş gıda sınıfında (NOVA 4).');
  }

  if (t.contains('lif') || t.contains('tam_tahil') || (lif != null && lif >= 5)) {
    puan += 2;
    iyi.add('Lif içeriyor; tokluk hissini artırır.');
  }
  if (t.contains('protein') || (protein != null && protein >= 10)) {
    puan += 1;
    iyi.add('Protein içeriyor; tokluğu destekler.');
  }

  if (t.contains('yapay_tatli')) {
    notlar.add('Yapay tatlandırıcı içeriyor: kaloriyi düşürür ama tatlı isteğini sürdürebilir.');
  }
  if (kcal == null) {
    notlar.add('Kalori ve porsiyon bilgisi bulunmuyor; değerlendirme içerik listesine dayanıyor.');
  }

  var s = puan >= 2 ? Seviye.iyi : (puan <= -2 ? Seviye.kotu : Seviye.orta);
  if (genel == Seviye.kotu) {
    s = Seviye.kotu;
    if (kotu.isEmpty) kotu.add('Genel içerik değerlendirmesi olumsuz.');
  }
  final bos = iyi.isEmpty && kotu.isEmpty;
  final ozet = switch (s) {
    Seviye.iyi => 'Kilo vermek isteyenler için uygun bir seçim.',
    Seviye.orta => bos ? 'Belirgin olumlu ya da olumsuz bir bileşen bulunamadı.' : 'Porsiyon kontrolüyle tüketilebilir.',
    Seviye.kotu => 'Kilo vermek isteyenler için uygun değil.',
    Seviye.bilinmiyor => '',
  };
  return Profil(s, ozet, iyi, kotu, notlar);
}
