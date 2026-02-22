import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  Future<User> call(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      throw Exception('Email ve şifre boş olamaz');
    }

    if (!_isValidEmail(email)) {
      throw Exception('Geçerli bir email adresi girin');
    }

    if (password.length < 6) {
      throw Exception('Şifre en az 6 karakter olmalıdır');
    }

    return await repository.login(email, password);
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}