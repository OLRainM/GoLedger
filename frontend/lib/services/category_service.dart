import '../core/http/api_client.dart';
import '../core/http/api_response.dart';
import '../models/category.dart';

class CategoryService {
  final _client = ApiClient();

  /// 创建分类
  Future<ApiResponse<Category>> create({
    required String name,
    required String type,
  }) async {
    final resp = await _client.post('/api/categories', data: {
      'name': name,
      'type': type,
    });
    return ApiResponse.fromJson(
      resp.data as Map<String, dynamic>,
      (data) => Category.fromJson(data as Map<String, dynamic>),
    );
  }

  /// 分类列表
  Future<ApiResponse<List<Category>>> list({String? type}) async {
    final params = <String, dynamic>{};
    if (type != null) params['type'] = type;

    final resp = await _client.get('/api/categories', queryParameters: params);
    return ApiResponse.fromJson(
      resp.data as Map<String, dynamic>,
      (data) => (data as List<dynamic>)
          .map((e) => Category.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// 编辑分类
  Future<ApiResponse<Category>> update(int id, {
    String? name,
    int? isActive,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (isActive != null) body['is_active'] = isActive;

    final resp = await _client.put('/api/categories/$id', data: body);
    return ApiResponse.fromJson(
      resp.data as Map<String, dynamic>,
      (data) => Category.fromJson(data as Map<String, dynamic>),
    );
  }
}

