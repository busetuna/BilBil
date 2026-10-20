class AnswerChecker {
  /// Kısmi söylenen kelimenin kabul edilmesi için hedefe oranı.
  static const double _minPartialRatio = 0.6;
  static const int _minPartialLength = 3;

  // Dart'ın toLowerCase'i Türkçe'ye duyarlı değil (I→i, İ→i̇),
  // bu yüzden İ/I dönüşümü küçültmeden ÖNCE yapılmalı.
  static String normalize(String s) => s
      .replaceAll('İ', 'i')
      .replaceAll('I', 'ı')
      .toLowerCase()
      .replaceAll(RegExp(r'[^\p{L}\p{N}\s]', unicode: true), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  /// [r] hedefin kendisi mi, hedefi ayrı kelime olarak içeriyor mu, ya da
  /// hedefin yeterince büyük bir parçası mı?
  /// ("bu bir kedi" ✓, "televizyon" ≠ "el", "kap" ≠ "kaplumbağa")
  static bool _matches(String r, String target) {
    if (r == target || ' $r '.contains(' $target ')) return true;
    return target.contains(r) &&
        r.length >= _minPartialLength &&
        r.length >= target.length * _minPartialRatio;
  }

  static int _editDistance(String a, String b) {
    final m = a.length, n = b.length;
    final dp = List.generate(m + 1, (i) => List.filled(n + 1, 0));
    for (var i = 0; i <= m; i++) {
      dp[i][0] = i;
    }
    for (var j = 0; j <= n; j++) {
      dp[0][j] = j;
    }
    for (var i = 1; i <= m; i++) {
      for (var j = 1; j <= n; j++) {
        dp[i][j] = a[i - 1] == b[j - 1]
            ? dp[i - 1][j - 1]
            : 1 + [dp[i - 1][j], dp[i][j - 1], dp[i - 1][j - 1]]
                .reduce((x, y) => x < y ? x : y);
      }
    }
    return dp[m][n];
  }

  /// Ses motorunun alternatif tahminlerinden herhangi biri tutuyor mu?
  static bool checkAny(Iterable<String> candidates, String expected) =>
      candidates.any((c) => check(c, expected));

  /// Çocukların eksik/yanlış telaffuzunu tolere eden cevap kontrolü.
  static bool check(String recognized, String expected) {
    // Vosk kapalı sözlükte tanıyamadığı sesleri "[unk]" diye yazar.
    final r = normalize(recognized.replaceAll('[unk]', ' '));
    final e = normalize(expected);

    // 0. Boş tanıma asla doğru değildir ("x".contains("") her zaman true)
    if (r.isEmpty) return false;

    // 1. Tam eşleşme veya kısmi içerme
    if (_matches(r, e)) return true;

    // 1b. Boşluksuz aynı mı? Vosk sözlüğünde olmayan kelimeleri parçalarla
    //     yazar ("kelebek" → "ke le bek", "denizatı" → "deniz atı").
    if (r.replaceAll(' ', '') == e.replaceAll(' ', '')) return true;

    // 2. Çok kelimeli ifade → herhangi bir kelime eşleşiyor mu?
    //    ("muhabbet kuşu" için çocuk "kuşu" diyebilir)
    final words = e.split(' ');
    if (words.length > 1) {
      for (final w in words) {
        if (w.length >= 3 && _matches(r, w)) return true;
      }
    }

    // 3. Levenshtein toleransı: her 4 harfe 1 hata, min 1, max 3
    //    (4 harfli kelimede 2 hata "dede"yi "kedi" saydırıyordu)
    final threshold = (e.length / 4).ceil().clamp(1, 3);
    return _editDistance(r, e) <= threshold;
  }
}