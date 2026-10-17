import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:vosk_flutter/vosk_flutter.dart';
import 'model_manager.dart';
import 'audio_proprocessing/vad_detector.dart';

enum AsrModelStatus { idle, downloading, ready, error }

class VoskAsrService extends ChangeNotifier {
  // İlk dinlemede oluşturulur (oluşturmak mikrofon eklentisini başlatır).
  late final _recorder = AudioRecorder();
  Model? _model;
  Recognizer? _recognizer;
  StreamSubscription<Uint8List>? _sub;

  // Vosk çağrıları sırayla yapılır; eşzamanlı parçalar sonuçları karıştırır.
  Future<void> _pending = Future.value();
  // false iken ses yine işlenir ama onPartial/onFinal çağrılmaz.
  bool _emit = false;

  AsrModelStatus _status = AsrModelStatus.idle;
  double _downloadProgress = 0;
  String? _errorMessage;

  AsrModelStatus get status => _status;
  double get downloadProgress => _downloadProgress;
  String? get errorMessage => _errorMessage;
  bool get isReady => _status == AsrModelStatus.ready;
  bool get isDownloading => _status == AsrModelStatus.downloading;

  Future<void> initialize() async {
    if (_status == AsrModelStatus.ready ||
        _status == AsrModelStatus.downloading)
      return;
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
      _recognizer = await vosk.createRecognizer(
        model: _model!,
        sampleRate: 16000,
      );
      // Tek tahmin yerine en iyi birkaç tahmin: biri tutarsa cevap doğru sayılır.
      await _recognizer!.setMaxAlternatives(maxAlternatives);
      _status = AsrModelStatus.ready;
    } catch (e) {
      _status = AsrModelStatus.error;
      _errorMessage = e.toString();
      debugPrint('VoskAsrService init error: $e');
    }
    notifyListeners();
  }

  static const maxAlternatives = 3;

  // Şu an yüklü kapalı sözlük (JSON); aynıysa yeniden derlenmez.
  String _grammarKey = '';

  /// [onFinal] en iyiden başlayarak tahminleri alır.
  /// [grammar]: verilirse Vosk yalnızca bu ifadeleri (ve "[unk]") tanır;
  /// null ise tam sözlük kullanılır (bkz. QuizGrammar).
  /// [onSpeech]: parçada konuşma enerjisi varsa çağrılır (henüz kelime
  /// çıkmasa bile çocuğun konuştuğunu bildirir).
  void startListening({
    required void Function(String partial) onPartial,
    required void Function(List<String> candidates) onFinal,
    void Function()? onSpeech,
    List<String>? grammar,
  }) async {
    final recognizer = _recognizer;
    if (!isReady || recognizer == null) return;
    final key = grammar == null ? '' : jsonEncode(grammar);
    if (key != _grammarKey) {
      _grammarKey = key;
      // "[]" tam sözlüğe döner.
      _enqueue(() => recognizer.setGrammar(grammar ?? const []));
    }
    _enqueue(recognizer.reset);
    _emit = true;

    final stream = await _recorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
        // Küçük çocukların kısık sesini yükselt, ortam gürültüsünü bastır.
        autoGain: true,
        noiseSuppress: true,
        androidConfig: AndroidRecordConfig(
          audioSource: AndroidAudioSource.voiceRecognition,
        ),
      ),
    );

    _sub = stream.listen((chunk) {
      // Sessiz parçalar da Vosk'a gider: konuşmanın bittiğini sondaki
      // sessizlikten anlar. Enerji eşiğiyle elemek ayrıca kısık çocuk sesini
      // ve s/ş/f/z gibi sürtünmeli sesleri kesiyordu.
      if (onSpeech != null && VadDetector.hasSpeech(chunk)) onSpeech();
      _enqueue(() => _process(recognizer, chunk, onPartial, onFinal));
    }, onError: (e) => debugPrint('VoskAsrService stream error: $e'));
  }

  /// İşi kuyruğa ekler; biri hata verse de sonrakiler çalışmaya devam eder.
  void _enqueue(Future<void> Function() job) {
    _pending = _pending.then((_) => job()).catchError((Object e) {
      debugPrint('VoskAsrService: $e');
    });
  }

  Future<void> _process(
    Recognizer recognizer,
    Uint8List chunk,
    void Function(String) onPartial,
    void Function(List<String>) onFinal,
  ) async {
    final accepted = await recognizer.acceptWaveformBytes(chunk);
    if (accepted) {
      final candidates = parseFinal(await recognizer.getResult());
      if (candidates.isEmpty) return;
      if (_emit) {
        onFinal(candidates);
      } else {
        // finishListening sırasında tamamlanan cümle
        _heardWhileFinishing = candidates;
      }
    } else if (_emit) {
      final text = parsePartial(await recognizer.getPartialResult());
      if (text.isNotEmpty && _emit) onPartial(text);
    }
  }

  List<String> _heardWhileFinishing = const [];

  /// Dinlemeyi keser; duyulanı atar.
  void stopListening() {
    _emit = false;
    _sub?.cancel();
    _sub = null;
    _recorder.stop();
    final recognizer = _recognizer;
    if (recognizer != null) _enqueue(recognizer.reset);
  }

  /// Dinlemeyi bitirir ve kalan sesi de işleyip o ana kadar duyulan
  /// tahminleri döner (hiçbir şey duyulmadıysa boş). Callback'ler artık
  /// çağrılmaz.
  Future<List<String>> finishListening() async {
    final recognizer = _recognizer;
    _emit = false;
    _heardWhileFinishing = const [];
    await _sub?.cancel();
    _sub = null;
    await _recorder.stop();
    if (recognizer == null) return const [];
    var candidates = const <String>[];
    _enqueue(() async {
      candidates = parseFinal(await recognizer.getFinalResult());
      await recognizer.reset();
    });
    await _pending;
    return candidates.isNotEmpty ? candidates : _heardWhileFinishing;
  }

  /// Vosk sonucundaki tahminler, en iyisi önce. Alternatif açıkken sonuç
  /// `{"alternatives": [{"text": ..}, ..]}`, değilken `{"text": ..}` olur.
  /// Kapalı sözlükte tanınamayan sesler "[unk]" diye yazılır; atılır.
  @visibleForTesting
  static List<String> parseFinal(String json) {
    try {
      final map = jsonDecode(json) as Map;
      final raw = map['alternatives'] is List
          ? [for (final a in map['alternatives'] as List) (a as Map)['text']]
          : [map['text']];
      final out = <String>[];
      for (final t in raw.whereType<String>()) {
        final clean = t
            .split(' ')
            .where((w) => w.isNotEmpty && w != '[unk]')
            .join(' ');
        if (clean.isNotEmpty && !out.contains(clean)) out.add(clean);
      }
      return out;
    } catch (_) {
      return const [];
    }
  }

  @visibleForTesting
  static String parsePartial(String json) {
    try {
      // Kapalı gramerde tanınmayan ses "[unk]" gelir; ekranda görünmesin.
      final text = (jsonDecode(json) as Map)['partial'] as String? ?? '';
      return text
          .replaceAll('[unk]', ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
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
