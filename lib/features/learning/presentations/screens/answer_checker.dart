class AnswerChecker {
  static String normalize(String s) => s
      .trim()
      .toLowerCase()
      .replaceAll('İ', 'i')
      .replaceAll('I', 'ı')
      .replaceAll('Ğ', 'ğ')
      .replaceAll('Ü', 'ü')
      .replaceAll('Ş', 'ş')
      .replaceAll('Ö', 'ö')
      .replaceAll('Ç', 'ç');

  static int _editDistance(String a, String b) {
    final m = a.length, n = b.length;
    final dp = List.generate(m + 1, (i) => List.filled(n + 1, 0));
    for (var i = 0; i <= m; i++) dp[i][0] = i;
    for (var j = 0; j <= n; j++) dp[0][j] = j;
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

  /// Çocukların eksik/yanlış telaffuzunu tolere eden cevap kontrolü.
  static bool check(String recognized, String expected) {
    final r = normalize(recognized);
    final e = normalize(expected);

    // 1. Tam eşleşme veya kısmi içerme
    if (r == e || r.contains(e) || e.contains(r)) return true;

    // 2. Çok kelimeli ifade → herhangi bir kelime eşleşiyor mu?
    //    ("muhabbet kuşu" için çocuk "kuşu" diyebilir)
    final words = e.split(' ');
    if (words.length > 1) {
      for (final w in words) {
        if (w.length >= 3 && (r.contains(w) || w.contains(r))) return true;
      }
    }

    // 3. Levenshtein toleransı: her 3 harfe 1 hata, min 1, max 3
    final threshold = (e.length / 3).ceil().clamp(1, 3);
    return _editDistance(r, e) <= threshold;
  }
}