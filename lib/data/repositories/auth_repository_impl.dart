import 'package:uuid/uuid.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/local/auth_local_datasource.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthLocalDataSource localDataSource;

  AuthRepositoryImpl(this.localDataSource);

  @override
  Future<User?> getCurrentUser() async {
    final userModel = await localDataSource.getCurrentUser();
    return userModel?.toEntity();
  }

  @override
  Future<User> login(String email, String password) async {
    // Kullanıcıyı bul
    final userModel = await localDataSource.findUserByEmail(email);

    if (userModel == null) {
      throw Exception('Kullanıcı bulunamadı. Lütfen önce kayıt olun.');
    }

    // Basit şifre kontrolü (gerçek uygulamada hash karşılaştırması yapılmalı)
    final isValid = await localDataSource.validateCredentials(email, password);
    if (!isValid) {
      throw Exception('Email veya şifre hatalı');
    }

    // Kullanıcıyı current user olarak kaydet
    await localDataSource.saveCurrentUser(userModel);

    return userModel.toEntity();
  }

  @override
  Future<User> register(
      String email,
      String password,
      String name,
      UserType userType,
      ) async {
    // Email'in daha önce kullanılıp kullanılmadığını kontrol et
    final existingUser = await localDataSource.findUserByEmail(email);
    if (existingUser != null) {
      throw Exception('Bu email adresi zaten kullanılıyor');
    }

    // Yeni kullanıcı oluştur
    final newUser = UserModel(
      id: const Uuid().v4(),
      email: email,
      name: name,
      userTypeString: userType.toString(),              // ✅ Doğru
      createdAtString: DateTime.now().toIso8601String(), // ✅ Doğru
    );

    // Kullanıcıyı kaydet
    await localDataSource.saveUser(newUser);
    await localDataSource.saveCurrentUser(newUser);

    return newUser.toEntity();
  }

  @override
  Future<void> logout() async {
    await localDataSource.clearCurrentUser();
  }

  @override
  Future<bool> isLoggedIn() async {
    final user = await localDataSource.getCurrentUser();
    return user != null;
  }
}