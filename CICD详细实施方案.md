# GoLedger CI/CD 详细实施方案

> 基于 GitHub Actions 的完整 CI/CD 实现指南  
> 目标环境：CentOS 服务器 (115.190.125.177)

---

## 📋 实施概览

### 总体架构

```
开发者 → GitHub 仓库 → GitHub Actions → 生产服务器
         (代码推送)    (自动构建测试)   (自动部署)
```

### 实施阶段

- **Phase 1**：基础 CI（代码检查 + 测试）— 1-2 天
- **Phase 2**：自动构建（Docker 镜像 + APK）— 2-3 天  
- **Phase 3**：自动部署（SSH 部署到服务器）— 2-3 天

---

## Phase 1: 基础 CI 实施（1-2 天）

### 目标

✅ 每次代码推送自动运行代码检查和测试  
✅ PR 合并前必须通过所有检查  
✅ 及早发现代码质量问题

---

### 1.1 服务器端准备工作

#### 步骤 1：SSH 登录服务器

```bash
ssh root@115.190.125.177
# 或使用你的实际用户名
```

#### 步骤 2：创建部署专用用户（推荐）

```bash
# 创建 deploy 用户
useradd -m -s /bin/bash deploy
passwd deploy  # 设置密码

# 添加到 docker 组
usermod -aG docker deploy

# 切换到 deploy 用户
su - deploy
```

#### 步骤 3：生成 SSH 密钥对

```bash
# 在服务器上生成密钥对
ssh-keygen -t ed25519 -C "github-actions-deploy" -f ~/.ssh/github_actions

# 查看公钥（需要添加到 authorized_keys）
cat ~/.ssh/github_actions.pub

# 添加公钥到 authorized_keys
cat ~/.ssh/github_actions.pub >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

# 查看私钥（需要添加到 GitHub Secrets）
cat ~/.ssh/github_actions
# 复制整个私钥内容（包括 BEGIN 和 END 行）
```

#### 步骤 4：测试 SSH 连接

```bash
# 在本地测试（将私钥保存为 test_key）
ssh -i test_key deploy@115.190.125.177 "echo 'SSH 连接成功'"
```

---

### 1.2 GitHub 仓库配置

#### 步骤 1：配置 GitHub Secrets

访问：`https://github.com/OLRainM/GoLedger/settings/secrets/actions`

添加以下 Secrets：

| Secret 名称 | 值 | 说明 |
|------------|---|------|
| `SSH_PRIVATE_KEY` | 私钥内容 | 步骤 3 生成的私钥 |
| `SERVER_HOST` | `115.190.125.177` | 服务器 IP |
| `SERVER_USER` | `deploy` | 服务器用户名 |
| `SERVER_PORT` | `22` | SSH 端口（默认 22） |

#### 步骤 2：配置分支保护规则（可选）

访问：`https://github.com/OLRainM/GoLedger/settings/branches`

为 `main` 分支添加保护规则：
- ✅ Require status checks to pass before merging
- ✅ Require branches to be up to date before merging

---

### 1.3 创建后端 CI Workflow

#### 步骤 1：创建 Workflow 文件

在项目根目录创建：`.github/workflows/backend-ci.yml`

```yaml
name: Backend CI

on:
  push:
    branches: [ main ]
    paths:
      - 'backend/**'
      - '.github/workflows/backend-ci.yml'
  pull_request:
    branches: [ main ]
    paths:
      - 'backend/**'

jobs:
  lint-and-test:
    name: 代码检查和测试
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout 代码
        uses: actions/checkout@v4
      
      - name: 设置 Go 环境
        uses: actions/setup-go@v5
        with:
          go-version: '1.21'
          cache-dependency-path: backend/go.sum
      
      - name: 安装依赖
        working-directory: backend
        run: go mod download
      
      - name: 代码格式检查
        working-directory: backend
        run: |
          if [ -n "$(gofmt -l .)" ]; then
            echo "以下文件需要格式化:"
            gofmt -l .
            exit 1
          fi
      
      - name: 运行 go vet
        working-directory: backend
        run: go vet ./...
      
      - name: 运行单元测试
        working-directory: backend
        run: go test -v -race -coverprofile=coverage.out ./...
      
      - name: 上传测试覆盖率
        uses: codecov/codecov-action@v4
        with:
          files: backend/coverage.out
          flags: backend
        continue-on-error: true
```

