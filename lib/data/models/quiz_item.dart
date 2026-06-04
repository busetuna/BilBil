// lib/data/models/quiz_item.dart

class QuizItem {
  final String imagePath;
  final String word;
  final String category;
  final int difficulty; // 0=kolay, 1=orta, 2=zor

  const QuizItem({
    required this.imagePath,
    required this.word,
    required this.category,
    required this.difficulty,
  });
}

class QuizData {
  static const List<QuizItem> animals = [
    QuizItem(imagePath: 'assets/images/kolay/1.png',   word: 'Kedi',           category: 'animals', difficulty: 0),
    QuizItem(imagePath: 'assets/images/orta/6.png',    word: 'Baykuş',         category: 'animals', difficulty: 1),
    QuizItem(imagePath: 'assets/images/orta/10.png',   word: 'Zürafa',         category: 'animals', difficulty: 1),
    QuizItem(imagePath: 'assets/images/kolay/13.png',  word: 'Köpek',          category: 'animals', difficulty: 0),
    QuizItem(imagePath: 'assets/images/zor/23.png',    word: 'Nar Bülbülü',    category: 'animals', difficulty: 2),
    QuizItem(imagePath: 'assets/images/zor/28.png',    word: 'Tukan',          category: 'animals', difficulty: 2),
    QuizItem(imagePath: 'assets/images/zor/31.png',    word: 'Muhabbet kuşu',  category: 'animals', difficulty: 2),
    QuizItem(imagePath: 'assets/images/kolay/32.png',  word: 'Panda',          category: 'animals', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/33.png',  word: 'Kedi',           category: 'animals', difficulty: 0),
    QuizItem(imagePath: 'assets/images/orta/34.png',   word: 'Yunus',          category: 'animals', difficulty: 1),
    QuizItem(imagePath: 'assets/images/orta/35.png',   word: 'Denizatı',       category: 'animals', difficulty: 1),
    QuizItem(imagePath: 'assets/images/kolay/37.png',  word: 'Fil',            category: 'animals', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/40.png',  word: 'Kedi',           category: 'animals', difficulty: 0),
    QuizItem(imagePath: 'assets/images/orta/41.png',   word: 'Yarasa',         category: 'animals', difficulty: 1),
    QuizItem(imagePath: 'assets/images/kolay/43.png',  word: 'Köpek',          category: 'animals', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/44.png',  word: 'Aslan',          category: 'animals', difficulty: 0),
    QuizItem(imagePath: 'assets/images/orta/45.png',   word: 'Papağan',        category: 'animals', difficulty: 1),
    QuizItem(imagePath: 'assets/images/orta/47.png',   word: 'Sincap',         category: 'animals', difficulty: 1),
    QuizItem(imagePath: 'assets/images/zor/51.png',    word: 'Salyangoz',      category: 'animals', difficulty: 2),
    QuizItem(imagePath: 'assets/images/kolay/53.png',  word: 'Ayı',            category: 'animals', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/56.png',  word: 'Kedi',           category: 'animals', difficulty: 0),
    QuizItem(imagePath: 'assets/images/zor/59.png',    word: 'Rakun',          category: 'animals', difficulty: 2),
    QuizItem(imagePath: 'assets/images/orta/63.png',   word: 'Zebra',          category: 'animals', difficulty: 1),
    QuizItem(imagePath: 'assets/images/kolay/65.png',  word: 'Kedi',           category: 'animals', difficulty: 0),
    QuizItem(imagePath: 'assets/images/zor/66.png',    word: 'Kaniş',          category: 'animals', difficulty: 2),
    QuizItem(imagePath: 'assets/images/kolay/72.png',  word: 'Tavşan',         category: 'animals', difficulty: 0),
    QuizItem(imagePath: 'assets/images/orta/73.png',   word: 'Penguen',        category: 'animals', difficulty: 1),
    QuizItem(imagePath: 'assets/images/orta/82.png',   word: 'Balina',         category: 'animals', difficulty: 1),
    QuizItem(imagePath: 'assets/images/zor/88.png',    word: 'Pug',            category: 'animals', difficulty: 2),
    QuizItem(imagePath: 'assets/images/kolay/97.png',  word: 'Maymun',         category: 'animals', difficulty: 0),
    QuizItem(imagePath: 'assets/images/orta/99.png',   word: 'Kaplumbağa',     category: 'animals', difficulty: 1),
    QuizItem(imagePath: 'assets/images/orta/101.png',  word: 'Timsah',         category: 'animals', difficulty: 1),
    QuizItem(imagePath: 'assets/images/orta/102.png',  word: 'Flamingo',       category: 'animals', difficulty: 1),
    QuizItem(imagePath: 'assets/images/kolay/104.png', word: 'Kedi',           category: 'animals', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/115.png', word: 'Koyun',          category: 'animals', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/116.png', word: 'Koyun',          category: 'animals', difficulty: 0),
    QuizItem(imagePath: 'assets/images/orta/117.png',  word: 'Yengeç',         category: 'animals', difficulty: 1),
    QuizItem(imagePath: 'assets/images/orta/118.png',  word: 'Civciv',         category: 'animals', difficulty: 1),
    QuizItem(imagePath: 'assets/images/kolay/120.png', word: 'Arı',            category: 'animals', difficulty: 0),
    QuizItem(imagePath: 'assets/images/zor/121.png',   word: 'Buldog',         category: 'animals', difficulty: 2),
    QuizItem(imagePath: 'assets/images/zor/124.png',   word: 'Dalmaçyalı',     category: 'animals', difficulty: 2),
    QuizItem(imagePath: 'assets/images/orta/126.png',  word: 'Papağan',        category: 'animals', difficulty: 1),
    QuizItem(imagePath: 'assets/images/kolay/128.png', word: 'Kuş',            category: 'animals', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/132.png', word: 'Köpek',          category: 'animals', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/134.png', word: 'Kedi',           category: 'animals', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/153.png', word: 'İnek',           category: 'animals', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/155.png', word: 'Köpek',          category: 'animals', difficulty: 0),
    QuizItem(imagePath: 'assets/images/zor/156.png',   word: 'Bengal kedisi',  category: 'animals', difficulty: 2),
    QuizItem(imagePath: 'assets/images/orta/163.png',  word: 'Kelebek',        category: 'animals', difficulty: 1),
    QuizItem(imagePath: 'assets/images/orta/164.png',  word: 'Kirpi',          category: 'animals', difficulty: 1),
    QuizItem(imagePath: 'assets/images/zor/175.png',   word: 'Ahtapot',        category: 'animals', difficulty: 2),
    QuizItem(imagePath: 'assets/images/kolay/176.png', word: 'Köpek',          category: 'animals', difficulty: 0),
    QuizItem(imagePath: 'assets/images/orta/179.png',  word: 'Baykuş',         category: 'animals', difficulty: 1),
    QuizItem(imagePath: 'assets/images/zor/181.png',   word: 'Yusufçuk',       category: 'animals', difficulty: 2),
    QuizItem(imagePath: 'assets/images/kolay/185.png', word: 'Kedi',           category: 'animals', difficulty: 0),
    QuizItem(imagePath: 'assets/images/zor/187.png',   word: 'Chihuahua',      category: 'animals', difficulty: 2),
    QuizItem(imagePath: 'assets/images/orta/198.png',  word: 'Güvercin',       category: 'animals', difficulty: 1),
    QuizItem(imagePath: 'assets/images/zor/211.png',   word: 'Denizanası',     category: 'animals', difficulty: 2),
    QuizItem(imagePath: 'assets/images/kolay/217.png', word: 'Domuz',          category: 'animals', difficulty: 0),
    QuizItem(imagePath: 'assets/images/zor/236.png',   word: 'Uğurböceği',     category: 'animals', difficulty: 2),
    QuizItem(imagePath: 'assets/images/kolay/240.png', word: 'Kedi',           category: 'animals', difficulty: 0),
  ];

  static const List<QuizItem> fruitsVegetables = [
    QuizItem(imagePath: 'assets/images/zor/14.png',    word: 'Yaban mersini',  category: 'fruits_vegetables', difficulty: 2),
    QuizItem(imagePath: 'assets/images/kolay/36.png',  word: 'Mısır',          category: 'fruits_vegetables', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/46.png',  word: 'Havuç',          category: 'fruits_vegetables', difficulty: 0),
    QuizItem(imagePath: 'assets/images/zor/83.png',    word: 'Ahududu',        category: 'fruits_vegetables', difficulty: 2),
    QuizItem(imagePath: 'assets/images/kolay/85.png',  word: 'Nar',            category: 'fruits_vegetables', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/103.png', word: 'Üzüm',           category: 'fruits_vegetables', difficulty: 0),
    QuizItem(imagePath: 'assets/images/orta/106.png',  word: 'Bezelye',        category: 'fruits_vegetables', difficulty: 1),
    QuizItem(imagePath: 'assets/images/orta/108.png',  word: 'Erik',           category: 'fruits_vegetables', difficulty: 1),
    QuizItem(imagePath: 'assets/images/kolay/112.png', word: 'Biber',          category: 'fruits_vegetables', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/113.png', word: 'Patates',        category: 'fruits_vegetables', difficulty: 0),
    QuizItem(imagePath: 'assets/images/zor/127.png',   word: 'Hindistancevizi',category: 'fruits_vegetables', difficulty: 2),
    QuizItem(imagePath: 'assets/images/orta/135.png',  word: 'Mango',          category: 'fruits_vegetables', difficulty: 1),
    QuizItem(imagePath: 'assets/images/kolay/136.png', word: 'Muz',            category: 'fruits_vegetables', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/137.png', word: 'Domates',        category: 'fruits_vegetables', difficulty: 0),
    QuizItem(imagePath: 'assets/images/orta/141.png',  word: 'Sarımsak',       category: 'fruits_vegetables', difficulty: 1),
    QuizItem(imagePath: 'assets/images/zor/142.png',   word: 'Mor lahana',     category: 'fruits_vegetables', difficulty: 2),
    QuizItem(imagePath: 'assets/images/orta/143.png',  word: 'Turp',           category: 'fruits_vegetables', difficulty: 1),
    QuizItem(imagePath: 'assets/images/orta/149.png',  word: 'Mantar',         category: 'fruits_vegetables', difficulty: 1),
    QuizItem(imagePath: 'assets/images/orta/158.png',  word: 'Marul',          category: 'fruits_vegetables', difficulty: 1),
    QuizItem(imagePath: 'assets/images/kolay/161.png', word: 'Armut',          category: 'fruits_vegetables', difficulty: 0),
    QuizItem(imagePath: 'assets/images/orta/162.png',  word: 'Brokoli',        category: 'fruits_vegetables', difficulty: 1),
    QuizItem(imagePath: 'assets/images/zor/166.png',   word: 'Karnabahar',     category: 'fruits_vegetables', difficulty: 2),
    QuizItem(imagePath: 'assets/images/orta/171.png',  word: 'Patlıcan',       category: 'fruits_vegetables', difficulty: 1),
    QuizItem(imagePath: 'assets/images/kolay/183.png', word: 'Kiraz',          category: 'fruits_vegetables', difficulty: 0),
    QuizItem(imagePath: 'assets/images/orta/186.png',  word: 'Ananas',         category: 'fruits_vegetables', difficulty: 1),
    QuizItem(imagePath: 'assets/images/zor/189.png',   word: 'Böğürtlen',      category: 'fruits_vegetables', difficulty: 2),
    QuizItem(imagePath: 'assets/images/zor/197.png',   word: 'Kereviz',        category: 'fruits_vegetables', difficulty: 2),
    QuizItem(imagePath: 'assets/images/orta/201.png',  word: 'Kabak',          category: 'fruits_vegetables', difficulty: 1),
    QuizItem(imagePath: 'assets/images/kolay/204.png', word: 'Karpuz',         category: 'fruits_vegetables', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/207.png', word: 'Portakal',       category: 'fruits_vegetables', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/214.png', word: 'Elma',           category: 'fruits_vegetables', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/224.png', word: 'Limon',          category: 'fruits_vegetables', difficulty: 0),
    QuizItem(imagePath: 'assets/images/orta/230.png',  word: 'Şeftali',        category: 'fruits_vegetables', difficulty: 1),
    QuizItem(imagePath: 'assets/images/orta/235.png',  word: 'Bezelye',        category: 'fruits_vegetables', difficulty: 1),
    QuizItem(imagePath: 'assets/images/orta/238.png',  word: 'Soğan',          category: 'fruits_vegetables', difficulty: 1),
    QuizItem(imagePath: 'assets/images/kolay/237.png', word: 'Kivi',           category: 'fruits_vegetables', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/241.png', word: 'Çilek',          category: 'fruits_vegetables', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/244.png', word: 'Biber',          category: 'fruits_vegetables', difficulty: 0),
  ];

  static const List<QuizItem> colors = [
    QuizItem(imagePath: 'assets/images/kolay/7.png',   word: 'Kırmızı',        category: 'colors', difficulty: 0),
    QuizItem(imagePath: 'assets/images/orta/48.png',   word: 'Kahverengi',     category: 'colors', difficulty: 1),
    QuizItem(imagePath: 'assets/images/kolay/67.png',  word: 'Beyaz',          category: 'colors', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/75.png',  word: 'Pembe',          category: 'colors', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/80.png',  word: 'Siyah',          category: 'colors', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/96.png',  word: 'Pembe',          category: 'colors', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/105.png', word: 'Yeşil',          category: 'colors', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/107.png', word: 'Yeşil',          category: 'colors', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/146.png', word: 'Gri',            category: 'colors', difficulty: 0),
    QuizItem(imagePath: 'assets/images/orta/154.png',  word: 'Şeftali',        category: 'colors', difficulty: 1),
    QuizItem(imagePath: 'assets/images/kolay/170.png', word: 'Mavi',           category: 'colors', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/173.png', word: 'Yeşil',          category: 'colors', difficulty: 0),
    QuizItem(imagePath: 'assets/images/orta/174.png',  word: 'Kahverengi',     category: 'colors', difficulty: 1),
    QuizItem(imagePath: 'assets/images/kolay/178.png', word: 'Sarı',           category: 'colors', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/191.png', word: 'Mavi',           category: 'colors', difficulty: 0),
    QuizItem(imagePath: 'assets/images/orta/192.png',  word: 'Turuncu',        category: 'colors', difficulty: 1),
    QuizItem(imagePath: 'assets/images/kolay/199.png', word: 'Mor',            category: 'colors', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/212.png', word: 'Mor',            category: 'colors', difficulty: 0),
    QuizItem(imagePath: 'assets/images/zor/234.png',   word: 'Bej',            category: 'colors', difficulty: 2),
    QuizItem(imagePath: 'assets/images/orta/243.png',  word: 'Kahverengi',     category: 'colors', difficulty: 1),
  ];

  static const List<QuizItem> shapes = [
    QuizItem(imagePath: 'assets/images/kolay/4.png',   word: 'Yıldız',         category: 'shapes', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/30.png',  word: 'Kalp',           category: 'shapes', difficulty: 0),
    QuizItem(imagePath: 'assets/images/zor/39.png',    word: 'Beşgen',         category: 'shapes', difficulty: 2),
    QuizItem(imagePath: 'assets/images/kolay/81.png',  word: 'Yıldız',         category: 'shapes', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/94.png',  word: 'Daire',          category: 'shapes', difficulty: 0),
    QuizItem(imagePath: 'assets/images/orta/129.png',  word: 'Üçgen',          category: 'shapes', difficulty: 1),
    QuizItem(imagePath: 'assets/images/orta/190.png',  word: 'Oval',           category: 'shapes', difficulty: 1),
    QuizItem(imagePath: 'assets/images/zor/222.png',   word: 'Eşkenar dörtgen',category: 'shapes', difficulty: 2),
    QuizItem(imagePath: 'assets/images/kolay/227.png', word: 'Ay',             category: 'shapes', difficulty: 0),
  ];

  static const List<QuizItem> bodyParts = [
    QuizItem(imagePath: 'assets/images/orta/25.png',   word: 'Parmak',         category: 'body_parts', difficulty: 1),
    QuizItem(imagePath: 'assets/images/orta/42.png',   word: 'Boyun',          category: 'body_parts', difficulty: 1),
    QuizItem(imagePath: 'assets/images/kolay/57.png',  word: 'Ayak',           category: 'body_parts', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/69.png',  word: 'Baş',            category: 'body_parts', difficulty: 0),
    QuizItem(imagePath: 'assets/images/orta/78.png',   word: 'Dirsek',         category: 'body_parts', difficulty: 1),
    QuizItem(imagePath: 'assets/images/orta/79.png',   word: 'Göbek',          category: 'body_parts', difficulty: 1),
    QuizItem(imagePath: 'assets/images/orta/95.png',   word: 'Sırt',           category: 'body_parts', difficulty: 1),
    QuizItem(imagePath: 'assets/images/kolay/110.png', word: 'Ağız',           category: 'body_parts', difficulty: 0),
    QuizItem(imagePath: 'assets/images/orta/114.png',  word: 'Yumruk',         category: 'body_parts', difficulty: 1),
    QuizItem(imagePath: 'assets/images/kolay/122.png', word: 'Yüz',            category: 'body_parts', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/125.png', word: 'Burun',          category: 'body_parts', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/130.png', word: 'Diz',            category: 'body_parts', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/150.png', word: 'Bacak',          category: 'body_parts', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/172.png', word: 'El',             category: 'body_parts', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/203.png', word: 'Ayak',           category: 'body_parts', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/208.png', word: 'Göz',            category: 'body_parts', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/209.png', word: 'Ayak',           category: 'body_parts', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/215.png', word: 'Kulak',          category: 'body_parts', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/218.png', word: 'Dil',            category: 'body_parts', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/223.png', word: 'Kol',            category: 'body_parts', difficulty: 0),
  ];

  static const List<QuizItem> clothes = [
    QuizItem(imagePath: 'assets/images/orta/2.png',    word: 'Tulum',          category: 'clothes', difficulty: 1),
    QuizItem(imagePath: 'assets/images/kolay/11.png',  word: 'Şapka',          category: 'clothes', difficulty: 0),
    QuizItem(imagePath: 'assets/images/orta/16.png',   word: 'Etek',           category: 'clothes', difficulty: 1),
    QuizItem(imagePath: 'assets/images/kolay/93.png',  word: 'Şort',           category: 'clothes', difficulty: 0),
    QuizItem(imagePath: 'assets/images/orta/100.png',  word: 'Pijama',         category: 'clothes', difficulty: 1),
    QuizItem(imagePath: 'assets/images/kolay/131.png', word: 'Şort',           category: 'clothes', difficulty: 0),
    QuizItem(imagePath: 'assets/images/zor/216.png',   word: 'Kapüşonlu',      category: 'clothes', difficulty: 2),
    QuizItem(imagePath: 'assets/images/orta/228.png',  word: 'Tayt',           category: 'clothes', difficulty: 1),
  ];

  static const List<QuizItem> dailyObjects = [
    QuizItem(imagePath: 'assets/images/zor/8.png',     word: 'Çalar saat',     category: 'daily_objects', difficulty: 2),
    QuizItem(imagePath: 'assets/images/orta/9.png',    word: 'Sandalye',       category: 'daily_objects', difficulty: 1),
    QuizItem(imagePath: 'assets/images/orta/17.png',   word: 'Biberon',        category: 'daily_objects', difficulty: 1),
    QuizItem(imagePath: 'assets/images/kolay/20.png',  word: 'Kitap',          category: 'daily_objects', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/22.png',  word: 'Çorap',          category: 'daily_objects', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/24.png',  word: 'Yatak',          category: 'daily_objects', difficulty: 0),
    QuizItem(imagePath: 'assets/images/orta/29.png',   word: 'Dolap',          category: 'daily_objects', difficulty: 1),
    QuizItem(imagePath: 'assets/images/kolay/54.png',  word: 'Masa',           category: 'daily_objects', difficulty: 0),
    QuizItem(imagePath: 'assets/images/orta/60.png',   word: 'Tişört',         category: 'daily_objects', difficulty: 1),
    QuizItem(imagePath: 'assets/images/orta/61.png',   word: 'Televizyon',     category: 'daily_objects', difficulty: 1),
    QuizItem(imagePath: 'assets/images/orta/64.png',   word: 'Hırka',          category: 'daily_objects', difficulty: 1),
    QuizItem(imagePath: 'assets/images/orta/70.png',   word: 'Elbise',         category: 'daily_objects', difficulty: 1),
    QuizItem(imagePath: 'assets/images/zor/76.png',    word: 'Çöp kutusu',     category: 'daily_objects', difficulty: 2),
    QuizItem(imagePath: 'assets/images/orta/87.png',   word: 'Pencere',        category: 'daily_objects', difficulty: 1),
    QuizItem(imagePath: 'assets/images/orta/89.png',   word: 'Sünger',         category: 'daily_objects', difficulty: 1),
    QuizItem(imagePath: 'assets/images/zor/90.png',    word: 'Klozet',         category: 'daily_objects', difficulty: 2),
    QuizItem(imagePath: 'assets/images/kolay/91.png',  word: 'Telefon',        category: 'daily_objects', difficulty: 0),
    QuizItem(imagePath: 'assets/images/orta/119.png',  word: 'Tencere',        category: 'daily_objects', difficulty: 1),
    QuizItem(imagePath: 'assets/images/orta/123.png',  word: 'Fincan',         category: 'daily_objects', difficulty: 1),
    QuizItem(imagePath: 'assets/images/kolay/148.png', word: 'Araba',          category: 'daily_objects', difficulty: 0),
    QuizItem(imagePath: 'assets/images/orta/151.png',  word: 'Kanepe',         category: 'daily_objects', difficulty: 1),
    QuizItem(imagePath: 'assets/images/orta/152.png',  word: 'Koltuk',         category: 'daily_objects', difficulty: 1),
    QuizItem(imagePath: 'assets/images/orta/157.png',  word: 'Küvet',          category: 'daily_objects', difficulty: 1),
    QuizItem(imagePath: 'assets/images/orta/165.png',  word: 'Lavabo',         category: 'daily_objects', difficulty: 1),
    QuizItem(imagePath: 'assets/images/kolay/168.png', word: 'Yastık',         category: 'daily_objects', difficulty: 0),
    QuizItem(imagePath: 'assets/images/orta/188.png',  word: 'Tişört',         category: 'daily_objects', difficulty: 1),
    QuizItem(imagePath: 'assets/images/kolay/195.png', word: 'Yastık',         category: 'daily_objects', difficulty: 0),
    QuizItem(imagePath: 'assets/images/zor/202.png',   word: 'Abajur',         category: 'daily_objects', difficulty: 2),
    QuizItem(imagePath: 'assets/images/orta/210.png',  word: 'Kupa',           category: 'daily_objects', difficulty: 1),
    QuizItem(imagePath: 'assets/images/zor/213.png',   word: 'Buzdolabı',      category: 'daily_objects', difficulty: 2),
    QuizItem(imagePath: 'assets/images/kolay/219.png', word: 'Havlu',          category: 'daily_objects', difficulty: 0),
    QuizItem(imagePath: 'assets/images/orta/221.png',  word: 'Ayakkabı',       category: 'daily_objects', difficulty: 1),
    QuizItem(imagePath: 'assets/images/orta/231.png',  word: 'Ayakkabı',       category: 'daily_objects', difficulty: 1),
    QuizItem(imagePath: 'assets/images/orta/232.png',  word: 'Vazo',           category: 'daily_objects', difficulty: 1),
    QuizItem(imagePath: 'assets/images/orta/242.png',  word: 'Ayakkabı',       category: 'daily_objects', difficulty: 1),
  ];

  static const List<QuizItem> weather = [
    QuizItem(imagePath: 'assets/images/kolay/18.png',  word: 'Soğuk',          category: 'weather', difficulty: 0),
    QuizItem(imagePath: 'assets/images/orta/19.png',   word: 'Rüzgarlı',       category: 'weather', difficulty: 1),
    QuizItem(imagePath: 'assets/images/kolay/26.png',  word: 'Güneşli',        category: 'weather', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/27.png',  word: 'Yağmur',         category: 'weather', difficulty: 0),
    QuizItem(imagePath: 'assets/images/orta/50.png',   word: 'Fırtına',        category: 'weather', difficulty: 1),
    QuizItem(imagePath: 'assets/images/zor/58.png',    word: 'Kasırga',        category: 'weather', difficulty: 2),
    QuizItem(imagePath: 'assets/images/kolay/74.png',  word: 'Bulutlu',        category: 'weather', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/86.png',  word: 'Bulutlu',        category: 'weather', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/167.png', word: 'Sıcak',          category: 'weather', difficulty: 0),
    QuizItem(imagePath: 'assets/images/zor/193.png',   word: 'Parçalı bulutlu',category: 'weather', difficulty: 2),
    QuizItem(imagePath: 'assets/images/kolay/196.png', word: 'Rüzgar',         category: 'weather', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/205.png', word: 'Bulutlu',        category: 'weather', difficulty: 0),
    QuizItem(imagePath: 'assets/images/orta/220.png',  word: 'Gökkuşağı',      category: 'weather', difficulty: 1),
    QuizItem(imagePath: 'assets/images/kolay/233.png', word: 'Bulutlu',        category: 'weather', difficulty: 0),
  ];

  static const List<QuizItem> actions = [
    QuizItem(imagePath: 'assets/images/kolay/3.png',   word: 'Oturuyor',       category: 'actions', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/12.png',  word: 'Okuyor',         category: 'actions', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/15.png',  word: 'Yürüyor',        category: 'actions', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/38.png',  word: 'Oturuyor',       category: 'actions', difficulty: 0),
    QuizItem(imagePath: 'assets/images/orta/49.png',   word: 'El sallıyor',    category: 'actions', difficulty: 1),
    QuizItem(imagePath: 'assets/images/orta/52.png',   word: 'Yüzüyor',        category: 'actions', difficulty: 1),
    QuizItem(imagePath: 'assets/images/kolay/55.png',  word: 'Uyuyor',         category: 'actions', difficulty: 0),
    QuizItem(imagePath: 'assets/images/orta/68.png',   word: 'El sallıyor',    category: 'actions', difficulty: 1),
    QuizItem(imagePath: 'assets/images/kolay/77.png',  word: 'Uyuyor',         category: 'actions', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/84.png',  word: 'Yiyor',          category: 'actions', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/98.png',  word: 'Yiyor',          category: 'actions', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/138.png', word: 'Koşuyor',        category: 'actions', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/139.png', word: 'Koşuyor',        category: 'actions', difficulty: 0),
    QuizItem(imagePath: 'assets/images/orta/145.png',  word: 'Zıplıyor',       category: 'actions', difficulty: 1),
    QuizItem(imagePath: 'assets/images/kolay/159.png', word: 'Koşuyor',        category: 'actions', difficulty: 0),
    QuizItem(imagePath: 'assets/images/orta/160.png',  word: 'Su içiyor',      category: 'actions', difficulty: 1),
    QuizItem(imagePath: 'assets/images/kolay/169.png', word: 'Okuyor',         category: 'actions', difficulty: 0),
    QuizItem(imagePath: 'assets/images/orta/194.png',  word: 'Su içiyor',      category: 'actions', difficulty: 1),
    QuizItem(imagePath: 'assets/images/orta/206.png',  word: 'Zıplıyor',       category: 'actions', difficulty: 1),
    QuizItem(imagePath: 'assets/images/orta/225.png',  word: 'Yüzüyor',        category: 'actions', difficulty: 1),
    QuizItem(imagePath: 'assets/images/kolay/229.png', word: 'Yürüyor',        category: 'actions', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/245.png', word: 'Uyuyor',         category: 'actions', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/246.png', word: 'Koşuyor',        category: 'actions', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/247.png', word: 'Koşuyor',        category: 'actions', difficulty: 0),
  ];

  static const List<QuizItem> adjectives = [
    QuizItem(imagePath: 'assets/images/orta/5.png',    word: 'Hediye',         category: 'adjectives', difficulty: 1),
    QuizItem(imagePath: 'assets/images/kolay/21.png',  word: 'Mutlu',          category: 'adjectives', difficulty: 0),
    QuizItem(imagePath: 'assets/images/zor/62.png',    word: 'Yıpranmış',      category: 'adjectives', difficulty: 2),
    QuizItem(imagePath: 'assets/images/kolay/92.png',  word: 'Soğuk',          category: 'adjectives', difficulty: 0),
    QuizItem(imagePath: 'assets/images/kolay/109.png', word: 'Temiz',          category: 'adjectives', difficulty: 0),
    QuizItem(imagePath: 'assets/images/orta/133.png',  word: 'Parlak',         category: 'adjectives', difficulty: 1),
    QuizItem(imagePath: 'assets/images/orta/140.png',  word: 'Hızlı',          category: 'adjectives', difficulty: 1),
    QuizItem(imagePath: 'assets/images/kolay/144.png', word: 'Güneşli',        category: 'adjectives', difficulty: 0),
    QuizItem(imagePath: 'assets/images/zor/147.png',   word: 'Çamurlu',        category: 'adjectives', difficulty: 2),
    QuizItem(imagePath: 'assets/images/zor/180.png',   word: 'Dişli',          category: 'adjectives', difficulty: 2),
    QuizItem(imagePath: 'assets/images/zor/182.png',   word: 'Solgun',         category: 'adjectives', difficulty: 2),
    QuizItem(imagePath: 'assets/images/orta/200.png',  word: 'Renkli',         category: 'adjectives', difficulty: 1),
    QuizItem(imagePath: 'assets/images/orta/226.png',  word: 'Taş',            category: 'adjectives', difficulty: 1),
    QuizItem(imagePath: 'assets/images/orta/239.png',  word: 'Sevimli',        category: 'adjectives', difficulty: 1),
  ];

  static List<QuizItem> get all => [
    ...animals,
    ...fruitsVegetables,
    ...colors,
    ...shapes,
    ...bodyParts,
    ...clothes,
    ...dailyObjects,
    ...weather,
    ...actions,
    ...adjectives,
  ];

  static List<QuizItem> byCategory(String category) {
    switch (category) {
      case 'animals':           return animals;
      case 'fruits_vegetables': return fruitsVegetables;
      case 'colors':            return colors;
      case 'shapes':            return shapes;
      case 'body_parts':        return bodyParts;
      case 'clothes':           return clothes;
      case 'daily_objects':     return dailyObjects;
      case 'weather':           return weather;
      case 'actions':           return actions;
      case 'adjectives':        return adjectives;
      default:                  return all;
    }
  }

  static List<QuizItem> byDifficulty(int difficulty) =>
      all.where((item) => item.difficulty == difficulty).toList();
}