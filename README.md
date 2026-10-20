# 🐦 Bilbil

2–5 yaş çocuklar için Türkçe kelime öğrenme uygulaması. Bilbil ekranda bir
resim gösterir, çocuk resmin adını söyler; uygulama sesi cihazın üstünde tanır,
Bilbil neşeli bir sesle cevap verir. Zorluk ve tekrarlar çocuğun cevaplarına
göre kendiliğinden ayarlanır, ebeveyn ilerlemeyi PIN korumalı panelden izler.

Flutter (Android öncelikli, iOS da derlenir) + Django REST API (Railway).

## Özellikler

**Çocuk için**
- **Sesli quiz:** 214 kelime, 11 konu (hayvanlar, meyve-sebze, renkler,
  şekiller, vücut, kıyafetler, eşyalar, oyuncaklar, doğa, hava, eylemler).
  Ana ekranda karışık oyna ya da konu seç.
- **Cihaz üstü ses tanıma:** Vosk (`vosk-model-small-tr-0.3`), her soruda
  yalnızca quiz kelimelerinden oluşan kapalı sözlükle; isteğe bağlı telefonun
  kendi tanıyıcısı. Cevap kontrolü çocukların eksik/bozuk söyleyişini tolere
  eder; resmin diğer doğru adları da kabul edilir (Kupa için "bardak").
- **Bilbil'in sesi:** önceden seslendirilmiş neşeli kayıtlar (cümleler
  parçalardan birleştirilir); kaydı olmayan cümlede telefonun sesi.
- **"Bilbil söylesin" ipucu**; 2–3 yaşta duyulmazsa "Hadi birlikte söyleyelim".
- **Uyarlanır zorluk:** seviye başına Q tablosu olan ε-greedy bandit; zor
  seviyedeki doğru cevap daha değerli, iki yanlışta kolaylaşır, öğrendikleri
  quizler arasında saklanır.
- **Aralıklı tekrar:** Leitner kutuları; bilinemeyen kelime üç soru sonra
  yeniden gelir, zorlanılan kelimeler daha sık sorulur.
- **Ödüller ve canlar:** puzzle ödülleri, 5 can; canlar bitince mola (isteğe
  bağlı ödüllü reklamla dolar).
- **Ses efektleri ve kısık arka plan müziği** (mikrofon dinlerken susar).

**Ebeveyn için** (PIN korumalı)
- İstatistikler, zorluk geçmişi, konu bazında başarı, "zorlandığı kelimeler".
- Ayarlar: çocuğun yaşı (en yüksek zorluğu belirler), başlangıç zorluğu, ses
  tanıma motoru, Bilbil'in sesi, ses efektleri ve müzik, PIN, hesap silme.

**Bulut ve gizlilik**
- Giriş Firebase Auth; veriler Django API'de (`backend/`). Uygulama internetsiz
  de çalışır: gönderilemeyen kayıtlar yeniden denenir, internetsiz oynanan
  ilerleme bağlantı gelince buluta yazılır (buluttaki eski veri üstüne yazmaz).
- Reklamlar (AdMob) çocuklara yönelik ayarlarla: kişiselleştirilmemiş, G
  derecesi; quiz sonu geçiş reklamı seyrek, mola ekranında isteğe bağlı ödüllü
  reklam. Debug derlemesinde test reklamları.
- Gizlilik politikası ve hesap silme sayfaları backend'de.

## Proje yapısı

