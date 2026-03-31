import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/category_provider.dart';

class CategoryFormPage extends ConsumerStatefulWidget {
  final int? categoryId;
  const CategoryFormPage({super.key, this.categoryId});

  bool get isEdit => categoryId != null;

  @override
  ConsumerState<CategoryFormPage> createState() => _CategoryFormPageState();
}

class _CategoryFormPageState extends ConsumerState<CategoryFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  String _selectedType = 'expense';
  bool _isActive = true;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final categories = ref.read(categoryListProvider);
        categories.whenData((list) {
          final cat = list.where((c) => c.id == widget.categoryId).firstOrNull;
          if (cat != null) {
            _nameCtrl.text = cat.name;
            _selectedType = cat.type;
            _isActive = cat.active;
            setState(() {});
          }
        });
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    bool ok;
    if (widget.isEdit) {
      ok = await ref.read(categoryListProvider.notifier).update(
            widget.categoryId!,
            name: _nameCtrl.text.trim(),
            isActive: _isActive ? 1 : 0,
          );
    } else {
      ok = await ref.read(categoryListProvider.notifier).create(
            _nameCtrl.text.trim(),
            _selectedType,
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
      appBar: AppBar(title: Text(widget.isEdit ? '编辑分类' : '新建分类')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: '分类名称',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? '请输入分类名称' : null,
              ),
              if (!widget.isEdit) ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedType,
                  decoration: const InputDecoration(
                    labelText: '分类类型',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'expense', child: Text('支出')),
                    DropdownMenuItem(value: 'income', child: Text('收入')),
                  ],
                  onChanged: (v) =>
                      setState(() => _selectedType = v ?? 'expense'),
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
                      : Text(widget.isEdit ? '保存修改' : '创建分类'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

