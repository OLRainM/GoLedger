# GoLedger Shorebird 集成指南

> 本指南适用于 Windows 环境下的 Flutter 项目热更新配置

---

## 一、安装 Shorebird CLI

### 1.1 Windows 安装方式

Shorebird 官方暂未提供 Windows 一键安装脚本，需要手动安装：

#### 方法一：通过 PowerShell 安装（推荐）

```powershell
# 1. 下载 Shorebird CLI
$SHOREBIRD_VERSION = "1.1.3"  # 检查最新版本: https://github.com/shorebirdtech/shorebird/releases
$DOWNLOAD_URL = "https://github.com/shorebirdtech/shorebird/releases/download/v$SHOREBIRD_VERSION/shorebird-v$SHOREBIRD_VERSION-windows-x64.zip"
$INSTALL_DIR = "$env:LOCALAPPDATA\shorebird"

# 2. 创建安装目录
New-Item -ItemType Directory -Force -Path $INSTALL_DIR

# 3. 下载并解压
Invoke-WebRequest -Uri $DOWNLOAD_URL -OutFile "$env:TEMP\shorebird.zip"
Expand-Archive -Path "$env:TEMP\shorebird.zip" -DestinationPath $INSTALL_DIR -Force

# 4. 添加到 PATH（临时）
$env:Path = "$INSTALL_DIR\bin;" + $env:Path

# 5. 验证安装
shorebird --version
```

#### 方法二：手动安装

1. 访问 https://github.com/shorebirdtech/shorebird/releases
2. 下载最新的 `shorebird-vX.X.X-windows-x64.zip`
3. 解压到 `C:\Users\你的用户名\AppData\Local\shorebird`
4. 添加到系统环境变量 PATH：`%LOCALAPPDATA%\shorebird\bin`

### 1.2 永久添加到 PATH

```powershell
# 添加到用户环境变量（需要管理员权限）
[Environment]::SetEnvironmentVariable(
    "Path",
    [Environment]::GetEnvironmentVariable("Path", "User") + ";$env:LOCALAPPDATA\shorebird\bin",
    "User"
)

# 重启终端后生效
```

### 1.3 验证安装

```bash
shorebird --version
# 输出: Shorebird 1.1.3
```

---

## 二、初始化 Shorebird

### 2.1 登录账号

```bash
cd e:\project\GoLedger\frontend

# 首次使用需要登录（会打开浏览器）
shorebird login

# 登录成功后会显示：
# ✓ Logged in as your-email@example.com
```

### 2.2 初始化项目

```bash
# 在 frontend 目录下执行
shorebird init

# 会提示选择应用类型，选择 "Flutter"
# 会自动创建 shorebird.yaml 配置文件
```

### 2.3 检查生成的配置文件

初始化后会生成 `shorebird.yaml`：

```yaml
# shorebird.yaml
app_id: your-app-id-here
```

---

## 三、构建支持热更新的 Release 版本

### 3.1 首次发布（创建基线版本）

```bash
# 构建 Android Release 版本（带热更新能力）
shorebird release android --dart-define=BASE_URL=http://www.olraingin.com:8080

# 构建过程会：
# 1. 编译 Flutter 代码
# 2. 生成 Dart AOT 快照
# 3. 上传快照到 Shorebird 服务器
# 4. 生成 APK/AAB 文件
```

### 3.2 构建产物

```
build/app/outputs/
├── apk/release/
│   └── app-release.apk          # 可直接安装的 APK
└── bundle/release/
    └── app-release.aab          # 用于上传应用商店的 AAB
```

### 3.3 版本号管理

在 `pubspec.yaml` 中管理版本：

```yaml
version: 1.0.0+1  # 格式: 主版本号.次版本号.修订号+构建号
```

- 每次发布到应用商店时，递增版本号
- 热更新补丁不需要修改版本号

---

## 四、发布热更新补丁

### 4.1 修改代码后发布补丁

```bash
# 1. 修改 Dart 代码（如修复 Bug、调整 UI）
# 2. 发布补丁
shorebird patch android --dart-define=BASE_URL=http://www.olraingin.com:8080

# 3. 补丁会自动上传到 Shorebird 服务器
# 4. 用户下次启动应用时自动下载并应用
```

### 4.2 查看补丁列表

```bash
shorebird patches list android
```

### 4.3 回滚补丁

```bash
# 如果补丁导致问题，可以一键回滚
shorebird patch rollback android
```

---

## 五、测试热更新流程

### 5.1 完整测试步骤

```bash
# 1. 构建并安装基线版本
shorebird release android --dart-define=BASE_URL=http://www.olraingin.com:8080
adb install build/app/outputs/apk/release/app-release.apk

# 2. 修改代码（如改变按钮颜色）
# 编辑 lib/pages/auth/login_page.dart，修改某个文字

# 3. 发布补丁
shorebird patch android --dart-define=BASE_URL=http://www.olraingin.com:8080

# 4. 重启应用，观察是否自动更新
# 首次启动会下载补丁，第二次启动应用补丁
```

### 5.2 查看更新日志

应用启动时会在日志中显示：

```
[Shorebird] Checking for updates...
[Shorebird] Update available: patch 1.0.0+2
[Shorebird] Downloading patch...
[Shorebird] Patch downloaded, will apply on next restart
```

---

## 六、GoLedger 项目配置

### 6.1 推荐的构建命令

```bash
# 开发测试版本（使用域名）
shorebird release android --dart-define=BASE_URL=http://www.olraingin.com:8080

# 如果需要使用 IP 直连
shorebird release android --dart-define=BASE_URL=http://115.190.125.177:8080
```

