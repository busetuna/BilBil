// Telefonun kendi ses tanıyıcısı (speech_to_text): Android'de Google'ın
// cihaz üstü tanıyıcısı, iOS'ta Apple'ınki. Ayarlarda "Platform ASR".
// (Önceden adı WhisperAsrService'ti; Whisper ile ilgisi yoktur.)
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';

enum PlatformAsrStatus { idle, initializing, ready, error }

class PlatformAsrService extends ChangeNotifier {
  final _stt = SpeechToText();

  PlatformAsrStatus _status = PlatformAsrStatus.idle;
  String? _errorMessage;

  PlatformAsrStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isReady => _status == PlatformAsrStatus.ready;
  bool get isInitializing => _status == PlatformAsrStatus.initializing;

  Future<void> initialize() async {
    if (_status == PlatformAsrStatus.ready ||
        _status == PlatformAsrStatus.initializing) {
      return;
    }
    _status = PlatformAsrStatus.initializing;
    _errorMessage = null;
    notifyListeners();

    try {
      final available = await _stt.initialize(
        onError: (e) => debugPrint('PlatformAsrService error: ${e.errorMsg}'),
        onStatus: (s) => debugPrint('PlatformAsrService status: $s'),
      );
      _status = available ? PlatformAsrStatus.ready : PlatformAsrStatus.error;
      if (!available) _errorMessage = 'Platform ses tanıma kullanılamıyor';
    } catch (e) {
      _status = PlatformAsrStatus.error;
      _errorMessage = e.toString();
      debugPrint('PlatformAsrService init error: $e');
    }
    notifyListeners();
  }

  void startListening({
    required void Function(String partial) onPartial,
    required void Function(List<String> candidates) onFinal,
  }) {
    if (!isReady) return;

    _stt.listen(
      onResult: (result) {
        if (result.finalResult) {
          // En iyi tahmin önce; biri tutarsa cevap doğru sayılır.
          onFinal([
            for (final alt in result.alternates)
              if (alt.recognizedWords.trim().isNotEmpty) alt.recognizedWords,
          ]);
        } else {
          onPartial(result.recognizedWords);
        }
      },
      localeId: 'tr_TR',
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 3),
      listenOptions: SpeechListenOptions(
        onDevice: true, // ses cihazdan çıkmasın
        partialResults: true,
        listenMode: ListenMode.confirmation, // tek kelimelik cevaplar için
      ),
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
