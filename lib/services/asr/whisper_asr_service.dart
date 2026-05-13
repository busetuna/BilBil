// Platform-native ASR servisi.
// Raporda belirtilen Whisper-tiny/Vosk seçeneğinin platform karşılığıdır.
// Android'de Google'ın on-device sinir ağı tabanlı ses tanımayı,
// iOS'ta Apple'ın yerleşik ASR'ını kullanır.
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';

enum PlatformAsrStatus { idle, initializing, ready, error }

class WhisperAsrService extends ChangeNotifier {
  final _stt = SpeechToText();

  PlatformAsrStatus _status = PlatformAsrStatus.idle;
  String? _errorMessage;

  PlatformAsrStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isReady => _status == PlatformAsrStatus.ready;
  bool get isInitializing => _status == PlatformAsrStatus.initializing;

  Future<void> initialize() async {
    if (_status == PlatformAsrStatus.ready ||
        _status == PlatformAsrStatus.initializing) return;
    _status = PlatformAsrStatus.initializing;
    _errorMessage = null;
    notifyListeners();

    try {
      final available = await _stt.initialize(
        onError: (e) => debugPrint('WhisperAsrService error: ${e.errorMsg}'),
        onStatus: (s) => debugPrint('WhisperAsrService status: $s'),
      );
      _status = available ? PlatformAsrStatus.ready : PlatformAsrStatus.error;
      if (!available) _errorMessage = 'Platform ses tanıma kullanılamıyor';
    } catch (e) {
      _status = PlatformAsrStatus.error;
      _errorMessage = e.toString();
      debugPrint('WhisperAsrService init error: $e');
    }
    notifyListeners();
  }

  void startListening({
    required void Function(String partial) onPartial,
    required void Function(String text) onFinal,
  }) {
    if (!isReady) return;

    _stt.listen(
      onResult: (result) {
        if (result.finalResult) {
          onFinal(result.recognizedWords);
        } else {
          onPartial(result.recognizedWords);
        }
      },
      localeId: 'tr_TR',
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 3),
      onDevice: true, // cihaz üzeri tanımayı tercih et
    );
  }

  void stopListening() {
    _stt.stop();
  }

  @override
  void dispose() {
    _stt.cancel();
    super.dispose();
  }
}