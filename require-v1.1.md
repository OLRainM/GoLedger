# GoLedger V1.1 — 体验优化与工程化

> **基线版本**: V1-MVP（已完成）
>
> **预计周期**: 3 ~ 4 周
>
> **核心目标**: 在 V1-MVP 核心记账流程已跑通的基础上，从三个维度进行升级——**前端体验打磨**、**后端健壮性增强**、**工程化与持续交付**。本版本不引入新的业务模块，不新增数据库表，聚焦把现有功能做得更稳、更好用、更易维护。

---

# 前端增强

## 流水日历视图

V1 的流水列表是一维的滚动列表，用户很难直观感知"哪天花了多少"。V1.1 在流水模块新增一个**日历视图**，与现有列表视图并列切换。

具体设计：

- 流水页面顶部增加一个视图切换按钮（列表 / 日历），默认仍为列表视图，用户可自由切换。

- 日历视图以**月**为单位显示。顶部显示当前年月，左右箭头或左右滑动切换月份。

- 每个日期格子内显示当天的**总支出**金额（红色）和**总收入**金额（绿色）。没有流水的日期格子留空，有流水的日期格子底部加一个小圆点标记。

- 点击某一天后，下方展开当天的流水明细列表（复用现有 ListTile 样式），可点击进入流水详情。

- 日历视图的数据来源：复用现有 `GET /api/v1/transactions` 接口，按月查询（通过 `start_date` 和 `end_date` 参数），前端按日期分组渲染。**不新增后端接口**。

- 切换月份时加载对应月份数据，显示 loading 态。已加载过的月份数据在内存中缓存，避免重复请求。

验收标准：

- 列表/日历视图可自由切换，互不影响
- 日历格子中的收支金额与实际流水数据一致
- 点击日期后正确展示当天流水明细
- 切换月份时有 loading 态，加载完成后正确渲染

## 下拉刷新动画优化

V1 的下拉刷新使用了 Flutter 默认的 `RefreshIndicator`，体验比较生硬。V1.1 对以下页面的下拉刷新进行动画优化：

优化范围：首页（HomePage）、流水列表页（TransactionListPage）、账户列表页（AccountListPage）、分类列表页（CategoryListPage）。

具体设计：

- 将默认的 Material `RefreshIndicator` 替换为自定义动画效果。推荐使用 `custom_refresh_indicator` 包或自行实现。

- 下拉时显示一个品牌化的动画：GoLedger 的 logo 图标配合旋转或弹性动画。拉到阈值后松手触发刷新，刷新中图标持续旋转动画，刷新完成后回弹消失。

- 动画需流畅，不出现卡顿或撕裂。下拉→松手→刷新→回弹整个过程的总时长应控制在 1.5 秒以内（不含网络请求时间）。

- 刷新失败时（网络异常），显示错误提示 SnackBar，动画正常回弹不卡死。

验收标准：

- 四个页面的下拉刷新动画一致，品牌感统一
- 动画流畅，无卡顿
- 网络异常时能正确回弹并提示错误

## 本地输入缓存（防丢失）

用户在填写记账表单（TransactionFormPage）时，如果意外退出（接电话、误触返回键、App 被系统杀死），已输入的数据全部丢失。V1.1 为记账表单增加**本地草稿缓存**机制。

具体设计：

- 仅针对**新建流水表单**（非编辑模式），在用户输入过程中自动将表单数据保存到本地。

- 保存时机：表单任意字段发生变化时，使用防抖策略（debounce 1 秒），将当前表单状态序列化为 JSON 存入 SharedPreferences。

- 保存的字段包括：type（收入/支出）、amount（金额字符串）、accountId、categoryId、transactionAt（ISO 字符串）、note（备注）。

- 用户下次打开新建流水表单时，检查是否存在草稿。如果存在，弹出对话框询问"检测到未提交的记账草稿，是否恢复？"，提供"恢复"和"丢弃"两个按钮。

- 选择"恢复"后将草稿数据填充到表单各字段中。选择"丢弃"后清除草稿数据，显示空白表单。

