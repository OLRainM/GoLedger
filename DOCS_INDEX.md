# GoLedger 文档索引

> 本文件用于索引项目所有文档。⚠️ 标记为「本地」的文档包含服务器 IP、配置等敏感信息，已在 `.gitignore` 中忽略，**不上传到 GitHub**。

---

## 一、文档分类总览

### 📘 公开文档（上传 GitHub）

| 文档 | 用途 |
|------|------|
| `README.md` | 项目主文档：功能概览、技术栈、架构图、快速开始 |
| `DOCS_INDEX.md` | 本文件，文档索引 |

### 📗 需求与设计文档（本地）

| 文档 | 用途 |
|------|------|
| `api.md` | 完整 API 接口文档（14 个接口，含请求/响应示例） |
| `require-v1.1.md` | V1.1 体验优化版需求文档 |
| `ui-design.md` | 轻盈暖色系 UI 设计规范 |

### 📙 项目规划文档（本地）

| 文档 | 用途 |
|------|------|
| `后续模块划分与分工.md` | V1.1 ~ V4 全版本规划与团队分工 |
| `V2.0版本任务书.md` | V2.0（数据洞察）四人团队任务书 |
| `第一次测试结果以及使用建议.md` | V1 首轮测试记录与建议 |

### 📕 运维与 CI/CD 文档（本地）

| 文档 | 用途 |
|------|------|
| `Jenkins-CICD实施方案.md` | Jenkins + 本地 Registry 完整方案（当前采用） |
| `CICD准备工作清单.md` | CI/CD 部署分阶段清单 |
| `快速开始手册.md` | CI/CD 5 步快速部署手册 |
| `准备工作完成总结.md` | CI/CD 准备工作总结 |
| `CICD使用指南.md` | CI/CD 日常使用指南（口语化） |
| `CICD故障排除手册.md` | CI/CD 问题排查手册（口语化） |
| `CICD详细实施方案.md` | ⚠️ 旧版 GitHub Actions 方案（已废弃，保留参考） |
| `Linux服务器代理配置指南.md` | Clash 代理配置方案 |

### 🛠️ 自动化脚本（本地）

| 脚本 | 用途 |
|------|------|
| `scripts/setup-cicd.sh` | 一键安装 Jenkins + Docker Registry |
| `scripts/verify-cicd.sh` | CI/CD 环境验证脚本 |

### 📱 前端专项文档（本地）

| 文档 | 用途 |
|------|------|
| `frontend/Shorebird集成指南.md` | Shorebird 热更新（Windows 环境） |
| `frontend/Shorebird-Linux安装指南.md` | Shorebird 热更新（Linux 环境） |
| `frontend/容错机制说明.md` | 域名失败降级到 IP 直连机制 |
| `frontend/热更新可行性评估.md` | Shorebird 热更新可行性评估 |

---

## 二、按场景查找

| 我想... | 看这个文档 |
|---------|-----------|
| 了解项目整体 | `README.md` |
| 开发新接口 | `api.md` |
| 做 UI 设计 | `ui-design.md` |
| 规划下一个版本 | `后续模块划分与分工.md` |
| 执行 V2 开发 | `V2.0版本任务书.md` |
| 首次部署 CI/CD | `快速开始手册.md` → `Jenkins-CICD实施方案.md` |
| CI/CD 日常使用 | `CICD使用指南.md` |
| CI/CD 出问题排查 | `CICD故障排除手册.md` |
| 配置服务器代理 | `Linux服务器代理配置指南.md` |
| 集成热更新 | `frontend/Shorebird-Linux安装指南.md` |

---

## 三、平台说明

### 前端平台范围

本项目前端**仅支持 Android 平台**。已移除以下平台目录：
- ❌ iOS（`frontend/ios/`）
- ❌ Linux（`frontend/linux/`）
- ❌ macOS（`frontend/macos/`）
- ❌ Web（`frontend/web/`）
- ❌ Windows（`frontend/windows/`）

保留：
- ✅ Android（`frontend/android/`）

构建命令：
```bash
cd frontend
flutter build apk --release --dart-define=BASE_URL=http://你的后端地址:8080
```

---

## 四、安全说明

⚠️ 所有标记为「本地」的文档包含以下敏感信息，**严禁上传到公开仓库**：
- 服务器 IP 地址
- 端口配置
- 部署路径
- 内部 API 细节

这些文档已在 `.gitignore` 中配置忽略。如需团队共享，请通过私有渠道（加密网盘、内部 Wiki）分发。
