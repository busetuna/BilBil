import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class RegisterUseCase {
  final AuthRepository repository;

  RegisterUseCase(this.repository);

  Future<User> call({
    required String email,
    required String password,
    required String name,
    required UserType userType,
  }) async {
    if (email.isEmpty || password.isEmpty || name.isEmpty) {
      throw Exception('Tüm alanlar doldurulmalıdır');
    }

    if (!_isValidEmail(email)) {
      throw Exception('Geçerli bir email adresi girin');
    }

    if (password.length < 6) {
      throw Exception('Şifre en az 6 karakter olmalıdır');
    }

    if (name.length < 2) {
      throw Exception('İsim en az 2 karakter olmalıdır');
    }

    return await repository.register(email, password, name, userType);
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}