#### 步骤 2：提交并推送

```bash
cd /path/to/GoLedger
git add .github/workflows/backend-ci.yml
git commit -m "ci: 添加后端 CI workflow"
git push origin main
```

#### 步骤 3：验证 Workflow

访问：`https://github.com/OLRainM/GoLedger/actions`

查看 Workflow 运行状态，确保通过。

---

### 1.4 创建前端 CI Workflow

#### 步骤 1：创建 Workflow 文件

在项目根目录创建：`.github/workflows/frontend-ci.yml`

```yaml
name: Frontend CI

on:
  push:
    branches: [ main ]
    paths:
      - 'frontend/**'
      - '.github/workflows/frontend-ci.yml'
  pull_request:
    branches: [ main ]
    paths:
      - 'frontend/**'

jobs:
  analyze-and-test:
    name: 代码检查和测试
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout 代码
        uses: actions/checkout@v4
      
      - name: 设置 Flutter 环境
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.32.2'
          channel: 'stable'
          cache: true
      
      - name: 安装依赖
        working-directory: frontend
        run: flutter pub get
      
      - name: 代码分析
        working-directory: frontend
        run: flutter analyze
      
      - name: 运行单元测试
        working-directory: frontend
        run: flutter test
      
      - name: 检查代码格式
        working-directory: frontend
        run: dart format --set-exit-if-changed .
```

#### 步骤 2：提交并推送

```bash
git add .github/workflows/frontend-ci.yml
git commit -m "ci: 添加前端 CI workflow"
git push origin main
```

---

### 1.5 Phase 1 验证清单

- [ ] 服务器 SSH 密钥已生成
- [ ] GitHub Secrets 已配置
- [ ] 后端 CI workflow 已创建并通过
- [ ] 前端 CI workflow 已创建并通过
- [ ] 分支保护规则已配置（可选）

---

## Phase 2: 自动构建实施（2-3 天）

### 目标

✅ Tag 推送时自动构建 Docker 镜像和 APK  
✅ 自动推送镜像到 Docker Hub  
✅ 自动创建 GitHub Release

---

### 2.1 Docker Hub 准备

#### 步骤 1：注册 Docker Hub 账号

访问：https://hub.docker.com/signup

#### 步骤 2：创建 Access Token

1. 登录 Docker Hub
2. 访问：Account Settings → Security → New Access Token
3. 名称：`github-actions`
4. 权限：Read, Write, Delete
5. 复制生成的 Token

#### 步骤 3：添加到 GitHub Secrets

| Secret 名称 | 值 | 说明 |
|------------|---|------|
| `DOCKER_USERNAME` | 你的 Docker Hub 用户名 | 例如：`olrainm` |
| `DOCKER_PASSWORD` | Access Token | 步骤 2 生成的 Token |

---

### 2.2 创建后端构建 Workflow

#### 步骤 1：创建 Workflow 文件

在项目根目录创建：`.github/workflows/backend-build.yml`

```yaml
name: Backend Build & Push

on:
  push:
    tags:
      - 'v*'

env:
  DOCKER_IMAGE: ${{ secrets.DOCKER_USERNAME }}/goledger-backend

jobs:
  build-and-push:
    name: 构建并推送 Docker 镜像
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout 代码
        uses: actions/checkout@v4
      
      - name: 设置 Docker Buildx
        uses: docker/setup-buildx-action@v3
      
      - name: 登录 Docker Hub
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}
      
      - name: 提取版本号
        id: meta
        run: |
          VERSION=${GITHUB_REF#refs/tags/}
          echo "version=$VERSION" >> $GITHUB_OUTPUT
          echo "构建版本: $VERSION"
      
      - name: 构建并推送镜像
        uses: docker/build-push-action@v5
        with:
          context: ./backend
          file: ./backend/Dockerfile
          push: true
          tags: |
            ${{ env.DOCKER_IMAGE }}:${{ steps.meta.outputs.version }}
            ${{ env.DOCKER_IMAGE }}:latest
          cache-from: type=gha
          cache-to: type=gha,mode=max
      
      - name: 创建 GitHub Release
        uses: softprops/action-gh-release@v1
        with:
          generate_release_notes: true
          body: |
            ## 后端版本 ${{ steps.meta.outputs.version }}
            
            Docker 镜像已推送到 Docker Hub:
            - `${{ env.DOCKER_IMAGE }}:${{ steps.meta.outputs.version }}`
            - `${{ env.DOCKER_IMAGE }}:latest`
```

