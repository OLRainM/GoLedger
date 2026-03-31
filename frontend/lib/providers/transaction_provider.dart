import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction.dart';
import '../services/transaction_service.dart';

/// 流水列表状态
class TransactionListState {
  final List<Transaction> items;
  final int total;
  final int page;
  final int pageSize;
  final bool isLoading;
  final String? error;

  TransactionListState({
    this.items = const [],
    this.total = 0,
    this.page = 1,
    this.pageSize = 20,
    this.isLoading = false,
    this.error,
  });

  bool get hasMore => items.length < total;

  TransactionListState copyWith({
    List<Transaction>? items,
    int? total,
    int? page,
    int? pageSize,
    bool? isLoading,
    String? error,
  }) {
    return TransactionListState(
      items: items ?? this.items,
      total: total ?? this.total,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

final transactionListProvider =
    StateNotifierProvider<TransactionListNotifier, TransactionListState>((ref) {
  return TransactionListNotifier();
});

class TransactionListNotifier extends StateNotifier<TransactionListState> {
  final _service = TransactionService();

  TransactionListNotifier() : super(TransactionListState()) {
    load();
  }

  Future<void> load({
    int? accountId,
    int? categoryId,
    String? type,
    String? startDate,
    String? endDate,
  }) async {
    state = state.copyWith(isLoading: true, error: null, page: 1);
    try {
      final resp = await _service.list(
        page: 1,
        pageSize: state.pageSize,
        accountId: accountId,
        categoryId: categoryId,
        type: type,
        startDate: startDate,
        endDate: endDate,
      );
      if (resp.isSuccess && resp.data != null) {
        final data = resp.data!;
        state = state.copyWith(
          items: data.list,
          total: data.total,
          page: 1,
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false, error: resp.message);
      }
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message ?? '加载失败');
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true);
    try {
      final nextPage = state.page + 1;
      final resp = await _service.list(page: nextPage, pageSize: state.pageSize);
      if (resp.isSuccess && resp.data != null) {
        final data = resp.data!;
        state = state.copyWith(
          items: [...state.items, ...data.list],
          total: data.total,
          page: nextPage,
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<bool> create({
    required int accountId,
    required int categoryId,
    required String type,
    required int amount,
    String? note,
    required String transactionAt,
  }) async {
    try {
      final resp = await _service.create(
        accountId: accountId,
        categoryId: categoryId,
        type: type,
        amount: amount,
        note: note,
        transactionAt: transactionAt,
      );
      if (resp.isSuccess) {
        await load();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> delete(int id, int version) async {
    try {
      final resp = await _service.delete(id, version: version);
      if (resp.isSuccess) {
        await load();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}

