/// Bir cevabın ödülü: bandit'in çocuğu o seviyeye getiren kararını puanlar.
///
/// Önceki fonksiyon (hızlı+doğru=+1.5, yavaş+doğru=+1.0, çok geç=+0.5,
/// yanlış=-1.0) zorluğa bakmıyordu. Kolay sorular hep daha çok doğru
/// getirdiği için ajan zamanla "zorluk azalt"ı öğreniyordu. Şimdi zor
/// seviyedeki doğru cevap daha değerli: ajan çocuğu, çoğunu bildiği ama
/// sıkılmadığı seviyede tutmaya çalışır.
class RewardCalculator {
  /// Süre, mikrofon açıldıktan çocuk konuşmaya başlayana kadar ölçülür
  /// (tereddüt). Bilbil'in konuşması ve sessizlik beklemesi dahil değildir.
  static const double fastSec = 2.0;
  static const double slowSec = 5.0;

  static const double correct = 1.0;
  static const double fastBonus = 0.5;
  static const double okBonus = 0.25;

  /// Seviye başına doğru cevap primi (Kolay 0, Orta +1, Zor +2).
  /// Bu değerle bir üst seviye, orada başarı ~%75'i geçince daha kârlı
  /// olur (simülasyonla ayarlandı): çocuk ne sıkılır ne de sürekli can kaybeder ("akış" bölgesi).
  static const double challengeBonus = 1.0;

  /// "Bilbil söylesin" ipucuyla doğru: destekli başarı, küçük ödül. Önceden
  /// "çok geç ama doğru" sayılıyordu.
  static const double hinted = 0.25;

  static const double wrong = -1.0;

  static double calculate({
    required bool isCorrect,
    required double responseTimeSec,
    int difficulty = 0,
    bool hintUsed = false,
  }) {
    if (!isCorrect) return wrong;
    if (hintUsed) return hinted;
    final speed = responseTimeSec <= fastSec
        ? fastBonus
        : responseTimeSec <= slowSec
        ? okBonus
        : 0.0;
    return correct + speed + challengeBonus * difficulty;
  }
}