---

### 2.3 创建前端构建 Workflow

#### 步骤 1：创建 Workflow 文件

在项目根目录创建：`.github/workflows/frontend-build.yml`

```yaml
name: Frontend Build APK

on:
  push:
    tags:
      - 'v*'

jobs:
  build-apk:
    name: 构建 Android APK
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout 代码
        uses: actions/checkout@v4
      
      - name: 设置 Java 环境
        uses: actions/setup-java@v4
        with:
          distribution: 'zulu'
          java-version: '17'
      
      - name: 设置 Flutter 环境
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.32.2'
          channel: 'stable'
          cache: true
      
      - name: 安装依赖
        working-directory: frontend
        run: flutter pub get
      
      - name: 构建 Release APK
        working-directory: frontend
        run: |
          flutter build apk --release \
            --dart-define=BASE_URL=http://www.olraingin.com:8080
      
      - name: 提取版本号
        id: meta
        run: |
          VERSION=${GITHUB_REF#refs/tags/}
          echo "version=$VERSION" >> $GITHUB_OUTPUT
      
      - name: 重命名 APK
        run: |
          mv frontend/build/app/outputs/flutter-apk/app-release.apk \
             frontend/build/app/outputs/flutter-apk/goledger-${{ steps.meta.outputs.version }}.apk
      
      - name: 上传到 GitHub Release
        uses: softprops/action-gh-release@v1
        with:
          files: |
            frontend/build/app/outputs/flutter-apk/goledger-${{ steps.meta.outputs.version }}.apk
          body: |
            ## 前端版本 ${{ steps.meta.outputs.version }}
            
            ### 下载安装
            1. 下载 `goledger-${{ steps.meta.outputs.version }}.apk`
            2. 传输到 Android 设备
            3. 安装并使用
```

---

### 2.4 测试构建流程

#### 步骤 1：创建测试 Tag

```bash
cd /path/to/GoLedger

# 确保代码已提交
git add .
git commit -m "ci: 添加构建 workflows"

# 创建并推送 Tag
git tag v1.0.0-test
git push origin v1.0.0-test
```

#### 步骤 2：查看构建状态

访问：`https://github.com/OLRainM/GoLedger/actions`

等待构建完成（约 10-15 分钟）

#### 步骤 3：验证产物

1. **Docker Hub**：访问 `https://hub.docker.com/r/你的用户名/goledger-backend`
2. **GitHub Release**：访问 `https://github.com/OLRainM/GoLedger/releases`

---

### 2.5 Phase 2 验证清单

- [ ] Docker Hub 账号已创建
- [ ] Docker Hub Token 已添加到 GitHub Secrets
- [ ] 后端构建 workflow 已创建
- [ ] 前端构建 workflow 已创建
- [ ] 测试 Tag 推送成功
- [ ] Docker 镜像已推送到 Docker Hub
- [ ] APK 已上传到 GitHub Release

---

## Phase 3: 自动部署实施（2-3 天）

### 目标

✅ Tag 推送时自动部署到生产服务器  
✅ 自动拉取最新镜像并重启服务  
✅ 部署失败自动回滚

---

### 3.1 服务器端准备

#### 步骤 1：创建部署脚本

SSH 登录服务器，创建部署脚本：

