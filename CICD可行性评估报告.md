# GoLedger CI/CD 可行性评估报告

> 评估日期：2026-05-06  
> 项目类型：Go 后端 + Flutter 前端  
> 部署环境：自有服务器 (CentOS, 115.190.125.177)

---

## 一、项目现状分析

### 1.1 技术栈

| 组件 | 技术 | 构建方式 | 部署方式 |
|------|------|---------|---------|
| **后端** | Go 1.21 + Gin + MySQL | `go build` | Docker Compose |
| **前端** | Flutter 3.32.2 + Dart 3.8.1 | `flutter build apk` | APK 分发 |
| **数据库** | MySQL 8.0 | Docker 镜像 | Docker Compose |
| **版本控制** | Git + GitHub | - | - |

### 1.2 当前部署流程

**后端部署**（手动）：
```bash
1. SSH 登录服务器
2. git pull origin main
3. docker compose down
4. docker compose up -d --build
```

**前端发布**（手动）：
```bash
1. 本地执行 flutter build apk
2. 手动传输 APK 到手机
3. 用户手动安装
```

**痛点**：
- ❌ 手动操作，容易出错
- ❌ 无自动化测试
- ❌ 无版本回滚机制
- ❌ 无部署日志记录
- ❌ 前端发布依赖本地环境

---

## 二、CI/CD 方案对比

### 2.1 GitHub Actions（推荐 ⭐⭐⭐⭐⭐）

#### 优势
- ✅ **零成本**：公开仓库完全免费，私有仓库 2000 分钟/月免费
- ✅ **零配置服务器**：GitHub 提供 Runner，无需自建
- ✅ **生态完善**：海量现成 Actions 可用
- ✅ **与 GitHub 深度集成**：PR 自动触发、状态检查
- ✅ **支持多平台**：Linux/Windows/macOS Runner

#### 劣势
- ❌ **国内访问慢**：GitHub 服务器在海外
- ❌ **构建时间限制**：单个 Job 最长 6 小时
- ❌ **依赖网络**：无法访问内网资源

#### 适用场景
✅ **强烈推荐用于 GoLedger**
- 后端自动构建 Docker 镜像
- 前端自动构建 APK
- 自动运行测试
- 自动部署到服务器（通过 SSH）

#### 成本估算
- **免费额度**：2000 分钟/月（私有仓库）
- **GoLedger 预估**：
  - 后端构建：5 分钟/次
  - 前端构建：10 分钟/次
  - 每天 3 次构建 = 45 分钟/天 = 1350 分钟/月
- ✅ **完全在免费额度内**

---

### 2.2 GitLab CI/CD（备选 ⭐⭐⭐⭐）

#### 优势
- ✅ **功能强大**：内置 CI/CD、容器镜像仓库、制品库
- ✅ **可自建**：可部署到自己服务器
- ✅ **免费额度**：400 分钟/月（SaaS 版）

#### 劣势
- ❌ **需要迁移仓库**：当前在 GitHub
- ❌ **自建成本高**：需要额外服务器资源
- ❌ **学习曲线**：配置比 GitHub Actions 复杂

#### 适用场景
- 需要完全自主可控
- 已有 GitLab 基础设施
- 需要内网部署

#### 成本估算
- **SaaS 版**：免费 400 分钟/月（不够用）
- **自建版**：需要 2C4G 服务器（约 ¥100/月）

---

### 2.3 Jenkins（传统方案 ⭐⭐⭐）

#### 优势
- ✅ **完全免费**：开源软件
- ✅ **高度可定制**：插件生态丰富
- ✅ **内网部署**：可访问内网资源

#### 劣势
- ❌ **需要自建服务器**：占用资源
- ❌ **维护成本高**：需要管理 Jenkins 本身
- ❌ **配置复杂**：学习曲线陡峭
- ❌ **UI 老旧**：用户体验差

#### 适用场景
- 已有 Jenkins 基础设施
- 需要复杂的构建流程
- 企业级项目

#### 成本估算
- **服务器成本**：需要独立服务器（2C4G，约 ¥100/月）
- **维护成本**：需要专人维护

---

### 2.4 自建 CI/CD（不推荐 ⭐⭐）

#### 优势
- ✅ **完全自主**：无第三方依赖

#### 劣势
- ❌ **开发成本极高**：需要从零开发
- ❌ **维护成本极高**：需要持续维护
- ❌ **功能有限**：难以达到成熟方案的水平

#### 适用场景
❌ **不推荐用于 GoLedger**

---

## 三、推荐方案：GitHub Actions

### 3.1 为什么选择 GitHub Actions

