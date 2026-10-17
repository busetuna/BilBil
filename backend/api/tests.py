import importlib
from datetime import UTC, datetime
from unittest import mock

from django.apps import apps as django_apps
from django.core.cache import cache
from django.test import override_settings
from google.auth.exceptions import DefaultCredentialsError
from rest_framework.test import APITestCase

from .models import Profile
from .throttling import FirebaseUserRateThrottle

VALID_STATS = {
    'totalCorrect': 12,
    'totalWrong': 3,
    'difficultyHistory': [0, 0, 1, 1, 2],
    'startingDifficulty': 0,
    'pinHash': 'a' * 64,
    'pinSalt': 'b' * 32,
    'totalAsrAttempts': 15,
    'exactAsrMatches': 12,
    'totalLatencyMs': 45000,
    'latencyHistory': [3000, 2500],
    'categoryWrong': {'animals': 1},
    'categoryTotal': {'animals': 5, 'colors': 2},
    'childAge': 4,
}
VALID_REWARDS = {
    'totalCorrect': 12,
    'earnedIds': ['first_correct'],
    'puzzlePieces': {'first_correct': 9, 'five_correct': 3},
}
VALID_PROFILE = {
    'name': 'Ada',
    'email': 'ada@example.com',
    'userType': 'UserType.parent',
    'createdAt': '2026-10-13T12:00:00.000Z',
}


def fake_verify(token):
    if not token.startswith('token-'):
        raise ValueError('bad token')
    return token.removeprefix('token-')