- 流水成功提交后，立即清除本地草稿。

- SharedPreferences 中的 key 为 `draft_transaction`，存储格式为 JSON 字符串。

验收标准：

- 填写表单中途退出 App 后，重新打开能恢复草稿
- 选择丢弃后草稿被清除，下次打开不再提示
- 提交成功后草稿被自动清除
- 编辑模式（已有流水的修改）不触发草稿机制

## 多语言支持（i18n）

V1 的所有界面文字都是中文硬编码。V1.1 引入国际化框架，支持**中文（简体）**和**英文**两种语言。

具体设计：

- 使用 Flutter 官方推荐的 `flutter_localizations` + `intl` 包实现。生成方式使用 ARB 文件（`app_zh.arb` 和 `app_en.arb`）。

- 默认语言跟随系统设置。如果系统语言是中文（zh），显示中文；否则 fallback 到英文。

- 需要翻译的内容范围：所有页面标题、按钮文字、表单标签、提示信息（SnackBar）、对话框文字、空状态文字、错误提示、底部导航栏标签。

- **不包括**后端返回的错误信息（如 "邮箱已注册"），后端消息保持原样展示。V2 再考虑后端多语言。

- 金额格式跟随语言：中文用 `¥` 前缀，英文用 `$` 前缀。但底层币种仍为人民币分，仅是显示符号的差异。

- 在 MaterialApp.router 中配置 `localizationsDelegates` 和 `supportedLocales`。

翻译量估算：

| 类别 | 预计条目数 |
|------|-----------|
| 页面标题 | ~15 |
| 按钮文字 | ~20 |
| 表单标签与校验提示 | ~25 |
| SnackBar 提示 | ~15 |
| 对话框 | ~5 |
| 空状态与加载 | ~10 |
| 导航栏 | 4 |
| **合计** | **~94** |

验收标准：

- 系统语言为中文时界面显示中文，切换为英文后界面全部切换为英文
- 无遗漏的硬编码中文字符串
- 金额符号正确跟随语言切换

---

# 后端增强

## 请求限流（Rate Limit — 令牌桶）

V1 没有任何限流措施，一旦有恶意请求或客户端 bug 导致高频重试，后端可能被打崩。V1.1 引入基于**令牌桶（Token Bucket）**算法的请求限流中间件。

为什么选令牌桶：令牌桶允许一定程度的突发请求（桶中有令牌就放行），同时通过固定速率补充令牌来限制长期平均速率。相比漏桶（Leaky Bucket）的恒定速率出站，令牌桶对正常用户的突发操作（比如快速连续记几笔账）更友好。

技术选型：使用 Go 标准扩展库 `golang.org/x/time/rate`，它提供了开箱即用的令牌桶实现（`rate.Limiter`）。

限流策略设计（三层）：

**全局限流** — 整个服务的总请求速率上限，防止极端情况下的资源耗尽。

| 参数 | 值 | 说明 |
|------|-----|------|
| 速率（r） | 500 req/s | 每秒补充 500 个令牌 |
| 桶容量（b） | 1000 | 允许瞬时突发最多 1000 个请求 |
| 触发行为 | 返回 HTTP 429 | `{"code": 42901, "message": "server busy, try later"}` |

**Per-IP 限流** — 防止单个 IP 的恶意刷接口。

| 参数 | 值 | 说明 |
|------|-----|------|
| 速率（r） | 20 req/s | 每秒补充 20 个令牌 |
| 桶容量（b） | 50 | 允许突发 50 个请求 |
| 清理策略 | 5 分钟无请求后回收 | 避免 map 无限膨胀，使用后台 goroutine 定期清理 |
| 触发行为 | 返回 HTTP 429 | `{"code": 42902, "message": "too many requests"}` |

**Per-User 限流**（仅对已登录用户）— 防止单用户高频操作。

| 参数 | 值 | 说明 |
|------|-----|------|
| 速率（r） | 10 req/s | 每秒补充 10 个令牌 |
| 桶容量（b） | 30 | 允许突发 30 个请求 |
| 清理策略 | 同 Per-IP | 5 分钟无活动后回收 |
| 触发行为 | 返回 HTTP 429 | `{"code": 42903, "message": "too many requests"}` |

