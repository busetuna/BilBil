"""Çocukların quiz kelimelerini tipik olarak nasıl söylediğini üretir.

2-5 yaşta sık görülen sesletim süreçleri (Türkçe), yazım üzerinden:
  önleşme        k->t, g->d             "kedi" -> "tedi"
  ş/ç yumuşatma  ş->s, ç->ş             "şapka" -> "sapka", "çiçek" -> "şişek"
  r değişimi     r->y, r->l, sondaki r  "araba" -> "ayaba", "kırmızı" -> "kılmızı"
  benzeşme       ilk ünsüz/ünlü sonrakine benzer  "yeşil" -> "şeşil", "şişil"
  hece düşmesi   uzun kelimede ilk hece "zürafa" -> "rafa"
  son ses düşmesi                       "köpek" -> "köpe"

Başka bir quiz kelimesine (ya da onun bir harf yakınına) denk gelen değişken
atılır: "kek" gibi bir değişken başka sorunun cevabıyla karışmasın.
"""

VOWELS = set('aeıioöuü')


def tr_lower(text):
    return text.replace('İ', 'i').replace('I', 'ı').lower()


def lev(a, b):
    prev = list(range(len(b) + 1))
    for i, ca in enumerate(a, 1):
        cur = [i]
        for j, cb in enumerate(b, 1):
            cur.append(min(prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + (ca != cb)))
        prev = cur
    return prev[-1]


def syllables(word):
    """Türkçe heceleme: ünlü başına bir hece; ünlüden önceki tek ünsüz o heceye."""
    out, cur, i = [], '', 0
    while i < len(word):
        cur += word[i]
        if word[i] in VOWELS:
            j = i + 1
            while j < len(word) and word[j] not in VOWELS:
                j += 1
            cons = word[i + 1:j]
            if j < len(word):  # arada ünlü var: son ünsüz sonraki heceye
                cur += cons[:-1] if cons else ''
                out.append(cur)
                cur = cons[-1] if cons else ''
                i = j
                continue
            cur += cons
            out.append(cur)
            cur = ''
            i = j
            continue
        i += 1
    if cur:
        out.append(cur)
    return out


def _sub_all(w, a, b):
    return w.replace(a, b) if a in w else None


def _word_variants(w):
    """Tek kelime için, olasılık sırasıyla değişkenler."""
    out = []
    add = lambda v: v and v != w and v not in out and out.append(v)
    add(_sub_all(w, 'k', 't'))
    add(_sub_all(w, 'g', 'd'))
    add(_sub_all(w, 'ş', 's'))
    add(_sub_all(w, 'ç', 'ş'))
    add(_sub_all(w, 'r', 'y'))
    add(_sub_all(w, 'r', 'l'))
    if w.endswith('r') and len(w) > 3:
        add(w[:-1])
    # benzeşme: ilk ünsüz, sonraki (farklı) ünsüze; ilk ünlü de sonrakine
    cons = [(i, ch) for i, ch in enumerate(w) if ch not in VOWELS]
    if len(cons) >= 2 and cons[0][0] == 0 and cons[1][1] != cons[0][1]:
        harmonized = cons[1][1] + w[1:]
        add(harmonized)
        vows = [(i, ch) for i, ch in enumerate(harmonized) if ch in VOWELS]
        if len(vows) >= 2 and vows[0][1] != vows[1][1]:
            i0 = vows[0][0]
            add(harmonized[:i0] + vows[1][1] + harmonized[i0 + 1:])
    syl = syllables(w)
    if len(syl) >= 3:
        add(''.join(syl[1:]))
    if w[-1] not in VOWELS and len(w) >= 4:
        add(w[:-1])
    return out


def variants(word, all_words, limit=6):
    """[word] için çocuk söyleyişleri (küçük harf). Çok kelimeli ifadede
    her seferinde bir kelime değişir ("muhabbet kuşu" -> "muhabbet tuşu")."""
    target = tr_lower(word)
    others = {tr_lower(o) for o in all_words} - {target}
    parts = target.split()
    cands = []
    for k, p in enumerate(parts):
        for v in _word_variants(p):
            cands.append(' '.join(parts[:k] + [v] + parts[k + 1:]))
    out = []
    for v in cands:
        flat = v.replace(' ', '')
        if len(flat) < 3:
            continue
        # başka bir quiz kelimesine çok yakın değişken karışıklık yaratır
        if any(lev(flat, o.replace(' ', '')) <= 1 for o in others):
            continue
        if v not in out:
            out.append(v)
        if len(out) >= limit:
            break
    return out


if __name__ == '__main__':
    import re
    from pathlib import Path
    quiz = Path(__file__).resolve().parent.parent / 'lib/data/models/quiz_item.dart'
    words = list(dict.fromkeys(re.findall(r"word: '([^']+)'", quiz.read_text('utf-8'))))
    for w in ['Yeşil', 'Kedi', 'Köpek', 'Araba', 'Zürafa', 'Kırmızı', 'Çiçek', 'Şapka', 'Muhabbet kuşu', 'Top']:
        print(f'{w:15} {syllables(tr_lower(w.split()[-1]))}  {variants(w, words)}')
