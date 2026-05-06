import 'package:dio/dio.dart';
import '../constants.dart';
import '../storage/token_storage.dart';

/// Dio HTTP 客户端封装（支持域名失败自动降级到 IP）
class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio _dio;
  String _currentBaseUrl = AppConstants.baseUrl;
  int _currentServerIndex = 0; // 0=主地址, 1+=备用地址

  ApiClient._internal() {
    _initializeClient();
  }

  void _initializeClient() async {
    // 尝试从缓存读取上次可用的服务器地址
    final cachedUrl = TokenStorage.getCurrentServerUrl();
    if (cachedUrl != null && cachedUrl.isNotEmpty) {
      _currentBaseUrl = cachedUrl;
      // 找到对应的索引
      if (cachedUrl == AppConstants.baseUrl) {
        _currentServerIndex = 0;
      } else {
        final index = AppConstants.fallbackUrls.indexOf(cachedUrl);
        if (index >= 0) {
          _currentServerIndex = index + 1;
        }
      }
    }

    _dio = Dio(
      BaseOptions(
        baseUrl: _currentBaseUrl,
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
        onError: (error, handler) async {
          // 401 时清除 Token, 触发路由守卫跳转登录页
          if (error.response?.statusCode == 401) {
            TokenStorage.removeToken();
            handler.next(error);
            return;
          }

          // 网络错误或连接超时，尝试切换到备用地址
          if (_shouldTryFallback(error)) {
            final switched = await _switchToNextServer();
            if (switched) {
              // 用新地址重试请求
              try {
                final response = await _dio.fetch(error.requestOptions);
                handler.resolve(response);
                return;
              } catch (e) {
                // 重试失败，继续传递原错误
              }
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  Dio get dio => _dio;

  /// 判断是否应该尝试备用地址
  bool _shouldTryFallback(DioException error) {
    // 连接超时、接收超时、连接错误时尝试切换
    return error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.unknown;
  }

  /// 切换到下一个可用服务器
  Future<bool> _switchToNextServer() async {
    final totalServers = 1 + AppConstants.fallbackUrls.length;
    final startIndex = _currentServerIndex;

    // 尝试所有备用地址（循环一圈）
    for (int i = 1; i < totalServers; i++) {
      _currentServerIndex = (startIndex + i) % totalServers;

      String newUrl;
      if (_currentServerIndex == 0) {
        newUrl = AppConstants.baseUrl;
      } else {
        newUrl = AppConstants.fallbackUrls[_currentServerIndex - 1];
      }

      // 测试新地址是否可用
      if (await _testServerConnection(newUrl)) {
        _currentBaseUrl = newUrl;
        _dio.options.baseUrl = newUrl;
        // 持久化当前可用地址
        await TokenStorage.saveCurrentServerUrl(newUrl);
        return true;
      }
    }

    return false; // 所有地址都不可用
  }

  /// 测试服务器连接（发送健康检查请求）
  Future<bool> _testServerConnection(String url) async {
    try {
      final testDio = Dio(BaseOptions(
        baseUrl: url,
        connectTimeout: const Duration(seconds: 3),
        receiveTimeout: const Duration(seconds: 3),
      ));
      // 尝试访问健康检查端点（如果没有则用登录接口测试连通性）
      await testDio.get('/health');
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 获取当前使用的服务器地址
  String getCurrentServerUrl() => _currentBaseUrl;

  /// 手动切换服务器地址（用于设置页面）
  Future<void> switchServer(String url) async {
    _currentBaseUrl = url;
    _dio.options.baseUrl = url;
    await TokenStorage.saveCurrentServerUrl(url);
  }

  /// 更新 baseUrl (用于设置页面切换环境)
  void setBaseUrl(String url) {
    _currentBaseUrl = url;
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

