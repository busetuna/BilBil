import '../../features/learning/presentations/screens/answer_checker.dart';
import 'vosk_vocabulary.dart';

/// Vosk kapalı sözlüğü (grammar): tanımayı quiz kelimeleriyle sınırlar.
///
/// Açık sözlükte Vosk on binlerce kelime arasından seçer ve çocuğun bozuk
/// söylediği "kedi"yi kolayca "dedi" yapar; kapalı sözlükte yalnızca quiz
/// kelimeleri ve "[unk]" (tanınmayan ses) arasından seçer. Sözlük, hedef ve
/// bir avuç çeldirici değil BÜTÜN quiz kelimelerinden oluşur: çocuk başka bir
/// kelime söylerse o kelime kendi adıyla tanınır, hedef sanılmaz.
class QuizGrammar {
  static List<String>? _all;

  /// [word] için kapalı sözlük. Vosk bu kelimeyi hiç yazamıyorsa (sözlükte
  /// yok ve parçalanamıyor) null: o soruda açık sözlük kullanılır, çünkü
  /// kapalı sözlükte hedef hiç tanınamazdı.
  ///
  /// Hedefin çocuk söyleyişleri de eklenir ("yeşil" sorulurken "şişil"):
  /// yalnızca o sorunun sözlüğüne, başka kelimelerinkiyle karışmasın.
  static List<String>? forWord(String word) {
    final key = AnswerChecker.normalize(word);
    if (!voskQuizPhrases.containsKey(key)) return null;
    final base = _all ??= List.unmodifiable(_build());
    final child = voskChildVariants[key];
    if (child == null || child.isEmpty) return base;
    return _withChild[key] ??= List.unmodifiable([
      ...base.where((p) => p != '[unk]'),
      ...child.where((c) => !base.contains(c)),
      '[unk]',
    ]);
  }

  static final _withChild = <String, List<String>>{};

  /// Vosk'un yazdığı metin bu kelimenin bir çocuk söyleyişi mi? Çocuk
  /// "şişil" dediğinde Vosk "şişil" (ya da parçalı "şiş il") yazar.
  static bool isChildVariant(String recognized, String word) {
    final variants = voskChildVariants[AnswerChecker.normalize(word)];
    if (variants == null) return false;
    final flat = AnswerChecker.normalize(
      recognized.replaceAll('[unk]', ' '),
    ).replaceAll(' ', '');
    return flat.isNotEmpty &&
        variants.any((v) => v.replaceAll(' ', '') == flat);
  }

  static List<String> _build() {
    final phrases = <String>{};
    voskQuizPhrases.forEach((word, phrase) {
      phrases.add(phrase);
      // Sözlükteki çok kelimeli ifadelerin kelimeleri de: "muhabbet kuşu"
      // için çocuk yalnızca "kuşu" diyebilir.
      if (word == phrase && phrase.contains(' ')) {
        phrases.addAll(phrase.split(' '));
      }
    });
    return [...phrases, '[unk]'];
  }
}
