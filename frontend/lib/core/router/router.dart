import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../storage/token_storage.dart';
import '../../pages/auth/login_page.dart';
import '../../pages/auth/register_page.dart';
import '../../pages/home/home_page.dart';
import '../../pages/account/account_list_page.dart';
import '../../pages/account/account_form_page.dart';
import '../../pages/category/category_list_page.dart';
import '../../pages/category/category_form_page.dart';
import '../../pages/transaction/transaction_list_page.dart';
import '../../pages/transaction/transaction_detail_page.dart';
import '../../pages/transaction/transaction_form_page.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    final isLoggedIn = TokenStorage.hasToken();
    final isAuthRoute = state.matchedLocation == '/login' ||
        state.matchedLocation == '/register';

    if (!isLoggedIn && !isAuthRoute) return '/login';
    if (isLoggedIn && isAuthRoute) return '/';
    return null;
  },
  routes: [
    // ---- 鉴权 ----
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterPage(),
    ),

    // ---- 底部导航 Shell ----
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const HomePage(),
        ),
        GoRoute(
          path: '/transactions',
          builder: (context, state) => const TransactionListPage(),
        ),
        GoRoute(
          path: '/accounts',
          builder: (context, state) => const AccountListPage(),
        ),
        GoRoute(
          path: '/categories',
          builder: (context, state) => const CategoryListPage(),
        ),
      ],
    ),

    // ---- 独立页面 (无底部导航) ----
    GoRoute(
      path: '/accounts/create',
      builder: (context, state) => const AccountFormPage(),
    ),
    GoRoute(
      path: '/accounts/:id/edit',
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return AccountFormPage(accountId: id);
      },
    ),
    GoRoute(
      path: '/categories/create',
      builder: (context, state) => const CategoryFormPage(),
    ),
    GoRoute(
      path: '/categories/:id/edit',
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return CategoryFormPage(categoryId: id);
      },
    ),
    GoRoute(
      path: '/transactions/create',
      builder: (context, state) => const TransactionFormPage(),
    ),
    GoRoute(
      path: '/transactions/:id',
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return TransactionDetailPage(transactionId: id);
      },
    ),
    GoRoute(
      path: '/transactions/:id/edit',
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return TransactionFormPage(transactionId: id);
      },
    ),
  ],
);

/// 主壳: 底部导航栏
class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location == '/') return 0;
    if (location == '/transactions') return 1;
    if (location == '/accounts') return 2;
    if (location == '/categories') return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex(context),
        onDestinationSelected: (index) {
          switch (index) {
            case 0: context.go('/'); break;
            case 1: context.go('/transactions'); break;
            case 2: context.go('/accounts'); break;
            case 3: context.go('/categories'); break;
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: '首页'),
          NavigationDestination(icon: Icon(Icons.receipt_long), label: '流水'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet), label: '账户'),
          NavigationDestination(icon: Icon(Icons.category), label: '分类'),
        ],
      ),
    );
  }
}

