import 'package:flutter_test/flutter_test.dart';
import 'package:app/data/models/quiz_item.dart';
import 'package:app/features/learning/presentations/screens/answer_checker.dart';

void main() {
  test('her quiz kelimesi kendisi söylendiğinde doğru sayılır', () {
    for (final item in QuizData.all) {
      expect(AnswerChecker.check(item.word, item.word), isTrue,
          reason: item.word);
      expect(AnswerChecker.check(item.word.toLowerCase(), item.word), isTrue,
          reason: item.word);
    }
  });

  group('AnswerChecker.normalize', () {
    test('Türkçe büyük İ ve I doğru küçülür', () {
      expect(AnswerChecker.normalize('İNEK'), 'inek');
      expect(AnswerChecker.normalize('IŞIK'), 'ışık');
    });

    test('noktalama ve fazla boşluk temizlenir', () {
      expect(AnswerChecker.normalize('  Kedi.  '), 'kedi');
      expect(AnswerChecker.normalize('bu   bir kedi!'), 'bu bir kedi');
    });
  });

  group('AnswerChecker.check — kabul edilmesi gerekenler', () {
    test('tam eşleşme, büyük/küçük harf duyarsız', () {
      expect(AnswerChecker.check('kedi', 'Kedi'), isTrue);
      expect(AnswerChecker.check('inek', 'İnek'), isTrue);
    });

    test('cümle içinde hedef kelime', () {
      expect(AnswerChecker.check('bu bir kedi', 'Kedi'), isTrue);
    });

    test('kelimenin büyük kısmı söylenmişse', () {
      expect(AnswerChecker.check('kaplumba', 'Kaplumbağa'), isTrue);
    });

    test('çok kelimeli ifadede tek kelime', () {
      expect(AnswerChecker.check('kuşu', 'Muhabbet kuşu'), isTrue);
      expect(AnswerChecker.check('kedi', 'Bengal kedisi'), isTrue);
    });

    test('küçük telaffuz hatası', () {
      expect(AnswerChecker.check('köbek', 'Köpek'), isTrue);
      expect(AnswerChecker.check('kedu', 'Kedi'), isTrue);
    });

    test('Vosk sözlüğünde olmayan kelime parçalarla yazılmışsa', () {
      expect(AnswerChecker.check('ke le bek', 'Kelebek'), isTrue);
      expect(AnswerChecker.check('deniz atı', 'Denizatı'), isTrue);
      expect(AnswerChecker.check('uğur böceği', 'Uğurböceği'), isTrue);
    });

    test('Vosk "[unk]" işaretleri cevabı bozmaz', () {
      expect(AnswerChecker.check('[unk] kedi [unk]', 'Kedi'), isTrue);
    });

    test('alternatif tahminlerden biri tutuyorsa', () {
      expect(AnswerChecker.checkAny(['dedi', 'kedi'], 'Kedi'), isTrue);
      expect(AnswerChecker.checkAny(['elma', 'armut'], 'Kedi'), isFalse);
      expect(AnswerChecker.checkAny(const [], 'Kedi'), isFalse);
    });
  });

  group('AnswerChecker.check — reddedilmesi gerekenler', () {
    test('boş ya da sadece boşluk', () {
      expect(AnswerChecker.check('', 'Kedi'), isFalse);
      expect(AnswerChecker.check('   ', 'Kedi'), isFalse);
      expect(AnswerChecker.check('[unk]', 'Kedi'), isFalse);
    });

    test('kelimenin küçük bir parçası', () {
      expect(AnswerChecker.check('kap', 'Kaplumbağa'), isFalse);
      expect(AnswerChecker.check('ke', 'Kedi'), isFalse);
      expect(AnswerChecker.check('u', 'Muhabbet kuşu'), isFalse);
    });

    test('hedef, başka bir kelimenin içinde geçiyorsa', () {
      expect(AnswerChecker.check('televizyon', 'El'), isFalse);
      expect(AnswerChecker.check('domuz', 'Muz'), isFalse);
      expect(AnswerChecker.check('brokoli', 'Kol'), isFalse);
    });

    test('alakasız kelime', () {
      expect(AnswerChecker.check('elma', 'Kedi'), isFalse);
      expect(AnswerChecker.check('dede', 'Kedi'), isFalse);
    });
  });
}
