import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../services/firestore/firestore_service.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirestoreService _firestore;
  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;

  AuthRepositoryImpl(this._firestore);

  @override
  Future<User?> getCurrentUser() async {
    final fbUser = _auth.currentUser;
    if (fbUser == null) return null;
    final data = await _firestore.loadUserData(fbUser.uid);
    return _buildUser(fbUser, data);
  }

  @override
  Future<User> login(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final data = await _firestore.loadUserData(cred.user!.uid);
      return _buildUser(cred.user!, data);
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
      await _firestore.createUserProfile(
        fbUser.uid,
        name: name,
        email: email,
        userType: userType.toString(),
        createdAt: now.toIso8601String(),
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
      default:
        return 'Bir hata oluştu: $code';
    }
  }
}