限流中间件的执行顺序：全局限流 → Per-IP 限流 → JWT 鉴权 → Per-User 限流 → Handler。

429 响应头中应包含 `Retry-After` 字段（值为建议等待秒数，固定为 1）。

所有限流参数应通过 `config.yaml` 配置，支持不重启服务的情况下通过配置热更新调整。配置示例：

```yaml
rate_limit:
  global:
    rate: 500
    burst: 1000
  per_ip:
    rate: 20
    burst: 50
    cleanup_interval: 5m
  per_user:
    rate: 10
    burst: 30
    cleanup_interval: 5m
```

新增错误码：

| code | HTTP 状态码 | 含义 |
|------|------------|------|
| 42901 | 429 | 全局限流触发 |
| 42902 | 429 | 单 IP 限流触发 |
| 42903 | 429 | 单用户限流触发 |

验收标准：

- 使用压测工具（如 `hey` 或 `wrk`）对任意接口发送超过阈值的请求，确认返回 429
- Per-IP 限流和 Per-User 限流互相独立，不互相干扰
- 限流参数通过 config.yaml 可配置
- 正常使用场景下（手动记账）不触发限流

## 接口参数更严格校验

V1 的参数校验依赖 Gin 的 `binding` tag，覆盖面有限。V1.1 对所有接口进行更严格的参数校验，确保非法数据在进入 Service 层之前就被拒绝。

增强方向：

**通用增强** — 在 Gin 的 validator 中注册自定义校验函数：

- `valid_account_type`：校验账户类型必须为 `cash | bank_card | e_wallet | other` 之一
- `valid_category_type`：校验分类类型必须为 `income | expense` 之一
- `valid_transaction_type`：校验流水类型必须为 `income | expense` 之一
- `no_leading_trailing_spaces`：校验字符串首尾无空格（适用于 name 字段）

**各接口的具体校验规则增强**：

注册接口（POST /api/auth/register）：
- email：增加正则校验，确保符合 RFC 5322 简化格式，不仅仅是 `required`
- password：增加 `min=8,max=72` 长度限制（bcrypt 最大 72 字节），增加复杂度提示（至少包含字母和数字，但 V1.1 不做强制，仅返回 warning）
- nickname：增加 `max=50` 限制，增加 `no_leading_trailing_spaces` 校验

创建账户（POST /api/accounts）：
- name：增加 `min=1,max=50` 和 `no_leading_trailing_spaces`
- type：使用 `valid_account_type` 自定义校验
- initial_balance：增加范围校验 `min=0,max=9999999999`

创建分类（POST /api/categories）：
- name：增加 `min=1,max=50` 和 `no_leading_trailing_spaces`
- type：使用 `valid_category_type` 自定义校验

创建/编辑流水（POST & PUT /api/transactions）：
- amount：增加 `min=1,max=9999999999` 范围校验
- type：使用 `valid_transaction_type` 自定义校验
- transaction_at：校验日期不能是未来日期（允许到当天 23:59:59）
- note：增加 `max=200` 限制

流水列表查询（GET /api/transactions）：
- page：增加 `min=1` 校验
- page_size：增加 `min=1,max=50` 校验
- start_date / end_date：校验日期格式为 `YYYY-MM-DD`，且 start_date <= end_date

月度统计（GET /api/stats/monthly）：
- year：增加 `min=2000,max=2100` 校验
- month：增加 `min=1,max=12` 校验

错误响应增强：当校验失败时，`message` 字段应返回具体的校验失败原因（如 `"amount must be between 1 and 9999999999"`），而不是笼统的 `"参数错误"`。

验收标准：

- 所有接口的非法参数都能被正确拦截，返回 400 和具体错误描述
- 合法边界值（如 amount=1、amount=9999999999）能正常通过校验
- 自定义校验器注册后在所有相关接口生效

## Swagger / OpenAPI 文档自动生成

