// GoLedger 全局常量

class AppConstants {
  AppConstants._();

  /// 后端 API 基础地址
  /// 通过编译参数注入: flutter run --dart-define=BASE_URL=http://your-server:8080
  /// 未传参时默认使用 Android 模拟器回环地址
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://10.0.2.2:8080',
  );

  /// Token 在 SharedPreferences 中的 key
  static const String tokenKey = 'auth_token';

  /// 连接超时 (毫秒)
  static const int connectTimeout = 10000;

  /// 接收超时 (毫秒)
  static const int receiveTimeout = 15000;

  /// 默认分页大小
  static const int defaultPageSize = 20;

  /// 最大分页大小
  static const int maxPageSize = 50;

  /// 账户类型枚举
  static const List<String> accountTypes = [
    'cash',
    'bank_card',
    'e_wallet',
    'other',
  ];

  /// 账户类型中文映射
  static const Map<String, String> accountTypeLabels = {
    'cash': '现金',
    'bank_card': '银行卡',
    'e_wallet': '电子钱包',
    'other': '其他',
  };

  /// 流水类型
  static const String typeIncome = 'income';
  static const String typeExpense = 'expense';
}

/// 金额工具: 分 <-> 元
class MoneyUtil {
  MoneyUtil._();

  /// 分 -> 元 (显示用)
  static String fenToYuan(int fen) {
    final yuan = fen / 100;
    return yuan.toStringAsFixed(2);
  }

  /// 元 -> 分 (提交用)
  static int yuanToFen(double yuan) {
    return (yuan * 100).round();
  }

  /// 格式化金额显示 (带 ¥ 前缀)
  static String format(int fen) {
    return '¥${fenToYuan(fen)}';
  }
}

