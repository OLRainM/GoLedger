import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../../providers/account_provider.dart';

class AccountFormPage extends ConsumerStatefulWidget {
  final int? accountId;
  const AccountFormPage({super.key, this.accountId});

  bool get isEdit => accountId != null;

  @override
  ConsumerState<AccountFormPage> createState() => _AccountFormPageState();
}

class _AccountFormPageState extends ConsumerState<AccountFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _balanceCtrl = TextEditingController(text: '0.00');
  String _selectedType = 'cash';
  bool _isActive = true;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit) {
      // 编辑模式: 从现有数据填充
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final accounts = ref.read(accountListProvider);
        accounts.whenData((list) {
          final account = list.where((a) => a.id == widget.accountId).firstOrNull;
          if (account != null) {
            _nameCtrl.text = account.name;
            _selectedType = account.type;
            _isActive = account.active;
            setState(() {});
          }
        });
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _balanceCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    bool ok;
    if (widget.isEdit) {
      ok = await ref.read(accountListProvider.notifier).update(
            widget.accountId!,
            name: _nameCtrl.text.trim(),
            type: _selectedType,
            isActive: _isActive ? 1 : 0,
          );
    } else {
      final yuan = double.tryParse(_balanceCtrl.text) ?? 0;
      final fen = MoneyUtil.yuanToFen(yuan);
      ok = await ref.read(accountListProvider.notifier).create(
            _nameCtrl.text.trim(),
            _selectedType,
            fen,
          );
    }

    if (!mounted) return;
    setState(() => _loading = false);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.isEdit ? '修改成功' : '创建成功')),
      );
      context.pop();
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('操作失败')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.isEdit ? '编辑账户' : '新建账户')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: '账户名称',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? '请输入账户名称' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: '账户类型',
                  border: OutlineInputBorder(),
                ),
                items: AppConstants.accountTypes
                    .map((t) => DropdownMenuItem(
                          value: t,
                          child: Text(AppConstants.accountTypeLabels[t] ?? t),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _selectedType = v ?? 'cash'),
              ),
              if (!widget.isEdit) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _balanceCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: '初始余额 (元)',
                    border: OutlineInputBorder(),
                    prefixText: '¥ ',
                  ),
                ),
              ],
              if (widget.isEdit) ...[
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('启用状态'),
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                ),
              ],
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text(widget.isEdit ? '保存修改' : '创建账户'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

