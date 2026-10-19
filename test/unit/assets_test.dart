import 'dart:io';

import 'package:app/services/rewards/reward_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('her ödülün puzzle resmi var, kimlikler tekrarsız', () {
    final ids = RewardService.allRewards.map((r) => r.id).toList();
    expect(ids.toSet().length, ids.length);
    for (final r in RewardService.allRewards) {
      expect(File(r.imagePath).existsSync(), isTrue, reason: r.imagePath);
    }
  });

  test('kodda adı geçen her resim dosyası var (yanlış uzantı kalmasın)', () {
    final refs = RegExp(r"'((?:assets/images|bilbil-puzzle)/[^']+\.(?:png|webp))'");
    final missing = <String>[];
    for (final f in Directory('lib').listSync(recursive: true).whereType<File>()) {
      if (!f.path.endsWith('.dart')) continue;
      for (final m in refs.allMatches(f.readAsStringSync())) {
        if (!File(m[1]!).existsSync()) missing.add('${f.path}: ${m[1]}');
      }
    }
    expect(missing, isEmpty);
  });
}
