import '../entities/user.dart';

abstract class AuthRepository {
  Future<User?> getCurrentUser();
  Future<User> login(String email, String password);
  Future<User> register(String email, String password, String name, UserType userType);
  Future<void> logout();
  Future<bool> isLoggedIn();

  /// Hassas işlemlerden önce hesap şifresini doğrular; yanlışsa hata fırlatır.
  Future<void> reauthenticate(String password);

  /// Hesabı ve sunucudaki tüm verisini kalıcı olarak siler.
  Future<void> deleteAccount(String password);
}