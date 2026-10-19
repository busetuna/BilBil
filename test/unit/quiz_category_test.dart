import 'dart:io';

import 'package:app/data/models/quiz_category.dart';
import 'package:app/data/models/quiz_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('verideki her kategori tanımlı, kimlikler tekrarsız', () {
    final ids = QuizCategory.all.map((c) => c.id).toList();
    expect(ids.toSet().length, ids.length);
    expect(ids.toSet(), QuizData.all.map((i) => i.category).toSet());
    for (final c in QuizCategory.all) {
      expect(QuizCategory.nameOf(c.id), c.name);
    }
  });

  test(
    'kapak resmi Kolay seviyeden, seçilen kelimenin kendisi; dosyası var',
    () {
      for (final c in QuizCategory.all) {
        expect(c.cover.word, c.coverWord, reason: c.id);
        expect(c.cover.difficulty, 0, reason: c.id);
        expect(File(c.cover.imagePath).existsSync(), isTrue, reason: c.id);
      }
    },
  );

  test('kategoride kelimesi az olan seviyeye çıkılmaz', () {
    final max = {for (final c in QuizCategory.all) c.id: c.maxDifficulty};
    expect(max['animals'], 2);
    expect(max['actions'], 1, reason: 'Zor eylem yok');
    expect(max['body_parts'], 1, reason: 'Zor vücut bölümü yok');
    expect(max['shapes'], 0, reason: 'Orta ve Zor ikişer kelime');
    for (final c in QuizCategory.all) {
      expect(c.maxDifficulty, greaterThanOrEqualTo(0), reason: c.id);
      for (var d = 0; d <= c.maxDifficulty; d++) {
        expect(
          c.itemsAt(d).length,
          greaterThanOrEqualTo(QuizCategory.minItemsPerLevel),
          reason: '${c.id} seviye $d',
        );
      }
    }
  });
}
