import 'dart:io';

import 'package:app/services/asr/model_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('bilbil_model_test');
  });

  tearDown(() async {
    await dir.delete(recursive: true);
  });

  test('SHA-256 özeti dosya içeriğinden hesaplanır', () async {
    final file = File('${dir.path}/abc.txt')..writeAsStringSync('abc');
    expect(
      await ModelManager.sha256OfFile(file.path),
      'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
    );
  });

  test('tek bayt değişince özet değişir (bozuk indirme reddedilir)', () async {
    final a = File('${dir.path}/a.bin')..writeAsBytesSync(List.filled(70000, 7));
    final b = File('${dir.path}/b.bin')
      ..writeAsBytesSync(List.filled(70000, 7)..[69999] = 8);
    expect(
      await ModelManager.sha256OfFile(a.path),
      isNot(await ModelManager.sha256OfFile(b.path)),
    );
  });
}
