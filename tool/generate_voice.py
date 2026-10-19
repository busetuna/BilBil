"""Bilbil'in konuşmalarını önceden seslendirir (pocket-tts-tr).

Telefonun sentetik sesi çok robotik bulundu. Bilbil'in söyleyebileceği her
cümle parçası burada bir kere üretilip uygulamaya gömülür; uygulama cümleyi
parçalardan birleştirip çalar (bkz. lib/services/tts/voice_clips.dart).
Kaydı olmayan bir cümle telefonun sesiyle söylenir.

Ses: pocket-tts-tr (kaanhgunay, CC BY 4.0; Kyutai Pocket TTS türevi, Serdar
Çağlar'ın "Turkish TTS Audiobooks" verisiyle eğitilmiş). Model, konuşma
tarzını tool/voice/bilbil_ref.wav örneğinden taklit eder; bu örnek EMA
Lightning (Canberk Aslan, Apache-2.0) ile üretilip WORLD vokoderiyle
coşkulandırılmış sentetik bir sestir (gerçek bir kişinin sesi değildir).
Denenenler: telefonun sesi (robotik), EMA tek başına (nötr), EMA + ton
yükseltme (kalın/ince ve yapay), pocket + çıkışta ton yükseltme (ince).

Kurulum (bir kere, ~1.6 GB; model ilk çalıştırmada iner):
  pip install torch --index-url https://download.pytorch.org/whl/cpu
  pip install pocket-tts soundfile numpy
  # yalnızca örneği yeniden üretmek için (--make-ref): pip install ema-lightning pyworld
Kullanım (kelime listesi değişince yeniden çalıştır; CPU'da ~30 dk):
  python tool/generate_voice.py [--limit N]
Çıktı: assets/voice/manifest.json ve assets/voice/clips/*.mp3
"""
import json
import re
import sys
import time
import zlib
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parent.parent
QUIZ = ROOT / 'lib/data/models/quiz_item.dart'
CATEGORIES = ROOT / 'lib/data/models/quiz_category.dart'
VOICE_DIR = Path(__file__).resolve().parent / 'voice'
CONFIG = VOICE_DIR / 'pocket_tr.yaml'
REFERENCE = VOICE_DIR / 'bilbil_ref.wav'
OUT = ROOT / 'assets/voice'
RATE = 24000

# Daha canlı, daha az tekdüze okuma (varsayılan 0.3).
TEMPERATURE = 0.6
# "Bitti" dedikten sonra birkaç kare: fazlası yeni bir hece başlatıyordu.
FRAMES_AFTER_EOS = 4

# VoiceService'teki sabit cümleler ve parçalar (voice_service_test bunların
# eksiksiz olduğunu denetler).
CHEERS = ['Aferin!', 'Harika!', 'Süpersin!', 'Bravo!', 'Çok güzel!', 'Yaşasın!', 'Muhteşem!']
ALMOST = ['Neredeyse!', 'Az kaldı!', 'Çok yaklaştın!']
FIXED = [
    'Merhaba! Ben Bilbil. Haydi birlikte öğrenelim!',
    'Seni duyamadım! Bir daha söyler misin?',
    'Bir dahakine sen de söyle!',
    'Hadi sıradakine geçelim!',
    'Hadi birlikte söyleyelim!',
    'Birlikte başardık!',
]


def tr_lower(text):
    """Türkçe küçük harf: Python'un lower()'ı "İ"yi "i̇" yapar."""
    return text.replace('İ', 'i').replace('I', 'ı').lower()


def key(text):
    """VoiceClips.key ile aynı: Türkçe küçük harf, sondaki noktalama yok."""
    t = re.sub(r'\s+', ' ', tr_lower(text)).strip()
    return re.sub(r'[.!?,:;]+$', '', t).strip()


def slug(text):
    t = key(text)
    for a, b in zip('çğıöşüâî', 'cgiosuai'):
        t = t.replace(a, b)
    return re.sub(r'[^a-z0-9]+', '_', t).strip('_')[:60] or 'x'


def quiz_utterances():
    """Her quiz kelimesi için "Bu bir kedi!" ve ipucu "Bu bir... kedi!"."""
    leads = {}
    for m in re.finditer(r"QuizCategory\(\s*'([^']+)',\s*'[^']*',\s*'[^']*'(?:,\s*lead:\s*'([^']*)')?",
                         CATEGORIES.read_text('utf-8')):
        leads[m[1]] = m[2] or 'Bu bir'
    items = re.findall(r"word: '([^']+)',\s*category: '([^']+)'", QUIZ.read_text('utf-8'))
    assert items and leads, 'kelime ya da kategori okunamadı'
    out = []
    for word, cat in items:
        w = tr_lower(word)
        out += [f'{leads[cat]} {w}!', f'{leads[cat]}... {w}!']
    return out


