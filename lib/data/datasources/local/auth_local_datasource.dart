import 'package:hive/hive.dart';
import '../../models/user_model.dart';

class AuthLocalDataSource {
  static const String _boxName = 'authBox';
  static const String _userKey = 'currentUser';
  static const String _usersKey = 'users';

  Future<Box> _getBox() async {
    if (!Hive.isBoxOpen(_boxName)) {
      return await Hive.openBox(_boxName);
    }
    return Hive.box(_boxName);
  }

  Future<UserModel?> getCurrentUser() async {
    final box = await _getBox();
    final userData = box.get(_userKey);
    if (userData != null && userData is UserModel) {
      return userData;
    }
    return null;
  }

  Future<void> saveCurrentUser(UserModel user) async {
    final box = await _getBox();
    await box.put(_userKey, user);
  }

  Future<void> clearCurrentUser() async {
    final box = await _getBox();
    await box.delete(_userKey);
  }

  Future<List<UserModel>> getAllUsers() async {
    final box = await _getBox();
    final usersData = box.get(_usersKey);

    if (usersData != null && usersData is List) {
      return usersData.cast<UserModel>();
    }
    return [];
  }

  Future<void> saveUser(UserModel user) async {
    final box = await _getBox();
    final users = await getAllUsers();

    // Aynı email'e sahip kullanıcı varsa güncelle
    final existingIndex = users.indexWhere((u) => u.email == user.email);
    if (existingIndex != -1) {
      users[existingIndex] = user;
    } else {
      users.add(user);
    }

    await box.put(_usersKey, users);
  }

  Future<UserModel?> findUserByEmail(String email) async {
    final users = await getAllUsers();
    try {
      return users.firstWhere((user) => user.email == email);
    } catch (e) {
      return null;
    }
  }

  Future<bool> validateCredentials(String email, String password) async {
    final user = await findUserByEmail(email);
    // Gerçek uygulamada şifre hash'lenmiş olmalı
    // Şu an için basit kontrol yapıyoruz
    return user != null && password.length >= 6;
  }
}