import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:path_provider/path_provider.dart';

class ModelManager {
  static const _url =
      'https://alphacephei.com/vosk/models/vosk-model-small-tr-0.3.zip';
  static const _dirName = 'vosk-model-small-tr-0.3';

  /// İndirilen ZIP'in özeti (36.855.784 bayt, 17 Ekim 2026'da indirildi).
  /// Model yerel kodda (Kaldi) açılır; sunucudaki dosya değişirse ya da
  /// yolda bozulursa açılmadan reddedilir, ses tanıma yedeğe düşer.
  static const _sha256 =
      '8c8d07cec1bce31add14967c16891c84152cdf76d391e33c08278119b9ea96e5';

  static Future<String> ensureModel({void Function(double)? onProgress}) async {
    final appDir = await getApplicationDocumentsDirectory();
    final modelPath = '${appDir.path}/$_dirName';
    if (_isValidModelDir(modelPath)) return modelPath;

    // Önceki başarısız girişimden kalan dizini temizle
    final modelDir = Directory(modelPath);
    if (modelDir.existsSync()) modelDir.deleteSync(recursive: true);

    final zipFile = File('${appDir.path}/vosk_tr_tmp.zip');
    if (zipFile.existsSync()) zipFile.deleteSync();

    await _download(_url, zipFile.path, onProgress);
    if (await sha256OfFile(zipFile.path) != _sha256) {
      zipFile.deleteSync();
      throw Exception('Model dosyası doğrulanamadı (SHA-256 uyuşmuyor)');
    }
    try {
      final extracted = await _extractAndLocate(zipFile.path, appDir.path);
      zipFile.deleteSync();
      // ZIP içindeki klasör adı farklıysa beklenen yere taşı
      if (extracted != modelPath) {
        Directory(extracted).renameSync(modelPath);
      }
    } catch (e) {
      if (zipFile.existsSync()) zipFile.deleteSync();
      if (modelDir.existsSync()) modelDir.deleteSync(recursive: true);
      throw Exception('Model açılamadı: $e');
    }
    return modelPath;
  }

  // Akustik model dosyası varsa geçerli model dizinidir. Yeni modellerde
  // am/final.mdl, vosk-model-small-tr-0.3 gibi eskilerde kökte final.mdl
  // bulunur. Önceden yalnızca am/ ya da conf/ aranıyordu; bu model düz
  // yapıda olduğu için her açılışta silinip 36 MB yeniden indiriliyordu.
  static bool _isValidModelDir(String path) {
    if (!Directory(path).existsSync()) return false;
    return File('$path/final.mdl').existsSync() ||
        File('$path/am/final.mdl').existsSync();
  }

  /// Dosyanın SHA-256 özeti (küçük harf onaltılık); dosyayı parça parça okur.
  @visibleForTesting
  static Future<String> sha256OfFile(String path) async =>
      (await sha256.bind(File(path).openRead()).first).toString();

  // ZIP'i çıkarır, oluşturulan vosk-model* dizinini döner
  static Future<String> _extractAndLocate(
    String zipPath,
    String destDir,
  ) async {
    final before = _voskDirs(destDir);
    final input = InputFileStream(zipPath);
    try {
      final archive = ZipDecoder().decodeBuffer(input);
      await extractArchiveToDisk(archive, destDir);
    } finally {
      input.close();
    }

    final after = _voskDirs(destDir);
    final created = after.where((d) => !before.contains(d)).toList();
    if (created.isEmpty) {
      throw Exception('ZIP çıkarıldı fakat vosk-model* dizini bulunamadı');
    }
    return created.first;
  }

  static List<String> _voskDirs(String parent) {
    return Directory(parent)
        .listSync()
        .whereType<Directory>()
        .where(
          (d) => d.path
              .split(Platform.pathSeparator)
              .last
              .startsWith('vosk-model'),
        )
        .map((d) => d.path)
        .toList();
  }

  static Future<void> _download(
    String url,
    String dest,
    void Function(double)? onProgress,
  ) async {
    final client = HttpClient();
    try {
      final req = await client.getUrl(Uri.parse(url));
      final res = await req.close();
      if (res.statusCode != 200) {
        throw Exception('HTTP ${res.statusCode}');
      }
      final total = res.contentLength;
      int received = 0;
      final sink = File(dest).openWrite();
      await for (final chunk in res) {
        sink.add(chunk);
        received += chunk.length;
        if (total > 0) onProgress?.call(received / total);
      }
      await sink.close();
    } finally {
      client.close();
    }
  }
}
