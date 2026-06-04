import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:path_provider/path_provider.dart';

class ModelManager {
  static const _url =
      'https://alphacephei.com/vosk/models/vosk-model-small-tr-0.3.zip';
  static const _dirName = 'vosk-model-small-tr-0.3';

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

  // am/ veya conf/ alt dizini varsa geçerli model dizinidir
  static bool _isValidModelDir(String path) {
    if (!Directory(path).existsSync()) return false;
    return Directory('$path/am').existsSync() ||
        Directory('$path/conf').existsSync();
  }

  // ZIP'i çıkarır, oluşturulan vosk-model* dizinini döner
  static Future<String> _extractAndLocate(String zipPath, String destDir) async {
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
        .where((d) => d.path.split(Platform.pathSeparator).last.startsWith('vosk-model'))
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