```bash
ssh deploy@115.190.125.177

# 创建脚本目录
mkdir -p ~/scripts
cd ~/scripts

# 创建部署脚本
cat > deploy.sh << 'EOF'
#!/bin/bash
set -e

# 配置
PROJECT_DIR="/opt/GoLedger"
DOCKER_IMAGE="你的Docker用户名/goledger-backend"
VERSION=$1

echo "========================================="
echo "开始部署 GoLedger 版本: $VERSION"
echo "========================================="

# 进入项目目录
cd $PROJECT_DIR

# 备份当前版本
echo "📦 备份当前配置..."
cp docker-compose.yml docker-compose.yml.backup

# 拉取最新代码
echo "📥 拉取最新代码..."
git fetch origin
git checkout main
git pull origin main

# 更新 docker-compose.yml 中的镜像版本
echo "🔄 更新镜像版本..."
sed -i "s|image:.*goledger-backend.*|image: $DOCKER_IMAGE:$VERSION|g" backend/docker-compose.yml

# 拉取新镜像
echo "📥 拉取 Docker 镜像..."
cd backend
docker compose pull

# 停止旧服务
echo "🛑 停止旧服务..."
docker compose down

# 启动新服务
echo "🚀 启动新服务..."
docker compose up -d

# 等待服务启动
echo "⏳ 等待服务启动..."
sleep 10

# 健康检查
echo "🏥 健康检查..."
if curl -f http://localhost:8080/health > /dev/null 2>&1; then
    echo "✅ 部署成功！"
    # 清理旧镜像
    docker image prune -f
    exit 0
else
    echo "❌ 健康检查失败，回滚..."
    # 回滚
    cp docker-compose.yml.backup docker-compose.yml
    docker compose up -d
    exit 1
fi
EOF

# 添加执行权限
chmod +x deploy.sh
```

#### 步骤 2：测试部署脚本

```bash
# 手动测试部署
./deploy.sh latest

# 检查服务状态
cd /opt/GoLedger/backend
docker compose ps
docker compose logs -f --tail=50
```

---

### 3.2 创建部署 Workflow

#### 步骤 1：创建 Workflow 文件

在项目根目录创建：`.github/workflows/deploy.yml`

```yaml
name: Deploy to Production

on:
  push:
    tags:
      - 'v*'
  workflow_dispatch:
    inputs:
      version:
        description: '部署版本（留空则使用 latest）'
        required: false
        default: 'latest'

jobs:
  deploy:
    name: 部署到生产服务器
    runs-on: ubuntu-latest
    needs: [build-backend, build-frontend]  # 等待构建完成
    
    steps:
      - name: 提取版本号
        id: meta
        run: |
          if [ "${{ github.event_name }}" == "workflow_dispatch" ]; then
            VERSION="${{ github.event.inputs.version }}"
          else
            VERSION=${GITHUB_REF#refs/tags/}
          fi
          echo "version=$VERSION" >> $GITHUB_OUTPUT
          echo "部署版本: $VERSION"
      
      - name: 部署到服务器
        uses: appleboy/ssh-action@v1.0.0
        with:
          host: ${{ secrets.SERVER_HOST }}
          username: ${{ secrets.SERVER_USER }}
          key: ${{ secrets.SSH_PRIVATE_KEY }}
          port: ${{ secrets.SERVER_PORT }}
          script: |
            cd ~/scripts
            ./deploy.sh ${{ steps.meta.outputs.version }}
      
      - name: 发送部署通知
        if: always()
        run: |
          if [ ${{ job.status }} == 'success' ]; then
            echo "✅ 部署成功: ${{ steps.meta.outputs.version }}"
          else
            echo "❌ 部署失败: ${{ steps.meta.outputs.version }}"
          fi
```

---

### 3.3 完整的 CI/CD Workflow

#### 步骤 1：创建主 Workflow

在项目根目录创建：`.github/workflows/main.yml`

```yaml
name: CI/CD Pipeline

on:
  push:
    branches: [ main ]
    tags:
      - 'v*'
  pull_request:
    branches: [ main ]

jobs:
  # ========== CI 阶段 ==========
  
  backend-ci:
    name: 后端 CI
    runs-on: ubuntu-latest
    if: github.event_name == 'push' || github.event_name == 'pull_request'
    
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-go@v5
        with:
          go-version: '1.21'
      - name: 测试
        working-directory: backend
        run: |
          go mod download
          go test -v ./...
  
  frontend-ci:
    name: 前端 CI
    runs-on: ubuntu-latest
    if: github.event_name == 'push' || github.event_name == 'pull_request'
    
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.32.2'
      - name: 测试
        working-directory: frontend
        run: |
          flutter pub get
          flutter analyze
          flutter test
  
  # ========== 构建阶段 ==========
  
  build-backend:
    name: 构建后端
    runs-on: ubuntu-latest
    if: startsWith(github.ref, 'refs/tags/v')
    needs: [backend-ci]
    
    steps:
      - uses: actions/checkout@v4
      - uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}
      - name: 构建并推送
        run: |
          VERSION=${GITHUB_REF#refs/tags/}
          docker build -t ${{ secrets.DOCKER_USERNAME }}/goledger-backend:$VERSION backend/
          docker push ${{ secrets.DOCKER_USERNAME }}/goledger-backend:$VERSION
  
  build-frontend:
    name: 构建前端
    runs-on: ubuntu-latest
    if: startsWith(github.ref, 'refs/tags/v')
    needs: [frontend-ci]
    
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.32.2'
      - name: 构建 APK
        working-directory: frontend
        run: |
          flutter build apk --release \
            --dart-define=BASE_URL=http://www.olraingin.com:8080
      - uses: softprops/action-gh-release@v1
        with:
          files: frontend/build/app/outputs/flutter-apk/app-release.apk
  
  # ========== 部署阶段 ==========
  
  deploy:
    name: 部署到生产
    runs-on: ubuntu-latest
    if: startsWith(github.ref, 'refs/tags/v')
    needs: [build-backend, build-frontend]
    
    steps:
      - name: 部署
        uses: appleboy/ssh-action@v1.0.0
        with:
          host: ${{ secrets.SERVER_HOST }}
          username: ${{ secrets.SERVER_USER }}
          key: ${{ secrets.SSH_PRIVATE_KEY }}
          script: |
            VERSION=${GITHUB_REF#refs/tags/}
            cd ~/scripts
            ./deploy.sh $VERSION
```

