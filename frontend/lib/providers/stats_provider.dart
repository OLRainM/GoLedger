import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/monthly_stats.dart';
import '../services/stats_service.dart';

final statsProvider =
    StateNotifierProvider<StatsNotifier, AsyncValue<MonthlyStats>>((ref) {
  return StatsNotifier();
});

class StatsNotifier extends StateNotifier<AsyncValue<MonthlyStats>> {
  final _service = StatsService();

  StatsNotifier() : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load({int? year, int? month}) async {
    state = const AsyncValue.loading();
    try {
      final resp = await _service.monthly(year: year, month: month);
      if (resp.isSuccess && resp.data != null) {
        state = AsyncValue.data(resp.data!);
      } else {
        state = AsyncValue.error(resp.message, StackTrace.current);
      }
    } on DioException catch (e, st) {
      state = AsyncValue.error(e.message ?? '加载失败', st);
    }
  }
}

