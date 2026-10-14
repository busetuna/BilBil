from django.db import connection
from rest_framework import status
from rest_framework.decorators import api_view, authentication_classes, permission_classes
from rest_framework.response import Response

from .models import Profile
from .serializers import (
    LivesSerializer,
    ProfileSerializer,
    RewardsSerializer,
    StatsSerializer,
    WordProgressSerializer,
)


@api_view(['GET'])
@authentication_classes([])
@permission_classes([])
def health(request):
    """Railway sağlık kontrolü: veritabanına ulaşılamıyorsa 500 döner."""
    connection.ensure_connection()
    return Response({'ok': True})


@api_view(['GET', 'DELETE'])
def me(request):
    if request.method == 'DELETE':
        # Hesap silme: kullanıcının sunucudaki tüm verisi kalıcı olarak silinir.
        Profile.objects.filter(uid=request.user.uid).delete()
        return Response(status=status.HTTP_204_NO_CONTENT)

    profile = Profile.objects.filter(uid=request.user.uid).first()
    if profile is None:
        return Response(status=status.HTTP_404_NOT_FOUND)
    return Response(profile.to_api())


def _save(request, serializer_class, to_fields):
    """Gövdeyi doğrular ve yalnızca ilgili alanları günceller (yoksa satırı oluşturur)."""
    serializer = serializer_class(data=request.data)
    serializer.is_valid(raise_exception=True)
    Profile.objects.update_or_create(
        uid=request.user.uid, defaults=to_fields(serializer.validated_data))
    return Response(status=status.HTTP_204_NO_CONTENT)


@api_view(['PUT'])
def save_profile(request):
    return _save(request, ProfileSerializer, lambda d: {
        'name': d['name'],
        'email': d['email'],
        'user_type': d['userType'],
        'created_at': d['createdAt'],
    })


@api_view(['PUT'])
def save_stats(request):
    return _save(request, StatsSerializer, lambda d: {'stats': d})


@api_view(['PUT'])
def save_rewards(request):
    return _save(request, RewardsSerializer, lambda d: {'rewards': d})


@api_view(['PUT'])
def save_lives(request):
    return _save(request, LivesSerializer, lambda d: {'lives': d['lives']})


@api_view(['PUT'])
def save_word_progress(request):
    return _save(request, WordProgressSerializer, lambda d: {'word_progress': d['words']})
