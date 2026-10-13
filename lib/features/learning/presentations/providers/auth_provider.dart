import 'package:flutter/material.dart';
import '../../../../domain/entities/user.dart';
import '../../../../domain/usecases/login_usecase.dart';
import '../../../../domain/usecases/logout_usecase.dart';
import '../../../../domain/usecases/register_usecase.dart';
import '../../../../domain/repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  final LoginUseCase loginUseCase;
  final RegisterUseCase registerUseCase;
  final LogoutUseCase logoutUseCase;
  final AuthRepository authRepository;
  final Future<void> Function(String uid) onSignedIn;
  final Future<void> Function() onSignedOut;
  final Future<void> Function() onAccountDeleted;

  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _currentUser != null;

  AuthProvider({
    required this.loginUseCase,
    required this.registerUseCase,
    required this.logoutUseCase,
    required this.authRepository,
    required this.onSignedIn,
    required this.onSignedOut,
    required this.onAccountDeleted,
  }) {
    _checkCurrentUser();
  }

  Future<void> _checkCurrentUser() async {
    _currentUser = await authRepository.getCurrentUser();
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();
    try {
      _currentUser = await loginUseCase(email, password);
      await onSignedIn(_currentUser!.id);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      _setLoading(false);
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String name,
    required UserType userType,
  }) async {
    _setLoading(true);
    _clearError();
    try {
      _currentUser = await registerUseCase(
        email: email,
        password: password,
        name: name,
        userType: userType,
      );
      await onSignedIn(_currentUser!.id);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      _setLoading(false);
      return false;
    }
  }

  Future<void> logout() async {
    await logoutUseCase();
    await onSignedOut();
    _currentUser = null;
    notifyListeners();
  }

  /// Hesap şifresini doğrular (ör. PIN'i unutan ebeveyn için).
  /// Yanlışsa false döner, sebebi [errorMessage]'dadır.
  Future<bool> reauthenticate(String password) async {
    _clearError();
    try {
      await authRepository.reauthenticate(password);
      return true;
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  /// Hesabı, sunucudaki ve cihazdaki tüm verisiyle siler.
  /// Başarısızsa false döner, sebebi [errorMessage]'dadır.
  Future<bool> deleteAccount(String password) async {
    _clearError();
    try {
      await authRepository.deleteAccount(password);
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      return false;
    }
    await onAccountDeleted();
    _currentUser = null;
    notifyListeners();
    return true;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void clearError() {
    _clearError();
    notifyListeners();
  }
}