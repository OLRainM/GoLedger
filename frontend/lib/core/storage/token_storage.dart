import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';

/// Token 及凭证持久化存储
class TokenStorage {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ────────── Token ──────────

  static Future<void> saveToken(String token) async {
    await _prefs?.setString(AppConstants.tokenKey, token);
  }

  static String? getToken() {
    return _prefs?.getString(AppConstants.tokenKey);
  }

  static Future<void> removeToken() async {
    await _prefs?.remove(AppConstants.tokenKey);
  }

  static bool hasToken() {
    final token = getToken();
    return token != null && token.isNotEmpty;
  }

  // ────────── 记住密码 ──────────

  /// 保存登录凭证（邮箱 + 密码）
  static Future<void> saveCredentials(String email, String password) async {
    await _prefs?.setBool(AppConstants.rememberKey, true);
    await _prefs?.setString(AppConstants.savedEmailKey, email);
    await _prefs?.setString(AppConstants.savedPasswordKey, password);
  }

  /// 清除保存的登录凭证
  static Future<void> clearCredentials() async {
    await _prefs?.setBool(AppConstants.rememberKey, false);
    await _prefs?.remove(AppConstants.savedEmailKey);
    await _prefs?.remove(AppConstants.savedPasswordKey);
  }

  /// 是否勾选了"记住密码"
  static bool isRememberPassword() {
    return _prefs?.getBool(AppConstants.rememberKey) ?? false;
  }

  /// 获取保存的邮箱
  static String? getSavedEmail() {
    return _prefs?.getString(AppConstants.savedEmailKey);
  }

  /// 获取保存的密码
  static String? getSavedPassword() {
    return _prefs?.getString(AppConstants.savedPasswordKey);
  }
}