V1 的 API 文档是手写的 `api.md`，维护成本高且容易与代码不同步。V1.1 引入 Swagger 自动生成工具，从代码注释直接生成交互式 API 文档。

技术选型：使用 `swaggo/swag`（CLI 工具，解析 Go 注释生成 OpenAPI 2.0 spec）+ `swaggo/gin-swagger`（Gin 中间件，提供 Swagger UI）。

具体设计：

- 在 `cmd/server/main.go` 中添加项目级别的 Swagger 注释（标题、版本、描述、BasePath、安全定义）。

- 在每个 Handler 函数上方添加 Swagger 注释，包含：Summary、Description、Tags、Accept/Produce、Param、Success、Failure、Router。

- 注释示例（以创建流水为例）：

```go
// CreateTransaction godoc
// @Summary 创建流水
// @Description 新增一条收入或支出记录，同时更新关联账户余额
// @Tags 流水
// @Accept json
// @Produce json
// @Param Authorization header string true "Bearer {token}"
// @Param body body CreateTransactionRequest true "创建流水请求体"
// @Success 200 {object} Response{data=Transaction}
// @Failure 400 {object} Response
// @Failure 401 {object} Response
// @Failure 409 {object} Response
// @Router /api/transactions [post]
```

- 运行 `swag init -g cmd/server/main.go` 自动生成 `docs/` 目录（包含 `swagger.json`、`swagger.yaml`、`docs.go`）。

- 在 Gin 路由中注册 Swagger UI 路由：`GET /swagger/*any`，**仅在非生产环境启用**（通过配置项 `swagger.enabled` 控制）。

- `docs/` 目录加入版本控制，确保其他开发者 clone 后直接可用。

- 在 `Makefile`（或开发脚本）中添加 `make swagger` 命令，一键重新生成文档。

配置示例：

```yaml
swagger:
  enabled: true  # 生产环境设为 false
```

验收标准：

- 运行 `swag init` 后无报错，生成完整的 OpenAPI spec
- 访问 `/swagger/index.html` 可看到交互式文档，所有 14 个接口都有
- 可在 Swagger UI 中直接发起测试请求
- 生产环境（`swagger.enabled: false`）访问 `/swagger/*` 返回 404

---

# 运维与工程化

## CI/CD（GitHub Actions）

V1 的构建和部署全靠手动 `docker compose up`。V1.1 引入 GitHub Actions，实现代码推送后自动构建、测试、镜像打包的持续集成流水线。

### 工作流设计

项目需要两条工作流（workflow）：

**工作流一：CI — 构建与测试**（文件：`.github/workflows/ci.yml`）

触发条件：
- `push` 到 `main` 分支
- 任何 Pull Request 指向 `main` 分支

包含 3 个 Job（并行执行）：

**Job 1：backend-lint-and-test**
- Runner：`ubuntu-latest`
- 步骤：
  1. Checkout 代码
  2. Setup Go（version 1.23）
  3. 进入 `backend/` 目录
  4. 运行 `go vet ./...`（静态检查）
  5. 安装 `golangci-lint`，运行 lint
  6. 启动 MySQL 服务（使用 GitHub Actions 的 `services` 配置项，映射 3306 端口）
  7. 运行 `go test -v -race -coverprofile=coverage.out ./...`
  8. 上传覆盖率报告为 Artifact

**Job 2：backend-build**
- Runner：`ubuntu-latest`
- 步骤：
  1. Checkout 代码
  2. Setup Go
  3. 运行 `go build -o server ./cmd/server/`，确认编译通过

**Job 3：frontend-analyze**
- Runner：`ubuntu-latest`
- 步骤：
  1. Checkout 代码
  2. Setup Flutter（使用 `subosito/flutter-action`，version `3.32.2`）
  3. 进入 `frontend/` 目录
  4. 运行 `flutter pub get`
  5. 运行 `flutter analyze --no-fatal-infos`
  6. 运行 `flutter test`（如有测试）

**工作流二：Docker Build**（文件：`.github/workflows/docker.yml`）

