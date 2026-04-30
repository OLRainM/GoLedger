import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/storage/token_storage.dart';
import '../../providers/auth_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  bool _remember = false;

  @override
  void initState() {
    super.initState();
    // 恢复已保存的凭证
    _remember = TokenStorage.isRememberPassword();
    if (_remember) {
      _emailCtrl.text = TokenStorage.getSavedEmail() ?? '';
      _passwordCtrl.text = TokenStorage.getSavedPassword() ?? '';
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    final ok = await ref.read(authStateProvider.notifier).login(email, password);
    if (!mounted) return;
    setState(() => _loading = false);
    if (ok) {
      // 登录成功后根据勾选状态保存/清除凭证
      if (_remember) {
        await TokenStorage.saveCredentials(email, password);
      } else {
        await TokenStorage.clearCredentials();
      }
      if (!mounted) return;
      context.go('/');
    } else {
      final err = ref.read(authStateProvider).errorMessage ?? '登录失败';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.account_balance_wallet,
                      size: 72, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 8),
                  Text('GoLedger',
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: '邮箱',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return '请输入邮箱';
                      if (!v.contains('@')) return '邮箱格式不正确';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordCtrl,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      labelText: '密码',
                      prefixIcon: const Icon(Icons.lock),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(_obscure
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return '请输入密码';
                      if (v.length < 8) return '密码至少 8 个字符';
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  // ── 记住密码 ──
                  Row(
                    children: [
                      SizedBox(
                        height: 24,
                        width: 24,
                        child: Checkbox(
                          value: _remember,
                          onChanged: (v) =>
                              setState(() => _remember = v ?? false),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () =>
                            setState(() => _remember = !_remember),
                        child: const Text('记住密码'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
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
                          : const Text('登 录'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => context.go('/register'),
                    child: const Text('没有账号？去注册'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

