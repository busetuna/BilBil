"""Quiz kelimelerinin Vosk'ta nasıl söylenebildiğini üretir.

Vosk sözlüğünde olmayan bir kelimeyi hiç yazamaz; kapalı sözlüğe (grammar)
verilen sözlük dışı kelimeleri de sessizce atar. Bu araç her quiz kelimesi için
modelin söyleyebileceği biçimi bulur:
  - kelime sözlükteyse kendisi ("kedi"),
  - değilse sözlükteki parçalara bölünmüş hali ("kelebek" -> "ke le bek"),
  - hiçbiri olmuyorsa kelime tabloya girmez (o soruda açık sözlük kullanılır).

Kullanım (kelime listesi ya da model değişince yeniden çalıştır):
  pip install vosk
  python tool/generate_vosk_vocabulary.py <vosk-model-small-tr-0.3 klasörü>
Çıktı: lib/services/asr/vosk_vocabulary.dart
"""
import re
import sys
from pathlib import Path

from vosk import Model, SetLogLevel

ROOT = Path(__file__).resolve().parent.parent
QUIZ = ROOT / 'lib/data/models/quiz_item.dart'
OUT = ROOT / 'lib/services/asr/vosk_vocabulary.dart'


def normalize(s):  # AnswerChecker.normalize ile aynı (Türkçe İ/I)
    return re.sub(r'\s+', ' ', s.replace('İ', 'i').replace('I', 'ı').lower()).strip()


def main(model_dir):
    SetLogLevel(-1)
    model = Model(model_dir)
    known = lambda t: len(t) >= 2 and model.vosk_model_find_word(t) != -1

    def split(word, max_parts=3):
        best = None

        def rec(rest, parts):
            nonlocal best
            if not rest:
                key = (len(parts), -min(map(len, parts)))
                if best is None or key < best[0]:
                    best = (key, parts[:])
                return
            if len(parts) < max_parts:
                for i in range(len(rest), 1, -1):
                    if known(rest[:i]):
                        rec(rest[i:], parts + [rest[:i]])

        rec(word, [])
        return ' '.join(best[1]) if best else None

    # Asıl kelimeler ve resmin diğer doğru adları (alsoAccepted)
    text = QUIZ.read_text('utf-8')
    found = re.findall(r"word: '([^']+)'", text)
    for extra in re.findall(r"alsoAccepted: \[([^\]]*)\]", text):
        found += re.findall(r"'([^']+)'", extra)
    words = sorted({normalize(w) for w in found})
    phrases, missing = {}, []
    for w in words:
        parts = [t if known(t) else split(t) for t in w.split()]
        if all(parts):
            phrases[w] = ' '.join(parts)
        else:
            missing.append(w)

    lines = [
        '// ÜRETİLMİŞ DOSYA — elle düzenleme; tool/generate_vosk_vocabulary.py ile üret.',
        '// Model: vosk-model-small-tr-0.3',
        '//',
        '// Quiz kelimesi -> Vosk\'un söyleyebildiği biçim. Sözlükte olmayan kelimeler',
        '// parçalara bölünmüştür ("kelebek" -> "ke le bek").',
        f'// Tabloda olmayan {len(missing)} kelime için açık sözlük kullanılır:',
    ]
    lines += [f'//   {w}' for w in missing]
    lines.append('const voskQuizPhrases = <String, String>{')
    lines += [f"  '{w}': '{p}'," for w, p in phrases.items()]
    lines.append('};')
    OUT.write_text('\n'.join(lines) + '\n', 'utf-8')
    print(f'{len(phrases)} kelime tabloda ({sum(1 for w, p in phrases.items() if w != p)} takma ad), '
          f'{len(missing)} açık sözlükte -> {OUT.relative_to(ROOT)}')


if __name__ == '__main__':
    main(sys.argv[1])
