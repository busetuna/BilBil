import '../entities/user.dart';

abstract class AuthRepository {
  Future<User?> getCurrentUser();
  Future<User> login(String email, String password);
  Future<User> register(String email, String password, String name, UserType userType);
  Future<void> logout();
  Future<bool> isLoggedIn();
}