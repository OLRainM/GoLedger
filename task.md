# GoLedger Flutter 前端开发任务列表

## 阶段一：环境与脚手架

- [ ] **Flutter SDK 安装** — 下载安装 Flutter SDK，配置 PATH 环境变量，运行 `flutter doctor` 确认环境就绪
- [ ] **项目脚手架** — `flutter create` 创建项目，配置 `pubspec.yaml` 依赖（dio / flutter_riverpod / go_router / shared_preferences / intl）

## 阶段二：基础设施层

- [ ] **网络层封装** — 封装 Dio HTTP 客户端：BaseURL 配置、Token 注入拦截器、统一响应解析（ApiResponse）、错误码映射、Token 过期自动跳登录
- [ ] **数据模型** — 定义 Model 类（User / Account / Category / Transaction / MonthlyStats），含 `fromJson` / `toJson`
- [ ] **API Service 层** — 对接后端 14 个接口：AuthService（注册/登录）、AccountService、CategoryService、TransactionService、StatsService
- [ ] **状态管理** — 使用 Riverpod 管理全局状态：AuthState（Token/登录态）、各业务数据的 Provider
- [ ] **路由配置** — 使用 GoRouter 配置路由表：鉴权守卫（未登录重定向到登录页）、各页面路由注册

## 阶段三：页面开发

- [ ] **鉴权页面** — 登录页 + 注册页：邮箱/密码表单校验、调用接口、Token 持久化存储、登录成功跳转首页
- [ ] **首页** — 月度统计卡片（本月收入 / 支出 / 结余）+ 最近流水列表（最近 10 条）
- [ ] **记账页面** — 选账户、选分类（收入/支出切换）、输入金额（分转换）、选日期、填备注，提交后刷新账户余额
- [ ] **账户管理页面** — 账户列表（显示余额）+ 创建账户 + 编辑账户（含停用/启用）
- [ ] **分类管理页面** — 分类列表（区分系统/自建）+ 创建分类 + 编辑分类（含停用/启用，系统分类不可编辑）
- [ ] **流水页面** — 流水列表（分页加载 + 按账户/分类/类型筛选）+ 流水详情 + 编辑流水 + 删除流水（软删除确认）

## 阶段四：收尾

- [ ] **编译验证与推送** — `flutter build apk` 验证编译通过，`flutter analyze` 无严重警告，推送到 GitHub

---

## 技术栈

| 用途 | 库 | 版本 |
|------|-----|------|
| HTTP 客户端 | dio | ^5.x |
| 状态管理 | flutter_riverpod | ^2.x |
| 路由 | go_router | ^14.x |
| 本地存储 | shared_preferences | ^2.x |
| 日期/数字格式化 | intl | ^0.19.x |

## 目录结构

```
frontend/lib/
├── main.dart
├── app.dart
├── core/
│   ├── constants.dart
│   ├── http/
│   │   ├── api_client.dart
│   │   └── api_response.dart
│   ├── router/
│   │   └── router.dart
│   └── storage/
│       └── token_storage.dart
├── models/
│   ├── user.dart
│   ├── account.dart
│   ├── category.dart
│   ├── transaction.dart
│   └── monthly_stats.dart
├── services/
│   ├── auth_service.dart
│   ├── account_service.dart
│   ├── category_service.dart
│   ├── transaction_service.dart
│   └── stats_service.dart
├── providers/
│   ├── auth_provider.dart
│   ├── account_provider.dart
│   ├── category_provider.dart
│   ├── transaction_provider.dart
│   └── stats_provider.dart
└── pages/
    ├── auth/
    │   ├── login_page.dart
    │   └── register_page.dart
    ├── home/
    │   └── home_page.dart
    ├── account/
    │   ├── account_list_page.dart
    │   └── account_form_page.dart
    ├── category/
    │   ├── category_list_page.dart
    │   └── category_form_page.dart
    └── transaction/
        ├── transaction_list_page.dart
        ├── transaction_detail_page.dart
        └── transaction_form_page.dart
```