触发条件：
- 在 `main` 分支上创建 tag（格式 `v*`，如 `v1.1.0`）

包含 1 个 Job：

**Job：build-and-push**
- Runner：`ubuntu-latest`
- 步骤：
  1. Checkout 代码
  2. 登录 Docker Hub（使用 Secrets：`DOCKER_USERNAME`、`DOCKER_PASSWORD`）
  3. Setup Docker Buildx
  4. Build 并 Push 镜像到 Docker Hub，tag 为版本号 + `latest`

### 需要配置的 Secrets

| Secret 名称 | 用途 | 在哪里设置 |
|-------------|------|-----------|
| `DOCKER_USERNAME` | Docker Hub 用户名 | GitHub → Settings → Secrets → Actions |
| `DOCKER_PASSWORD` | Docker Hub Token | 同上 |

### 状态徽章

在 `README.md` 顶部添加 CI 状态徽章：

```markdown
![CI](https://github.com/OLRainM/GoLedger/actions/workflows/ci.yml/badge.svg)
```

验收标准：

- Push 到 main 后自动触发 CI，3 个 Job 全部通过（绿色 ✅）
- PR 中能看到 CI 检查结果，阻止合并失败的 PR
- 创建 tag 后自动构建 Docker 镜像并推送到 Docker Hub
- CI 总耗时控制在 5 分钟以内

## 自动化测试流水线

V1 几乎没有自动化测试。V1.1 建立测试基础设施，编写核心路径的单元测试和集成测试。

### Go 后端测试策略

**单元测试**（不依赖外部服务）：

需要覆盖的模块：
- `pkg/jwt`：Token 生成、解析、过期判断
- `pkg/errs`：错误码构造、消息格式
- `pkg/response`：JSON 响应格式化
- `service/` 层：核心业务逻辑（使用接口 mock Repository 层）

Mock 方案：为每个 Repository 定义 interface，Service 层依赖 interface 而非具体实现。测试时使用手写 mock 或 `gomock` 生成 mock。

**集成测试**（依赖 MySQL）：

需要覆盖的模块：
- `repository/` 层：所有 CRUD 操作和事务逻辑
- 端到端（Handler 层）：使用 `httptest` 发起真实 HTTP 请求

集成测试的 MySQL 来源：CI 环境中使用 GitHub Actions 的 service container；本地开发使用 Docker 启动临时 MySQL 实例。

**覆盖率目标**：

| 模块 | V1.1 目标覆盖率 | 说明 |
|------|----------------|------|
| pkg/ | >= 80% | 工具函数，容易测试 |
| service/ | >= 60% | 核心业务逻辑 |
| repository/ | >= 50% | 集成测试覆盖主要路径 |
| handler/ | >= 40% | 端到端测试覆盖关键接口 |
| **整体** | **>= 50%** | V1.1 的底线 |

### Flutter 前端测试策略

**Widget 测试**：

需要覆盖的页面：
- 登录页（LoginPage）：表单校验、提交、跳转
- 记账表单页（TransactionFormPage）：字段填写、草稿恢复、提交
- 首页（HomePage）：数据加载、显示

Mock 方案：使用 `mocktail` 或 `mockito` mock Service 层。使用 `ProviderScope.overrides` 注入 mock Provider。

**覆盖率目标**：V1.1 不对 Flutter 端设定硬性覆盖率目标，但要求至少有 3 个 Widget 测试文件通过。

验收标准：

- `go test ./...` 全部通过，无 FAIL
- 覆盖率报告生成成功，核心模块达到目标
- Flutter `flutter test` 全部通过
- CI 流水线中测试步骤正确执行

---

# GitHub Actions 使用指南

本节为团队成员提供 GitHub Actions 的完整入门指南，确保每个人都能理解和维护 CI/CD 流水线。

## 核心概念

GitHub Actions 是 GitHub 提供的 CI/CD 平台，允许在代码仓库中定义自动化工作流。它的核心概念有以下几个：

