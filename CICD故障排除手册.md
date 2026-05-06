# GoLedger CI/CD 故障排除手册

> 遇到问题不要慌，这份文档手把手教你怎么解决

---

## 一、快速诊断：我的问题属于哪一类？

### 看看你的情况是哪种：

| 症状 | 可能的问题 | 跳转到 |
|------|-----------|--------|
| 推送代码后没反应 | CI 没有触发 | [问题 1](#问题-1ci-没有触发) |
| 代码检查失败（红叉） | 代码格式或语法错误 | [问题 2](#问题-2代码检查失败) |
| 测试失败 | 单元测试有问题 | [问题 3](#问题-3测试失败) |
| Docker 镜像构建失败 | Dockerfile 或依赖问题 | [问题 4](#问题-4docker-镜像构建失败) |
| APK 构建失败 | Flutter 环境或配置问题 | [问题 5](#问题-5apk-构建失败) |
| 部署到服务器失败 | SSH 连接或服务器问题 | [问题 6](#问题-6部署失败) |
| 服务启动后立即挂掉 | 配置错误或端口冲突 | [问题 7](#问题-7服务启动失败) |
| APK 没有上传到 Release | 权限或路径问题 | [问题 8](#问题-8apk-未上传) |

---

## 问题 1：CI 没有触发

### 症状

推送代码到 GitHub 后，Actions 页面没有新的运行记录。

### 可能原因

1. **修改的文件不在监控范围内**
   - 比如你只改了 `README.md`，但 CI 只监控 `backend/` 和 `frontend/` 目录

2. **Workflow 文件有语法错误**
   - YAML 格式不对，GitHub 无法解析

3. **分支不对**
   - CI 只监控 `main` 分支，你推送到了其他分支

### 解决步骤

**步骤 1：确认推送成功**
```bash
# 查看最近的提交
git log --oneline -5

# 确认已推送到远程
git status
```

**步骤 2：检查 Workflow 配置**
```bash
# 查看后端 CI 配置
cat .github/workflows/backend-ci.yml

# 重点看这几行：
on:
  push:
    branches: [ main ]  # 确认分支名正确
    paths:
      - 'backend/**'    # 确认路径包含你修改的文件
```

**步骤 3：检查 Actions 是否启用**
- 访问：https://github.com/OLRainM/GoLedger/settings/actions
- 确认 "Actions permissions" 设置为 "Allow all actions"

**步骤 4：手动触发测试**
- 访问：https://github.com/OLRainM/GoLedger/actions
- 点击左侧的 Workflow 名称
- 点击 "Run workflow" 按钮

### 如果还是不行

```bash
# 强制触发：修改 Workflow 文件
cd .github/workflows
# 在文件末尾加一个空行
echo "" >> backend-ci.yml
git add .
git commit -m "ci: trigger workflow"
git push origin main
```

---

## 问题 2：代码检查失败

### 症状

GitHub Actions 显示红色 ❌，点开看到 "代码格式检查" 或 "go vet" 失败。

### 典型错误信息

```
以下文件需要格式化:
internal/handler/auth_handler.go
internal/service/auth_service.go
```

或者

```
go vet: undefined: SomeFunction
```

### 解决步骤

**对于 Go 后端：**

```bash
# 1. 格式化所有代码
cd backend
go fmt ./...

# 2. 运行静态检查
go vet ./...

# 3. 如果有错误，根据提示修复

# 4. 重新提交
git add .
git commit -m "fix: 修复代码格式问题"
git push origin main
```

**对于 Flutter 前端：**

```bash
# 1. 格式化所有代码
cd frontend
dart format .

# 2. 运行代码分析
flutter analyze

# 3. 如果有错误，根据提示修复

# 4. 重新提交
git add .
git commit -m "fix: 修复代码格式问题"
git push origin main
```

### 常见错误及修复

| 错误 | 原因 | 修复 |
|------|------|------|
| `gofmt` 失败 | 代码格式不规范 | 运行 `go fmt ./...` |
| `undefined: xxx` | 函数或变量未定义 | 检查拼写，添加 import |
| `unused variable` | 声明了变量但没用 | 删除或使用该变量 |
| `missing return` | 函数缺少返回值 | 添加 return 语句 |

---

## 问题 3：测试失败

### 症状

CI 运行到 "运行单元测试" 步骤时失败。

### 典型错误信息

```
FAIL: TestLogin (0.00s)
    auth_test.go:25: Expected status 200, got 401
```

### 解决步骤

**步骤 1：本地复现问题**
```bash
# 后端测试
cd backend
go test -v ./...

# 前端测试
cd frontend
flutter test
```

**步骤 2：查看失败的测试**
- 找到报错的测试文件和行号
- 理解测试期望的行为
- 检查代码是否符合预期

**步骤 3：修复测试或代码**

两种情况：
1. **代码有 Bug** → 修复代码
2. **测试过时了** → 更新测试

**步骤 4：确认修复**
```bash
# 再次运行测试
go test -v ./...  # 或 flutter test

# 确认全部通过后提交
git add .
git commit -m "fix: 修复测试失败问题"
git push origin main
```

### 调试技巧

```bash
# 只运行特定的测试
go test -v -run TestLogin ./internal/service

# 查看详细输出
go test -v -race ./...

# Flutter 测试调试
flutter test --reporter expanded
```

---

## 问题 4：Docker 镜像构建失败

### 症状

"构建并推送 Docker 镜像" 步骤失败。

### 典型错误信息

```
ERROR: failed to solve: process "/bin/sh -c go build" did not complete successfully
```

或者

```
ERROR: failed to push: denied: requested access to the resource is denied
```

### 解决步骤

**情况 A：构建失败**

```bash
# 1. 本地测试构建
cd backend
docker build -t test-build .

# 2. 查看详细错误
docker build --no-cache -t test-build .

# 3. 常见问题：
# - go.mod 文件缺失或损坏
# - 依赖下载失败
# - 代码编译错误
```

**情况 B：推送失败（权限问题）**

```bash
# 1. 检查 Docker Hub Token
# 访问：https://github.com/OLRainM/GoLedger/settings/secrets/actions
# 确认 DOCKER_USERNAME 和 DOCKER_PASSWORD 正确

# 2. 测试 Token 是否有效
docker login -u 你的用户名 -p 你的Token

# 3. 如果 Token 过期，重新生成
# 访问：https://hub.docker.com/settings/security
# 生成新 Token 并更新 GitHub Secrets
```

**情况 C：网络问题**

```bash
# 如果是依赖下载失败，可能是网络问题
# 在 Dockerfile 中添加镜像加速：

# Go 模块代理
ENV GOPROXY=https://goproxy.cn,direct

# 或者重试构建（有时候网络抖动）
```

---

## 问题 5：APK 构建失败

### 症状

"构建 Release APK" 步骤失败。

### 典型错误信息

```
Error: Gradle task assembleRelease failed with exit code 1
```

或者

```
Error: The Flutter SDK is not available
```

### 解决步骤

**步骤 1：本地测试构建**
```bash
cd frontend
flutter clean
flutter pub get
flutter build apk --release --dart-define=BASE_URL=http://www.olraingin.com:8080
```

**步骤 2：常见问题排查**

| 错误 | 原因 | 解决 |
|------|------|------|
| `Gradle build failed` | 依赖冲突或配置错误 | 检查 `build.gradle.kts` |
| `SDK not found` | Flutter 版本不对 | 检查 Workflow 中的 Flutter 版本 |
| `Out of memory` | 构建内存不足 | 在 `gradle.properties` 增加内存 |
| `NDK not found` | NDK 版本问题 | 更新 `build.gradle.kts` 中的 NDK 版本 |

**步骤 3：检查 Workflow 配置**
```yaml
# .github/workflows/frontend-build.yml
- name: 设置 Flutter 环境
  uses: subosito/flutter-action@v2
  with:
    flutter-version: '3.32.2'  # 确认版本正确
    channel: 'stable'
```

**步骤 4：清理缓存重试**

有时候是缓存问题，可以在 Workflow 中添加清理步骤：
```yaml
- name: 清理缓存
  run: flutter clean
```

---

## 问题 6：部署失败

### 症状

"部署到生产服务器" 步骤失败。

### 典型错误信息

```
ssh: connect to host 115.190.125.177 port 22: Connection refused
```

或者

```
Permission denied (publickey)
```

或者

```
Error response from daemon: pull access denied
```

### 解决步骤

**情况 A：SSH 连接失败**

```bash
# 1. 测试 SSH 连接
ssh deploy@115.190.125.177

# 2. 如果连不上，检查：
# - 服务器是否在线
# - 防火墙是否开放 22 端口
# - SSH 服务是否运行

# 3. 在服务器上检查
sudo systemctl status sshd
sudo systemctl start sshd
```

**情况 B：SSH 密钥问题**

```bash
# 1. 检查 GitHub Secrets 中的密钥
# 访问：https://github.com/OLRainM/GoLedger/settings/secrets/actions
# 确认 SSH_PRIVATE_KEY 正确

# 2. 在服务器上检查 authorized_keys
ssh deploy@115.190.125.177
cat ~/.ssh/authorized_keys
# 确认包含对应的公钥

# 3. 检查权限
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
```

**情况 C：部署脚本执行失败**

```bash
# 1. SSH 登录服务器
ssh deploy@115.190.125.177

# 2. 手动执行部署脚本
cd ~/scripts
./deploy.sh latest

# 3. 查看详细错误
# 根据错误信息修复脚本

# 4. 常见问题：
# - 脚本没有执行权限：chmod +x deploy.sh
# - Docker 命令权限不足：sudo usermod -aG docker deploy
# - 项目目录不存在：mkdir -p /opt/GoLedger
```

**情况 D：Docker 镜像拉取失败**

```bash
# 在服务器上手动拉取测试
docker pull 你的用户名/goledger-backend:latest

# 如果失败，可能是：
# 1. Docker Hub 登录过期
docker login

# 2. 镜像名称错误
# 检查 docker-compose.yml 中的镜像名

# 3. 网络问题
# 配置 Docker 镜像加速
```

---

## 问题 7：服务启动失败

### 症状

部署成功了，但服务启动后立即退出或健康检查失败。

### 解决步骤

**步骤 1：查看服务状态**
```bash
ssh deploy@115.190.125.177
cd /opt/GoLedger/backend
docker compose ps
```

**步骤 2：查看日志**
```bash
# 查看所有服务日志
docker compose logs

# 查看特定服务日志
docker compose logs backend
docker compose logs mysql

# 实时查看日志
docker compose logs -f --tail=100
```

**步骤 3：常见问题排查**

| 症状 | 可能原因 | 解决 |
|------|---------|------|
| 端口已被占用 | 8080 端口被其他程序占用 | `netstat -tlnp \| grep 8080` 找到并关闭 |
| 数据库连接失败 | MySQL 未启动或配置错误 | 检查 `config.yaml` 和 `docker-compose.yml` |
| 配置文件缺失 | `config.yaml` 不存在 | 确认文件存在且格式正确 |
| 权限问题 | 文件权限不对 | `chmod` 修改权限 |

**步骤 4：手动启动测试**
```bash
# 停止所有服务
docker compose down

# 逐个启动，观察日志
docker compose up mysql
# 等 MySQL 启动完成后
docker compose up backend
```

---

## 问题 8：APK 未上传

### 症状

构建成功了，但 GitHub Release 页面没有 APK 文件。

### 解决步骤

**步骤 1：检查构建日志**
- 打开 Frontend Build 的日志
- 找到 "上传到 GitHub Release" 步骤
- 查看是否有错误信息

**步骤 2：检查 APK 路径**
```yaml
# .github/workflows/frontend-build.yml
- name: 上传到 GitHub Release
  uses: softprops/action-gh-release@v1
  with:
    files: |
      frontend/build/app/outputs/flutter-apk/goledger-${{ steps.meta.outputs.version }}.apk
```

确认路径正确。

**步骤 3：检查权限**
- 访问：https://github.com/OLRainM/GoLedger/settings/actions
- 确认 "Workflow permissions" 设置为 "Read and write permissions"

**步骤 4：手动上传（临时方案）**
```bash
# 本地构建 APK
cd frontend
flutter build apk --release --dart-define=BASE_URL=http://www.olraingin.com:8080

# 手动上传到 Release
# 访问：https://github.com/OLRainM/GoLedger/releases
# 点击 "Edit" 编辑对应的 Release
# 拖拽 APK 文件上传
```

---

## 三、通用排查技巧

### 1. 查看完整日志

```bash
# 在 GitHub Actions 页面
# 1. 点击失败的 Workflow
# 2. 点击失败的 Job
# 3. 展开每个步骤
# 4. 复制完整的错误信息
```

### 2. 本地复现问题

```bash
# 尽量在本地复现问题
# 这样可以快速调试，不用等 CI 运行

# 后端
cd backend
go test ./...
go build ./...

# 前端
cd frontend
flutter analyze
flutter test
flutter build apk --release
```

### 3. 对比成功的运行

- 找到最近一次成功的运行
- 对比代码变更：`git diff 成功的commit 失败的commit`
- 看看改了什么导致失败

### 4. 搜索错误信息

- 复制完整的错误信息
- Google 搜索：`错误信息 + github actions`
- 通常能找到类似问题的解决方案

### 5. 清理缓存

有时候是缓存问题：
```bash
# 在 Workflow 中添加清理步骤
- name: 清理缓存
  run: |
    go clean -cache
    flutter clean
```

---

## 四、紧急情况处理

### 生产环境挂了怎么办？

**不要慌！按这个顺序来：**

1. **立即回滚到上一个稳定版本**
```bash
ssh deploy@115.190.125.177
cd /opt/GoLedger/backend
git log --oneline -10  # 找到上一个稳定版本的 commit
git checkout 稳定版本的commit
docker compose down
docker compose up -d
```

2. **确认服务恢复**
```bash
curl http://115.190.125.177:8080/health
```

3. **排查问题**
- 查看日志找到根本原因
- 在本地修复问题
- 充分测试后再部署

### CI/CD 完全不工作了？

**临时方案：手动部署**

```bash
# 1. SSH 登录服务器
ssh deploy@115.190.125.177

# 2. 拉取最新代码
cd /opt/GoLedger
git pull origin main

# 3. 重新构建和部署
cd backend
docker compose down
docker compose build
docker compose up -d

# 4. 检查服务状态
docker compose ps
docker compose logs -f
```

---

## 五、预防措施

### 1. 定期检查

```bash
# 每周检查一次
# - GitHub Actions 运行状态
# - 服务器磁盘空间
# - Docker 镜像数量
# - 日志文件大小
```

### 2. 监控告警

设置监控（可选）：
- 服务器 CPU/内存/磁盘监控
- 服务健康检查
- 部署失败邮件通知

### 3. 备份

```bash
# 定期备份数据库
docker exec mysql mysqldump -u root -p goledger > backup.sql

# 定期备份配置文件
tar -czf config-backup.tar.gz backend/config.yaml backend/docker-compose.yml
```

### 4. 文档更新

遇到新问题并解决后：
- 记录到这份文档
- 分享给团队成员
- 避免重复踩坑

---

## 六、求助渠道

如果以上方法都不行：

1. **查看官方文档**
   - GitHub Actions: https://docs.github.com/actions
   - Docker: https://docs.docker.com
   - Flutter: https://docs.flutter.dev

2. **搜索 Issues**
   - GitHub Actions Issues
   - Stack Overflow

3. **提问**
   - 准备好完整的错误日志
   - 说明你已经尝试过的方法
   - 提供复现步骤

---

## 七、总结

**记住这几点：**
- ✅ 遇到问题先看日志
- ✅ 本地能复现就本地调试
- ✅ 改一点测一点，不要一次改太多
- ✅ 不确定就先回滚，稳定最重要
- ✅ 解决问题后记录下来

**CI/CD 是工具，不是魔法。出问题很正常，关键是知道怎么解决！**
