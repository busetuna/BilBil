import 'dart:math';

/// Bağlamsal ε-greedy bandit: her zorluk seviyesi (durum) için ayrı 3 kol.
/// Kol 0 → zorluk azalt, Kol 1 → aynı kal, Kol 2 → zorluk artır
///
/// Önceden tek bir Q listesi vardı: "Kolay'dan zorlaştır" ile "Orta'dan
/// zorlaştır" aynı değeri paylaşıyor, en kolayda "azalt" kolu da "aynı kal"
/// gibi ödül topluyordu. Şimdi her seviyenin kendi Q satırı var ve geçersiz
/// kollar (en kolayda azalt, yaş sınırında artır) hiç seçilmez.
class EpsilonGreedyBandit {
  static const arms = 3;
  static const stay = 1;

  final int states;

  /// Başlangıç keşif oranı. Bir seviyede deneyim biriktikçe [minEpsilon]'a
  /// iner: çocuk sonsuza dek rastgele zorluk sıçramaları yaşamasın.
  final double epsilon;
  final double minEpsilon;

  final List<List<double>> _q;
  final List<List<int>> _n;
  final Random _rng;

  EpsilonGreedyBandit({
    this.states = 3,
    this.epsilon = 0.2,
    this.minEpsilon = 0.05,
    Random? rng,
  }) : _q = List.generate(states, (_) => List.filled(arms, 0.0)),
       _n = List.generate(states, (_) => List.filled(arms, 0)),
       _rng = rng ?? Random();

  int visits(int state) => _n[state].fold(0, (a, b) => a + b);

  double epsilonFor(int state) =>
      max(minEpsilon, epsilon * 10 / (10 + visits(state)));

  /// [allowed] boş olamaz. Eşitlikte "aynı kal" tercih edilir; önceden
  /// hepsi 0 iken ilk kol (azalt) seçiliyordu.
  int selectArm(int state, {required List<int> allowed}) {
    assert(allowed.isNotEmpty);
    if (_rng.nextDouble() < epsilonFor(state)) {
      return allowed[_rng.nextInt(allowed.length)]; // keşif
    }
    // sömürü: en yüksek Q değerli kol
    var bestArm = allowed.contains(stay) ? stay : allowed.first;
    for (final arm in allowed) {
      if (_q[state][arm] > _q[state][bestArm]) bestArm = arm;
    }
    return bestArm;
  }

  /// Q-değerini güncelle: ilk denemelerde artımlı ortalama, sonra sabit
  /// adım. Çocuk geliştikçe eski deneyimler unutulsun; düz ortalamada
  /// aylar önceki yanlışlar "zorlaştır"ı sonsuza dek kötü gösterirdi.
  static const minStep = 0.1;

  void update(int state, int arm, double reward) {
    _n[state][arm]++;
    final step = max(1 / _n[state][arm], minStep);
    _q[state][arm] += (reward - _q[state][arm]) * step;
  }

  /// Bu kararın sonucu en az [minTries] kez görüldü mü?
  bool knows(int state, int arm, {int minTries = 3}) =>
      _n[state][arm] >= minTries;

  double valueOf(int state, int arm) => _q[state][arm];

  List<List<double>> get qValues =>
      List.unmodifiable(_q.map((row) => List<double>.unmodifiable(row)));
  List<List<int>> get counts =>
      List.unmodifiable(_n.map((row) => List<int>.unmodifiable(row)));

  Map<String, dynamic> toJson() => {
    'q': [for (final row in _q) List<double>.of(row)],
    'n': [for (final row in _n) List<int>.of(row)],
  };

  /// Kayıtlı öğrenmeyi geri yükler. Biçim bozuksa (eski sürüm, elle
  /// düzenlenmiş veri) sessizce sıfırdan başlanır.
  void load(Map<String, dynamic>? json) {
    final q = json?['q'], n = json?['n'];
    if (q is! List || n is! List || q.length != states || n.length != states) {
      return;
    }
    for (var s = 0; s < states; s++) {
      final qs = q[s], ns = n[s];
      if (qs is! List || ns is! List) return;
      if (qs.length != arms || ns.length != arms) return;
      if (qs.any((v) => v is! num) || ns.any((v) => v is! num)) return;
    }
    for (var s = 0; s < states; s++) {
      for (var a = 0; a < arms; a++) {
        _q[s][a] = ((q[s] as List)[a] as num).toDouble();
        _n[s][a] = max(0, ((n[s] as List)[a] as num).toInt());
      }
    }
  }
}
