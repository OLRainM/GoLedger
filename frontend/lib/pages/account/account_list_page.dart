import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../../providers/account_provider.dart';

class AccountListPage extends ConsumerWidget {
  const AccountListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('账户管理')),
      body: accountsAsync.when(
        data: (accounts) {
          if (accounts.isEmpty) {
            return const Center(child: Text('暂无账户，点击右下角添加'));
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(accountListProvider.notifier).load(),
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: accounts.length,
              itemBuilder: (context, index) {
                final a = accounts[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: a.active
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Colors.grey.shade300,
                      child: Icon(
                        _accountIcon(a.type),
                        color: a.active
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey,
                      ),
                    ),
                    title: Text(
                      a.name,
                      style: TextStyle(
                        decoration: a.active ? null : TextDecoration.lineThrough,
                        color: a.active ? null : Colors.grey,
                      ),
                    ),
                    subtitle: Text(
                      '${AppConstants.accountTypeLabels[a.type] ?? a.type}'
                      '${a.active ? "" : " (已停用)"}',
                    ),
                    trailing: Text(
                      MoneyUtil.format(a.balance),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: a.balance >= 0 ? Colors.black87 : Colors.red,
                      ),
                    ),
                    onTap: () => context.push('/accounts/${a.id}/edit'),
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'account_add',
        onPressed: () => context.push('/accounts/create'),
        child: const Icon(Icons.add),
      ),
    );
  }

  IconData _accountIcon(String type) {
    switch (type) {
      case 'cash':
        return Icons.payments;
      case 'bank_card':
        return Icons.credit_card;
      case 'e_wallet':
        return Icons.phone_android;
      default:
        return Icons.account_balance;
    }
  }
}

