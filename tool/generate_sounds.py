"""Bilbil'in ses efektlerini ve arka plan müziğini üretir.

Sesler sentezlenir (hazır ses dosyası yok): telif/lisans sorunu yoktur ve
istenince değiştirilip yeniden üretilebilir. Yalnızca Python standart
kütüphanesi gerekir.

Kullanım:
  python tool/generate_sounds.py
Çıktı:
  assets/sounds/feedback/{correct,wrong,reward}.wav
  assets/sounds/backgrounds/music_box.wav  (dikişsiz döngü)
"""
import math
import random
import struct
import wave
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
FEEDBACK = ROOT / 'assets/sounds/feedback'
BACKGROUNDS = ROOT / 'assets/sounds/backgrounds'


def note(name):
    """'C5' -> frekans (Hz)."""
    steps = {'C': -9, 'D': -7, 'E': -5, 'F': -4, 'G': -2, 'A': 0, 'B': 2}
    semitone = steps[name[0]] + 12 * (int(name[-1]) - 4)
    return 440.0 * 2 ** (semitone / 12)


def bell(buf, rate, start, freq, amp, decay, partials):
    """Çan/müzik kutusu tınısı: kısmi seslerin üstel sönümlü toplamı."""
    length = int(rate * 6 / decay)  # sönümün ~%0.25'ine kadar
    s0 = int(start * rate)
    for i in range(length):
        t = i / rate
        env = math.exp(-t * decay) * min(1.0, t / 0.004)  # tık sesi olmasın
        v = sum(a * math.sin(2 * math.pi * freq * m * t) for m, a in partials)
        j = s0 + i
        if j < len(buf):
            buf[j] += amp * env * v


def soft_tone(buf, rate, start, dur, f_from, f_to, amp):
    """Yumuşak, kayan sinüs ("boop"): yavaş giriş ve çıkış."""
    s0, n = int(start * rate), int(dur * rate)
    phase = 0.0
    for i in range(n):
        t = i / n
        freq = f_from + (f_to - f_from) * t
        phase += 2 * math.pi * freq / rate
        env = math.sin(math.pi * t) ** 1.5
        v = math.sin(phase) + 0.25 * math.sin(2 * phase)
        if s0 + i < len(buf):
            buf[s0 + i] += amp * env * v


def write(path, buf, rate, peak):
    top = max(abs(v) for v in buf) or 1.0
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(rate)
        w.writeframes(b''.join(
            struct.pack('<h', int(v / top * peak * 32767)) for v in buf))
    print(f'{path.relative_to(ROOT)}: {len(buf) / rate:.2f} sn, '
          f'{path.stat().st_size // 1024} KB')


BELL = [(1, 1.0), (2.0, 0.4), (3.0, 0.18), (4.2, 0.08)]
MUSIC_BOX = [(1, 1.0), (2.0, 0.3), (3.0, 0.12), (5.4, 0.05)]


def correct(rate=22050):
    """Doğru: hızla yükselen üç nota, parlak çan."""
    buf = [0.0] * int(rate * 0.75)
    for k, n in enumerate(['E6', 'G6', 'C7']):
        bell(buf, rate, 0.085 * k, note(n), 0.6 + 0.2 * k, 7.0, BELL)
    return buf


def wrong(rate=22050):
    """Yanlış: cezalandırmayan, yumuşak iki notalık "boop" (aşağı doğru)."""
    buf = [0.0] * int(rate * 0.5)
    soft_tone(buf, rate, 0.0, 0.2, note('G4'), note('F4'), 0.8)
    soft_tone(buf, rate, 0.2, 0.28, note('E4'), note('D4'), 0.7)
    return buf


def reward(rate=22050):
    """Ödül: yükselen akor ve pırıltılar."""
    rng = random.Random(7)
    buf = [0.0] * int(rate * 1.6)
    for k, n in enumerate(['C5', 'E5', 'G5', 'C6']):
        bell(buf, rate, 0.1 * k, note(n), 0.7, 3.5, BELL)
    bell(buf, rate, 0.4, note('E6'), 0.5, 3.0, BELL)
    for k in range(9):  # pırıltı
        f = note(rng.choice(['C7', 'E7', 'G7', 'A6', 'D7']))
        bell(buf, rate, 0.5 + 0.08 * k + rng.uniform(0, 0.03), f, 0.18, 9.0, BELL)
    return buf


def tick(buf, rate, start, amp, rng):
    """Hafif ritim tıkırtısı: çok kısa, sönen gürültü."""
    s0 = int(start * rate)
    for i in range(int(rate * 0.03)):
        if s0 + i < len(buf):
            buf[s0 + i] += amp * math.exp(-i / rate * 160) * rng.uniform(-1, 1)


def music_box(rate=16000):
    """Neşeli müzik kutusu ezgisi (özgün), 126 vuruş/dk, sekizlik notalar,
    8 ölçü, dikişsiz döngü. (İlk sürüm 96 vuruş/dk ve dörtlüklerdi; fazla
    yavaş bulundu.)"""
    rng = random.Random(3)
    eighth = 60 / 126 / 2
    melody = [  # her biri sekizlik; None = uzat
        'C5', 'E5', 'G5', 'E5', 'C6', 'G5', 'E5', 'G5',
        'F5', 'A5', 'C6', 'A5', 'G5', 'F5', 'E5', 'D5',
        'E5', 'G5', 'C6', 'E6', 'D6', 'C6', 'G5', 'E5',
        'D5', 'G5', 'B5', 'G5', 'D6', 'B5', 'G5', None,
        'A5', 'C6', 'E6', 'C6', 'B5', 'A5', 'G5', 'E5',
        'F5', 'A5', 'C6', 'F6', 'E6', 'C6', 'A5', 'F5',
        'G5', 'B5', 'D6', 'B5', 'A5', 'G5', 'F5', 'D5',
        'C5', 'E5', 'G5', 'C6', 'G5', 'E5', 'C5', None,
    ]
    chords = [('C3', 'G3'), ('F3', 'C4'), ('C3', 'G3'), ('G2', 'D3'),
              ('A2', 'E3'), ('F2', 'C3'), ('G2', 'D3'), ('C3', 'G3')]
    loop = int(rate * eighth * len(melody))
    buf = [0.0] * (loop + rate * 2)  # sonda kuyruk payı
    for k, n in enumerate(melody):
        if n:
            accent = 1.0 if k % 2 == 0 else 0.8
            bell(buf, rate, k * eighth, note(n), 0.5 * accent, 4.0, MUSIC_BOX)
    for bar, (root, fifth) in enumerate(chords):
        for q in range(4):  # dörtlük bas: kök-beşli zıplar
            n = root if q % 2 == 0 else fifth
            bell(buf, rate, (bar * 8 + q * 2) * eighth, note(n), 0.3, 3.0,
                 MUSIC_BOX[:2])
        for e in range(1, 8, 2):  # arka vuruşlarda tıkırtı
            tick(buf, rate, (bar * 8 + e) * eighth, 0.12, rng)
    # Döngü sonuna taşan kuyruk başa eklenir: tekrar ederken kesinti olmaz.
    out = buf[:loop]
    for i, v in enumerate(buf[loop:]):
        out[i % loop] += v
    return out


if __name__ == '__main__':
    write(FEEDBACK / 'correct.wav', correct(), 22050, 0.8)
    write(FEEDBACK / 'wrong.wav', wrong(), 22050, 0.55)
    write(FEEDBACK / 'reward.wav', reward(), 22050, 0.8)
    write(BACKGROUNDS / 'music_box.wav', music_box(), 16000, 0.6)
