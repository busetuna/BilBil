import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class Reward {
  final String id;
  final String emoji;
  final String imagePath;
  final String badgeLabel;
  final String title;
  final String description;
  final Color color;

  const Reward({
    required this.id,
    required this.emoji,
    required this.imagePath,
    required this.badgeLabel,
    required this.title,
    required this.description,
    required this.color,
  });
}

class RewardService extends ChangeNotifier {
  static const _boxName = 'rewards_box';
  static const _totalCorrectKey = 'total_correct';
  static const _earnedIdsKey = 'earned_ids';
  static const _puzzlePiecesKey = 'puzzle_pieces';

  // Her ödül için 3×3 yapboz
  static const int puzzlePieceCount = 9;

  late Box _box;
  int _totalCorrect = 0;
  List<String> _earnedIds = [];
  Map<String, int> _puzzlePieces = {}; // rewardId -> kazanılan parça sayısı

  static final List<Reward> allRewards = [
    const Reward(
      id: 'first_correct',
      emoji: '🐣',
      imagePath: 'bilbil-puzzle/Gemini_Generated_Image_mw6k4bmw6k4bmw6k.png',
      badgeLabel: 'İlk Adım ✨',
      title: 'Bilbil',
      description: 'Bilbil rozetini kazandın!',
      color: Color(0xFFFFC107),
    ),
    const Reward(
      id: 'five_correct',
      emoji: '👑',
      imagePath: 'bilbil-puzzle/kral.png',
      badgeLabel: 'Kral Bilbil 👑',
      title: 'Kral Bilbil',
      description: 'Kral Bilbil rozetini kazandın!',
      color: Color(0xFFFF5722),
    ),
    const Reward(
      id: 'ten_correct',
      emoji: '🧙',
      imagePath: 'bilbil-puzzle/büyücü.png',
      badgeLabel: 'Büyücü Bilbil 🧙',
      title: 'Büyücü Bilbil',
      description: 'Büyücü Bilbil rozetini kazandın!',
      color: Color(0xFF4CAF50),
    ),
    const Reward(
      id: 'twentyfive_correct',
      emoji: '🎨',
      imagePath: 'bilbil-puzzle/ressam.png',
      badgeLabel: 'Ressam Bilbil 🎨',
      title: 'Ressam Bilbil',
      description: 'Ressam Bilbil rozetini kazandın!',
      color: Color(0xFF2196F3),
    ),
    const Reward(
      id: 'fifty_correct',
      emoji: '🦸',
      imagePath: 'bilbil-puzzle/süperman.png',
      badgeLabel: 'Süper Bilbil 🦸',
      title: 'Süper Bilbil',
      description: 'Süper Bilbil rozetini kazandın!',
      color: Color(0xFF9C27B0),
    ),
    const Reward(
      id: 'hundred_correct',
      emoji: '🎤',
      imagePath: 'bilbil-puzzle/şarkıcı.png',
      badgeLabel: 'Şarkıcı Bilbil 🎤',
      title: 'Şarkıcı Bilbil',
      description: 'Şarkıcı Bilbil rozetini kazandın!',
      color: Color(0xFFE91E63),
    ),
  ];

  int get totalCorrect => _totalCorrect;
  List<String> get earnedIds => List.unmodifiable(_earnedIds);

  /// Şu an üzerinde çalışılan yapboz (kazanılmamış ilk ödül)
  Reward? get activeReward {
    for (final r in allRewards) {
      if (!_earnedIds.contains(r.id)) return r;
    }
    return null;
  }

  /// Geriye dönük uyumluluk için
  Reward? get nextReward => activeReward;

  /// Bir ödül için kazanılan parça sayısı
  int puzzlePiecesFor(String rewardId) =>
      (_puzzlePieces[rewardId] ?? 0).clamp(0, puzzlePieceCount);

  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
    _totalCorrect = (_box.get(_totalCorrectKey, defaultValue: 0) as num).toInt();
    final stored = _box.get(_earnedIdsKey, defaultValue: <dynamic>[]);
    _earnedIds = List<String>.from(stored as List);
    final raw = _box.get(_puzzlePiecesKey, defaultValue: <dynamic, dynamic>{});
    _puzzlePieces = Map<String, int>.from(
      (raw as Map).map((k, v) => MapEntry(k.toString(), (v as num).toInt())),
    );
  }

  bool isEarned(String id) => _earnedIds.contains(id);

  Future<List<Reward>> addCorrect() async {
    _totalCorrect++;
    await _box.put(_totalCorrectKey, _totalCorrect);

    final active = activeReward;
    if (active == null) {
      notifyListeners();
      return [];
    }

    // Aktif yapboza bir parça ekle
    final pieces = puzzlePiecesFor(active.id) + 1;
    _puzzlePieces[active.id] = pieces;
    await _box.put(
        _puzzlePiecesKey, _puzzlePieces.map((k, v) => MapEntry(k, v)));

    final newlyEarned = <Reward>[];
    if (pieces >= puzzlePieceCount && !_earnedIds.contains(active.id)) {
      _earnedIds.add(active.id);
      await _box.put(_earnedIdsKey, _earnedIds);
      newlyEarned.add(active);
    }

    notifyListeners();
    return newlyEarned;
  }

  Future<void> resetRewards() async {
    _totalCorrect = 0;
    _earnedIds = [];
    _puzzlePieces = {};
    await _box.put(_totalCorrectKey, 0);
    await _box.put(_earnedIdsKey, <String>[]);
    await _box.put(_puzzlePiecesKey, <String, int>{});
    notifyListeners();
  }
}