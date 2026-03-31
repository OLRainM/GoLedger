import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/account.dart';
import '../services/account_service.dart';

final accountListProvider =
    StateNotifierProvider<AccountListNotifier, AsyncValue<List<Account>>>((ref) {
  return AccountListNotifier();
});

class AccountListNotifier extends StateNotifier<AsyncValue<List<Account>>> {
  final _service = AccountService();

  AccountListNotifier() : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final resp = await _service.list();
      if (resp.isSuccess && resp.data != null) {
        state = AsyncValue.data(resp.data!);
      } else {
        state = AsyncValue.error(resp.message, StackTrace.current);
      }
    } on DioException catch (e, st) {
      state = AsyncValue.error(e.message ?? '加载失败', st);
    }
  }

  Future<bool> create(String name, String type, int initialBalance) async {
    try {
      final resp = await _service.create(
        name: name,
        type: type,
        initialBalance: initialBalance,
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

  Future<bool> update(int id, {String? name, String? type, int? isActive}) async {
    try {
      final resp = await _service.update(id, name: name, type: type, isActive: isActive);
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

