import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class Reward {
  final String id;
  final String emoji;
  final String imagePath;
  final String badgeLabel;
  final String title;
  final String description;
  final int requiredCorrect;
  final Color color;

  const Reward({
    required this.id,
    required this.emoji,
    required this.imagePath,
    required this.badgeLabel,
    required this.title,
    required this.description,
    required this.requiredCorrect,
    required this.color,
  });
}

class RewardService extends ChangeNotifier {
  static const _boxName = 'rewards_box';
  static const _totalCorrectKey = 'total_correct';
  static const _earnedIdsKey = 'earned_ids';

  late Box _box;
  int _totalCorrect = 0;
  List<String> _earnedIds = [];

  static final List<Reward> allRewards = [
    const Reward(
      id: 'first_correct',
      emoji: '🐱',
      imagePath: 'assets/images/animals/1.png',
      badgeLabel: 'İlk Adım ✨',
      title: 'Sevimli Yavru',
      description: 'Sevimli Yavru rozetini kazandın!',
      requiredCorrect: 1,
      color: Color(0xFFFFC107),
    ),
    const Reward(
      id: 'five_correct',
      emoji: '🦁',
      imagePath: 'assets/images/animals/44.png',
      badgeLabel: 'Çok Havalı ✨',
      title: 'Aslan Kral',
      description: 'Aslan Kral rozetini kazandın!',
      requiredCorrect: 5,
      color: Color(0xFFFF5722),
    ),
    const Reward(
      id: 'ten_correct',
      emoji: '🐘',
      imagePath: 'assets/images/animals/37.png',
      badgeLabel: 'Süper Güçlü 💪',
      title: 'Güçlü Fil',
      description: 'Güçlü Fil rozetini kazandın!',
      requiredCorrect: 10,
      color: Color(0xFF4CAF50),
    ),
    const Reward(
      id: 'twentyfive_correct',
      emoji: '🦒',
      imagePath: 'assets/images/animals/10.png',
      badgeLabel: 'Harika Çocuk 🌟',
      title: 'Uzun Boylu',
      description: 'Uzun Boylu rozetini kazandın!',
      requiredCorrect: 25,
      color: Color(0xFF2196F3),
    ),
    const Reward(
      id: 'fifty_correct',
      emoji: '🐼',
      imagePath: 'assets/images/animals/32.png',
      badgeLabel: 'Efsane 🏆',
      title: 'Panda Ustası',
      description: 'Panda Ustası rozetini kazandın!',
      requiredCorrect: 50,
      color: Color(0xFF9C27B0),
    ),
    const Reward(
      id: 'hundred_correct',
      emoji: '🐬',
      imagePath: 'assets/images/animals/34.png',
      badgeLabel: 'Bilgi Kralı 👑',
      title: 'Yunus Kahramanı',
      description: 'Yunus Kahramanı rozetini kazandın!',
      requiredCorrect: 100,
      color: Color(0xFFE91E63),
    ),
  ];

  int get totalCorrect => _totalCorrect;
  List<String> get earnedIds => List.unmodifiable(_earnedIds);

  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
    _totalCorrect = (_box.get(_totalCorrectKey, defaultValue: 0) as num).toInt();
    final stored = _box.get(_earnedIdsKey, defaultValue: <dynamic>[]);
    _earnedIds = List<String>.from(stored as List);
  }

  bool isEarned(String id) => _earnedIds.contains(id);

  Reward? get nextReward {
    for (final r in allRewards) {
      if (!_earnedIds.contains(r.id)) return r;
    }
    return null;
  }

  Future<List<Reward>> addCorrect() async {
    _totalCorrect++;
    await _box.put(_totalCorrectKey, _totalCorrect);

    final newlyEarned = <Reward>[];
    for (final reward in allRewards) {
      if (!_earnedIds.contains(reward.id) &&
          _totalCorrect >= reward.requiredCorrect) {
        _earnedIds.add(reward.id);
        newlyEarned.add(reward);
      }
    }

    if (newlyEarned.isNotEmpty) {
      await _box.put(_earnedIdsKey, _earnedIds);
    }

    notifyListeners();
    return newlyEarned;
  }
}