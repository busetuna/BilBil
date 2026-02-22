class User {
  final String id;
  final String email;
  final String name;
  final UserType userType;
  final DateTime createdAt;
  final String? profileImageUrl;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.userType,
    required this.createdAt,
    this.profileImageUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'userType': userType.toString(),
      'createdAt': createdAt.toIso8601String(),
      'profileImageUrl': profileImageUrl,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      name: json['name'],
      userType: UserType.values.firstWhere(
            (e) => e.toString() == json['userType'],
      ),
      createdAt: DateTime.parse(json['createdAt']),
      profileImageUrl: json['profileImageUrl'],
    );
  }
}

enum UserType {
  child,
  parent,
}