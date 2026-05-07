/// Bandit kolunu zorluk seviyesi değişimine çevirir.
/// Kol 0 → zorluk azalt, Kol 1 → aynı kal, Kol 2 → zorluk artır
class ActionSelector {
  static int adjustDifficulty(int current, int arm) {
    switch (arm) {
      case 0:
        return (current - 1).clamp(0, 2);
      case 2:
        return (current + 1).clamp(0, 2);
      default:
        return current;
    }
  }
}