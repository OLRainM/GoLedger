import 'package:dio/dio.dart';
import '../constants.dart';
import '../storage/token_storage.dart';

/// Dio HTTP 客户端封装
class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio _dio;

  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: Duration(milliseconds: AppConstants.connectTimeout),
        receiveTimeout: Duration(milliseconds: AppConstants.receiveTimeout),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // 请求拦截: 自动添加 Token
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = TokenStorage.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          // 401 时清除 Token, 触发路由守卫跳转登录页
          if (error.response?.statusCode == 401) {
            TokenStorage.removeToken();
          }
          handler.next(error);
        },
      ),
    );
  }

  Dio get dio => _dio;

  /// 更新 baseUrl (用于设置页面切换环境)
  void setBaseUrl(String url) {
    _dio.options.baseUrl = url;
  }

  /// GET 请求
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) {
    return _dio.get(path, queryParameters: queryParameters);
  }

  /// POST 请求
  Future<Response> post(String path, {dynamic data}) {
    return _dio.post(path, data: data);
  }

  /// PUT 请求
  Future<Response> put(String path, {dynamic data}) {
    return _dio.put(path, data: data);
  }

  /// DELETE 请求
  Future<Response> delete(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) {
    return _dio.delete(path, queryParameters: queryParameters);
  }
}

