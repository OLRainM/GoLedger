import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../../models/transaction.dart';
import '../../services/transaction_service.dart';
import '../../providers/transaction_provider.dart';

class TransactionDetailPage extends ConsumerStatefulWidget {
  final int transactionId;
  const TransactionDetailPage({super.key, required this.transactionId});

  @override
  ConsumerState<TransactionDetailPage> createState() =>
      _TransactionDetailPageState();
}

class _TransactionDetailPageState
    extends ConsumerState<TransactionDetailPage> {
  final _service = TransactionService();
  Transaction? _tx;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() => _loading = true);
    try {
      final resp = await _service.detail(widget.transactionId);
      if (resp.isSuccess && resp.data != null) {
        _tx = resp.data;
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _delete() async {
    if (_tx == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('删除后将回滚对账户余额的影响，此操作不可恢复。'),
        actions: [
          TextButton(onPressed: () => ctx.pop(false), child: const Text('取消')),
          TextButton(onPressed: () => ctx.pop(true), child: const Text('删除')),
        ],
      ),
    );
    if (confirm != true) return;

    final ok = await ref
        .read(transactionListProvider.notifier)
        .delete(_tx!.id, _tx!.version);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('删除成功')));
      context.pop();
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('删除失败')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('流水详情'),
        actions: [
          if (_tx != null) ...[
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () =>
                  context.push('/transactions/${_tx!.id}/edit').then((_) => _loadDetail()),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _delete,
            ),
          ],
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _tx == null
              ? const Center(child: Text('流水不存在'))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _InfoRow('类型', _tx!.isIncome ? '收入' : '支出'),
                    _InfoRow('金额', MoneyUtil.format(_tx!.amount)),
                    _InfoRow('记账时间', _tx!.transactionAt.substring(0, 16)),
                    if (_tx!.note != null && _tx!.note!.isNotEmpty)
                      _InfoRow('备注', _tx!.note!),
                    _InfoRow('创建时间', _tx!.createdAt.substring(0, 16)),
                    _InfoRow('更新时间', _tx!.updatedAt.substring(0, 16)),
                    _InfoRow('版本号', '${_tx!.version}'),
                  ],
                ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.grey)),
          ),
          Expanded(
            child: Text(value,
                style: Theme.of(context).textTheme.bodyLarge),
          ),
        ],
      ),
    );
  }
}

