# Shorebird Linux/CentOS 安装指南

> 适用于 CentOS 7/8/9 及其他 Linux 发行版的 Shorebird CLI 安装

---

## 一、环境准备

### 1.1 系统要求

- **操作系统**：CentOS 7+, Ubuntu 18.04+, Debian 10+
- **架构**：x86_64 (amd64)
- **必需工具**：curl, unzip, git
- **Flutter SDK**：3.19.0+ (需提前安装)

### 1.2 安装依赖

```bash
# CentOS/RHEL
sudo yum install -y curl unzip git

# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y curl unzip git
```

---

## 二、安装 Shorebird CLI

### 2.1 一键安装（推荐）

```bash
# 使用官方安装脚本
curl --proto '=https' --tlsv1.2 https://raw.githubusercontent.com/shorebirdtech/install/main/install.sh -sSf | bash

# 安装完成后，添加到 PATH
echo 'export PATH="$HOME/.shorebird/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# 验证安装
shorebird --version
```

### 2.2 手动安装

如果自动安装失败，可以手动安装：

```bash
# 1. 设置版本号（检查最新版本：https://github.com/shorebirdtech/shorebird/releases）
SHOREBIRD_VERSION="1.1.3"

# 2. 下载
cd /tmp
curl -L -o shorebird.tar.gz \
  "https://github.com/shorebirdtech/shorebird/releases/download/v${SHOREBIRD_VERSION}/shorebird-v${SHOREBIRD_VERSION}-linux-x64.tar.gz"

# 3. 解压到用户目录
mkdir -p ~/.shorebird
tar -xzf shorebird.tar.gz -C ~/.shorebird

# 4. 添加到 PATH
echo 'export PATH="$HOME/.shorebird/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# 5. 验证
shorebird --version

# 6. 清理
rm -f /tmp/shorebird.tar.gz
```

### 2.3 国内加速（可选）

如果 GitHub 访问慢，可以使用镜像：

```bash
# 使用 ghproxy 镜像
SHOREBIRD_VERSION="1.1.3"
curl -L -o shorebird.tar.gz \
  "https://ghproxy.com/https://github.com/shorebirdtech/shorebird/releases/download/v${SHOREBIRD_VERSION}/shorebird-v${SHOREBIRD_VERSION}-linux-x64.tar.gz"
```

---

## 三、配置 Shorebird

### 3.1 登录账号

```bash
# 方式一：交互式登录（需要浏览器）
shorebird login

# 方式二：使用 Token 登录（推荐用于 CI/CD）
# 1. 访问 https://console.shorebird.dev/settings
# 2. 生成 API Token
# 3. 使用 Token 登录
shorebird login --token YOUR_TOKEN_HERE
```

### 3.2 环境变量配置（CI/CD 用）

```bash
# 在 ~/.bashrc 或 CI 配置中添加
export SHOREBIRD_TOKEN="your-token-here"

# 验证
shorebird doctor
```

---

## 四、GoLedger 项目配置

### 4.1 克隆项目到服务器

```bash
# 克隆项目
cd /opt  # 或其他工作目录
git clone git@github.com:OLRainM/GoLedger.git
cd GoLedger/frontend

# 安装 Flutter 依赖
flutter pub get
```

### 4.2 初始化 Shorebird

```bash
cd /opt/GoLedger/frontend

# 初始化项目
shorebird init

# 会生成 shorebird.yaml 文件
```

### 4.3 构建 Release 版本

```bash
# 构建支持热更新的 Android Release 版本
shorebird release android \
  --dart-define=BASE_URL=http://www.olraingin.com:8080

# 构建产物位置
ls -lh build/app/outputs/apk/release/app-release.apk
ls -lh build/app/outputs/bundle/release/app-release.aab
```

---

## 五、CI/CD 集成示例

### 5.1 GitHub Actions 配置

创建 `.github/workflows/shorebird-release.yml`：

