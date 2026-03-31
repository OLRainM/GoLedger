import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../../providers/account_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../services/transaction_service.dart';

class TransactionFormPage extends ConsumerStatefulWidget {
  final int? transactionId;
  const TransactionFormPage({super.key, this.transactionId});

  bool get isEdit => transactionId != null;

  @override
  ConsumerState<TransactionFormPage> createState() =>
      _TransactionFormPageState();
}

class _TransactionFormPageState extends ConsumerState<TransactionFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  String _type = 'expense';
  int? _accountId;
  int? _categoryId;
  DateTime _transactionAt = DateTime.now();
  bool _loading = false;

  // 编辑模式
  int? _editVersion;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit) {
      _loadExisting();
    }
  }

  Future<void> _loadExisting() async {
    try {
      final resp = await TransactionService().detail(widget.transactionId!);
      if (resp.isSuccess && resp.data != null) {
        final tx = resp.data!;
        _type = tx.type;
        _accountId = tx.accountId;
        _categoryId = tx.categoryId;
        _amountCtrl.text = MoneyUtil.fenToYuan(tx.amount);
        _noteCtrl.text = tx.note ?? '';
        _transactionAt = DateTime.parse(tx.transactionAt);
        _editVersion = tx.version;
        if (mounted) setState(() {});
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _transactionAt,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_transactionAt),
    );
    if (time == null || !mounted) return;

    setState(() {
      _transactionAt = DateTime(
        date.year, date.month, date.day, time.hour, time.minute,
      );
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_accountId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('请选择账户')));
      return;
    }
    if (_categoryId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('请选择分类')));
      return;
    }

    setState(() => _loading = true);
    final yuan = double.tryParse(_amountCtrl.text) ?? 0;
    final fen = MoneyUtil.yuanToFen(yuan);
    final atStr = _transactionAt.toUtc().toIso8601String();

    bool ok;
    if (widget.isEdit) {
      final resp = await TransactionService().update(
        widget.transactionId!,
        accountId: _accountId,
        categoryId: _categoryId,
        type: _type,
        amount: fen,
        note: _noteCtrl.text.trim(),
        transactionAt: atStr,
        version: _editVersion!,
      );
      ok = resp.isSuccess;
      if (ok) {
        ref.read(transactionListProvider.notifier).load();
      }
    } else {
      ok = await ref.read(transactionListProvider.notifier).create(
            accountId: _accountId!,
            categoryId: _categoryId!,
            type: _type,
            amount: fen,
            note: _noteCtrl.text.trim(),
            transactionAt: atStr,
          );
    }

    if (!mounted) return;
    setState(() => _loading = false);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.isEdit ? '修改成功' : '记账成功')),
      );
      context.pop();
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('操作失败')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountListProvider);
    final categoriesAsync = ref.watch(categoryListProvider);

    return Scaffold(
      appBar: AppBar(title: Text(widget.isEdit ? '编辑流水' : '新建流水')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(children: [
            // 类型切换
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'expense', label: Text('支出')),
                ButtonSegment(value: 'income', label: Text('收入')),
              ],
              selected: {_type},
              onSelectionChanged: (s) {
                setState(() {
                  _type = s.first;
                  _categoryId = null;
                });
              },
            ),
            const SizedBox(height: 16),
            // 金额
            TextFormField(
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: '金额 (元)',
                prefixText: '¥ ',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return '请输入金额';
                final n = double.tryParse(v);
                if (n == null || n <= 0) return '金额必须大于 0';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // 账户选择
            accountsAsync.when(
              data: (accounts) {
                final active = accounts.where((a) => a.active).toList();
                return DropdownButtonFormField<int>(
                  value: _accountId,
                  decoration: const InputDecoration(
                    labelText: '账户', border: OutlineInputBorder()),
                  items: active.map((a) => DropdownMenuItem(
                    value: a.id, child: Text(a.name))).toList(),
                  onChanged: (v) => setState(() => _accountId = v),
                  validator: (v) => v == null ? '请选择账户' : null,
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('账户加载失败: $e'),
            ),
            const SizedBox(height: 16),

            // 分类选择
            categoriesAsync.when(
              data: (categories) {
                final filtered = categories
                    .where((c) => c.type == _type && c.active).toList();
                return DropdownButtonFormField<int>(
                  value: _categoryId,
                  decoration: const InputDecoration(
                    labelText: '分类', border: OutlineInputBorder()),
                  items: filtered.map((c) => DropdownMenuItem(
                    value: c.id, child: Text(c.name))).toList(),
                  onChanged: (v) => setState(() => _categoryId = v),
                  validator: (v) => v == null ? '请选择分类' : null,
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('分类加载失败: $e'),
            ),
            const SizedBox(height: 16),

            // 记账时间
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('记账时间'),
              subtitle: Text(
                '${_transactionAt.year}-'
                '${_transactionAt.month.toString().padLeft(2, '0')}-'
                '${_transactionAt.day.toString().padLeft(2, '0')} '
                '${_transactionAt.hour.toString().padLeft(2, '0')}:'
                '${_transactionAt.minute.toString().padLeft(2, '0')}',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickDateTime,
            ),
            const SizedBox(height: 16),

            // 备注
            TextFormField(
              controller: _noteCtrl,
              maxLines: 2,
              maxLength: 200,
              decoration: const InputDecoration(
                labelText: '备注 (选填)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        width: 24, height: 24,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(widget.isEdit ? '保存修改' : '记 账'),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

