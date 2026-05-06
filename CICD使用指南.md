# GoLedger CI/CD 使用指南

> 这份文档用大白话告诉你怎么用 CI/CD，不懂技术也能看懂

---

## 一、CI/CD 是什么？能帮我做什么？

### 简单来说

**CI/CD 就是一个自动化小助手**，你只需要：
1. 写完代码
2. 推送到 GitHub
3. 剩下的事情它全帮你搞定

**它能帮你做什么？**
- ✅ 自动检查代码有没有错误
- ✅ 自动运行测试，确保功能正常
- ✅ 自动构建 Docker 镜像和 APK 安装包
- ✅ 自动部署到服务器
- ✅ 出问题了自动通知你

**不用 CI/CD 的话：**
- ❌ 每次都要手动 SSH 登录服务器
- ❌ 手动执行一堆命令
- ❌ 容易忘记步骤或者敲错命令
- ❌ 部署一次要 30 分钟

**用了 CI/CD 之后：**
- ✅ 推送代码后自动完成所有步骤
- ✅ 5-10 分钟自动部署完成
- ✅ 不会出错，每次都一样
- ✅ 你可以去喝杯咖啡等着

---

## 二、日常开发流程（最常用）

### 场景 1：修改代码并测试

**你要做的：**

```bash
# 1. 修改代码
# 在 VS Code 里改你的代码

# 2. 提交到本地
git add .
git commit -m "fix: 修复了登录页面的一个 Bug"

# 3. 推送到 GitHub
git push origin main
```

**CI/CD 自动帮你做的：**
1. 检测到你推送了代码
2. 自动运行代码检查（看有没有语法错误）
3. 自动运行测试（确保功能没坏）
4. 5 分钟后，你会在 GitHub Actions 页面看到结果

**在哪里看结果？**
- 打开：https://github.com/OLRainM/GoLedger/actions
- 找到最新的那个运行记录
- 绿色 ✅ = 通过，红色 ❌ = 有问题

**如果是红色怎么办？**
- 点进去看详细日志
- 找到报错的地方
- 修复代码
- 重新推送

---

### 场景 2：发布新版本到生产环境

**什么时候需要发布新版本？**
- 修复了重要 Bug，需要立即上线
- 开发了新功能，准备给用户使用
- 需要更新服务器上的代码

**你要做的：**

```bash
# 1. 确保代码已经推送到 main 分支
git checkout main
git pull origin main

# 2. 更新版本号（可选但推荐）
# 编辑 frontend/pubspec.yaml
# 把 version: 1.0.0+1 改成 version: 1.1.0+1

# 3. 提交版本号变更
git add frontend/pubspec.yaml
git commit -m "chore: bump version to 1.1.0"
git push origin main

# 4. 创建版本标签（这是关键！）
git tag v1.1.0
git push origin v1.1.0
```

**CI/CD 自动帮你做的：**
1. 检测到你推送了 Tag（v1.1.0）
2. 自动构建后端 Docker 镜像
3. 自动构建前端 APK 安装包
4. 自动推送镜像到 Docker Hub
5. 自动 SSH 连接到服务器
6. 自动拉取新镜像并重启服务
7. 自动进行健康检查
8. 自动创建 GitHub Release，上传 APK

**整个过程大约 10-15 分钟**

**在哪里看结果？**
- GitHub Actions：https://github.com/OLRainM/GoLedger/actions
- GitHub Release：https://github.com/OLRainM/GoLedger/releases
- Docker Hub：https://hub.docker.com/r/你的用户名/goledger-backend

**怎么确认部署成功？**
```bash
# 方法 1：访问健康检查接口
curl http://115.190.125.177:8080/health

# 方法 2：SSH 登录服务器查看
ssh deploy@115.190.125.177
cd /opt/GoLedger/backend
docker compose ps
docker compose logs -f --tail=50
```

---

## 三、查看构建状态

### 在 GitHub 上查看

1. **打开 Actions 页面**
   - 访问：https://github.com/OLRainM/GoLedger/actions
   
2. **看懂状态图标**
   - 🟡 黄色圆圈 = 正在运行
   - ✅ 绿色对勾 = 成功
   - ❌ 红色叉号 = 失败
   - ⚪ 灰色圆圈 = 等待中

3. **查看详细日志**
   - 点击任意一个运行记录
   - 点击左侧的 Job 名称（如"后端 CI"）
   - 展开每个步骤查看详细输出

### 在 README 上添加状态徽章（可选）

在 `README.md` 顶部添加：

