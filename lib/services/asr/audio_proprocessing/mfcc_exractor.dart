import 'dart:math' as math;
import 'dart:typed_data';

/// MFCC (Mel-Frequency Cepstral Coefficients) çıkarım pipeline'ı.
/// Pipeline: PCM → Ön-vurgu → Çerçeveleme → Hamming penceresi
///           → FFT güç spektrumu → Mel filtre bankası → Log → DCT → MFCC
class MfccExtractor {
  static const int sampleRate = 16000;    // 16 kHz
  static const int numCoefficients = 13;  // MFCC katsayı sayısı
  static const int numMelFilters = 26;    // Mel filtre sayısı
  static const int nfft = 512;           // FFT boyutu (2^9)
  static const double preEmphasisCoeff = 0.97;
  static const double frameLengthSec = 0.025; // 25 ms
  static const double frameStepSec = 0.010;   // 10 ms hop
  static const double lowFreqHz = 300.0;
  static const double highFreqHz = 8000.0;

  static int get frameSizeSamples => (sampleRate * frameLengthSec).round(); // 400
  static int get frameStepSamples => (sampleRate * frameStepSec).round();   // 160

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

  // ── Ön-vurgu filtresi ─────────────────────────────────────────────────────
  // Yüksek frekansları güçlendirir; fonetik özellikler için SNR artar.

  static List<double> _preEmphasize(List<double> s) {
    final out = List<double>.filled(s.length, 0.0);
    out[0] = s[0];
    for (int i = 1; i < s.length; i++) {
      out[i] = s[i] - preEmphasisCoeff * s[i - 1];
    }
    return out;
  }

  // ── Çerçeveleme ───────────────────────────────────────────────────────────

  static List<List<double>> _frame(List<double> s) {
    final frames = <List<double>>[];
    final size = frameSizeSamples;
    final step = frameStepSamples;
    for (int start = 0; start + size <= s.length; start += step) {
      frames.add(s.sublist(start, start + size));
    }
    return frames;
  }

  // ── Hamming penceresi ─────────────────────────────────────────────────────

  static List<double> _hamming(List<double> f) {
    final n = f.length;
    return List.generate(n,
        (i) => f[i] * (0.54 - 0.46 * math.cos(2 * math.pi * i / (n - 1))));
  }

  // ── Cooley-Tukey radix-2 FFT ──────────────────────────────────────────────

  static (List<double>, List<double>) _fft(List<double> re, List<double> im) {
    final n = re.length;
    final r = List<double>.from(re);
    final c = List<double>.from(im);

    // Bit-reversal permutation
    int j = 0;
    for (int i = 1; i < n; i++) {
      int bit = n >> 1;
      while (j & bit != 0) {
        j ^= bit;
        bit >>= 1;
      }
      j ^= bit;
      if (i < j) {
        double t = r[i]; r[i] = r[j]; r[j] = t;
        t = c[i]; c[i] = c[j]; c[j] = t;
      }
    }

    // Butterfly
    for (int len = 2; len <= n; len <<= 1) {
      final ang = -2 * math.pi / len;
      final wRe = math.cos(ang);
      final wIm = math.sin(ang);
      for (int i = 0; i < n; i += len) {
        double cRe = 1.0, cIm = 0.0;
        final half = len >> 1;
        for (int k = 0; k < half; k++) {
          final uRe = r[i + k];
          final uIm = c[i + k];
          final vRe = r[i + k + half] * cRe - c[i + k + half] * cIm;
          final vIm = r[i + k + half] * cIm + c[i + k + half] * cRe;
          r[i + k] = uRe + vRe;
          c[i + k] = uIm + vIm;
          r[i + k + half] = uRe - vRe;
          c[i + k + half] = uIm - vIm;
          final nCRe = cRe * wRe - cIm * wIm;
          cIm = cRe * wIm + cIm * wRe;
          cRe = nCRe;
        }
      }
    }
    return (r, c);
  }

  // ── Güç spektrumu ─────────────────────────────────────────────────────────