---

### 3.4 Phase 3 验证清单

- [ ] 服务器部署脚本已创建
- [ ] 部署脚本手动测试通过
- [ ] 部署 workflow 已创建
- [ ] 主 workflow 已创建
- [ ] 完整流程测试通过

---

## 🎯 完整发版流程

### 日常开发流程

```bash
# 1. 开发新功能
git checkout -b feature/new-feature
# ... 编写代码 ...

# 2. 提交代码
git add .
git commit -m "feat: 添加新功能"
git push origin feature/new-feature

# 3. 创建 PR
# 访问 GitHub 创建 Pull Request
# CI 自动运行，检查代码质量

# 4. 合并到 main
# PR 通过后合并
```

### 发布新版本流程

```bash
# 1. 确保 main 分支最新
git checkout main
git pull origin main

# 2. 更新版本号
# 编辑 frontend/pubspec.yaml
version: 1.1.0+2

# 3. 提交版本号变更
git add frontend/pubspec.yaml
git commit -m "chore: bump version to 1.1.0"
git push origin main

# 4. 创建并推送 Tag
git tag v1.1.0
git push origin v1.1.0

# 5. 自动触发 CI/CD
# - 构建 Docker 镜像
# - 构建 APK
# - 部署到服务器
# - 创建 GitHub Release

# 6. 验证部署
curl http://115.190.125.177:8080/health
```

---

## 📊 监控与维护

### 查看部署日志

```bash
# SSH 登录服务器
ssh deploy@115.190.125.177

# 查看服务日志
cd /opt/GoLedger/backend
docker compose logs -f --tail=100

# 查看部署历史
cat ~/scripts/deploy.log
```

### 手动回滚

```bash
# 回滚到上一个版本
cd /opt/GoLedger/backend
docker compose down
git checkout v1.0.0  # 回滚到指定版本
docker compose up -d
```

---

## ⚠️ 注意事项

1. **首次部署**：需要手动在服务器上克隆项目到 `/opt/GoLedger`
2. **环境变量**：确保 `backend/config.yaml` 配置正确
3. **数据库迁移**：新版本如有数据库变更，需要手动执行迁移
4. **备份**：部署前自动备份配置文件
5. **健康检查**：部署后自动检查服务健康状态

---

## 🔧 故障排查

### 问题 1：SSH 连接失败

```bash
# 检查 SSH 密钥
ssh -i ~/.ssh/github_actions deploy@115.190.125.177

# 检查 authorized_keys
cat ~/.ssh/authorized_keys
```

### 问题 2：Docker 镜像拉取失败

```bash
# 手动登录 Docker Hub
docker login

# 手动拉取镜像
docker pull 你的用户名/goledger-backend:latest
```

### 问题 3：服务启动失败

```bash
# 查看详细日志
docker compose logs backend

# 检查端口占用
netstat -tlnp | grep 8080
```

---

## 📚 参考资料

- GitHub Actions 文档：https://docs.github.com/actions
- Docker Compose 文档：https://docs.docker.com/compose/
- SSH Action：https://github.com/appleboy/ssh-action