```markdown
![Backend CI](https://github.com/OLRainM/GoLedger/workflows/Backend%20CI/badge.svg)
![Frontend CI](https://github.com/OLRainM/GoLedger/workflows/Frontend%20CI/badge.svg)
```

这样别人一眼就能看到项目的构建状态。

---

## 四、手动触发部署

有时候你可能需要手动触发部署，比如：
- 自动部署失败了，想重试
- 想部署一个旧版本
- 想在不推送代码的情况下重新部署

**怎么做？**

1. 打开 Actions 页面
2. 点击左侧的 "Deploy to Production"
3. 点击右上角的 "Run workflow"
4. 选择分支（通常是 main）
5. 输入版本号（如 v1.0.0，留空则使用 latest）
6. 点击 "Run workflow"

---

## 五、常见问题

### Q1: 推送代码后没有触发 CI？

**可能原因：**
- 你修改的文件不在监控范围内
- Workflow 文件配置有问题

**解决方法：**
```bash
# 查看 Workflow 配置
cat .github/workflows/backend-ci.yml

# 确认 paths 配置是否包含你修改的文件
```

### Q2: 构建失败了怎么办？

**步骤：**
1. 打开失败的 Workflow
2. 查看红色的步骤
3. 展开查看错误信息
4. 根据错误信息修复代码
5. 重新推送

**常见错误：**
- 代码格式不对 → 运行 `go fmt` 或 `dart format`
- 测试失败 → 修复测试或代码
- 依赖缺失 → 检查 `go.mod` 或 `pubspec.yaml`

### Q3: 部署到服务器失败？

**可能原因：**
- SSH 连接失败
- 服务器磁盘满了
- Docker 镜像拉取失败

**排查步骤：**
```bash
# 1. 手动 SSH 测试
ssh deploy@115.190.125.177

# 2. 检查磁盘空间
df -h

# 3. 检查 Docker 状态
docker ps
docker compose logs

# 4. 手动拉取镜像测试
docker pull 你的用户名/goledger-backend:latest
```

### Q4: APK 没有上传到 Release？

**可能原因：**
- 构建失败
- GitHub Token 权限不足

**解决方法：**
- 检查 Frontend Build 的日志
- 确认 APK 文件路径正确
- 检查 GitHub Actions 权限设置

---

## 六、最佳实践

### 1. 提交信息规范

使用清晰的提交信息，方便追踪：

```bash
# 好的提交信息
git commit -m "fix: 修复登录页面密码校验问题"
git commit -m "feat: 添加账户余额统计功能"
git commit -m "docs: 更新 API 文档"

# 不好的提交信息
git commit -m "修改"
git commit -m "update"
git commit -m "fix bug"
```

### 2. 版本号管理

遵循语义化版本：

- **主版本号**：大改动，不兼容旧版本 → `2.0.0`
- **次版本号**：新功能，兼容旧版本 → `1.1.0`
- **修订号**：Bug 修复 → `1.0.1`

### 3. 发布前检查清单

- [ ] 本地测试通过
- [ ] 代码已推送到 main
- [ ] 版本号已更新
- [ ] CHANGELOG 已更新（如果有）
- [ ] 确认要发布的功能都已完成

### 4. 定期清理

```bash
# 清理旧的 Docker 镜像（在服务器上）
docker image prune -a -f

# 清理旧的 Tag（如果打错了）
git tag -d v1.0.0-test
git push origin :refs/tags/v1.0.0-test
```

---

## 七、快速参考

### 常用命令

```bash
# 查看所有 Tag
git tag -l

# 删除本地 Tag
git tag -d v1.0.0

# 删除远程 Tag
git push origin :refs/tags/v1.0.0

# 查看最近的提交
git log --oneline -10

# 回滚到上一个版本
git revert HEAD
```

### 重要链接

- **GitHub Actions**: https://github.com/OLRainM/GoLedger/actions
- **GitHub Releases**: https://github.com/OLRainM/GoLedger/releases
- **Docker Hub**: https://hub.docker.com
- **服务器健康检查**: http://115.190.125.177:8080/health

---

## 八、下一步

现在你已经学会了：
- ✅ 如何推送代码触发 CI
- ✅ 如何发布新版本
- ✅ 如何查看构建状态
- ✅ 如何排查常见问题

**建议：**
1. 先在测试分支练习几次
2. 熟悉了再在 main 分支操作
3. 遇到问题先看日志，再查文档
4. 不确定的操作先问一下

**记住：CI/CD 是来帮你的，不是来添麻烦的！**
