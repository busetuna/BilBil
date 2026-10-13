from django.db import migrations


def remove_plaintext_pin(apps, schema_editor):
    """Önceki sürümün sakladığı düz metin PIN'leri istatistiklerden siler."""
    Profile = apps.get_model('api', 'Profile')
    for profile in Profile.objects.exclude(stats=None).iterator():
        if isinstance(profile.stats, dict) and 'pin' in profile.stats:
            profile.stats.pop('pin')
            profile.save(update_fields=['stats'])


class Migration(migrations.Migration):

    dependencies = [
        ('api', '0001_initial'),
    ]

    operations = [
        migrations.RunPython(remove_plaintext_pin, migrations.RunPython.noop),
    ]