### 6.2 .gitignore 配置

确保 `.gitignore` 中已包含：

```gitignore
# Shorebird
.shorebird/
shorebird.yaml  # 可选：如果不想提交 app_id
```

### 6.3 版本发布流程

```
1. 开发新功能
   ↓
2. 测试通过
   ↓
3. 更新 pubspec.yaml 版本号（如 1.0.0 → 1.1.0）
   ↓
4. 构建 Release 版本
   shorebird release android
   ↓
5. 上传到应用商店
   ↓
6. 发现 Bug？
   ↓
7. 修复代码
   ↓
8. 发布热更新补丁
   shorebird patch android
   ↓
9. 用户自动更新（无需重新下载 APK）
```

---

## 七、常见问题排查

### 7.1 安装失败

**问题**：下载 Shorebird 失败或速度慢

**解决**：
```powershell
# 使用代理下载
$env:HTTP_PROXY = "http://127.0.0.1:7890"
$env:HTTPS_PROXY = "http://127.0.0.1:7890"
# 然后重新执行下载命令
```

### 7.2 登录失败

**问题**：`shorebird login` 无法打开浏览器

**解决**：
1. 手动访问：https://console.shorebird.dev
2. 登录后复制 Token
3. 执行：`shorebird login --token YOUR_TOKEN`

### 7.3 构建失败

**问题**：`shorebird release` 报错

**检查清单**：
- [ ] Flutter 版本是否兼容（建议 3.19+）
- [ ] 是否已执行 `flutter pub get`
- [ ] Android SDK 是否正确配置
- [ ] 网络是否正常（需要上传到 Shorebird 服务器）

### 7.4 补丁不生效

**问题**：发布补丁后应用未更新

**排查步骤**：
1. 检查应用是否联网
2. 完全关闭应用后重新启动（不是切到后台）
3. 查看日志：`adb logcat | grep Shorebird`
4. 确认补丁版本号与基线版本匹配

---

## 八、最佳实践

### 8.1 版本管理策略

```
应用商店版本          热更新补丁
v1.0.0 (基线)    →  patch 1.0.0+1 (修复登录 Bug)
                 →  patch 1.0.0+2 (调整 UI 颜色)
                 →  patch 1.0.0+3 (优化性能)

v1.1.0 (新功能)  →  patch 1.1.0+1 (修复新功能 Bug)
```

### 8.2 发布前检查清单

- [ ] 代码已在本地测试通过
- [ ] 修改内容仅涉及 Dart 代码（不含原生代码）
- [ ] 未添加新的插件依赖
- [ ] 未修改 AndroidManifest.xml
- [ ] 版本号正确（补丁不需要改版本号）

### 8.3 灰度发布建议

Shorebird 支持按百分比灰度发布：

```bash
# 先发布给 10% 用户
shorebird patch android --stage 0.1

# 观察无问题后扩大到 50%
shorebird patch android --stage 0.5

# 最后全量发布
shorebird patch android --stage 1.0
```

---

## 九、监控与分析

### 9.1 查看更新统计

访问 Shorebird 控制台：https://console.shorebird.dev

可查看：
- 补丁下载次数
- 更新成功率
- 各版本分布
- 错误日志

### 9.2 本地查看补丁信息

```bash
# 查看当前项目的所有补丁
shorebird patches list android

# 查看特定补丁详情
shorebird patch info <patch-id>
```

---

## 十、注意事项

### 10.1 不支持的更新类型

❌ **以下情况必须发布新的应用商店版本**：
- 添加新的系统权限
- 添加/删除 Flutter 插件
- 修改原生 Kotlin/Java 代码
- 修改 AndroidManifest.xml
- 升级 Flutter SDK 大版本

### 10.2 应用商店政策

- **Google Play**：允许热更新，但不能改变应用核心功能
- **建议**：仅用于 Bug 修复和 UI 微调
- **禁止**：通过热更新添加未经审核的新功能

### 10.3 安全建议

- 定期更新 Shorebird CLI 到最新版本
- 不要在公开仓库中提交 `shorebird.yaml`（包含 app_id）
- 使用 CI/CD 时，通过环境变量传递 Token

---

## 十一、快速参考

### 常用命令

```bash
# 登录
shorebird login

# 初始化项目
shorebird init

# 构建 Release 版本
shorebird release android --dart-define=BASE_URL=http://www.olraingin.com:8080

# 发布补丁
shorebird patch android --dart-define=BASE_URL=http://www.olraingin.com:8080

# 查看补丁列表
shorebird patches list android

# 回滚补丁
shorebird patch rollback android

# 查看版本
shorebird --version

# 更新 CLI
shorebird upgrade
```

### 目录结构

```
frontend/
├── shorebird.yaml          # Shorebird 配置文件
├── .shorebird/             # 本地缓存（不提交到 Git）
├── pubspec.yaml            # 版本号管理
└── build/
    └── app/outputs/
        ├── apk/release/    # APK 文件
        └── bundle/release/ # AAB 文件
```

---

## 十二、下一步

完成 Shorebird 集成后：

1. ✅ 发布首个支持热更新的版本到应用商店
2. ✅ 测试热更新流程（修改代码 → 发布补丁 → 验证更新）
3. ✅ 建立发版规范文档
4. ✅ 配置 CI/CD 自动化发布（可选）
5. ✅ 监控更新数据，优化发布策略

---

## 参考资料

- **Shorebird 官网**：https://shorebird.dev
- **Shorebird 文档**：https://docs.shorebird.dev
- **GitHub Releases**：https://github.com/shorebirdtech/shorebird/releases
- **控制台**：https://console.shorebird.dev
