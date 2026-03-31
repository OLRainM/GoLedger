import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../../providers/transaction_provider.dart';

class TransactionListPage extends ConsumerWidget {
  const TransactionListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txState = ref.watch(transactionListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('流水记录')),
      body: txState.isLoading && txState.items.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : txState.items.isEmpty
              ? const Center(child: Text('暂无流水记录'))
              : RefreshIndicator(
                  onRefresh: () =>
                      ref.read(transactionListProvider.notifier).load(),
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      if (notification is ScrollEndNotification &&
                          notification.metrics.extentAfter < 200) {
                        ref.read(transactionListProvider.notifier).loadMore();
                      }
                      return false;
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount:
                          txState.items.length + (txState.hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= txState.items.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child:
                                Center(child: CircularProgressIndicator()),
                          );
                        }
                        final tx = txState.items[index];
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: tx.isIncome
                                  ? Colors.green.shade50
                                  : Colors.red.shade50,
                              child: Icon(
                                tx.isIncome
                                    ? Icons.arrow_downward
                                    : Icons.arrow_upward,
                                color:
                                    tx.isIncome ? Colors.green : Colors.red,
                              ),
                            ),
                            title: Text(tx.categoryName ?? '未知分类'),
                            subtitle: Text(
                              '${tx.accountName ?? ""}'
                              '${tx.note != null && tx.note!.isNotEmpty ? " · ${tx.note}" : ""}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${tx.isExpense ? "-" : "+"}${MoneyUtil.format(tx.amount)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: tx.isIncome
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),
                                Text(
                                  tx.transactionAt.substring(0, 10),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                            onTap: () =>
                                context.push('/transactions/${tx.id}'),
                          ),
                        );
                      },
                    ),
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'tx_add',
        onPressed: () => context.push('/transactions/create'),
        child: const Icon(Icons.add),
      ),
    );
  }
}

