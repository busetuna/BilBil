import 'package:hive/hive.dart';
import '../../domain/entities/user.dart';

part 'user_model.g.dart';

@HiveType(typeId: 0)
class UserModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String email;

  @HiveField(2)
  final String name;

  @HiveField(3)
  final String userTypeString;

  @HiveField(4)
  final String createdAtString;

  @HiveField(5)
  final String? profileImageUrl;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.userTypeString,
    required this.createdAtString,
    this.profileImageUrl,
  });

  // Factory constructor - Entity'den oluştur
  factory UserModel.fromEntity(User user) {
    return UserModel(
      id: user.id,
      email: user.email,
      name: user.name,
      userTypeString: user.userType.toString(),
      createdAtString: user.createdAt.toIso8601String(),
      profileImageUrl: user.profileImageUrl,
    );
  }

  // Entity'ye dönüştür
  User toEntity() {
    return User(
      id: id,
      email: email,
      name: name,
      userType: UserType.values.firstWhere(
            (e) => e.toString() == userTypeString,
      ),
      createdAt: DateTime.parse(createdAtString),
      profileImageUrl: profileImageUrl,
    );
  }

  // Getter'lar (kolaylık için)
  UserType get userType => UserType.values.firstWhere(
        (e) => e.toString() == userTypeString,
  );

  DateTime get createdAt => DateTime.parse(createdAtString);

  // JSON dönüşümleri
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'userType': userTypeString,
      'createdAt': createdAtString,
      'profileImageUrl': profileImageUrl,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      userTypeString: json['userType'] as String,
      createdAtString: json['createdAt'] as String,
      profileImageUrl: json['profileImageUrl'] as String?,
    );
  }
}