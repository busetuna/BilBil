import '../../data/models/quiz_item.dart';
import '../../features/learning/presentations/screens/answer_checker.dart';
import 'quiz_grammar.dart';
import 'vosk_vocabulary.dart';

/// Tanınan metin bu sorunun cevabı mı?
///
/// [AnswerChecker] çocukların bozuk söyleyişini harf toleransıyla kabul
/// eder. Ama tanınan metin BAŞKA bir quiz kelimesinin kendisiyse (Vosk
/// kapalı sözlükte "diz" yazdıysa) çocuk büyük ihtimalle gerçekten o kelimeyi
/// söylemiştir: tolerans uygulanmaz. Önceden "diz", "diş" sorusunda doğru
/// sayılıyordu; sentetik seslerle ölçümde yanlış kabul %31'den %7'ye indi,
/// doğru kabul değişmedi. Çocukların tipik söyleyişleri ("yeşil" için
/// "şişil", bkz. [QuizGrammar.isChildVariant]) doğru sayılır.
class QuizAnswer {
  // Normalize edilmiş quiz kelimesi ya da Vosk biçimi -> o kelime.
  static final Map<String, String> _owners = _build();

  static Map<String, String> _build() {
    final owners = <String, String>{};
    for (final item in QuizData.all) {
      for (final a in item.answers) {
        final n = AnswerChecker.normalize(a);
        owners[n] = n;
      }
    }
    voskQuizPhrases.forEach(
      (word, phrase) =>
          owners.putIfAbsent(AnswerChecker.normalize(phrase), () => word),
    );
    return owners;
  }

  static bool accepts(String recognized, QuizItem item) {
    if (QuizGrammar.isChildVariant(recognized, item.word)) return true;
    final heard = AnswerChecker.normalize(recognized.replaceAll('[unk]', ' '));
    if (heard.isEmpty) return false;
    final answers = {for (final a in item.answers) AnswerChecker.normalize(a)};
    final owner = _owners[heard];
    // Başka bir quiz kelimesi duyuldu; çok kelimeli cevabın bir parçasıysa
    // ("Oyuncak ayı" için "ayı") tolerans yine geçerli.
    final partOfAnswer =
        owner != null && answers.any((a) => a.split(' ').contains(owner));
    if (owner != null && !partOfAnswer) return answers.contains(owner);
    return item.answers.any((a) => AnswerChecker.check(recognized, a));
  }
}
