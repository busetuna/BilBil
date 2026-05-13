import 'dart:math' as math;
import 'dart:typed_data';

/// Enerji tabanlı Ses Aktivite Tespiti (Voice Activity Detection).
/// PCM-16 audio chunk'ını analiz ederek konuşma içerip içermediğini belirler.
class VadDetector {
  /// Varsayılan RMS enerji eşiği (0–1 arası, normalize edilmiş).
  static const double defaultThreshold = 0.015;

  /// Sıfır geçiş oranı eşiği (sessiz gürültüyü konuşmadan ayırt etmek için).
  static const double defaultZcrThreshold = 0.1;

  // ── Yardımcı dönüşüm ─────────────────────────────────────────────────────

  static List<double> _pcmToDoubles(Uint8List bytes) {
    final out = <double>[];
    for (int i = 0; i + 1 < bytes.length; i += 2) {
      int raw = bytes[i] | (bytes[i + 1] << 8);
      if (raw > 32767) raw -= 65536;
      out.add(raw / 32768.0);
    }
    return out;
  }

  // ── Temel metrikler ────────────────────────────────────────────────────────

  /// RMS (Root Mean Square) enerji. Konuşmanın genel gücünü ölçer.
  static double rmsEnergy(Uint8List pcmBytes) {
    final s = _pcmToDoubles(pcmBytes);
    if (s.isEmpty) return 0.0;
    double sum = 0.0;
    for (final v in s) sum += v * v;
    return math.sqrt(sum / s.length);
  }

  /// Sıfır geçiş oranı (Zero-Crossing Rate). Yüksek değer → gürültü/fricative.
  static double zeroCrossingRate(Uint8List pcmBytes) {
    final s = _pcmToDoubles(pcmBytes);
    if (s.length < 2) return 0.0;
    int crossings = 0;
    for (int i = 1; i < s.length; i++) {
      if ((s[i] >= 0) != (s[i - 1] >= 0)) crossings++;
    }
    return crossings / (s.length - 1).toDouble();
  }

  // ── Ana karar ─────────────────────────────────────────────────────────────

  /// Chunk'ta konuşma var mı?
  /// Hem RMS hem ZCR birleşik kararla daha güvenilir sonuç verir.
  static bool hasSpeech(
    Uint8List pcmBytes, {
    double energyThreshold = defaultThreshold,
    double zcrThreshold = defaultZcrThreshold,
  }) {
    final energy = rmsEnergy(pcmBytes);
    if (energy < energyThreshold) return false; // sessiz
    // Çok yüksek ZCR + düşük enerji → ortam gürültüsü (tıslama vb.)
    final zcr = zeroCrossingRate(pcmBytes);
    if (energy < energyThreshold * 2 && zcr > 0.4) return false;
    return true;
  }

  /// Adaptif eşik için: birden fazla sessiz chunk'tan gürültü enerjisi öğren.
  static double estimateNoiseEnergy(List<Uint8List> silenceChunks) {
    if (silenceChunks.isEmpty) return defaultThreshold;
    final energies = silenceChunks.map(rmsEnergy).toList()..sort();
    // Medyan tabanlı tahmin (aşırı değerlere karşı dayanıklı)
    return energies[energies.length ~/ 2] * 1.5;
  }
}