```yaml
name: Shorebird Release

on:
  push:
    tags:
      - 'v*'

jobs:
  release:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.32.2'
          channel: 'stable'
      
      - name: Install Shorebird
        run: |
          curl --proto '=https' --tlsv1.2 \
            https://raw.githubusercontent.com/shorebirdtech/install/main/install.sh -sSf | bash
          echo "$HOME/.shorebird/bin" >> $GITHUB_PATH
      
      - name: Login to Shorebird
        env:
          SHOREBIRD_TOKEN: ${{ secrets.SHOREBIRD_TOKEN }}
        run: shorebird login --token $SHOREBIRD_TOKEN
      
      - name: Build Release
        working-directory: frontend
        run: |
          shorebird release android \
            --dart-define=BASE_URL=http://www.olraingin.com:8080
      
      - name: Upload APK
        uses: actions/upload-artifact@v3
        with:
          name: app-release
          path: frontend/build/app/outputs/apk/release/app-release.apk
```

### 5.2 GitLab CI 配置

创建 `.gitlab-ci.yml`：

```yaml
stages:
  - build

shorebird_release:
  stage: build
  image: cirrusci/flutter:stable
  
  before_script:
    - curl --proto '=https' --tlsv1.2 
        https://raw.githubusercontent.com/shorebirdtech/install/main/install.sh -sSf | bash
    - export PATH="$HOME/.shorebird/bin:$PATH"
    - shorebird login --token $SHOREBIRD_TOKEN
  
  script:
    - cd frontend
    - flutter pub get
    - shorebird release android 
        --dart-define=BASE_URL=http://www.olraingin.com:8080
  
  artifacts:
    paths:
      - frontend/build/app/outputs/apk/release/app-release.apk
    expire_in: 1 week
  
  only:
    - tags
```

### 5.3 Jenkins Pipeline

```groovy
pipeline {
    agent any
    
    environment {
        SHOREBIRD_TOKEN = credentials('shorebird-token')
    }
    
    stages {
        stage('Setup') {
            steps {
                sh '''
                    curl --proto '=https' --tlsv1.2 \
                        https://raw.githubusercontent.com/shorebirdtech/install/main/install.sh -sSf | bash
                    export PATH="$HOME/.shorebird/bin:$PATH"
                    shorebird --version
                '''
            }
        }
        
        stage('Build') {
            steps {
                sh '''
                    export PATH="$HOME/.shorebird/bin:$PATH"
                    shorebird login --token $SHOREBIRD_TOKEN
                    cd frontend
                    shorebird release android \
                        --dart-define=BASE_URL=http://www.olraingin.com:8080
                '''
            }
        }
        
        stage('Archive') {
            steps {
                archiveArtifacts artifacts: 'frontend/build/app/outputs/**/*.apk', 
                                 fingerprint: true
            }
        }
    }
}
```

---

## 六、发布热更新补丁

### 6.1 手动发布

```bash
cd /opt/GoLedger/frontend

# 拉取最新代码
git pull origin main

# 发布补丁
shorebird patch android \
  --dart-define=BASE_URL=http://www.olraingin.com:8080

# 查看补丁列表
shorebird patches list android
```

### 6.2 自动化发布脚本

创建 `scripts/release-patch.sh`：

```bash
#!/bin/bash
set -e

# 配置
PROJECT_DIR="/opt/GoLedger/frontend"
BASE_URL="http://www.olraingin.com:8080"

cd $PROJECT_DIR

# 拉取最新代码
echo "📥 拉取最新代码..."
git pull origin main

# 安装依赖
echo "📦 安装依赖..."
flutter pub get

# 发布补丁
echo "🚀 发布热更新补丁..."
shorebird patch android --dart-define=BASE_URL=$BASE_URL

# 查看结果
echo "✅ 补丁发布成功！"
shorebird patches list android | head -n 10
```

使用方式：

```bash
chmod +x scripts/release-patch.sh
./scripts/release-patch.sh
```

---

## 七、常见问题排查

### 7.1 权限问题

```bash
# 如果遇到权限错误
sudo chown -R $USER:$USER ~/.shorebird
chmod +x ~/.shorebird/bin/shorebird
```