**Workflow（工作流）**：一个自动化流程，由一个 YAML 文件定义，存放在仓库的 `.github/workflows/` 目录下。每个 YAML 文件就是一个 Workflow。一个仓库可以有多个 Workflow，它们互相独立。

**Event（事件）**：触发 Workflow 执行的动作。常用事件包括：
- `push`：代码推送时触发
- `pull_request`：PR 创建或更新时触发
- `schedule`：定时触发（cron 表达式）
- `workflow_dispatch`：手动触发

**Job（任务）**：Workflow 中的一组步骤。一个 Workflow 可以包含多个 Job，默认并行执行。如果 Job 之间有依赖关系，使用 `needs` 关键字声明顺序。每个 Job 运行在独立的虚拟机（Runner）上。

**Step（步骤）**：Job 中的最小执行单元。每个 Step 要么运行一条 shell 命令（`run`），要么调用一个 Action（`uses`）。Step 按顺序依次执行。

**Action（动作）**：可复用的操作单元，由社区或官方提供。使用 `uses` 关键字引用。比如 `actions/checkout@v4` 用于拉取代码，`actions/setup-go@v5` 用于安装 Go 环境。

**Runner（运行器）**：执行 Job 的虚拟机。GitHub 提供免费的托管 Runner（`ubuntu-latest`、`windows-latest`、`macos-latest`）。公开仓库每月有 2000 分钟免费额度，私有仓库每月有 500 分钟（Free 计划）。

## YAML 文件结构

一个典型的 Workflow YAML 文件结构如下：

```yaml
# .github/workflows/ci.yml

name: CI                          # Workflow 名称，显示在 Actions 页面

on:                               # 触发条件
  push:
    branches: [main]              # 仅 main 分支 push 时触发
  pull_request:
    branches: [main]              # 仅指向 main 的 PR 触发

jobs:                             # 任务列表
  build:                          # Job ID（自定义名称）
    name: Build and Test          # Job 显示名称
    runs-on: ubuntu-latest        # 运行环境

    services:                     # 附属服务（如数据库）
      mysql:
        image: mysql:8.0
        env:
          MYSQL_ROOT_PASSWORD: test
          MYSQL_DATABASE: goledger_test
        ports:
          - 3306:3306
        options: >-
          --health-cmd="mysqladmin ping"
          --health-interval=10s
          --health-timeout=5s
          --health-retries=5

    steps:                        # 步骤列表
      - name: Checkout            # 步骤名称
        uses: actions/checkout@v4 # 使用官方 Action 拉取代码

      - name: Setup Go
        uses: actions/setup-go@v5
        with:                     # Action 的输入参数
          go-version: '1.23'

      - name: Run tests
        run: |                    # 执行 shell 命令
          cd backend
          go test -v ./...
        env:                      # 环境变量
          DB_HOST: 127.0.0.1
          DB_PORT: 3306

      - name: Upload coverage
        uses: actions/upload-artifact@v4
        with:
          name: coverage-report
          path: backend/coverage.out
```

## 关键语法详解

**环境变量与 Secrets**：

```yaml
env:                              # Workflow 级环境变量
  GO_VERSION: '1.23'

jobs:
  build:
    env:                          # Job 级环境变量
      CGO_ENABLED: '0'
    steps:
      - run: echo ${{ secrets.DOCKER_PASSWORD }}  # 引用 Secret
```

Secret 的设置路径：GitHub 仓库页面 → Settings → Secrets and variables → Actions → New repository secret。Secret 在日志中会被自动遮蔽显示为 `***`。

**条件执行**：

```yaml
steps:
  - name: Deploy
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'
    run: ./deploy.sh
```

**Job 依赖**：

```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    steps: [...]

  deploy:
    needs: test                   # deploy 在 test 成功后才执行
    runs-on: ubuntu-latest
    steps: [...]
```

**矩阵策略**（多版本测试）：

```yaml
jobs:
  test:
    strategy:
      matrix:
        go-version: ['1.22', '1.23']
        os: [ubuntu-latest, macos-latest]
    runs-on: ${{ matrix.os }}
    steps:
      - uses: actions/setup-go@v5
        with:
          go-version: ${{ matrix.go-version }}
```

