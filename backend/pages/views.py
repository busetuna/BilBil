from django.conf import settings
from django.http import HttpResponse
from django.shortcuts import render

# Gizlilik politikasının yürürlük tarihi; içerik değişince güncelle.
PRIVACY_UPDATED = '13 Ekim 2026'


def _context(**extra):
    return {'contact_email': settings.CONTACT_EMAIL, **extra}


def home(request):
    return render(request, 'pages/home.html', _context())


def privacy(request):
    return render(request, 'pages/privacy.html', _context(updated=PRIVACY_UPDATED))


def delete_account(request):
    """Uygulamayı silmiş biri de hesabını silebilsin (Google Play şartı).

    Sayfa tarayıcıda Firebase ile giriş yapar ve uygulamanın kullandığı akışı
    izler: önce DELETE /v1/me (sunucudaki veri), sonra Firebase hesabı.
    Şifre bu sunucuya hiç gelmez, doğrudan Google'a gider.
    """
    return render(request, 'pages/delete_account.html',
                  _context(firebase_api_key=settings.FIREBASE_WEB_API_KEY))


def app_ads_txt(request):
    """AdMob'un reklam envanterini doğrulaması için (alan adının kökünde olmalı)."""
    line = f'google.com, {settings.ADMOB_PUBLISHER_ID}, DIRECT, f08c47fec0942fa0\n'
    return HttpResponse(line, content_type='text/plain; charset=utf-8')
