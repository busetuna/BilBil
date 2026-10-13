from django.urls import path

from . import views

urlpatterns = [
    path('me', views.me),
    path('me/profile', views.save_profile),
    path('me/stats', views.save_stats),
    path('me/rewards', views.save_rewards),
    path('me/lives', views.save_lives),
]