| 维度 | 评分 | 说明 |
|------|------|------|
| **成本** | ⭐⭐⭐⭐⭐ | 完全免费 |
| **易用性** | ⭐⭐⭐⭐⭐ | YAML 配置，简单直观 |
| **集成度** | ⭐⭐⭐⭐⭐ | 与 GitHub 无缝集成 |
| **生态** | ⭐⭐⭐⭐⭐ | 海量现成 Actions |
| **维护成本** | ⭐⭐⭐⭐⭐ | 零维护 |
| **国内可用性** | ⭐⭐⭐ | 需要稳定网络 |

### 3.2 GoLedger CI/CD 架构设计

```
GitHub 仓库
    ↓
代码推送/PR
    ↓
GitHub Actions Runner (云端)
    ├─ 后端 Pipeline
    │   ├─ 代码检查 (golangci-lint)
    │   ├─ 单元测试 (go test)
    │   ├─ 构建 Docker 镜像
    │   ├─ 推送到 Docker Hub
    │   └─ SSH 部署到服务器
    │
    └─ 前端 Pipeline
        ├─ 代码检查 (flutter analyze)
        ├─ 单元测试 (flutter test)
        ├─ 构建 APK (flutter build apk)
        ├─ 上传到 GitHub Release
        └─ (可选) Shorebird 热更新
```

### 3.3 实施计划

#### Phase 1: 基础 CI（1-2 天）

**目标**：自动化代码检查和测试

**后端 Workflow**：
- 触发条件：Push 到 main 分支、PR
- 步骤：
  1. Checkout 代码
  2. 安装 Go 环境
  3. 运行 `go mod download`
  4. 运行 `golangci-lint`
  5. 运行 `go test ./...`

**前端 Workflow**：
- 触发条件：Push 到 main 分支、PR
- 步骤：
  1. Checkout 代码
  2. 安装 Flutter 环境
  3. 运行 `flutter pub get`
  4. 运行 `flutter analyze`
  5. 运行 `flutter test`

**产出**：
- ✅ 每次提交自动检查代码质量
- ✅ PR 合并前必须通过测试
- ✅ 及早发现问题

#### Phase 2: 自动构建（2-3 天）

**目标**：自动构建可部署的产物

**后端 Workflow**：
- 触发条件：Tag 推送（如 `v1.0.0`）
- 步骤：
  1. 构建 Docker 镜像
  2. 推送到 Docker Hub
  3. 创建 GitHub Release

**前端 Workflow**：
- 触发条件：Tag 推送
- 步骤：
  1. 构建 Release APK
  2. 上传到 GitHub Release
  3. (可选) 发布 Shorebird 补丁

**产出**：
- ✅ 自动生成 Docker 镜像
- ✅ 自动生成 APK 文件
- ✅ 版本化管理

#### Phase 3: 自动部署（2-3 天）

**目标**：自动部署到生产服务器

**后端部署 Workflow**：
- 触发条件：Tag 推送
- 步骤：
  1. SSH 连接到服务器
  2. 拉取最新镜像
  3. 执行 `docker compose up -d`
  4. 健康检查
  5. 发送通知（可选）

**前端部署 Workflow**：
- 触发条件：Tag 推送
- 步骤：
  1. 构建 APK
  2. 上传到 GitHub Release
  3. 发送通知（可选）

**产出**：
- ✅ 一键发版
- ✅ 自动部署到生产
- ✅ 部署日志记录

---

## 四、详细实施方案

### 4.1 后端 CI/CD Workflow

**文件位置**：`.github/workflows/backend-ci.yml`

**核心功能**：
- 代码检查（golangci-lint）
- 单元测试（go test）
- Docker 镜像构建
- 自动部署到服务器

**触发条件**：
- Push 到 main：运行测试
- Tag 推送：构建 + 部署

**部署流程**：
```bash
1. GitHub Actions 构建 Docker 镜像
2. 推送镜像到 Docker Hub
3. SSH 连接到服务器 115.190.125.177
4. 执行部署脚本：
   - docker compose pull
   - docker compose up -d
   - 健康检查
```

### 4.2 前端 CI/CD Workflow

**文件位置**：`.github/workflows/frontend-ci.yml`

**核心功能**：
- 代码检查（flutter analyze）
- 单元测试（flutter test）
- APK 构建
- 上传到 GitHub Release
- (可选) Shorebird 热更新

**触发条件**：
- Push 到 main：运行测试
- Tag 推送：构建 APK

**发布流程**：
```bash
1. GitHub Actions 构建 APK
2. 上传到 GitHub Release
3. 用户从 Release 页面下载安装
4. (可选) 通过 Shorebird 推送热更新
```

---

## 五、成本与收益分析

