# Bilbil API

Uygulamanın bulut verisini (profil, istatistik, ödül, can) tutan Django REST API.
Giriş Firebase Auth'ta kalır; API her istekte Firebase ID token'ını doğrular ve
kullanıcıyı token'dan bulur.

## Endpointler

Hepsi `Authorization: Bearer <Firebase ID token>` ister (`/health` hariç).

| Metot | Yol | Açıklama |
|---|---|---|
| GET | `/health` | Sağlık kontrolü (veritabanını da yoklar) |
| GET | `/v1/me` | Kullanıcının tüm verisi; hiç verisi yoksa `404` |
| PUT | `/v1/me/profile` | `{name, email, userType, createdAt}` |
| PUT | `/v1/me/stats` | İstatistik haritası (bkz. `api/serializers.py`) |
| PUT | `/v1/me/rewards` | `{totalCorrect, earnedIds, puzzlePieces}` |
| PUT | `/v1/me/lives` | `{lives: 0-5}` |

PUT'lar yalnızca kendi alanını günceller, kayıt yoksa oluşturur; başarılıysa `204`,
geçersiz gövdede `400` döner.

## Yerelde çalıştırma

```bash
python -m venv .venv
.venv/Scripts/pip install -r requirements.txt
export DJANGO_DEBUG=1
.venv/Scripts/python manage.py migrate
.venv/Scripts/python manage.py test
.venv/Scripts/python manage.py runserver
```

`DATABASE_URL` yoksa SQLite kullanılır.

## Railway

1. Projeye bir **Postgres** ekle, bu klasörü (`backend/`) servis olarak deploy et
   (GitHub'dan bağlarsan *Root Directory* = `backend`).
2. Servis değişkenleri:
   - `DATABASE_URL` = `${{Postgres.DATABASE_URL}}`
   - `DJANGO_SECRET_KEY` = rastgele uzun bir değer
   - `WEB_CONCURRENCY` = `2` (gunicorn işçi sayısı)
   - `GUNICORN_CMD_ARGS` = `--access-logfile -` (istek logları)
3. *Networking → Generate Domain* ile bir alan adı al.

Başlangıç komutunu Railpack kendisi belirler (`migrate && gunicorn`); her
deploy'da migration'lar otomatik çalışır. Admin'in statik dosyalarını WhiteNoise
doğrudan sunduğu için `collectstatic` gerekmez.

Admin paneli `/admin/` adresinde. Kullanıcı oluşturmak için:

```bash
railway ssh python manage.py createsuperuser
```
