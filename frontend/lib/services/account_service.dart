import '../core/http/api_client.dart';
import '../core/http/api_response.dart';
import '../models/account.dart';

class AccountService {
  final _client = ApiClient();

  /// 创建账户
  Future<ApiResponse<Account>> create({
    required String name,
    required String type,
    int initialBalance = 0,
  }) async {
    final resp = await _client.post('/api/accounts', data: {
      'name': name,
      'type': type,
      'initial_balance': initialBalance,
    });
    return ApiResponse.fromJson(
      resp.data as Map<String, dynamic>,
      (data) => Account.fromJson(data as Map<String, dynamic>),
    );
  }

  /// 账户列表
  Future<ApiResponse<List<Account>>> list() async {
    final resp = await _client.get('/api/accounts');
    return ApiResponse.fromJson(
      resp.data as Map<String, dynamic>,
      (data) => (data as List<dynamic>)
          .map((e) => Account.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// 编辑账户
  Future<ApiResponse<Account>> update(int id, {
    String? name,
    String? type,
    int? isActive,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (type != null) body['type'] = type;
    if (isActive != null) body['is_active'] = isActive;

    final resp = await _client.put('/api/accounts/$id', data: body);
    return ApiResponse.fromJson(
      resp.data as Map<String, dynamic>,
      (data) => Account.fromJson(data as Map<String, dynamic>),
    );
  }
}

