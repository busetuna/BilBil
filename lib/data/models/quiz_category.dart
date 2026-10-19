import 'quiz_item.dart';

/// Quiz kategorisi: ana ekrandaki kart ve ebeveyn panelindeki adı.
class QuizCategory {
  final String id;
  final String name;

  /// Kartta gösterilen kelime: kategorinin Kolay seviyesinden, çocuğun
  /// tanıyacağı bir resim.
  final String coverWord;

  const QuizCategory(this.id, this.name, this.coverWord);

  /// Bir seviyenin kategoride oynanabilmesi için gereken en az kelime.
  /// Daha azında aynı resimler art arda gelir.
  static const minItemsPerLevel = 3;

  static const all = [
    QuizCategory('animals', 'Hayvanlar', 'Kedi'),
    QuizCategory('fruits_vegetables', 'Meyve-Sebze', 'Üzüm'),
    QuizCategory('colors', 'Renkler', 'Kırmızı'),
    QuizCategory('shapes', 'Şekiller', 'Yıldız'),
    QuizCategory('body_parts', 'Vücut Bölümleri', 'Burun'),
    QuizCategory('clothes', 'Kıyafetler', 'Şapka'),
    QuizCategory('daily_objects', 'Günlük Eşyalar', 'Araba'),
    QuizCategory('weather', 'Hava Durumu', 'Güneşli'),
    QuizCategory('actions', 'Eylemler', 'Yürüyor'),
    QuizCategory('adjectives', 'Basit Sıfatlar', 'Mutlu'),
  ];

  static String nameOf(String id) =>
      all.where((c) => c.id == id).firstOrNull?.name ?? id;

  List<QuizItem> get items => QuizData.byCategory(id);

  List<QuizItem> itemsAt(int difficulty) =>
      items.where((i) => i.difficulty == difficulty).toList();

  QuizItem get cover => items.firstWhere(
    (i) => i.word == coverWord && i.difficulty == 0,
    orElse: () => items.first,
  );

  /// Bu kategoride çıkılabilecek en yüksek zorluk: Kolay'dan başlayarak
  /// her seviyede en az [minItemsPerLevel] kelime olmalı. Örneğin
  /// Eylemler'de Zor kelime yok; ajan oraya çıkarsa quiz boş kalırdı.
  int get maxDifficulty {
    var max = -1;
    for (var d = 0; d <= 2; d++) {
      if (itemsAt(d).length < minItemsPerLevel) break;
      max = d;
    }
    return max;
  }
}
