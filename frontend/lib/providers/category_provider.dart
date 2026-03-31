import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category.dart';
import '../services/category_service.dart';

final categoryListProvider =
    StateNotifierProvider<CategoryListNotifier, AsyncValue<List<Category>>>((ref) {
  return CategoryListNotifier();
});

class CategoryListNotifier extends StateNotifier<AsyncValue<List<Category>>> {
  final _service = CategoryService();

  CategoryListNotifier() : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load({String? type}) async {
    state = const AsyncValue.loading();
    try {
      final resp = await _service.list(type: type);
      if (resp.isSuccess && resp.data != null) {
        state = AsyncValue.data(resp.data!);
      } else {
        state = AsyncValue.error(resp.message, StackTrace.current);
      }
    } on DioException catch (e, st) {
      state = AsyncValue.error(e.message ?? '加载失败', st);
    }
  }

  Future<bool> create(String name, String type) async {
    try {
      final resp = await _service.create(name: name, type: type);
      if (resp.isSuccess) {
        await load();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> update(int id, {String? name, int? isActive}) async {
    try {
      final resp = await _service.update(id, name: name, isActive: isActive);
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

