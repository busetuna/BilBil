import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

class FirebaseAuthService {
  final firebase_auth.FirebaseAuth _firebaseAuth = firebase_auth.FirebaseAuth.instance;

  // Şifre sıfırlama email'i gönder
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw Exception('Bu email adresi ile kayıtlı kullanıcı bulunamadı');
      } else if (e.code == 'invalid-email') {
        throw Exception('Geçersiz email adresi');
      } else {
        throw Exception('Email gönderilemedi: ${e.message}');
      }
    }
  }

  // Firebase'de kullanıcı oluştur
  Future<void> createUserWithEmailAndPassword(String email, String password) async {
    try {
      await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        throw Exception('Şifre çok zayıf');
      } else if (e.code == 'email-already-in-use') {
        throw Exception('Bu email adresi zaten kullanılıyor');
      } else {
        throw Exception('Kayıt başarısız: ${e.message}');
      }
    }
  }

  // Firebase ile login
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw Exception('Kullanıcı bulunamadı');
      } else if (e.code == 'wrong-password') {
        throw Exception('Hatalı şifre');
      } else {
        throw Exception('Giriş başarısız: ${e.message}');
      }
    }
  }

  // Çıkış yap
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
}