"""Uygulama resimlerini WebP'ye çevirir (uygulama boyutu).

PNG'ler toplam ~42 MB tutuyordu. WebP (kayıplı, şeffaflık korunur) gözle
fark edilmeyecek kalitede ~%80 küçüktür; Android ve iOS doğrudan açar.
Gösterildiğinden çok büyük resimler küçültülür (ör. 48-200 px'lik maskot
2048 px yüksekliğindeydi). Puzzle dosya adları ASCII'ye çevrilir.

Kullanım: pip install pillow; python tool/optimize_images.py
Var olan .png'leri .webp yapıp siler; Dart'taki yolları güncellemek ayrı adımdır.
"""
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
QUALITY = 85

# klasör/dosya -> (en uzun kenar sınırı, yeni ad)
TARGETS = {
    'assets/images/kolay': (None, None),
    'assets/images/orta': (None, None),
    'assets/images/zor': (None, None),
    'assets/images/bilbil1.png': (640, None),        # en büyük gösterim 200 px daire
    'assets/images/giris_bilbil.png': (None, None),
    'bilbil-puzzle/Gemini_Generated_Image_mw6k4bmw6k4bmw6k.png': (None, 'bilbil'),
    'bilbil-puzzle/kral.png': (None, 'kral'),
    'bilbil-puzzle/büyücü.png': (None, 'buyucu'),
    'bilbil-puzzle/ressam.png': (None, 'ressam'),
    'bilbil-puzzle/süperman.png': (None, 'superman'),
    'bilbil-puzzle/şarkıcı.png': (None, 'sarkici'),
}


def convert(src, max_side, new_stem):
    with Image.open(src) as im:
        im.load()
        if max_side and max(im.size) > max_side:
            scale = max_side / max(im.size)
            im = im.resize((round(im.width * scale), round(im.height * scale)), Image.LANCZOS)
        dst = src.with_name((new_stem or src.stem) + '.webp')
        im.save(dst, 'WEBP', quality=QUALITY, alpha_quality=100, method=6)
    before, after = src.stat().st_size, dst.stat().st_size
    src.unlink()
    return before, after


def main():
    total_before = total_after = count = 0
    for rel, (max_side, new_stem) in TARGETS.items():
        path = ROOT / rel
        files = sorted(path.glob('*.png')) if path.is_dir() else [path]
        for src in files:
            if not src.exists():
                print(f'yok (zaten çevrilmiş?): {src.relative_to(ROOT)}')
                continue
            b, a = convert(src, max_side, new_stem)
            total_before += b
            total_after += a
            count += 1
    print(f'{count} resim: {total_before / 1e6:.1f} MB -> {total_after / 1e6:.1f} MB')


if __name__ == '__main__':
    sys.exit(main())
