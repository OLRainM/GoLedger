import '../core/http/api_client.dart';
import '../core/http/api_response.dart';
import '../models/user.dart';

class AuthService {
  final _client = ApiClient();

  /// 注册
  Future<ApiResponse<User>> register({
    required String email,
    required String password,
    String? nickname,
  }) async {
    final body = <String, dynamic>{
      'email': email,
      'password': password,
    };
    if (nickname != null && nickname.isNotEmpty) {
      body['nickname'] = nickname;
    }
    final resp = await _client.post('/api/auth/register', data: body);
    return ApiResponse.fromJson(
      resp.data as Map<String, dynamic>,
      (data) => User.fromJson(data as Map<String, dynamic>),
    );
  }

  /// 登录
  Future<ApiResponse<LoginResult>> login({
    required String email,
    required String password,
  }) async {
    final resp = await _client.post('/api/auth/login', data: {
      'email': email,
      'password': password,
    });
    return ApiResponse.fromJson(
      resp.data as Map<String, dynamic>,
      (data) => LoginResult.fromJson(data as Map<String, dynamic>),
    );
  }
}

