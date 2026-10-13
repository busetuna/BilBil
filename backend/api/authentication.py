import functools

import firebase_admin
from django.conf import settings
from firebase_admin import auth as firebase_auth
from firebase_admin import credentials
from google.auth.credentials import AnonymousCredentials
from rest_framework import authentication, exceptions


class FirebaseUser:
    """DRF'nin request.user'ı; yalnızca Firebase uid'sini taşır."""

    is_authenticated = True

    def __init__(self, uid):
        self.uid = uid


class AuthUnavailable(exceptions.APIException):
    status_code = 503
    default_detail = 'Token şu an doğrulanamıyor, daha sonra tekrar deneyin'


class _NoCredentials(credentials.Base):
    """Token doğrulama servis hesabı istemez: Google'ın açık sertifikaları ve
    proje kimliği yeterli. Kimlik verilmezse firebase-admin makinede Google
    varsayılan kimliği (ADC) arar ve Railway'de bulamayınca patlar."""

    def get_credential(self):
        return AnonymousCredentials()


@functools.cache
def _firebase_app():
    return firebase_admin.initialize_app(
        _NoCredentials(), options={'projectId': settings.FIREBASE_PROJECT_ID}, name='bilbil')


def verify_token(token):
    """Geçerli bir Firebase ID token'ının uid'sini döner, değilse hata fırlatır."""
    return firebase_auth.verify_id_token(token, app=_firebase_app())['uid']


class FirebaseAuthentication(authentication.BaseAuthentication):
    """`Authorization: Bearer <Firebase ID token>` başlığını doğrular.

    Kullanıcı kimliği her zaman token'dan gelir; istek gövdesindeki ya da
    URL'deki bir uid'ye asla güvenilmez.
    """

    def authenticate(self, request):
        scheme, _, token = request.META.get('HTTP_AUTHORIZATION', '').partition(' ')
        if scheme.lower() != 'bearer' or not token.strip():
            return None
        try:
            uid = verify_token(token.strip())
        except firebase_auth.CertificateFetchError:
            raise AuthUnavailable()
        except (ValueError, firebase_auth.InvalidIdTokenError):
            raise exceptions.AuthenticationFailed('Geçersiz veya süresi dolmuş token')
        return FirebaseUser(uid), token

    def authenticate_header(self, request):
        # 403 yerine 401 + WWW-Authenticate dönmesini sağlar.
        return 'Bearer'