**Artifact（构建产物）**：

用于在 Job 之间传递文件，或保存构建产物供下载：

```yaml
# 上传
- uses: actions/upload-artifact@v4
  with:
    name: my-binary
    path: backend/server
    retention-days: 7              # 保留 7 天

# 下载（另一个 Job 中）
- uses: actions/download-artifact@v4
  with:
    name: my-binary
```

**缓存**（加速构建）：

```yaml
- uses: actions/cache@v4
  with:
    path: ~/go/pkg/mod
    key: ${{ runner.os }}-go-${{ hashFiles('**/go.sum') }}
    restore-keys: |
      ${{ runner.os }}-go-
```

## 常用 Actions 速查

| Action | 用途 | 示例 |
|--------|------|------|
| `actions/checkout@v4` | 拉取代码 | 几乎每个 Job 都需要 |
| `actions/setup-go@v5` | 安装 Go | `with: go-version: '1.23'` |
| `subosito/flutter-action@v2` | 安装 Flutter | `with: flutter-version: '3.32.2'` |
| `actions/cache@v4` | 缓存依赖 | 加速 `go mod download` |
| `actions/upload-artifact@v4` | 上传产物 | 保存覆盖率报告 |
| `docker/login-action@v3` | 登录 Docker Hub | 推送镜像前使用 |
| `docker/build-push-action@v5` | 构建并推送镜像 | 支持多平台构建 |

## 本项目的日常操作

**查看 CI 结果**：推送代码后，在 GitHub 仓库页面点击 "Actions" 标签页，可以看到所有 Workflow 的执行记录。点击具体的 Run 可以查看每个 Job 和 Step 的日志。

**手动触发 Workflow**：如果 Workflow 配置了 `workflow_dispatch` 事件，可以在 Actions 页面手动点击 "Run workflow" 按钮触发。

**调试失败的 CI**：
1. 点击失败的 Job，展开失败的 Step，查看错误日志
2. 如果是测试失败，查看具体的测试用例名和错误信息
3. 本地复现问题后修复，push 新代码会自动重新触发 CI

**添加新的 Workflow**：在 `.github/workflows/` 目录下新建 `.yml` 文件，push 到 main 分支即可生效。

---

# 开发计划

V1.1 的所有功能分为 4 个阶段，按优先级排序，可逐阶段交付。

## 第一阶段：工程基础（预计 3 ~ 4 天）

搭建 CI/CD 和测试基础设施，所有后续工作都建立在这个基础之上。

- 创建 `.github/workflows/ci.yml`，配置后端 lint + test + build 三个 Job
- 创建 `.github/workflows/docker.yml`，配置 tag 触发的 Docker 镜像构建
- 为 Repository 层定义 interface，重构 Service 层依赖注入
- 编写 `pkg/` 层单元测试（jwt、errs、response）
- 编写 Service 层核心测试（创建流水的事务逻辑、乐观锁）
- 确保 CI 全绿，覆盖率报告可生成
- README 添加 CI 状态徽章

里程碑：push 代码后 GitHub Actions 自动执行，3 个 Job 全部绿色。

## 第二阶段：后端增强（预计 4 ~ 5 天）

在 CI 保障下安全地增强后端。

- 实现限流中间件（全局 + Per-IP + Per-User），使用 `golang.org/x/time/rate`
- 新增 3 个限流错误码（42901/42902/42903）
- 配置文件新增 `rate_limit` 配置段
- 注册自定义参数校验器，增强所有接口的校验规则
- 校验失败返回具体错误描述
- 集成 `swaggo/swag`，为所有 Handler 添加 Swagger 注释
- 注册 Swagger UI 路由，通过配置控制启用/禁用
- 为新增的限流中间件和校验器编写测试
- 所有改动通过 CI

里程碑：限流中间件通过压测验证，Swagger UI 可访问并展示全部接口。

## 第三阶段：前端增强（预计 5 ~ 7 天）

并行于后端增强，可同时进行。

