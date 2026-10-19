import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../features/learning/presentations/screens/answer_checker.dart';
import '../api/api_service.dart';

/// Bir kelimenin öğrenme durumu. [box] Leitner kutusudur: 0 = zorlanıyor,
/// [WordProgressService.maxBox] = iyi biliyor.
@immutable
class WordState {
  final String word; // ekranda gösterilen biçim ("Muhabbet kuşu")
  final int box;
  final int seen;
  final int wrong;
  final int last; // son görülme, epoch ms

  const WordState({
    required this.word,
    required this.box,
    required this.seen,
    required this.wrong,
    required this.last,
  });

  Map<String, Object> toJson() => {
    'word': word,
    'box': box,
    'seen': seen,
    'wrong': wrong,
    'last': last,
  };

  static WordState? fromJson(Object? raw) {
    if (raw is! Map) return null;
    int n(Object? v) => (v as num?)?.toInt() ?? 0;
    final word = raw['word'];
    if (word is! String) return null;
    return WordState(
      word: word,
      box: n(raw['box']).clamp(0, WordProgressService.maxBox),
      seen: n(raw['seen']),
      wrong: n(raw['wrong']),
      last: n(raw['last']),
    );
  }
}

/// Kelime başına öğrenme durumu (aralıklı tekrar).
///
/// Doğru cevap kelimeyi bir üst kutuya çıkarır, yanlış cevap 0'a indirir.
/// Quiz soruları kutuya göre ağırlıklı seçilir (bkz. LearningScheduler):
/// zorlanılan kelimeler daha sık, iyi bilinenler daha seyrek gelir.
class WordProgressService extends ChangeNotifier {
  static const maxBox = 4;
  static const _boxName = 'word_progress';

  late Box _box;
  ApiService? _api;
  final DateTime Function() _now;

  WordProgressService({DateTime Function()? clock})
    : _now = clock ?? DateTime.now;

  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
  }

  void setCloudSync(ApiService api) => _api = api;

  void clearCloudSync() => _api = null;

  static String keyOf(String word) => AnswerChecker.normalize(word);

  WordState? stateOf(String word) => WordState.fromJson(_box.get(keyOf(word)));

  /// Hiç sorulmamışsa null.
  int? boxOf(String word) => stateOf(word)?.box;

  /// [hinted]: çocuk Bilbil'in ipucundan sonra doğru söyledi. Kelime
  /// "biliniyor" sayılmaz: kutusu yükselmez (ama düşmez de).
  void record(String word, {required bool correct, bool hinted = false}) {
    final old = stateOf(word);
    final int box;
    if (!correct) {
      box = 0;
    } else if (hinted) {
      box = old?.box ?? 0;
    } else {
      box = ((old?.box ?? -1) + 1).clamp(0, maxBox);
    }
    final state = WordState(
      word: old?.word ?? word,
      box: box,
      seen: (old?.seen ?? 0) + 1,
      wrong: (old?.wrong ?? 0) + (correct ? 0 : 1),
      last: _now().millisecondsSinceEpoch,
    );
    _box.put(keyOf(word), state.toJson());
    _syncToCloud();
    notifyListeners();
  }

  /// Ebeveyn paneli için: yanlış yapılmış ve henüz oturmamış kelimeler,
  /// en çok zorlanılandan başlayarak.
  /// [onlyWords]: yalnızca bu kelimeler (normalize edilmiş) — quiz'den
  /// çıkarılmış eski kelimeler listede görünmesin.
  List<WordState> struggling({int limit = 8, Set<String>? onlyWords}) {
    final states =
        _box.values
            .map(WordState.fromJson)
            .whereType<WordState>()
            .where((s) => s.wrong > 0 && s.box <= 1)
            .where(
              (s) => onlyWords == null || onlyWords.contains(keyOf(s.word)),
            )
            .toList()
          ..sort((a, b) {
            final byWrong = b.wrong.compareTo(a.wrong);
            return byWrong != 0 ? byWrong : b.last.compareTo(a.last);
          });
    return states.take(limit).toList();
  }

  Map<String, Map<String, Object>> toJsonMap() => {
    for (final key in _box.keys)
      if (WordState.fromJson(_box.get(key)) case final s?)
        key as String: s.toJson(),
  };

  void _syncToCloud() => _api?.saveWordProgress(toJsonMap());

  Future<void> loadFromCloud(Map<String, dynamic>? words) async {
    if (words == null) return;
    await _box.clear();
    for (final entry in words.entries) {
      final state = WordState.fromJson(entry.value);
      if (state != null) await _box.put(entry.key, state.toJson());
    }
    notifyListeners();
  }

  /// Hesap değişince ya da silinince: bu hesabın kelime geçmişi silinir.
  Future<void> clearAccountData() async {
    await _box.clear();
    notifyListeners();
  }
}
