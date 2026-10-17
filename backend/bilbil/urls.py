from django.urls import include, path

from api.views import health

# Django admin paneli bilerek yok: uygulama kullanmıyor, internete açık giriş
# sayfası yalnızca kaba kuvvet denemesine kapı açıyordu. Veriye bakmak
# gerekirse Railway'deki Postgres'e doğrudan bağlanılır.
urlpatterns = [
    path('health', health),
    path('v1/', include('api.urls')),
    path('', include('pages.urls')),
]