- 引入 `flutter_localizations` + `intl`，创建 ARB 文件
- 抽取所有硬编码中文字符串，替换为 `AppLocalizations` 调用
- 实现日历视图组件，集成到流水页面
- 实现下拉刷新自定义动画，替换 4 个页面的 RefreshIndicator
- 实现记账表单草稿缓存（debounce 保存 + 恢复提示 + 提交清除）
- 编写 3 个 Widget 测试文件
- CI 中增加 Flutter analyze 和 test

里程碑：App 支持中英文切换，日历视图可正常浏览，草稿功能可靠。

## 第四阶段：收尾与发布（预计 2 ~ 3 天）

- 全量回归测试（手动走一遍验收流程）
- 修复测试中发现的 bug
- 更新 `require-v1.1.md` 中的变更记录
- 更新 `README.md`（新增功能说明、Swagger 文档入口）
- 创建 tag `v1.1.0`，触发 Docker 镜像构建
- 部署到服务器验证

里程碑：`v1.1.0` tag 创建，Docker 镜像推送成功，服务器部署运行正常。

---

# 交付物清单

| 交付物 | 描述 | 验收方式 |
|--------|------|---------|
| 限流中间件 | 三层令牌桶限流（全局/IP/用户） | 压测超阈值返回 429 |
| 参数校验增强 | 所有接口的严格校验 + 自定义校验器 | 非法参数返回 400 + 具体描述 |
| Swagger 文档 | 自动生成的交互式 API 文档 | 访问 `/swagger/index.html` |
| CI/CD 流水线 | 2 条 GitHub Actions Workflow | push 后自动运行，全绿 |
| 自动化测试 | 后端单元测试 + 集成测试，覆盖率 >= 50% | `go test` 全通过 |
| 日历视图 | 流水模块的按月日历展示 | 切换月份、点击日期查看明细 |
| 下拉刷新动画 | 4 个页面的品牌化刷新动画 | 动画流畅，网络异常不卡死 |
| 本地草稿缓存 | 记账表单的防丢失机制 | 退出后重开能恢复草稿 |
| 多语言（i18n） | 中/英文双语支持 | 系统语言切换后界面跟随 |
| Flutter 测试 | 至少 3 个 Widget 测试 | `flutter test` 全通过 |
| 文档更新 | README + require-v1.1.md | 内容完整、与代码一致 |

---

# 版本变更记录

| 版本 | 日期 | 变更内容 |
|------|------|---------|
| v1.1.0-alpha.1 | 2026-04-03 | 第一阶段完成：CI/CD 流水线搭建，GitHub Actions 配置（ci.yml + docker.yml），Repository 接口抽象与依赖注入重构，pkg/ 层单元测试，Service 层核心测试，覆盖率报告生成，README 添加 CI 状态徽章 |
| v1.1.0-alpha.2 | 2026-04-03 | 第二阶段完成：三层令牌桶限流中间件（全局/Per-IP/Per-User），新增 3 个限流错误码（42901/42902/42903），自定义参数校验器注册与全接口校验规则增强，Swagger/OpenAPI 文档自动生成与 UI 路由集成，限流与校验器测试编写，CI 全绿 |
| v1.1.0-beta.1 | 2026-04-05 | 第三阶段完成：flutter_localizations + intl 国际化框架接入，~94 条中英文翻译（ARB 文件），日历视图组件实现与流水页面集成，4 个页面下拉刷新自定义品牌动画，记账表单草稿缓存机制（debounce + 恢复 + 清除），3 个 Widget 测试文件，CI 增加 Flutter analyze 和 test |
| v1.1.0-rc.1 | 2026-04-05 | 第四阶段完成：全量回归测试，bug 修复，require-v1.1.md 变更记录更新，README 更新（新增功能说明 + Swagger 入口），创建 tag v1.1.0 触发 Docker 镜像构建，服务器部署验证 |
| v1.1.0 | 2026-04-07 | 正式发布：所有功能验收通过，Docker 镜像推送成功，生产环境部署运行正常 |
