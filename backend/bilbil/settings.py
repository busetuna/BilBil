"""
Bilbil API ayarları.

Tüm gizli/ortama bağlı değerler ortam değişkenlerinden okunur.
Railway'de: DATABASE_URL (Postgres eklentisinden), DJANGO_SECRET_KEY,
RAILWAY_PUBLIC_DOMAIN (Railway otomatik verir).
"""

import os
from pathlib import Path

import dj_database_url

BASE_DIR = Path(__file__).resolve().parent.parent

DEBUG = os.environ.get('DJANGO_DEBUG') == '1'

SECRET_KEY = os.environ.get('DJANGO_SECRET_KEY', '')
if not SECRET_KEY:
    if not DEBUG:
        raise RuntimeError('DJANGO_SECRET_KEY tanımlı değil')
    SECRET_KEY = 'dev-only-insecure-key'

# Railway sağlık kontrolü bu host adıyla gelir.
ALLOWED_HOSTS = ['localhost', '127.0.0.1', 'healthcheck.railway.app']
CSRF_TRUSTED_ORIGINS = []
_railway_domain = os.environ.get('RAILWAY_PUBLIC_DOMAIN')
if _railway_domain:
    ALLOWED_HOSTS.append(_railway_domain)
    CSRF_TRUSTED_ORIGINS.append(f'https://{_railway_domain}')
ALLOWED_HOSTS += [h for h in os.environ.get('DJANGO_EXTRA_HOSTS', '').split(',') if h]

# Railway TLS'i proxy'de sonlandırır. Sağlık kontrolü container'a düz HTTP
# ile geldiği için /health yönlendirmeden muaf tutulur.
SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTO', 'https')
SECURE_SSL_REDIRECT = not DEBUG
SECURE_REDIRECT_EXEMPT = [r'^health$']
SECURE_HSTS_SECONDS = 0 if DEBUG else 60 * 60 * 24 * 30
SESSION_COOKIE_SECURE = not DEBUG
# Hesap silme sayfası Google'a (identitytoolkit) istek atar. Django'nun
# varsayılanı 'same-origin' başka siteye Referer göndermez; o zaman web API
# anahtarı bu alan adıyla kısıtlanamaz. Bu ayar yalnızca kökü gönderir, yolu
# göndermez.
SECURE_REFERRER_POLICY = 'strict-origin-when-cross-origin'
CSRF_COOKIE_SECURE = not DEBUG

# Firebase ID token'ları bu projeye ait olmalı.
FIREBASE_PROJECT_ID = os.environ.get('FIREBASE_PROJECT_ID', 'bilbil-35e16')

# Herkese açık sayfalar (gizlilik politikası, hesap silme, app-ads.txt).
CONTACT_EMAIL = os.environ.get('CONTACT_EMAIL', 'btuna194@gmail.com')
# Firebase web anahtarı gizli değildir (firebase_options.dart'taki web yapılandırması);
# hesap silme sayfası tarayıcıda Firebase ile giriş yapmak için kullanır.
FIREBASE_WEB_API_KEY = os.environ.get(
    'FIREBASE_WEB_API_KEY', 'AIzaSyALLkMiJMGu0fIhKEJbKmiMk45aODBTY7M')
ADMOB_PUBLISHER_ID = os.environ.get('ADMOB_PUBLISHER_ID', 'pub-9093997172830553')


INSTALLED_APPS = [
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'rest_framework',
    'api',
    'pages',
]

MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'whitenoise.middleware.WhiteNoiseMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = 'bilbil.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'bilbil.wsgi.application'


# DATABASE_URL yoksa (yerel geliştirme) SQLite kullanılır.
DATABASES = {
    'default': dj_database_url.config(
        default=f'sqlite:///{BASE_DIR / "db.sqlite3"}',
        conn_max_age=600,
        conn_health_checks=True,
    )
}


AUTH_PASSWORD_VALIDATORS = [
    {'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator'},
    {'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator'},
    {'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator'},
    {'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator'},
]


REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': ['api.authentication.FirebaseAuthentication'],
    'DEFAULT_PERMISSION_CLASSES': ['rest_framework.permissions.IsAuthenticated'],
    'DEFAULT_RENDERER_CLASSES': ['rest_framework.renderers.JSONRenderer'],
    'DEFAULT_PARSER_CLASSES': ['rest_framework.parsers.JSONParser'],
    # Kullanıcı başına istek sınırı. Uygulama her cevapta birkaç kayıt
    # gönderir ve bekleyenleri birleştirir; normal oyun dakikada birkaç düzine
    # istek eder. Sayaç her gunicorn işçisinin belleğinde tutulur, yani
    # gerçek sınır işçi sayısı kadar katlanır; kötüye kullanımı durdurmak için yeterli.
    'DEFAULT_THROTTLE_CLASSES': ['api.throttling.FirebaseUserRateThrottle'],
    'DEFAULT_THROTTLE_RATES': {'user': '120/min'},
}

# İstatistik gövdesi birkaç KB; büyük gövdeleri reddet.
DATA_UPLOAD_MAX_MEMORY_SIZE = 256 * 1024


LANGUAGE_CODE = 'tr'
TIME_ZONE = 'Europe/Istanbul'
USE_I18N = True
USE_TZ = True


# Statik dosyalar (admin kaldırıldığından şu an yok). WhiteNoise onları
# doğrudan uygulama klasörlerinden sunar; deploy'da collectstatic çalıştırmaya
# gerek kalmaz (Railpack'in varsayılan başlangıç komutu bunu yapmıyor).
STATIC_URL = 'static/'
WHITENOISE_USE_FINDERS = True
STORAGES = {
    'default': {'BACKEND': 'django.core.files.storage.FileSystemStorage'},
    'staticfiles': {'BACKEND': 'whitenoise.storage.CompressedStaticFilesStorage'},
}

# Gerçek ortamda 500 hatalarının ayrıntısı Railway loglarına düşsün.
LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'handlers': {'console': {'class': 'logging.StreamHandler'}},
    'loggers': {'django.request': {'handlers': ['console'], 'level': 'ERROR'}},
}

DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'
