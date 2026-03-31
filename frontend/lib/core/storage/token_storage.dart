import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';

/// Token 持久化存储
class TokenStorage {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

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
}

