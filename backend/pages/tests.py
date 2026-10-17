from django.test import TestCase, override_settings


class PublicPagesTests(TestCase):
    def test_pages_are_public_and_show_contact(self):
        for path in ['/', '/gizlilik', '/hesap-sil']:
            res = self.client.get(path)
            self.assertEqual(res.status_code, 200, path)
            self.assertContains(res, 'btuna194@gmail.com')
            self.assertContains(res, 'href="/gizlilik"')
            self.assertContains(res, 'href="/hesap-sil"')

    @override_settings(CONTACT_EMAIL='destek@example.com')
    def test_contact_email_comes_from_settings(self):
        self.assertContains(self.client.get('/gizlilik'), 'destek@example.com')

    def test_privacy_policy_covers_what_play_asks_for(self):
        res = self.client.get('/gizlilik')
        for text in ['Ses kaydı saklanmaz', 'AdMob', 'kişiselleştirilmiş reklam gösterilmez',
                     'Hesabımı Sil', '/hesap-sil', 'KVKK', 'Son güncelleme']:
            self.assertContains(res, text)

    def test_delete_page_runs_same_order_as_app(self):
        html = self.client.get('/hesap-sil').content.decode()
        self.assertIn('AIzaSyALLkMiJMGu0fIhKEJbKmiMk45aODBTY7M', html)
        sign_in = html.index('"signInWithPassword"')
        server_delete = html.index('fetch("/v1/me"')
        firebase_delete = html.index('identity("delete"')
        self.assertLess(sign_in, server_delete)
        self.assertLess(server_delete, firebase_delete,
                        'önce sunucudaki veri, sonra Firebase hesabı silinmeli')

    def test_delete_page_cannot_be_framed(self):
        # Tıklama tuzağına (clickjacking) karşı başka sitede iframe'e gömülemez.
        self.assertEqual(self.client.get('/hesap-sil')['X-Frame-Options'], 'DENY')

    def test_delete_page_sends_only_origin_as_referrer(self):
        # Web API anahtarı alan adıyla kısıtlanabilsin diye Google'a kök adres
        # gider; yol ve sorgu gitmez.
        self.assertEqual(self.client.get('/hesap-sil')['Referrer-Policy'],
                         'strict-origin-when-cross-origin')

    def test_app_ads_txt(self):
        res = self.client.get('/app-ads.txt')
        self.assertEqual(res.status_code, 200)
        self.assertTrue(res['Content-Type'].startswith('text/plain'))
        self.assertEqual(res.content.decode(),
                         'google.com, pub-9093997172830553, DIRECT, f08c47fec0942fa0\n')
