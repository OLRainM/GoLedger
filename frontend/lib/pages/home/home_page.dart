import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../../providers/stats_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/auth_provider.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(statsProvider);
    final txState = ref.watch(transactionListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('GoLedger'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authStateProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(statsProvider.notifier).load();
          await ref.read(transactionListProvider.notifier).load();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ---- 月度统计卡片 ----
            stats.when(
              data: (s) => _StatsCard(
                year: s.year,
                month: s.month,
                income: s.totalIncome,
                expense: s.totalExpense,
                balance: s.balance,
              ),
              loading: () =>
                  const SizedBox(height: 120, child: Center(child: CircularProgressIndicator())),
              error: (e, _) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('统计加载失败: $e'),
                ),
              ),
            ),

            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('最近流水', style: Theme.of(context).textTheme.titleMedium),
                TextButton(
                  onPressed: () => context.go('/transactions'),
                  child: const Text('查看全部'),
                ),
              ],
            ),

            // ---- 最近流水列表 ----
            if (txState.isLoading && txState.items.isEmpty)
              const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()))
            else if (txState.items.isEmpty)
              const SizedBox(
                height: 100,
                child: Center(child: Text('暂无流水记录')),
              )
            else
              ...txState.items.take(5).map((tx) => ListTile(
                    leading: Icon(
                      tx.isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                      color: tx.isIncome ? Colors.green : Colors.red,
                    ),
                    title: Text(tx.categoryName ?? '未知分类'),
                    subtitle: Text(tx.note ?? tx.accountName ?? ''),
                    trailing: Text(
                      '${tx.isExpense ? "-" : "+"}${MoneyUtil.format(tx.amount)}',
                      style: TextStyle(
                        color: tx.isIncome ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onTap: () => context.push('/transactions/${tx.id}'),
                  )),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/transactions/create'),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final int year, month, income, expense, balance;

  const _StatsCard({
    required this.year,
    required this.month,
    required this.income,
    required this.expense,
    required this.balance,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$year 年 $month 月',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatItem(
                      label: '收入', value: MoneyUtil.format(income), color: Colors.green),
                ),
                Expanded(
                  child: _StatItem(
                      label: '支出', value: MoneyUtil.format(expense), color: Colors.red),
                ),
                Expanded(
                  child: _StatItem(
                      label: '结余',
                      value: MoneyUtil.format(balance),
                      color: balance >= 0 ? Colors.blue : Colors.orange),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}

