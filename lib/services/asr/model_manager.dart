import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:path_provider/path_provider.dart';

class ModelManager {
  static const _url =
      'https://alphacephei.com/vosk/models/vosk-model-small-tr-0.15.zip';
  static const _dirName = 'vosk-model-small-tr-0.15';

  static Future<String> ensureModel({void Function(double)? onProgress}) async {
    final appDir = await getApplicationDocumentsDirectory();
    final modelPath = '${appDir.path}/$_dirName';
    if (Directory(modelPath).existsSync()) return modelPath;

    final zipPath = '${appDir.path}/vosk_tr_tmp.zip';
    await _download(_url, zipPath, onProgress);
    _extract(zipPath, appDir.path);
    File(zipPath).deleteSync();
    return modelPath;
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

  static void _extract(String zipPath, String destDir) {
    final input = InputFileStream(zipPath);
    final archive = ZipDecoder().decodeBuffer(input);
    extractArchiveToDisk(archive, destDir);
    input.close();
  }
}