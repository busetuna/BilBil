import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../services/api/api_service.dart';

class AuthRepositoryImpl implements AuthRepository {
  final ApiService _api;
  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;

  AuthRepositoryImpl(this._api);

  // Giriş ve açılışta API beklenmez: ekranlar yalnızca adı kullanır ve o
  // Firebase'de de var. Beklemek açılışı internete bağlıyordu; yavaş ağda
  // açılış ekranının zamanlayıcısıyla yarışıp girişli kullanıcıyı giriş
  // ekranına atabiliyordu. Bulut verisi AccountSync ile ayrıca yüklenir.
  @override
  Future<User?> getCurrentUser() async {
    final fbUser = _auth.currentUser;
    if (fbUser == null) return null;
    return _buildUser(fbUser, null);
  }

  @override
  Future<User> login(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _buildUser(cred.user!, null);
    } on fb.FirebaseAuthException catch (e) {
      throw Exception(_authError(e.code));
    }
  }

  @override
  Future<User> register(
    String email,
    String password,
    String name,
    UserType userType,
  ) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final fbUser = cred.user!;
      await fbUser.updateDisplayName(name);

      final now = DateTime.now();
      await _api.createUserProfile(
        name: name,
        email: email,
        userType: userType.toString(),
        createdAt: now,
      );

      return User(
        id: fbUser.uid,
        email: email,
        name: name,
        userType: userType,
        createdAt: now,
      );
    } on fb.FirebaseAuthException catch (e) {
      throw Exception(_authError(e.code));
    }
  }

  @override
  Future<void> logout() async {
    await _auth.signOut();
  }

  @override
  Future<bool> isLoggedIn() async => _auth.currentUser != null;

  @override
  Future<void> reauthenticate(String password) async {
    final user = _auth.currentUser;
    final email = user?.email;
    if (user == null || email == null) throw Exception('Oturum bulunamadı');
    try {
      await user.reauthenticateWithCredential(
          fb.EmailAuthProvider.credential(email: email, password: password));
    } on fb.FirebaseAuthException catch (e) {
      throw Exception(_authError(e.code));
    }
  }

  @override
  Future<void> deleteAccount(String password) async {
    await reauthenticate(password);
    // Önce sunucudaki veri: silinemezse Firebase hesabı da silinmez, yoksa
    // hesabı olmayan sahipsiz veri kalırdı.
    if (!await _api.deleteUserData()) {
      throw Exception(
          'Sunucuya ulaşılamadı, hesap silinmedi. İnternet bağlantını kontrol et.');
    }
    try {
      await _auth.currentUser!.delete();
    } on fb.FirebaseAuthException catch (e) {
      throw Exception(_authError(e.code));
    }
  }

  User _buildUser(fb.User fbUser, Map<String, dynamic>? data) {
    return User(
      id: fbUser.uid,
      email: fbUser.email ?? '',
      name: data?['name'] ?? fbUser.displayName ?? '',
      userType: UserType.values.firstWhere(
        (t) => t.toString() == (data?['userType'] ?? ''),
        orElse: () => UserType.child,
      ),
      createdAt: DateTime.tryParse(data?['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  String _authError(String code) {
    switch (code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email veya şifre hatalı';
      case 'email-already-in-use':
        return 'Bu email zaten kullanılıyor';
      case 'weak-password':
        return 'Şifre en az 6 karakter olmalı';
      case 'invalid-email':
        return 'Geçersiz email adresi';
      case 'too-many-requests':
        return 'Çok fazla deneme. Lütfen bekleyin.';
      case 'network-request-failed':
        return 'İnternet bağlantısı yok';
      case 'requires-recent-login':
        return 'Güvenlik için çıkış yapıp tekrar giriş yapman gerekiyor';
      default:
        return 'Bir hata oluştu: $code';
    }
  }
}