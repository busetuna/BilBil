import 'package:app/data/models/quiz_item.dart';
import 'package:app/services/asr/quiz_answer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  QuizItem item(String word) => QuizData.all.firstWhere((i) => i.word == word);
  bool ok(String heard, String word) => QuizAnswer.accepts(heard, item(word));

  test('doğru kelime ve bozuk söyleyişi kabul', () {
    expect(ok('kedi', 'Kedi'), isTrue);
    expect(
      ok('kedii', 'Kedi'),
      isTrue,
      reason: 'quiz kelimesi değil: tolerans',
    );
    expect(ok('bu bir kedi', 'Kedi'), isTrue);
    expect(ok('tedi', 'Kedi'), isTrue, reason: 'çocuk söyleyişi');
    expect(
      ok('şiş il', 'Yeşil'),
      isTrue,
      reason: '"şişil" (Vosk parçalı yazar)',
    );
  });

  test('başka bir quiz kelimesinin kendisi kabul edilmez', () {
    expect(ok('diz', 'Diş'), isFalse);
    expect(ok('diş', 'Diş'), isTrue);
    expect(ok('bay kuş', 'Kuş'), isFalse, reason: 'Baykuş\'un Vosk yazımı');
    expect(ok('göbek', 'Köpek'), isFalse);
  });

  test('resmin diğer doğru adı ve çok kelimeli cevabın parçası kabul', () {
    expect(ok('bardak', 'Kupa'), isTrue);
    expect(
      ok('ayı', 'Oyuncak ayı'),
      isTrue,
      reason: '"Ayı" ayrıca bir quiz kelimesi',
    );
    expect(ok('ayı', 'Kedi'), isFalse);
  });

  test('boş ya da tanınmayan ses kabul edilmez', () {
    expect(ok('', 'Kedi'), isFalse);
    expect(ok('[unk]', 'Kedi'), isFalse);
  });
}
