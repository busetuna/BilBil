import 'package:app/data/models/quiz_item.dart';
import 'package:app/features/learning/presentations/screens/answer_checker.dart';
import 'package:app/services/asr/quiz_grammar.dart';
import 'package:app/services/asr/vosk_asr_service.dart';
import 'package:app/services/asr/vosk_vocabulary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('QuizGrammar', () {
    test('sözlükteki kelime için kapalı sözlük: hedef ve "[unk]" içinde', () {
      final g = QuizGrammar.forWord('Kedi')!;
      expect(g, contains('kedi'));
      expect(g.last, '[unk]');
    });

    test('sözlükte olmayan kelime takma adıyla girer', () {
      expect(QuizGrammar.forWord('Kelebek'), contains('ke le bek'));
      expect(QuizGrammar.forWord('Uğurböceği'), contains('uğur böceği'));
    });

    test(
      'Vosk\'un hiç yazamadığı kelimede kapalı sözlük yok (açık sözlük)',
      () {
        expect(QuizGrammar.forWord('Kaplumbağa'), isNull);
        expect(QuizGrammar.forWord('Zürafa'), isNull);
      },
    );

    test('çok kelimeli ifadenin kelimeleri de tek başına söylenebilir', () {
      final g = QuizGrammar.forWord('Muhabbet kuşu')!;
      expect(g, containsAll(['muhabbet kuşu', 'kuşu']));
    });

    test(
      'tablo güncel: her quiz kelimesi ya tabloda ya açık sözlük listesinde',
      () {
        // Kelime listesi değişince tool/generate_vosk_vocabulary.py yeniden çalıştırılmalı.
        final inTable = QuizData.all
            .map((i) => AnswerChecker.normalize(i.word))
            .where(voskQuizPhrases.containsKey)
            .toSet();
        expect(inTable, isNotEmpty);
        for (final phrase in voskQuizPhrases.values) {
          expect(phrase, isNot(contains('[unk]')));
        }
      },
    );

    test('çocuk söyleyişleri yalnızca o sorunun sözlüğüne girer', () {
      final yesil = QuizGrammar.forWord('Yeşil')!;
      expect(yesil, contains('şiş il'), reason: '"şişil" (yeşil)');
      expect(yesil.last, '[unk]');
      expect(QuizGrammar.forWord('Kedi'), contains('tedi'));
      expect(QuizGrammar.forWord('Köpek'), isNot(contains('tedi')));
    });

    test('çocuk söyleyişi doğru sayılır, başka kelimeninki sayılmaz', () {
      expect(QuizGrammar.isChildVariant('şiş il', 'Yeşil'), isTrue);
      expect(QuizGrammar.isChildVariant('şişil', 'Yeşil'), isTrue);
      expect(QuizGrammar.isChildVariant('tedi', 'Kedi'), isTrue);
      expect(QuizGrammar.isChildVariant('tedi', 'Yeşil'), isFalse);
      expect(QuizGrammar.isChildVariant('', 'Kedi'), isFalse);
    });

    test('hiçbir çocuk söyleyişi başka bir quiz kelimesinin kendisi değil', () {
      final words = {
        for (final i in QuizData.all)
          AnswerChecker.normalize(i.word).replaceAll(' ', ''),
      };
      voskChildVariants.forEach((word, variants) {
        for (final v in variants) {
          final flat = v.replaceAll(' ', '');
          expect(
            words.contains(flat) && flat != word.replaceAll(' ', ''),
            isFalse,
            reason: '$word ← $v',
          );
        }
      });
    });

    test('takma ad tanınırsa cevap kontrolü doğru sayar', () {
      voskQuizPhrases.forEach((word, phrase) {
        expect(
          AnswerChecker.check(phrase, word),
          isTrue,
          reason: '$word ← $phrase',
        );
      });
    });
  });

  group('VoskAsrService.parseFinal', () {
    test('alternatifli sonuç: sırayla, "[unk]" ve boşlar atılır', () {
      const json =
          '{"alternatives": [{"confidence": 9.1, "text": "kedi"},'
          ' {"confidence": 7.3, "text": "[unk] dedi"}, {"confidence": 1, "text": "[unk]"},'
          ' {"confidence": 0.5, "text": "kedi"}]}';
      expect(VoskAsrService.parseFinal(json), ['kedi', 'dedi']);
    });

    test('alternatifsiz sonuç', () {
      expect(VoskAsrService.parseFinal('{"text": "köpek"}'), ['köpek']);
      expect(VoskAsrService.parseFinal('{"text": ""}'), isEmpty);
    });

    test('bozuk JSON çökertmez', () {
      expect(VoskAsrService.parseFinal('not json'), isEmpty);
    });
  });
}
