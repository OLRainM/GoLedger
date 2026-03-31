import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/category_provider.dart';

class CategoryListPage extends ConsumerWidget {
  const CategoryListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoryListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('分类管理')),
      body: categoriesAsync.when(
        data: (categories) {
          if (categories.isEmpty) {
            return const Center(child: Text('暂无分类'));
          }
          final expense = categories.where((c) => c.isExpense).toList();
          final income = categories.where((c) => c.isIncome).toList();

          return RefreshIndicator(
            onRefresh: () => ref.read(categoryListProvider.notifier).load(),
            child: ListView(
              padding: const EdgeInsets.all(8),
              children: [
                _SectionHeader(title: '支出分类', count: expense.length),
                ...expense.map((c) => _CategoryTile(category: c)),
                const SizedBox(height: 16),
                _SectionHeader(title: '收入分类', count: income.length),
                ...income.map((c) => _CategoryTile(category: c)),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'category_add',
        onPressed: () => context.push('/categories/create'),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  const _SectionHeader({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text('$title ($count)',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary)),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final dynamic category;
  const _CategoryTile({required this.category});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: category.isExpense
              ? Colors.red.shade50
              : Colors.green.shade50,
          child: Icon(
            category.isExpense ? Icons.arrow_upward : Icons.arrow_downward,
            color: category.isExpense ? Colors.red : Colors.green,
          ),
        ),
        title: Text(
          category.name,
          style: TextStyle(
            color: category.active ? null : Colors.grey,
            decoration: category.active ? null : TextDecoration.lineThrough,
          ),
        ),
        subtitle: Text(
          '${category.system ? "系统预置" : "自定义"}'
          '${category.active ? "" : " · 已停用"}',
        ),
        trailing: category.system
            ? null
            : const Icon(Icons.chevron_right),
        onTap: category.system
            ? null
            : () => context.push('/categories/${category.id}/edit'),
      ),
    );
  }
}

