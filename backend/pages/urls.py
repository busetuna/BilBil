from django.urls import path

from . import views

urlpatterns = [
    path('', views.home),
    path('gizlilik', views.privacy),
    path('hesap-sil', views.delete_account),
    path('app-ads.txt', views.app_ads_txt),
]
