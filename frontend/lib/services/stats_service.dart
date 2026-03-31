import '../core/http/api_client.dart';
import '../core/http/api_response.dart';
import '../models/monthly_stats.dart';

class StatsService {
  final _client = ApiClient();

  /// 月度统计
  Future<ApiResponse<MonthlyStats>> monthly({int? year, int? month}) async {
    final params = <String, dynamic>{};
    if (year != null) params['year'] = year;
    if (month != null) params['month'] = month;

    final resp = await _client.get('/api/stats/monthly', queryParameters: params);
    return ApiResponse.fromJson(
      resp.data as Map<String, dynamic>,
      (data) => MonthlyStats.fromJson(data as Map<String, dynamic>),
    );
  }
}