class ApiTests(APITestCase):
    def setUp(self):
        patcher = mock.patch('api.authentication.verify_token', side_effect=fake_verify)
        patcher.start()
        self.addCleanup(patcher.stop)
        # İstek sınırı sayacı önbellekte; testler birbirinin sayacını taşımasın.
        cache.clear()

    def login(self, uid):
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer token-{uid}')

    def test_health_needs_no_token(self):
        res = self.client.get('/health')
        self.assertEqual(res.status_code, 200)
        self.assertEqual(res.json(), {'ok': True})

    def test_missing_or_invalid_token_is_401(self):
        self.assertEqual(self.client.get('/v1/me').status_code, 401)
        self.client.credentials(HTTP_AUTHORIZATION='Bearer garbage')
        self.assertEqual(self.client.get('/v1/me').status_code, 401)

    def test_new_user_is_404(self):
        self.login('a')
        self.assertEqual(self.client.get('/v1/me').status_code, 404)

    def test_profile_roundtrip(self):
        self.login('a')
        res = self.client.put('/v1/me/profile', VALID_PROFILE, format='json')
        self.assertEqual(res.status_code, 204)
        data = self.client.get('/v1/me').json()
        self.assertEqual(data['name'], 'Ada')
        self.assertEqual(data['userType'], 'UserType.parent')
        self.assertEqual(datetime.fromisoformat(data['createdAt']),
                         datetime(2026, 10, 13, 12, 0, tzinfo=UTC))
        self.assertIsNone(data['stats'])
        self.assertIsNone(data['lives'])

    def test_each_part_updates_without_clobbering_others(self):
        self.login('a')
        self.client.put('/v1/me/stats', VALID_STATS, format='json')
        self.client.put('/v1/me/rewards', VALID_REWARDS, format='json')
        self.client.put('/v1/me/lives', {'lives': 2}, format='json')
        data = self.client.get('/v1/me').json()
        self.assertEqual(data['stats'], VALID_STATS)
        self.assertEqual(data['rewards'], VALID_REWARDS)
        self.assertEqual(data['lives'], 2)

    def test_users_cannot_see_each_other(self):
        self.login('a')
        self.client.put('/v1/me/stats', VALID_STATS, format='json')
        self.login('b')
        self.assertEqual(self.client.get('/v1/me').status_code, 404)

    def test_uid_comes_from_token_not_body(self):
        self.login('a')
        self.client.put('/v1/me/profile', {**VALID_PROFILE, 'uid': 'victim'}, format='json')
        self.assertTrue(Profile.objects.filter(uid='a').exists())
        self.assertFalse(Profile.objects.filter(uid='victim').exists())

    def test_invalid_stats_are_rejected_and_not_saved(self):
        self.login('a')
        for bad in [
            {**VALID_STATS, 'pinHash': '1234'},
            {**VALID_STATS, 'totalCorrect': -1},
            {**VALID_STATS, 'difficultyHistory': [5]},
            {**VALID_STATS, 'childAge': 9},
            {k: v for k, v in VALID_STATS.items() if k != 'totalWrong'},
        ]:
            res = self.client.put('/v1/me/stats', bad, format='json')
            self.assertEqual(res.status_code, 400, bad)
        self.assertFalse(Profile.objects.filter(uid='a').exists())

    def test_rl_agent_state_round_trips_and_is_validated(self):
        self.login('a')
        rl = {'q': [[0.0, 1.25, 0.5], [-1.0, 1.5, 0.0], [0.0, 0.0, 0.0]],
              'n': [[0, 4, 1], [1, 6, 0], [0, 0, 0]], 'level': 1}
        res = self.client.put('/v1/me/stats', {**VALID_STATS, 'rlAgent': rl}, format='json')
        self.assertEqual(res.status_code, 204)
        self.assertEqual(self.client.get('/v1/me').json()['stats']['rlAgent'], rl)

        no_level = {k: v for k, v in rl.items() if k != 'level'}
        for ok in [None, no_level]:
            res = self.client.put('/v1/me/stats', {**VALID_STATS, 'rlAgent': ok}, format='json')
            self.assertEqual(res.status_code, 204, ok)
        for bad in [
            {**rl, 'q': [[0.0, 0.0], [0.0, 0.0, 0.0], [0.0, 0.0, 0.0]]},
            {**rl, 'n': [[-1, 0, 0], [0, 0, 0], [0, 0, 0]]},
            {**rl, 'q': rl['q'] + [[0.0, 0.0, 0.0]]},
            {**rl, 'level': 3},
        ]:
            res = self.client.put('/v1/me/stats', {**VALID_STATS, 'rlAgent': bad}, format='json')
            self.assertEqual(res.status_code, 400, bad)

    def test_plaintext_pin_is_never_stored(self):
        self.login('a')
        self.client.put('/v1/me/stats', {**VALID_STATS, 'pin': '1234'}, format='json')
        self.assertNotIn('pin', self.client.get('/v1/me').json()['stats'])

    def test_pin_is_optional(self):
        self.login('a')
        no_pin = {k: v for k, v in VALID_STATS.items() if not k.startswith('pin')}
        self.assertEqual(self.client.put('/v1/me/stats', no_pin, format='json').status_code, 204)
        res = self.client.put('/v1/me/stats', {**no_pin, 'pinHash': None, 'pinSalt': None},
                              format='json')
        self.assertEqual(res.status_code, 204)

    def test_delete_removes_only_own_data_and_is_idempotent(self):
        self.login('b')
        self.client.put('/v1/me/lives', {'lives': 3}, format='json')
        self.login('a')
        self.client.put('/v1/me/stats', VALID_STATS, format='json')

        self.assertEqual(self.client.delete('/v1/me').status_code, 204)
        self.assertEqual(self.client.get('/v1/me').status_code, 404)
        self.assertEqual(self.client.delete('/v1/me').status_code, 204)
        self.assertTrue(Profile.objects.filter(uid='b').exists())

    def test_delete_requires_token(self):
        self.assertEqual(self.client.delete('/v1/me').status_code, 401)

    def test_migration_strips_plaintext_pin(self):
        Profile.objects.create(uid='old', stats={'pin': '1234', 'totalCorrect': 1})
        migration = importlib.import_module('api.migrations.0002_remove_plaintext_pin')
        migration.remove_plaintext_pin(django_apps, None)
        self.assertEqual(Profile.objects.get(uid='old').stats, {'totalCorrect': 1})

    def test_word_progress_roundtrip(self):
        self.login('a')
        body = {'words': {
            'kedi': {'word': 'Kedi', 'box': 2, 'seen': 5, 'wrong': 1, 'last': 1760000000000},
            'muhabbet kuşu': {'word': 'Muhabbet kuşu', 'box': 0, 'seen': 2, 'wrong': 2, 'last': 1},
        }}
        self.assertEqual(self.client.put('/v1/me/progress', body, format='json').status_code, 204)
        self.assertEqual(self.client.get('/v1/me').json()['wordProgress'], body['words'])

    def test_word_progress_is_validated(self):
        self.login('a')
        state = {'word': 'Kedi', 'box': 2, 'seen': 5, 'wrong': 1, 'last': 1}
        for bad in [
            {'words': {'kedi': {**state, 'box': 9}}},
            {'words': {'kedi': {**state, 'seen': -1}}},
            {'words': {'kedi': {k: v for k, v in state.items() if k != 'box'}}},
            {'words': {f'w{i}': state for i in range(501)}},
            {'words': 'kedi'},
        ]:
            self.assertEqual(self.client.put('/v1/me/progress', bad, format='json').status_code, 400)

    def test_rate_limit_is_per_user(self):
        with mock.patch.object(FirebaseUserRateThrottle, 'rate', '3/min', create=True):
            self.login('a')
            for _ in range(3):
                self.assertEqual(self.client.put('/v1/me/lives', {'lives': 1},
                                                 format='json').status_code, 204)
            res = self.client.get('/v1/me')
            self.assertEqual(res.status_code, 429)
            self.assertIn('Retry-After', res)
            # Başka kullanıcı etkilenmez; sağlık kontrolü hiç sayılmaz.
            self.login('b')
            self.assertEqual(self.client.get('/v1/me').status_code, 404)
            self.client.credentials()
            for _ in range(5):
                self.assertEqual(self.client.get('/health').status_code, 200)

    def test_lives_bounds(self):
        self.login('a')
        self.assertEqual(self.client.put('/v1/me/lives', {'lives': 6}, format='json').status_code, 400)
        self.assertEqual(self.client.put('/v1/me/lives', {'lives': 0}, format='json').status_code, 204)
        self.assertEqual(self.client.get('/v1/me').json()['lives'], 0)


@override_settings(SECURE_SSL_REDIRECT=True)
class HttpsRedirectTests(APITestCase):
    def test_healthcheck_over_plain_http_is_not_redirected(self):
        self.assertEqual(self.client.get('/health').status_code, 200)
        self.assertEqual(self.client.get('/v1/me').status_code, 301)


class RealVerifierTests(APITestCase):
    def setUp(self):
        # Railway'de Google varsayılan kimliği (ADC) yok; geliştirici
        # makinesindeki gcloud girişi testi yanıltmasın.
        patcher = mock.patch('google.auth.default',
                             side_effect=DefaultCredentialsError('ADC yok'))
        patcher.start()
        self.addCleanup(patcher.stop)

    def test_malformed_token_is_401_without_google_credentials(self):
        self.client.credentials(HTTP_AUTHORIZATION='Bearer not-a-jwt')
        self.assertEqual(self.client.get('/v1/me').status_code, 401)


class AdminRemovedTests(APITestCase):
    def test_admin_panel_does_not_exist(self):
        for path in ['/admin/', '/admin/login/', '/static/admin/css/base.css']:
            self.assertEqual(self.client.get(path).status_code, 404, path)