  static List<double> _powerSpectrum(List<double> windowed) {
    // Sıfır-doldurma ile nfft uzunluğuna getir
    final padded = List<double>.filled(nfft, 0.0);
    for (int i = 0; i < windowed.length && i < nfft; i++) {
      padded[i] = windowed[i];
    }
    final imag = List<double>.filled(nfft, 0.0);
    final (re, im) = _fft(padded, imag);

    // Yalnızca pozitif frekanslar (|X|² / N)
    final half = nfft ~/ 2 + 1;
    return List.generate(half, (k) => (re[k] * re[k] + im[k] * im[k]) / nfft);
  }

  // ── Mel filtre bankası ────────────────────────────────────────────────────

  static double _hzToMel(double hz) => 2595 * math.log(1 + hz / 700) / math.ln10;
  static double _melToHz(double mel) => 700 * (math.pow(10, mel / 2595) - 1);

  static List<double> _melFilterbank(List<double> power) {
    final lowMel = _hzToMel(lowFreqHz);
    final highMel = _hzToMel(highFreqHz);
    final melPts = List.generate(numMelFilters + 2,
        (i) => lowMel + (highMel - lowMel) * i / (numMelFilters + 1));
    final hzPts = melPts.map(_melToHz).toList();
    final bins = hzPts.map((hz) => ((nfft + 1) * hz / sampleRate).floor()).toList();

    return List.generate(numMelFilters, (m) {
      double energy = 0.0;
      for (int k = bins[m]; k < bins[m + 1] && k < power.length; k++) {
        energy += power[k] * (k - bins[m]) / (bins[m + 1] - bins[m]);
      }
      for (int k = bins[m + 1]; k < bins[m + 2] && k < power.length; k++) {
        energy += power[k] * (bins[m + 2] - k) / (bins[m + 2] - bins[m + 1]);
      }
      return math.log(energy + 1e-10);
    });
  }

  // ── DCT (Tip-II) ──────────────────────────────────────────────────────────

  static List<double> _dct(List<double> input) {
    final n = input.length;
    return List.generate(numCoefficients, (k) {
      double sum = 0.0;
      for (int i = 0; i < n; i++) {
        sum += input[i] * math.cos(math.pi * k * (2 * i + 1) / (2 * n));
      }
      return sum;
    });
  }

  // ── Ortalama çıkarma (cepstral mean subtraction) ──────────────────────────

  static List<List<double>> _cepstralMeanSubtraction(List<List<double>> mfccs) {
    if (mfccs.isEmpty) return mfccs;
    final means = List<double>.filled(numCoefficients, 0.0);
    for (final v in mfccs) {
      for (int i = 0; i < numCoefficients; i++) means[i] += v[i];
    }
    for (int i = 0; i < numCoefficients; i++) means[i] /= mfccs.length;
    return mfccs.map((v) =>
        List.generate(numCoefficients, (i) => v[i] - means[i])).toList();
  }

  // ── Ana çıkarım ────────────────────────────────────────────────────────────

  /// PCM chunk'tan MFCC matrisini çıkarır.
  /// Dönen liste: her öğe [numCoefficients] boyutunda bir çerçeve vektörü.
  static List<List<double>> extract(Uint8List pcmBytes,
      {bool applyCms = true}) {
    final signal = _pcmToDoubles(pcmBytes);
    if (signal.length < frameSizeSamples) return [];

    final emphasized = _preEmphasize(signal);
    final frames = _frame(emphasized);
    var mfccs = frames.map((f) {
      final windowed = _hamming(f);
      final power = _powerSpectrum(windowed);
      final melEnergies = _melFilterbank(power);
      return _dct(melEnergies);
    }).toList();

    if (applyCms) mfccs = _cepstralMeanSubtraction(mfccs);
    return mfccs;
  }

  /// Tek bir çerçeve için MFCC vektörü hesaplar.
  static List<double> extractFrame(List<double> frameSamples) {
    final windowed = _hamming(frameSamples);
    final power = _powerSpectrum(windowed);
    final mel = _melFilterbank(power);
    return _dct(mel);
  }
}