### 5.1 成本估算

| 项目 | 成本 | 说明 |
|------|------|------|
| **GitHub Actions** | ¥0/月 | 免费额度足够 |
| **Docker Hub** | ¥0/月 | 免费账户 |
| **服务器** | ¥0/月 | 已有服务器 |
| **开发时间** | 5-8 天 | 一次性投入 |
| **维护时间** | 1 小时/月 | 几乎零维护 |
| **总计** | **¥0/月** | |

### 5.2 收益分析

| 收益 | 量化 | 说明 |
|------|------|------|
| **节省部署时间** | 30 分钟/次 → 0 分钟 | 自动化部署 |
| **减少人为错误** | 100% | 标准化流程 |
| **提升发版频率** | 1 次/周 → 多次/天 | 降低发版成本 |
| **快速回滚** | 10 分钟 | 一键回滚到任意版本 |
| **提升代码质量** | - | 自动化测试 |

**投资回报率（ROI）**：
- 一次性投入：5-8 天开发时间
- 每月节省：约 10 小时部署时间
- **2 个月即可回本**

---

## 六、风险评估

### 6.1 技术风险

| 风险 | 概率 | 影响 | 缓解措施 |
|------|------|------|---------|
| GitHub Actions 服务中断 | 低 | 高 | 保留手动部署能力 |
| 网络问题导致部署失败 | 中 | 中 | 重试机制 + 通知 |
| Docker 镜像拉取失败 | 低 | 中 | 本地缓存镜像 |
| SSH 连接失败 | 低 | 高 | 多重认证方式 |

### 6.2 安全风险

| 风险 | 概率 | 影响 | 缓解措施 |
|------|------|------|---------|
| SSH 密钥泄露 | 低 | 高 | 使用 GitHub Secrets |
| Docker Hub Token 泄露 | 低 | 中 | 定期轮换 Token |
| 恶意代码注入 | 低 | 高 | PR Review + 分支保护 |

---

## 七、实施路线图

### 时间线（总计 5-8 天）

```
Week 1: 基础 CI
├─ Day 1-2: 后端 CI (代码检查 + 测试)
└─ Day 2-3: 前端 CI (代码检查 + 测试)

Week 2: 自动构建
├─ Day 4-5: 后端 Docker 构建
└─ Day 5-6: 前端 APK 构建

Week 3: 自动部署
├─ Day 7: 后端自动部署
└─ Day 8: 前端发布流程

Week 4: 优化与监控
└─ 按需: 通知、监控、回滚机制
```

### 里程碑

- ✅ **M1 (Day 3)**：CI 基础设施完成，PR 自动检查
- ✅ **M2 (Day 6)**：自动构建完成，Tag 触发构建
- ✅ **M3 (Day 8)**：自动部署完成，一键发版
- ✅ **M4 (按需)**：监控告警完成

---

## 八、前置条件检查

### 8.1 必需条件

- [x] GitHub 仓库已创建
- [x] 服务器可通过 SSH 访问
- [x] Docker 已安装在服务器
- [x] 后端已容器化（docker-compose.yml）
- [x] 前端可本地构建 APK

### 8.2 需要准备的资源

- [ ] Docker Hub 账号（免费）
- [ ] GitHub Secrets 配置：
  - `SSH_PRIVATE_KEY`：服务器 SSH 私钥
  - `SERVER_HOST`：115.190.125.177
  - `SERVER_USER`：服务器用户名
  - `DOCKER_USERNAME`：Docker Hub 用户名
  - `DOCKER_PASSWORD`：Docker Hub Token

---

## 九、结论与建议

### ✅ 强烈推荐实施 GitHub Actions CI/CD

**核心理由**：
1. **零成本**：完全免费，无额外开支
2. **低风险**：成熟方案，技术风险低
3. **高收益**：节省大量手动部署时间
4. **易维护**：几乎零维护成本
5. **可扩展**：未来可轻松添加更多功能

### 📋 下一步行动

1. **立即开始**：从 Phase 1 基础 CI 开始
2. **渐进式实施**：先 CI 后 CD，降低风险
3. **持续优化**：根据实际使用情况调整

### ⚠️ 注意事项

- 首次配置需要仔细测试，避免影响生产环境
- 建议先在测试分支验证 Workflow
- 保留手动部署能力作为备份方案
- 定期检查 GitHub Actions 使用量

---

## 参考资料

- **GitHub Actions 文档**：https://docs.github.com/actions
- **Docker Hub**：https://hub.docker.com
- **Go CI 最佳实践**：https://github.com/golangci/golangci-lint
- **Flutter CI 最佳实践**：https://docs.flutter.dev/deployment/cd