def tidy(x):
    """Baştaki sessizliği kırp, sonda sönüş payı bırak, eşit ses düzeyi."""
    env = np.abs(x)
    above = np.where(env > env.max() * 10 ** (-50 / 20))[0]
    if len(above):
        x = x[max(0, above[0] - int(RATE * 0.04)): above[-1] + int(RATE * 0.3)]
    x = x.copy()
    fade_in = min(len(x) // 4, int(RATE * 0.01))
    fade_out = min(len(x) // 3, int(RATE * 0.15))
    if fade_in:
        x[:fade_in] *= np.linspace(0, 1, fade_in, dtype=np.float32)
    if fade_out:
        x[-fade_out:] *= np.linspace(1, 0, fade_out, dtype=np.float32) ** 2
    rms = np.sqrt(np.mean(x ** 2)) or 1.0
    x = x * (10 ** (-18 / 20) / rms)  # -18 dBFS RMS
    peak = np.abs(x).max()
    return x * (0.95 / peak) if peak > 0.95 else x


def make_reference():
    """Taklit edilecek coşkulu örnek: EMA + WORLD (çok tiz, çok geniş ezgi)."""
    import pyworld as pw
    import soundfile as sf
    from ema_lightning import EMA

    def cheer(x, semitones=4.0, rng=2.0, formant=1.05):
        x = x.astype(np.float64)
        f0, t = pw.harvest(x, RATE, f0_floor=70, f0_ceil=600, frame_period=5.0)
        f0 = pw.stonemask(x, f0, t, RATE)
        sp, ap = pw.cheaptrick(x, f0, t, RATE), pw.d4c(x, f0, t, RATE)
        v = f0 > 0
        lf = np.log(f0[v])
        f0[v] = np.exp(lf.mean() + rng * (lf - lf.mean())) * 2 ** (semitones / 12)
        bins = sp.shape[1]
        src = np.clip(np.arange(bins) / formant, 0, bins - 1)
        lo = np.floor(src).astype(int)
        hi, w = np.minimum(lo + 1, bins - 1), src - np.floor(src)
        sp = np.ascontiguousarray(sp[:, lo] * (1 - w) + sp[:, hi] * w)
        ap = np.ascontiguousarray(ap[:, lo] * (1 - w) + ap[:, hi] * w)
        return pw.synthesize(f0, sp, ap, RATE, 5.0).astype(np.float32)

    ema = EMA(device='cpu')
    parts = []
    for text in ['Yaşasııın!', 'Harikaaa!', 'Süpersiiin!', 'Hadi oynayalım!']:
        # Sondaki nokta: EMA "!" ile biten metinde son heceyi kesiyordu.
        audio = np.asarray(ema.say(text + '.', speed=1.06, seed=1, sample_rate=RATE).audio,
                           np.float32).reshape(-1)
        parts += [tidy(cheer(audio)), np.zeros(int(RATE * 0.15), np.float32)]
    VOICE_DIR.mkdir(exist_ok=True)
    sf.write(REFERENCE, np.concatenate(parts), RATE, subtype='PCM_16')
    print(f'örnek -> {REFERENCE.relative_to(ROOT)}')


def main(limit=None):
    import soundfile as sf
    import torch
    from pocket_tts import TTSModel

    unique = {}
    for text in CHEERS + ALMOST + FIXED + quiz_utterances():
        unique.setdefault(key(text), text)
    items = list(unique.items())[:limit]

    clips_dir = OUT / 'clips'
    clips_dir.mkdir(parents=True, exist_ok=True)
    for old in clips_dir.glob('*.mp3'):
        old.unlink()

    model = TTSModel.load_model(config=str(CONFIG), temp=TEMPERATURE)
    state = model.get_state_for_audio_prompt(REFERENCE)
    clips, used, suspicious, t0 = {}, set(), [], time.time()
    for n, (k, text) in enumerate(items, 1):
        torch.manual_seed(zlib.crc32(k.encode()))  # her kayıt yeniden üretilebilir
        audio = model.generate_audio(state, text, frames_after_eos=FRAMES_AFTER_EOS)
        audio = tidy(audio.detach().cpu().numpy().astype(np.float32).reshape(-1))
        if len(audio) < RATE * 0.3 or len(audio) > RATE * 5:
            suspicious.append(text)  # boş ya da kendi kendine uzayan kayıt
        name = ('ipucu_' if '...' in text else '') + slug(text)
        while name in used:
            name += '_'
        used.add(name)
        sf.write(clips_dir / f'{name}.mp3', audio, RATE, format='MP3',
                 subtype='MPEG_LAYER_III', bitrate_mode='VARIABLE', compression_level=0.3)
        clips[k] = f'clips/{name}.mp3'
        if n % 50 == 0:
            print(f'{n}/{len(items)} ({time.time() - t0:.0f} sn)', flush=True)

    manifest = {
        'voice': 'pocket-tts-tr (kaanhgunay, CC BY 4.0; Kyutai Pocket TTS türevi), '
                 f'sıcaklık {TEMPERATURE}; ses örneği EMA Lightning (Apache-2.0)',
        'clips': dict(sorted(clips.items())),
    }
    (OUT / 'manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=1), 'utf-8')
    size = sum(p.stat().st_size for p in clips_dir.glob('*.mp3'))
    print(f'{len(clips)} kayıt, {size / 1e6:.1f} MB, {time.time() - t0:.0f} sn -> {OUT.relative_to(ROOT)}')
    if suspicious:
        print('Dinleyip kontrol et (süresi tuhaf):', suspicious)


if __name__ == '__main__':
    if '--make-ref' in sys.argv:
        make_reference()
    else:
        # --limit N: yalnızca ilk N kaydı üret (deneme)
        lim = int(sys.argv[sys.argv.index('--limit') + 1]) if '--limit' in sys.argv else None
        main(lim)
