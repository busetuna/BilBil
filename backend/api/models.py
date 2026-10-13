from django.db import models


class Profile(models.Model):
    """Bir Firebase kullanıcısının buluttaki verisi.

    Eski Firestore `users/{uid}` belgesinin karşılığıdır. stats/rewards
    uygulamanın gönderdiği haritalar olduğu için JSON olarak saklanır.
    """

    uid = models.CharField('Firebase UID', primary_key=True, max_length=128)
    name = models.CharField('ad', max_length=100, blank=True)
    email = models.CharField('e-posta', max_length=254, blank=True)
    user_type = models.CharField('kullanıcı tipi', max_length=50, blank=True)
    created_at = models.DateTimeField('kayıt tarihi', null=True, blank=True)
    stats = models.JSONField('istatistikler', null=True, blank=True)
    rewards = models.JSONField('ödüller', null=True, blank=True)
    lives = models.PositiveSmallIntegerField('can', null=True, blank=True)
    updated_at = models.DateTimeField('son güncelleme', auto_now=True)

    class Meta:
        verbose_name = 'profil'
        verbose_name_plural = 'profiller'

    def __str__(self):
        return self.email or self.uid

    def to_api(self):
        """Uygulamanın beklediği (Firestore ile aynı) biçim."""
        return {
            'name': self.name,
            'email': self.email,
            'userType': self.user_type,
            'createdAt': self.created_at.isoformat() if self.created_at else None,
            'stats': self.stats,
            'rewards': self.rewards,
            'lives': self.lives,
        }
