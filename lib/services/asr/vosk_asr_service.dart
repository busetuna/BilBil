import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:vosk_flutter/vosk_flutter.dart';
import 'model_manager.dart';

enum AsrModelStatus { idle, downloading, ready, error }

class VoskAsrService extends ChangeNotifier {
  final _recorder = AudioRecorder();
  Model? _model;
  Recognizer? _recognizer;
  StreamSubscription<Uint8List>? _sub;

  AsrModelStatus _status = AsrModelStatus.idle;
  double _downloadProgress = 0;
  String? _errorMessage;

  AsrModelStatus get status => _status;
  double get downloadProgress => _downloadProgress;
  String? get errorMessage => _errorMessage;
  bool get isReady => _status == AsrModelStatus.ready;
  bool get isDownloading => _status == AsrModelStatus.downloading;

  Future<void> initialize() async {
    if (_status == AsrModelStatus.ready || _status == AsrModelStatus.downloading) return;
    _status = AsrModelStatus.downloading;
    _downloadProgress = 0;
    _errorMessage = null;
    notifyListeners();

    try {
      final modelPath = await ModelManager.ensureModel(
        onProgress: (p) {
          _downloadProgress = p;
          notifyListeners();
        },
      );
      final vosk = VoskFlutterPlugin.instance();
      _model = await vosk.createModel(modelPath);
      _recognizer = await vosk.createRecognizer(model: _model!, sampleRate: 16000);
      _status = AsrModelStatus.ready;
    } catch (e) {
      _status = AsrModelStatus.error;
      _errorMessage = e.toString();
      debugPrint('VoskAsrService init error: $e');
    }
    notifyListeners();
  }

  void startListening({
    required void Function(String partial) onPartial,
    required void Function(String text) onFinal,
  }) async {
    if (!isReady || _recognizer == null) return;
    _recognizer!.reset();

    final stream = await _recorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
      ),
    );

    _sub = stream.listen(
      (chunk) async {
        final accepted = await _recognizer!.acceptWaveformBytes(chunk);
        if (accepted) {
          final text = _parseText(await _recognizer!.getResult());
          if (text.isNotEmpty) onFinal(text);
        } else {
          final text = _parsePartial(await _recognizer!.getPartialResult());
          if (text.isNotEmpty) onPartial(text);
        }
      },
      onError: (e) => debugPrint('VoskAsrService stream error: $e'),
    );
  }

  void stopListening() {
    _sub?.cancel();
    _sub = null;
    _recorder.stop();
    _recognizer?.reset();
  }

  String _parseText(String json) {
    try {
      return (jsonDecode(json) as Map)['text'] as String? ?? '';
    } catch (_) {
      return '';
    }
  }

  String _parsePartial(String json) {
    try {
      return (jsonDecode(json) as Map)['partial'] as String? ?? '';
    } catch (_) {
      return '';
    }
  }

  @override
  void dispose() {
    stopListening();
    _recorder.dispose();
    _recognizer?.dispose();
    _model?.dispose();
    super.dispose();
  }
}