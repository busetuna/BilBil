import 'dart:math' as math;
import 'dart:typed_data';

/// Spektral çıkarma (Spectral Subtraction) tabanlı gürültü azaltma.
/// Tahmini gürültü spektrumunu sinyal spektrumundan çıkararak gürültüyü azaltır.
class NoiseReduction {
  final List<double> _noiseSpectrum; // tahmin edilen gürültü güç spektrumu
  final double _overSubFactor;       // aşırı çıkarma faktörü (β) — tipik: 1.0–2.5
  final double _spectralFloor;       // sıfırın altına inmeyi önleyen taban (α)

  static const int _nfft = 256;

  NoiseReduction({
    required List<double> noiseSpectrum,
    double overSubFactor = 1.5,
    double spectralFloor = 0.002,
  })  : _noiseSpectrum = noiseSpectrum,
        _overSubFactor = overSubFactor,
        _spectralFloor = spectralFloor;

  // ── DFT yardımcıları ──────────────────────────────────────────────────────

  static (List<double>, List<double>) _dft(List<double> signal) {
    final n = signal.length;
    final re = List<double>.filled(n, 0.0);
    final im = List<double>.filled(n, 0.0);
    for (int k = 0; k < n; k++) {
      for (int t = 0; t < n; t++) {
        final angle = -2 * math.pi * k * t / n;
        re[k] += signal[t] * math.cos(angle);
        im[k] += signal[t] * math.sin(angle);
      }
    }
    return (re, im);
  }

  static List<double> _idft(List<double> re, List<double> im) {
    final n = re.length;
    return List.generate(n, (t) {
      double val = 0.0;
      for (int k = 0; k < n; k++) {
        final angle = 2 * math.pi * k * t / n;
        val += re[k] * math.cos(angle) - im[k] * math.sin(angle);
      }
      return val / n;
    });
  }

  // ── PCM dönüşüm ───────────────────────────────────────────────────────────

  static List<double> _pcmToDoubles(Uint8List bytes) {
    final out = <double>[];
    for (int i = 0; i + 1 < bytes.length; i += 2) {
      int raw = bytes[i] | (bytes[i + 1] << 8);
      if (raw > 32767) raw -= 65536;
      out.add(raw / 32768.0);
    }
    return out;
  }

  static Uint8List _doublesToPcm(List<double> samples) {
    final out = Uint8List(samples.length * 2);
    for (int i = 0; i < samples.length; i++) {
      final clamped = samples[i].clamp(-1.0, 1.0);
      int raw = (clamped * 32767).round();
      if (raw < 0) raw += 65536;
      out[i * 2] = raw & 0xFF;
      out[i * 2 + 1] = (raw >> 8) & 0xFF;
    }
    return out;
  }

  // ── Gürültü profili tahmini ───────────────────────────────────────────────

  /// Sessiz (gürültü-only) chunk'lardan gürültü spektrumunu tahmin et.
  /// [silenceChunks]: ilk 0.5–1 saniyelik sessiz audio chunk listesi.
  static List<double> estimateNoiseSpectrum(List<Uint8List> silenceChunks) {
    if (silenceChunks.isEmpty) return List.filled(_nfft ~/ 2, 0.0);

    final avgPower = List<double>.filled(_nfft ~/ 2, 0.0);
    int count = 0;

    for (final chunk in silenceChunks) {
      final samples = _pcmToDoubles(chunk);
      // Her _nfft uzunluğundaki frame'i işle
      for (int start = 0; start + _nfft <= samples.length; start += _nfft) {
        final frame = samples.sublist(start, start + _nfft);
        final (re, im) = _dft(frame);
        for (int k = 0; k < _nfft ~/ 2; k++) {
          avgPower[k] += re[k] * re[k] + im[k] * im[k];
        }
        count++;
      }
    }

    if (count == 0) return avgPower;
    for (int k = 0; k < avgPower.length; k++) {
      avgPower[k] /= count;
    }
    return avgPower;
  }

  // ── Ana gürültü azaltma ───────────────────────────────────────────────────

  /// PCM chunk'a spektral çıkarma uygular ve arındırılmış PCM döner.
  Uint8List denoise(Uint8List pcmBytes) {
    final samples = _pcmToDoubles(pcmBytes);
    final result = List<double>.from(samples);

    for (int start = 0; start + _nfft <= samples.length; start += _nfft) {
      final frame = samples.sublist(start, start + _nfft);
      final (re, im) = _dft(frame);

      for (int k = 0; k < _nfft ~/ 2; k++) {
        final power = re[k] * re[k] + im[k] * im[k];
        final noise = k < _noiseSpectrum.length ? _noiseSpectrum[k] : 0.0;
        final cleanPower = math.max(power - _overSubFactor * noise,
            _spectralFloor * power);
        final scale = power > 0 ? math.sqrt(cleanPower / power) : 0.0;
        re[k] *= scale;
        im[k] *= scale;
        // Simetrik spektrum (gerçek değerli sinyal)
        final mirrorK = _nfft - k;
        if (mirrorK < _nfft) {
          re[mirrorK] *= scale;
          im[mirrorK] *= scale;
        }
      }

      final cleaned = _idft(re, im);
      for (int i = 0; i < _nfft; i++) {
        result[start + i] = cleaned[i];
      }
    }

    return _doublesToPcm(result);
  }
}