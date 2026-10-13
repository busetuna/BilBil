import 'package:hive_flutter/hive_flutter.dart';

/// Tam ekran reklamların sıklığı: 2–5 yaştaki çocuğu reklamla boğmamak için.
///
/// Quiz bitişindeki geçiş reklamı ancak çocuk bu oturumda en az
/// [minAnswersForQuizEnd] soru cevapladıysa ve son tam ekran reklamdan (ödüllü
/// dahil) bu yana en az [minGap] geçtiyse gösterilir. Son gösterim zamanı
/// saklanır; uygulamayı kapatıp açmak sınırı sıfırlamaz. AdMob'daki "Quiz sonu"
/// biriminde ayrıca 10 dakikada 1 gösterim sıklık sınırı var.
class AdPacing {
  static const minAnswersForQuizEnd = 5;
  static const minGap = Duration(minutes: 10);
  static const _boxName = 'ads_box';
  static const _lastFullScreenKey = 'last_full_screen';

  final DateTime Function() _now;
  Box? _box;

  AdPacing({DateTime Function()? clock}) : _now = clock ?? DateTime.now;

  Future<void> init() async => _box ??= await Hive.openBox(_boxName);

  /// Quiz bitişinde geçiş reklamı gösterilebilir mi?
  bool canShowQuizEnd(int answersThisSession) {
    final box = _box;
    // Sıklık kaydı okunamıyorsa göstermemek daha güvenli.
    if (box == null || answersThisSession < minAnswersForQuizEnd) return false;
    final last = box.get(_lastFullScreenKey) as int?;
    if (last == null) return true;
    return _now().difference(DateTime.fromMillisecondsSinceEpoch(last)) >=
        minGap;
  }

  /// Herhangi bir tam ekran reklam (ödüllü ya da geçiş) ekrana geldi.
  void markFullScreenShown() =>
      _box?.put(_lastFullScreenKey, _now().millisecondsSinceEpoch);
}
