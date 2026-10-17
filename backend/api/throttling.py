from rest_framework.throttling import UserRateThrottle


class FirebaseUserRateThrottle(UserRateThrottle):
    """Kullanıcı başına istek sınırı (bkz. settings.DEFAULT_THROTTLE_RATES).

    DRF'nin sınıfı Django kullanıcısının pk'sını kullanır; FirebaseUser'ın
    pk'sı yok, uid'si var. Kimliksiz istekler zaten 401 alır, sayılmaz.
    """

    def get_cache_key(self, request, view):
        if not (request.user and request.user.is_authenticated):
            return None
        return self.cache_format % {'scope': self.scope, 'ident': request.user.uid}
