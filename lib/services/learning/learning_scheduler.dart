import 'dart:math';

/// Hangi sorunun ne sıklıkla geleceği (aralıklı tekrar).
class LearningScheduler {
  /// Leitner kutusuna göre ağırlık: zorlanılan kelime (0) en sık, iyi
  /// bilinen (4) en seyrek; hiç sorulmamış (null) kelimeler de öne çıkar.
  static double weightOf(int? box) => switch (box) {
    null => 3.0,
    0 => 4.0,
    1 => 2.5,
    2 => 1.5,
    3 => 0.8,
    _ => 0.4,
  };

  /// Ağırlıklı karıştırma (Efraimidis–Spirakis): ağırlığı büyük olan öğe
  /// sıranın başına gelme olasılığı daha yüksek, ama hepsi yine sırada.
  static List<T> order<T>(
    List<T> items,
    double Function(T) weight,
    Random rng,
  ) {
    final keyed = [
      for (final item in items) (item, pow(rng.nextDouble(), 1 / weight(item))),
    ]..sort((a, b) => b.$2.compareTo(a.$2));
    return [for (final k in keyed) k.$1];
  }
}

/// Oturum içi tekrar: bilinemeyen soru [delay] soru sonra yeniden sorulur.
/// Çocuk bunalmasın diye aynı soru bir oturumda en fazla [maxPerItem] kez
/// tekrarlanır.
class ReviewQueue<T> {
  static const delay = 3;
  static const maxPerItem = 2;

  final _due = <(T, int)>[];
  final _counts = <T, int>{};

  bool get isEmpty => _due.isEmpty;

  /// [questionNumber]: bilinemeyen sorunun sıra numarası.
  void scheduleAfterMiss(T item, int questionNumber) {
    final count = _counts[item] ?? 0;
    if (count >= maxPerItem) return;
    _counts[item] = count + 1;
    _due
      ..removeWhere((d) => d.$1 == item)
      ..add((item, questionNumber + delay));
  }

  /// [questionNumber]'da sorulma vakti gelmiş ilk soru ([exclude] hariç).
  T? takeDue(int questionNumber, {T? exclude}) {
    final i = _due.indexWhere((d) => d.$2 <= questionNumber && d.$1 != exclude);
    if (i < 0) return null;
    return _due.removeAt(i).$1;
  }
}
