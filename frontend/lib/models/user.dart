class User {
  final int id;
  final String email;
  final String nickname;

  User({required this.id, required this.email, required this.nickname});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      email: json['email'] as String,
      nickname: (json['nickname'] ?? '') as String,
    );
  }
}

class LoginResult {
  final String token;
  final String expiresAt;

  LoginResult({required this.token, required this.expiresAt});

  factory LoginResult.fromJson(Map<String, dynamic> json) {
    return LoginResult(
      token: json['token'] as String,
      expiresAt: json['expires_at'] as String,
    );
  }
}