```
lib/
├── core/            tema, renkler, bağlantılar
├── data/            quiz verisi (QuizItem, QuizCategory), Firebase auth
├── domain/          kullanıcı, auth arayüzü ve kullanım durumları
├── features/
│   ├── learning/    giriş, ana ekran, quiz, mola, ödüller, puzzle
│   ├── parent/      PIN, istatistik, grafik, ödül ve ayar sekmeleri
│   └── debug/       ses laboratuvarı (yalnızca debug)
└── services/
    ├── asr/         Vosk, telefonun tanıyıcısı, kapalı sözlük, model indirme
    ├── tts/         Bilbil'in sesi (kayıtlar + telefonun sesi)
    ├── rl_agent/    zorluk ajanı
    ├── learning/    kelime ilerlemesi (Leitner), soru sıralama
    ├── sound/       efektler ve müzik
    ├── ads/         AdMob ve reklam sıklığı
    ├── api/, sync/  bulut API'si ve hesap senkronu
    └── stats/, lives/, rewards/, theme/
backend/             Django REST API (bkz. backend/README.md)
tool/                ses/görsel üretim betikleri (aşağıda)
assets/
├── images/{kolay,orta,zor}/   quiz resimleri (WebP)
├── sounds/                    efektler ve müzik (tool/generate_sounds.py)
└── voice/                     Bilbil'in kayıtları (tool/generate_voice.py)
bilbil-puzzle/       puzzle ödül resimleri (WebP)
```

## Geliştirme

```bash
flutter pub get
flutter run
```

- Firebase ayar dosyaları (`android/app/google-services.json`,
  `lib/firebase_options.dart`) depoda.
- Uygulama varsayılan olarak Railway'deki API'yi kullanır. Yerel backend ile:
  `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000`
  (boş adres verilirse bulut senkronu kapanır).
- Backend'i yerelde çalıştırma ve deploy: `backend/README.md` (veritabanı
  adresi verilmezse SQLite).
- **Ses laboratuvarı:** debug derlemesinde giriş ekranında Bilbil'e uzun bas;
  Bilbil'in sesi, quiz cümleleri, efektler ve müzik giriş yapmadan denenir.

### Testler

```bash
flutter analyze
flutter test                                          # ~160 test
cd backend && DJANGO_DEBUG=1 python manage.py test    # backend
```

Testler şunları da denetler: Bilbil'in söyleyebileceği her cümlenin kaydı
var mı, kodda adı geçen her resim dosyası var mı, her kategoride oynanabilir
seviyeler.

### Üretim betikleri (`tool/`)

| Betik | Ne zaman | Gereken |
|---|---|---|
| `generate_vosk_vocabulary.py <model>` | quiz kelimeleri değişince | `pip install vosk` |
| `generate_voice.py` | kelime ya da Bilbil'in cümleleri değişince (CPU'da ~20–30 dk) | torch (CPU), `pocket-tts`, `soundfile` |
| `generate_sounds.py` | efekt/müzik değiştirilecekse | yalnızca Python |
| `optimize_images.py` | yeni PNG resim eklenince (WebP'ye çevirir) | `pillow` |

Bir kelime eklenince: `quiz_item.dart`'a ekle, resmi WebP yap,
`generate_vosk_vocabulary.py` ve `generate_voice.py` çalıştır, `flutter test`.

## İzinler

- **Mikrofon:** ses tanıma (kayıt cihazdan çıkmaz).
- **İnternet:** giriş, bulut senkronu, Vosk modelinin ilk indirilmesi, reklamlar.

## Kaynaklar ve lisanslar

- Ses tanıma: [Vosk](https://alphacephei.com/vosk/) `vosk-model-small-tr-0.3` (Apache 2.0).
- Bilbil'in sesi: [pocket-tts-tr](https://huggingface.co/kaanhgunay/pocket-tts-tr)
  (kaanhgunay, CC BY 4.0; [Kyutai Pocket TTS](https://huggingface.co/kyutai/pocket-tts)
  temelli, Turkish TTS Audiobooks verisi — Serdar I. Çağlar). Ses örneği
  [EMA Lightning](https://huggingface.co/canberkkkkkk/ema-lightning) (Canberk Aslan,
  Apache 2.0) ile üretildi. Uygulamada yapay zekâ sesi olduğu belirtilir.
- Efektler ve müzik `tool/generate_sounds.py` ile sentezlenir (hazır kayıt yok).
