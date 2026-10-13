from datetime import UTC, datetime
from unittest import mock

from django.test import override_settings
from rest_framework.test import APITestCase

from .models import Profile

VALID_STATS = {
    'totalCorrect': 12,
    'totalWrong': 3,
    'difficultyHistory': [0, 0, 1, 1, 2],
    'startingDifficulty': 0,
    'pin': '1234',
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
            {**VALID_STATS, 'pin': '12'},
            {**VALID_STATS, 'totalCorrect': -1},
            {**VALID_STATS, 'difficultyHistory': [5]},
            {**VALID_STATS, 'childAge': 9},
            {k: v for k, v in VALID_STATS.items() if k != 'totalWrong'},
        ]:
            res = self.client.put('/v1/me/stats', bad, format='json')
            self.assertEqual(res.status_code, 400, bad)
        self.assertFalse(Profile.objects.filter(uid='a').exists())

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
    def test_malformed_token_is_401_without_network(self):
        self.client.credentials(HTTP_AUTHORIZATION='Bearer not-a-jwt')
        self.assertEqual(self.client.get('/v1/me').status_code, 401)
