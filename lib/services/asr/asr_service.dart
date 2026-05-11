abstract class AsrService {
  bool get isReady;

  Future<void> initialize({void Function(double progress)? onProgress});

  void startListening({
    required void Function(String partial) onPartial,
    required void Function(String text) onFinal,
  });

  void stopListening();
}