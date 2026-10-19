// lib/data/models/quiz_item.dart

class QuizItem {
  final String imagePath;
  final String word;
  final String category;
  final int difficulty; // 0=kolay, 1=orta, 2=zor

  /// Resme çocukların verdiği diğer doğru adlar (ör. Kupa için "Bardak").
  /// Bilbil yine [word]'ü söyler.
  final List<String> alsoAccepted;

  const QuizItem({
    required this.imagePath,
    required this.word,
    required this.category,
    required this.difficulty,
    this.alsoAccepted = const [],
  });

  /// Kabul edilen bütün cevaplar, asıl kelime önce.
  List<String> get answers => [word, ...alsoAccepted];
}

class QuizData {
  static const List<QuizItem> animals = [
    QuizItem(imagePath: 'assets/images/kolay/1.webp',      word: 'Kedi',           category: 'animals', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/13.webp',     word: 'Köpek',          category: 'animals', difficulty: 0),
    QuizItem(imagePath: 'assets/images/zor/23.webp',       word: 'Kuş',            category: 'animals', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/32.webp',     word: 'Panda',          category: 'animals', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/37.webp',     word: 'Fil',            category: 'animals', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/44.webp',     word: 'Aslan',          category: 'animals', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/53.webp',     word: 'Ayı',            category: 'animals', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/56.webp',     word: 'Kedi',           category: 'animals', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/72.webp',     word: 'Tavşan',         category: 'animals', difficulty: 0),
    QuizItem(imagePath: 'assets/images/zor/88.webp',       word: 'Köpek',          category: 'animals', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/97.webp',     word: 'Maymun',         category: 'animals', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/104.webp',    word: 'Kedi',           category: 'animals', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/116.webp',    word: 'Koyun',          category: 'animals', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/120.webp',    word: 'Arı',            category: 'animals', difficulty: 0),
    QuizItem(imagePath: 'assets/images/zor/124.webp',      word: 'Köpek',          category: 'animals', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/128.webp',    word: 'Kuş',            category: 'animals', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/132.webp',    word: 'Köpek',          category: 'animals', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/153.webp',    word: 'İnek',           category: 'animals', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/176.webp',    word: 'Köpek',          category: 'animals', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/185.webp',    word: 'Kedi',           category: 'animals', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/217.webp',    word: 'Domuz',          category: 'animals', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/240.webp',    word: 'Kedi',           category: 'animals', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/4.webp',      word: 'Deniz yıldızı',  category: 'animals', difficulty: 1),
    QuizItem(imagePath: 'assets/images/orta/6.webp',       word: 'Baykuş',         category: 'animals', difficulty: 1),
    QuizItem(imagePath: 'assets/images/orta/10.webp',      word: 'Zürafa',         category: 'animals', difficulty: 1),
    QuizItem(imagePath: 'assets/images/orta/34.webp',      word: 'Yunus',          category: 'animals', difficulty: 1),
    QuizItem(imagePath: 'assets/images/orta/35.webp',      word: 'Denizatı',       category: 'animals', difficulty: 1),
    QuizItem(imagePath: 'assets/images/orta/41.webp',      word: 'Yarasa',         category: 'animals', difficulty: 1),
    QuizItem(imagePath: 'assets/images/orta/45.webp',      word: 'Papağan',        category: 'animals', difficulty: 1),
    QuizItem(imagePath: 'assets/images/orta/47.webp',      word: 'Sincap',         category: 'animals', difficulty: 1),
    QuizItem(imagePath: 'assets/images/orta/63.webp',      word: 'Zebra',          category: 'animals', difficulty: 1),
    QuizItem(imagePath: 'assets/images/orta/73.webp',      word: 'Penguen',        category: 'animals', difficulty: 1),
    QuizItem(imagePath: 'assets/images/orta/82.webp',      word: 'Balina',         category: 'animals', difficulty: 1),
    QuizItem(imagePath: 'assets/images/orta/99.webp',      word: 'Kaplumbağa',     category: 'animals', difficulty: 1),
    QuizItem(imagePath: 'assets/images/orta/101.webp',     word: 'Timsah',         category: 'animals', difficulty: 1),
    QuizItem(imagePath: 'assets/images/orta/102.webp',     word: 'Flamingo',       category: 'animals', difficulty: 1),
    QuizItem(imagePath: 'assets/images/orta/117.webp',     word: 'Yengeç',         category: 'animals', difficulty: 1),
    QuizItem(imagePath: 'assets/images/orta/118.webp',     word: 'Civciv',         category: 'animals', difficulty: 1),
    QuizItem(imagePath: 'assets/images/orta/126.webp',     word: 'Papağan',        category: 'animals', difficulty: 1),
    QuizItem(imagePath: 'assets/images/orta/163.webp',     word: 'Kelebek',        category: 'animals', difficulty: 1),
    QuizItem(imagePath: 'assets/images/orta/164.webp',     word: 'Kirpi',          category: 'animals', difficulty: 1),
    QuizItem(imagePath: 'assets/images/orta/198.webp',     word: 'Güvercin',       category: 'animals', difficulty: 1),
    QuizItem(imagePath: 'assets/images/zor/28.webp',       word: 'Tukan',          category: 'animals', difficulty: 2),
    QuizItem(imagePath: 'assets/images/zor/31.webp',       word: 'Muhabbet kuşu',  category: 'animals', difficulty: 2),
    QuizItem(imagePath: 'assets/images/zor/51.webp',       word: 'Salyangoz',      category: 'animals', difficulty: 2),
    QuizItem(imagePath: 'assets/images/zor/59.webp',       word: 'Rakun',          category: 'animals', difficulty: 2),
    QuizItem(imagePath: 'assets/images/zor/175.webp',      word: 'Ahtapot',        category: 'animals', difficulty: 2),
    QuizItem(imagePath: 'assets/images/zor/181.webp',      word: 'Yusufçuk',       category: 'animals', difficulty: 2),
    QuizItem(imagePath: 'assets/images/zor/211.webp',      word: 'Denizanası',     category: 'animals', difficulty: 2),
    QuizItem(imagePath: 'assets/images/zor/236.webp',      word: 'Uğurböceği',     category: 'animals', difficulty: 2),
  ];

  static const List<QuizItem> fruitsVegetables = [
    QuizItem(imagePath: 'assets/images/kolay/36.webp',     word: 'Mısır',          category: 'fruits_vegetables', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/46.webp',     word: 'Havuç',          category: 'fruits_vegetables', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/85.webp',     word: 'Nar',            category: 'fruits_vegetables', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/103.webp',    word: 'Üzüm',           category: 'fruits_vegetables', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/112.webp',    word: 'Biber',          category: 'fruits_vegetables', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/113.webp',    word: 'Patates',        category: 'fruits_vegetables', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/136.webp',    word: 'Muz',            category: 'fruits_vegetables', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/137.webp',    word: 'Domates',        category: 'fruits_vegetables', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/161.webp',    word: 'Armut',          category: 'fruits_vegetables', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/183.webp',    word: 'Kiraz',          category: 'fruits_vegetables', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/204.webp',    word: 'Karpuz',         category: 'fruits_vegetables', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/207.webp',    word: 'Portakal',       category: 'fruits_vegetables', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/214.webp',    word: 'Elma',           category: 'fruits_vegetables', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/224.webp',    word: 'Limon',          category: 'fruits_vegetables', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/237.webp',    word: 'Kivi',           category: 'fruits_vegetables', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/241.webp',    word: 'Çilek',          category: 'fruits_vegetables', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/244.webp',    word: 'Biber',          category: 'fruits_vegetables', difficulty: 0),
    QuizItem(imagePath: 'assets/images/orta/106.webp',     word: 'Bezelye',        category: 'fruits_vegetables', difficulty: 1),
    QuizItem(imagePath: 'assets/images/orta/108.webp',     word: 'Erik',           category: 'fruits_vegetables', difficulty: 1),
    QuizItem(imagePath: 'assets/images/orta/135.webp',     word: 'Mango',          category: 'fruits_vegetables', difficulty: 1),
    QuizItem(imagePath: 'assets/images/orta/141.webp',     word: 'Sarımsak',       category: 'fruits_vegetables', difficulty: 1),
    QuizItem(imagePath: 'assets/images/orta/143.webp',     word: 'Turp',           category: 'fruits_vegetables', difficulty: 1),
    QuizItem(imagePath: 'assets/images/orta/149.webp',     word: 'Mantar',         category: 'fruits_vegetables', difficulty: 1),
    QuizItem(imagePath: 'assets/images/orta/158.webp',     word: 'Marul',          category: 'fruits_vegetables', difficulty: 1),
    QuizItem(imagePath: 'assets/images/orta/162.webp',     word: 'Brokoli',        category: 'fruits_vegetables', difficulty: 1),
    QuizItem(imagePath: 'assets/images/orta/171.webp',     word: 'Patlıcan',       category: 'fruits_vegetables', difficulty: 1),
    QuizItem(imagePath: 'assets/images/orta/186.webp',     word: 'Ananas',         category: 'fruits_vegetables', difficulty: 1),
    QuizItem(imagePath: 'assets/images/orta/201.webp',     word: 'Kabak',          category: 'fruits_vegetables', difficulty: 1),
    QuizItem(imagePath: 'assets/images/orta/230.webp',     word: 'Şeftali',        category: 'fruits_vegetables', difficulty: 1),
    QuizItem(imagePath: 'assets/images/orta/235.webp',     word: 'Bezelye',        category: 'fruits_vegetables', difficulty: 1),
    QuizItem(imagePath: 'assets/images/orta/238.webp',     word: 'Soğan',          category: 'fruits_vegetables', difficulty: 1),
    QuizItem(imagePath: 'assets/images/zor/14.webp',       word: 'Yaban mersini',  category: 'fruits_vegetables', difficulty: 2),
    QuizItem(imagePath: 'assets/images/zor/83.webp',       word: 'Ahududu',        category: 'fruits_vegetables', difficulty: 2),
    QuizItem(imagePath: 'assets/images/zor/127.webp',      word: 'Hindistancevizi', category: 'fruits_vegetables', difficulty: 2),
    QuizItem(imagePath: 'assets/images/zor/142.webp',      word: 'Mor lahana',     category: 'fruits_vegetables', difficulty: 2),
    QuizItem(imagePath: 'assets/images/zor/166.webp',      word: 'Karnabahar',     category: 'fruits_vegetables', difficulty: 2),
    QuizItem(imagePath: 'assets/images/zor/189.webp',      word: 'Böğürtlen',      category: 'fruits_vegetables', difficulty: 2),
    QuizItem(imagePath: 'assets/images/zor/197.webp',      word: 'Kereviz',        category: 'fruits_vegetables', difficulty: 2),
  ];

  static const List<QuizItem> colors = [
    QuizItem(imagePath: 'assets/images/kolay/7.webp',      word: 'Kırmızı',        category: 'colors', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/67.webp',     word: 'Beyaz',          category: 'colors', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/75.webp',     word: 'Pembe',          category: 'colors', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/80.webp',     word: 'Siyah',          category: 'colors', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/105.webp',    word: 'Yeşil',          category: 'colors', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/146.webp',    word: 'Gri',            category: 'colors', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/170.webp',    word: 'Mavi',           category: 'colors', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/173.webp',    word: 'Yeşil',          category: 'colors', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/178.webp',    word: 'Sarı',           category: 'colors', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/199.webp',    word: 'Mor',            category: 'colors', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/212.webp',    word: 'Mor',            category: 'colors', difficulty: 0),
    QuizItem(imagePath: 'assets/images/orta/174.webp',     word: 'Kahverengi',     category: 'colors', difficulty: 1),
    QuizItem(imagePath: 'assets/images/orta/192.webp',     word: 'Turuncu',        category: 'colors', difficulty: 1),
    QuizItem(imagePath: 'assets/images/orta/243.webp',     word: 'Kahverengi',     category: 'colors', difficulty: 1),
    QuizItem(imagePath: 'assets/images/zor/234.webp',      word: 'Bej',            category: 'colors', difficulty: 2),
  ];

  static const List<QuizItem> shapes = [
    QuizItem(imagePath: 'assets/images/kolay/30.webp',     word: 'Kalp',           category: 'shapes', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/81.webp',     word: 'Yıldız',         category: 'shapes', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/94.webp',     word: 'Daire',          category: 'shapes', difficulty: 0),
    QuizItem(imagePath: 'assets/images/orta/129.webp',     word: 'Üçgen',          category: 'shapes', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/227.webp',    word: 'Ay',             category: 'shapes', difficulty: 0),
    QuizItem(imagePath: 'assets/images/orta/190.webp',     word: 'Oval',           category: 'shapes', difficulty: 1),
    QuizItem(imagePath: 'assets/images/zor/39.webp',       word: 'Beşgen',         category: 'shapes', difficulty: 2),
    QuizItem(imagePath: 'assets/images/zor/222.webp',      word: 'Baklava dilimi', category: 'shapes', difficulty: 2),
  ];

  static const List<QuizItem> bodyParts = [
    QuizItem(imagePath: 'assets/images/kolay/69.webp',     word: 'Saç',            category: 'body_parts', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/110.webp',    word: 'Ağız',           category: 'body_parts', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/122.webp',    word: 'Yüz',            category: 'body_parts', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/125.webp',    word: 'Burun',          category: 'body_parts', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/130.webp',    word: 'Diz',            category: 'body_parts', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/150.webp',    word: 'Bacak',          category: 'body_parts', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/172.webp',    word: 'El',             category: 'body_parts', difficulty: 0),
    QuizItem(imagePath: 'assets/images/zor/180.webp',      word: 'Diş',            category: 'body_parts', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/203.webp',    word: 'Ayak',           category: 'body_parts', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/208.webp',    word: 'Göz',            category: 'body_parts', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/209.webp',    word: 'Ayak',           category: 'body_parts', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/215.webp',    word: 'Kulak',          category: 'body_parts', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/218.webp',    word: 'Dil',            category: 'body_parts', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/223.webp',    word: 'Kol',            category: 'body_parts', difficulty: 0),
    QuizItem(imagePath: 'assets/images/orta/25.webp',      word: 'Parmak',         category: 'body_parts', difficulty: 1),
    QuizItem(imagePath: 'assets/images/orta/42.webp',      word: 'Boyun',          category: 'body_parts', difficulty: 1),
    QuizItem(imagePath: 'assets/images/orta/78.webp',      word: 'Dirsek',         category: 'body_parts', difficulty: 1),
    QuizItem(imagePath: 'assets/images/orta/79.webp',      word: 'Göbek',          category: 'body_parts', difficulty: 1),
    QuizItem(imagePath: 'assets/images/orta/95.webp',      word: 'Sırt',           category: 'body_parts', difficulty: 1),
    QuizItem(imagePath: 'assets/images/orta/114.webp',     word: 'Çene',           category: 'body_parts', difficulty: 1),
  ];

  static const List<QuizItem> clothes = [
    QuizItem(imagePath: 'assets/images/kolay/11.webp',     word: 'Şapka',          category: 'clothes', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/22.webp',     word: 'Çorap',          category: 'clothes', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/93.webp',     word: 'Şort',           category: 'clothes', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/131.webp',    word: 'Pantolon',       category: 'clothes', difficulty: 0),
    QuizItem(imagePath: 'assets/images/orta/2.webp',       word: 'Tulum',          category: 'clothes', difficulty: 1),
    QuizItem(imagePath: 'assets/images/orta/16.webp',      word: 'Etek',           category: 'clothes', difficulty: 1),
    QuizItem(imagePath: 'assets/images/orta/60.webp',      word: 'Tişört',         category: 'clothes', difficulty: 1),
    QuizItem(imagePath: 'assets/images/orta/64.webp',      word: 'Hırka',          category: 'clothes', difficulty: 1),
    QuizItem(imagePath: 'assets/images/orta/70.webp',      word: 'Elbise',         category: 'clothes', difficulty: 1),
    QuizItem(imagePath: 'assets/images/orta/100.webp',     word: 'Pijama',         category: 'clothes', difficulty: 1),
    QuizItem(imagePath: 'assets/images/zor/147.webp',      word: 'Çizme',          category: 'clothes', difficulty: 1),
    QuizItem(imagePath: 'assets/images/orta/188.webp',     word: 'Tişört',         category: 'clothes', difficulty: 1),
    QuizItem(imagePath: 'assets/images/orta/221.webp',     word: 'Ayakkabı',       category: 'clothes', difficulty: 1),
    QuizItem(imagePath: 'assets/images/orta/228.webp',     word: 'Tayt',           category: 'clothes', difficulty: 1),
    QuizItem(imagePath: 'assets/images/orta/231.webp',     word: 'Ayakkabı',       category: 'clothes', difficulty: 1),
    QuizItem(imagePath: 'assets/images/orta/242.webp',     word: 'Ayakkabı',       category: 'clothes', difficulty: 1),
    QuizItem(imagePath: 'assets/images/zor/216.webp',      word: 'Kapüşonlu',      category: 'clothes', difficulty: 2, alsoAccepted: ['Kazak']),
  ];

  static const List<QuizItem> dailyObjects = [
    QuizItem(imagePath: 'assets/images/kolay/20.webp',     word: 'Kitap',          category: 'daily_objects', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/24.webp',     word: 'Yatak',          category: 'daily_objects', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/54.webp',     word: 'Masa',           category: 'daily_objects', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/91.webp',     word: 'Telefon',        category: 'daily_objects', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/109.webp',    word: 'Sabun',          category: 'daily_objects', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/168.webp',    word: 'Yastık',         category: 'daily_objects', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/195.webp',    word: 'Yastık',         category: 'daily_objects', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/219.webp',    word: 'Havlu',          category: 'daily_objects', difficulty: 0),
    QuizItem(imagePath: 'assets/images/orta/9.webp',       word: 'Sandalye',       category: 'daily_objects', difficulty: 1),
    QuizItem(imagePath: 'assets/images/orta/17.webp',      word: 'Biberon',        category: 'daily_objects', difficulty: 1),
    QuizItem(imagePath: 'assets/images/orta/29.webp',      word: 'Dolap',          category: 'daily_objects', difficulty: 1),
    QuizItem(imagePath: 'assets/images/orta/61.webp',      word: 'Televizyon',     category: 'daily_objects', difficulty: 1),
    QuizItem(imagePath: 'assets/images/orta/87.webp',      word: 'Pencere',        category: 'daily_objects', difficulty: 1),
    QuizItem(imagePath: 'assets/images/orta/89.webp',      word: 'Sünger',         category: 'daily_objects', difficulty: 1),
    QuizItem(imagePath: 'assets/images/orta/119.webp',     word: 'Tencere',        category: 'daily_objects', difficulty: 1),
    QuizItem(imagePath: 'assets/images/orta/123.webp',     word: 'Fincan',         category: 'daily_objects', difficulty: 1, alsoAccepted: ['Bardak']),
    QuizItem(imagePath: 'assets/images/orta/152.webp',     word: 'Koltuk',         category: 'daily_objects', difficulty: 1, alsoAccepted: ['Kanepe']),
    QuizItem(imagePath: 'assets/images/orta/157.webp',     word: 'Küvet',          category: 'daily_objects', difficulty: 1),
    QuizItem(imagePath: 'assets/images/orta/165.webp',     word: 'Lavabo',         category: 'daily_objects', difficulty: 1),
    QuizItem(imagePath: 'assets/images/orta/210.webp',     word: 'Kupa',           category: 'daily_objects', difficulty: 1, alsoAccepted: ['Bardak']),
    QuizItem(imagePath: 'assets/images/orta/232.webp',     word: 'Vazo',           category: 'daily_objects', difficulty: 1),
    QuizItem(imagePath: 'assets/images/zor/8.webp',        word: 'Çalar saat',     category: 'daily_objects', difficulty: 2),
    QuizItem(imagePath: 'assets/images/zor/76.webp',       word: 'Çöp kutusu',     category: 'daily_objects', difficulty: 2),
    QuizItem(imagePath: 'assets/images/zor/90.webp',       word: 'Klozet',         category: 'daily_objects', difficulty: 2),
    QuizItem(imagePath: 'assets/images/zor/202.webp',      word: 'Abajur',         category: 'daily_objects', difficulty: 2, alsoAccepted: ['Lamba']),
    QuizItem(imagePath: 'assets/images/zor/213.webp',      word: 'Buzdolabı',      category: 'daily_objects', difficulty: 2),
  ];

  static const List<QuizItem> toys = [
    QuizItem(imagePath: 'assets/images/kolay/148.webp',    word: 'Araba',          category: 'toys', difficulty: 0),
    QuizItem(imagePath: 'assets/images/orta/200.webp',     word: 'Top',            category: 'toys', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/205.webp',    word: 'Balon',          category: 'toys', difficulty: 0),
    QuizItem(imagePath: 'assets/images/orta/239.webp',     word: 'Oyuncak ayı',    category: 'toys', difficulty: 0),
    QuizItem(imagePath: 'assets/images/orta/5.webp',       word: 'Hediye',         category: 'toys', difficulty: 1),
    QuizItem(imagePath: 'assets/images/orta/140.webp',     word: 'Yarış arabası',  category: 'toys', difficulty: 1),
  ];

  static const List<QuizItem> nature = [
    QuizItem(imagePath: 'assets/images/kolay/21.webp',     word: 'Çiçek',          category: 'nature', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/92.webp',     word: 'Buz',            category: 'nature', difficulty: 0),
    QuizItem(imagePath: 'assets/images/orta/133.webp',     word: 'Ay',             category: 'nature', difficulty: 0),
    QuizItem(imagePath: 'assets/images/orta/226.webp',     word: 'Taş',            category: 'nature', difficulty: 0),
  ];

  static const List<QuizItem> weather = [
    QuizItem(imagePath: 'assets/images/kolay/18.webp',     word: 'Soğuk',          category: 'weather', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/26.webp',     word: 'Güneşli',        category: 'weather', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/27.webp',     word: 'Yağmur',         category: 'weather', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/86.webp',     word: 'Bulutlu',        category: 'weather', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/167.webp',    word: 'Sıcak',          category: 'weather', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/196.webp',    word: 'Rüzgar',         category: 'weather', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/233.webp',    word: 'Bulut',          category: 'weather', difficulty: 0),
    QuizItem(imagePath: 'assets/images/orta/50.webp',      word: 'Fırtına',        category: 'weather', difficulty: 1),
    QuizItem(imagePath: 'assets/images/orta/220.webp',     word: 'Gökkuşağı',      category: 'weather', difficulty: 1),
    QuizItem(imagePath: 'assets/images/zor/58.webp',       word: 'Kasırga',        category: 'weather', difficulty: 2),
  ];

  static const List<QuizItem> actions = [
    QuizItem(imagePath: 'assets/images/kolay/3.webp',      word: 'Oturuyor',       category: 'actions', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/12.webp',     word: 'Okuyor',         category: 'actions', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/15.webp',     word: 'Yürüyor',        category: 'actions', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/38.webp',     word: 'Oturuyor',       category: 'actions', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/55.webp',     word: 'Uyuyor',         category: 'actions', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/84.webp',     word: 'Yiyor',          category: 'actions', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/98.webp',     word: 'Yiyor',          category: 'actions', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/138.webp',    word: 'Koşuyor',        category: 'actions', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/159.webp',    word: 'Koşuyor',        category: 'actions', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/169.webp',    word: 'Okuyor',         category: 'actions', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/229.webp',    word: 'Yürüyor',        category: 'actions', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/245.webp',    word: 'Uyuyor',         category: 'actions', difficulty: 0),
    QuizItem(imagePath: 'assets/images/orta/49.webp',      word: 'El sallıyor',    category: 'actions', difficulty: 1),
    QuizItem(imagePath: 'assets/images/orta/52.webp',      word: 'Yüzüyor',        category: 'actions', difficulty: 1),
    QuizItem(imagePath: 'assets/images/orta/68.webp',      word: 'El sallıyor',    category: 'actions', difficulty: 1),
    QuizItem(imagePath: 'assets/images/orta/145.webp',     word: 'Zıplıyor',       category: 'actions', difficulty: 1),
    QuizItem(imagePath: 'assets/images/orta/160.webp',     word: 'Su içiyor',      category: 'actions', difficulty: 1),
    QuizItem(imagePath: 'assets/images/orta/194.webp',     word: 'Su içiyor',      category: 'actions', difficulty: 1),
    QuizItem(imagePath: 'assets/images/orta/206.webp',     word: 'Zıplıyor',       category: 'actions', difficulty: 1),
    QuizItem(imagePath: 'assets/images/orta/225.webp',     word: 'Yüzüyor',        category: 'actions', difficulty: 1),
  ];

  static List<QuizItem> get all => [
    ...animals,
    ...fruitsVegetables,
    ...colors,
    ...shapes,
    ...bodyParts,
    ...clothes,
    ...dailyObjects,
    ...toys,
    ...nature,
    ...weather,
    ...actions,
  ];

  static List<QuizItem> byCategory(String category) {
    switch (category) {
      case 'animals':             return animals;
      case 'fruits_vegetables':   return fruitsVegetables;
      case 'colors':              return colors;
      case 'shapes':              return shapes;
      case 'body_parts':          return bodyParts;
      case 'clothes':             return clothes;
      case 'daily_objects':       return dailyObjects;
      case 'toys':                return toys;
      case 'nature':              return nature;
      case 'weather':             return weather;
      case 'actions':             return actions;
      default:                  return all;
    }
  }

  static List<QuizItem> byDifficulty(int difficulty) =>
      all.where((item) => item.difficulty == difficulty).toList();
}
