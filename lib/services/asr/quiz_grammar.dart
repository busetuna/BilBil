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
  static List<String>? forWord(String word) {
    if (!voskQuizPhrases.containsKey(AnswerChecker.normalize(word))) {
      return null;
    }
    return _all ??= List.unmodifiable(_build());
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