### 7.2 网络问题

```bash
# 测试连接
curl -I https://api.shorebird.dev

# 如果需要代理
export HTTP_PROXY=http://proxy.example.com:8080
export HTTPS_PROXY=http://proxy.example.com:8080
```

### 7.3 Flutter 版本不兼容

```bash
# 检查 Flutter 版本
flutter --version

# 升级 Flutter
flutter upgrade

# 检查 Shorebird 兼容性
shorebird doctor
```

---

## 八、服务器环境优化

### 8.1 安装 Android SDK（如果未安装）

```bash
# 下载 Android SDK Command-line Tools
cd /opt
wget https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip
unzip commandlinetools-linux-9477386_latest.zip -d android-sdk
rm commandlinetools-linux-9477386_latest.zip

# 配置环境变量
echo 'export ANDROID_HOME=/opt/android-sdk' >> ~/.bashrc
echo 'export PATH=$ANDROID_HOME/cmdline-tools/latest/bin:$PATH' >> ~/.bashrc
source ~/.bashrc

# 安装必需组件
sdkmanager --sdk_root=$ANDROID_HOME "platform-tools" "platforms;android-34" "build-tools;34.0.0"
sdkmanager --licenses
```

### 8.2 配置 Flutter

```bash
# 下载 Flutter SDK
cd /opt
git clone https://github.com/flutter/flutter.git -b stable --depth 1

# 配置环境变量
echo 'export PATH="/opt/flutter/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# 验证
flutter doctor
```

---

## 九、监控与日志

### 9.1 查看构建日志

```bash
# Shorebird 日志位置
tail -f ~/.shorebird/logs/shorebird.log

# Flutter 构建日志
flutter build apk --verbose
```

### 9.2 监控补丁状态

```bash
# 查看所有补丁
shorebird patches list android

# 查看特定补丁详情
shorebird patch info <patch-id>

# 查看更新统计（需要访问控制台）
# https://console.shorebird.dev
```

---

## 十、安全建议

### 10.1 Token 管理

```bash
# 不要在脚本中硬编码 Token
# 使用环境变量
export SHOREBIRD_TOKEN=$(cat /secure/path/shorebird-token.txt)

# 或使用密钥管理工具
# - HashiCorp Vault
# - AWS Secrets Manager
# - Azure Key Vault
```

### 10.2 权限控制

```bash
# 限制 Shorebird 目录权限
chmod 700 ~/.shorebird
chmod 600 ~/.shorebird/credentials.json

# 使用专用用户运行构建
sudo useradd -m -s /bin/bash flutter-builder
sudo su - flutter-builder
```

---

## 十一、快速参考

### 常用命令

```bash
# 安装
curl --proto '=https' --tlsv1.2 https://raw.githubusercontent.com/shorebirdtech/install/main/install.sh -sSf | bash

# 登录
shorebird login --token YOUR_TOKEN

# 初始化项目
shorebird init

# 构建 Release
shorebird release android --dart-define=BASE_URL=http://www.olraingin.com:8080

# 发布补丁
shorebird patch android --dart-define=BASE_URL=http://www.olraingin.com:8080

# 查看补丁
shorebird patches list android

# 回滚
shorebird patch rollback android

# 更新 CLI
shorebird upgrade

# 诊断
shorebird doctor
```

### 目录结构

```
/opt/GoLedger/
├── frontend/
│   ├── shorebird.yaml          # Shorebird 配置
│   ├── .shorebird/             # 本地缓存
│   └── build/
│       └── app/outputs/
│           ├── apk/release/    # APK
│           └── bundle/release/ # AAB

~/.shorebird/
├── bin/                        # CLI 可执行文件
├── cache/                      # 缓存
├── logs/                       # 日志
└── credentials.json            # 认证信息
```

---

## 参考资料

- **Shorebird 官网**：https://shorebird.dev
- **安装脚本**：https://github.com/shorebirdtech/install
- **文档**：https://docs.shorebird.dev
- **控制台**：https://console.shorebird.dev
