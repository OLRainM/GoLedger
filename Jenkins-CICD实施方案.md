# GoLedger Jenkins CI/CD 实施方案

> 基于 Jenkins + 本地 Docker Registry 的完全自主可控 CI/CD 方案

---

## 一、方案架构

### 1.1 整体架构

```
开发者 → GitHub 仓库 → Webhook → Jenkins (服务器) → 本地 Docker Registry → 生产部署
         (代码推送)    (触发构建)  (自动构建)      (镜像存储)         (自动部署)
```

### 1.2 核心组件

| 组件 | 部署位置 | 端口 | 说明 |
|------|---------|------|------|
| **Jenkins** | 115.190.125.177 | 8081 | CI/CD 服务器 |
| **Docker Registry** | 115.190.125.177 | 5000 | 私有镜像仓库 |
| **MySQL** | 115.190.125.177 | 3306 | 数据库 |
| **GoLedger Backend** | 115.190.125.177 | 8080 | 后端服务 |

### 1.3 方案优势

**相比 GitHub Actions：**
- ✅ **完全自主可控**：所有服务都在自己服务器上
- ✅ **镜像拉取快**：本地 Registry，无需访问 Docker Hub
- ✅ **无网络限制**：不受国内网络影响
- ✅ **免费无限制**：无构建时长和次数限制
- ✅ **灵活配置**：可以自定义任何构建流程

**相比 Docker Hub：**
- ✅ **速度快**：本地网络，秒级拉取
- ✅ **无限存储**：只受服务器磁盘限制
- ✅ **私有安全**：镜像不会泄露到公网

---

## 二、环境准备

### 2.1 服务器要求

**最低配置：**
- CPU: 2 核
- 内存: 4GB
- 磁盘: 50GB（建议 100GB+）
- 系统: CentOS 7/8 或 Ubuntu 18.04+

**当前服务器：**
- IP: 115.190.125.177
- 系统: CentOS
- 已安装: Docker, Docker Compose

### 2.2 端口规划

```bash
# 需要开放的端口
8080  # GoLedger 后端服务
8081  # Jenkins Web UI
5000  # Docker Registry
3306  # MySQL（仅内网）
```

### 2.3 防火墙配置

```bash
# 开放必要端口
firewall-cmd --permanent --add-port=8080/tcp
firewall-cmd --permanent --add-port=8081/tcp
firewall-cmd --permanent --add-port=5000/tcp
firewall-cmd --reload

# 验证
firewall-cmd --list-ports
```

---

## 三、安装 Docker Registry

### 3.1 创建 Registry 目录

```bash
# 创建数据目录
mkdir -p /opt/docker-registry/data
mkdir -p /opt/docker-registry/auth
mkdir -p /opt/docker-registry/certs

cd /opt/docker-registry
```

### 3.2 生成认证文件（可选但推荐）

```bash
# 安装 htpasswd 工具
yum install -y httpd-tools  # CentOS
# 或
apt-get install -y apache2-utils  # Ubuntu

# 创建用户（用户名: admin, 密码: 自己设置）
htpasswd -Bc auth/htpasswd admin
# 输入密码两次
```

### 3.3 创建 Registry 配置

```bash
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  registry:
    image: registry:2
    container_name: docker-registry
    restart: always
    ports:
      - "5000:5000"
    environment:
      REGISTRY_AUTH: htpasswd
      REGISTRY_AUTH_HTPASSWD_REALM: Registry Realm
      REGISTRY_AUTH_HTPASSWD_PATH: /auth/htpasswd
      REGISTRY_STORAGE_DELETE_ENABLED: "true"
    volumes:
      - ./data:/var/lib/registry
      - ./auth:/auth
    networks:
      - registry-net

networks:
  registry-net:
    driver: bridge
EOF
```

### 3.4 启动 Registry

```bash
# 启动
docker compose up -d

# 查看状态
docker compose ps
docker compose logs -f

# 测试
curl http://localhost:5000/v2/_catalog
# 应该返回: {"repositories":[]}
```

### 3.5 配置 Docker 使用本地 Registry

```bash
# 编辑 Docker 配置
cat > /etc/docker/daemon.json << 'EOF'
{
  "insecure-registries": ["115.190.125.177:5000"],
  "registry-mirrors": ["http://115.190.125.177:5000"]
}
EOF

# 重启 Docker
systemctl restart docker

# 验证
docker info | grep -A 5 "Insecure Registries"
```

### 3.6 登录 Registry

```bash
# 登录（如果配置了认证）
docker login 115.190.125.177:5000
# 输入用户名: admin
# 输入密码: 你设置的密码

# 测试推送
docker pull hello-world
docker tag hello-world 115.190.125.177:5000/hello-world
docker push 115.190.125.177:5000/hello-world

# 查看镜像列表
curl -u admin:密码 http://115.190.125.177:5000/v2/_catalog
```

---

## 四、安装 Jenkins

### 4.1 使用 Docker 安装 Jenkins

```bash
# 创建 Jenkins 目录
mkdir -p /opt/jenkins/home
chown -R 1000:1000 /opt/jenkins/home

cd /opt/jenkins

# 创建 docker-compose.yml
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  jenkins:
    image: jenkins/jenkins:lts
    container_name: jenkins
    restart: always
    privileged: true
    user: root
    ports:
      - "8081:8080"
      - "50000:50000"
    environment:
      - JAVA_OPTS=-Duser.timezone=Asia/Shanghai
    volumes:
      - ./home:/var/jenkins_home
      - /var/run/docker.sock:/var/run/docker.sock
      - /usr/bin/docker:/usr/bin/docker
      - /usr/local/bin/docker-compose:/usr/local/bin/docker-compose
    networks:
      - jenkins-net

networks:
  jenkins-net:
    driver: bridge
EOF

# 启动 Jenkins
docker compose up -d

# 查看日志，获取初始密码
docker compose logs -f
# 找到类似这样的行：
# *************************************************************
# Jenkins initial setup is required. An admin user has been created and a password generated.
# Please use the following password to proceed to installation:
# 
# a1b2c3d4e5f6g7h8i9j0
# 
# *************************************************************
```

### 4.2 初始化 Jenkins

```bash
# 1. 浏览器访问
http://115.190.125.177:8081

# 2. 输入初始密码（从日志中获取）
# 或者从文件中获取：
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword

# 3. 选择"安装推荐的插件"

# 4. 创建管理员用户
# 用户名: admin
# 密码: 自己设置
# 邮箱: 你的邮箱

# 5. Jenkins URL 设置为: http://115.190.125.177:8081
```

### 4.3 安装必要插件

在 Jenkins 中安装以下插件：

```
系统管理 → 插件管理 → 可选插件

必装插件：
1. Git Plugin（通常已安装）
2. Docker Pipeline
3. Pipeline
4. GitHub Integration Plugin
5. Credentials Binding Plugin
6. SSH Agent Plugin
```

### 4.4 配置 Jenkins 凭据

```
系统管理 → 凭据 → 系统 → 全局凭据 → 添加凭据

添加以下凭据：

1. GitHub 凭据（用于拉取代码）
   - 类型: Username with password
   - ID: github-credentials
   - 用户名: 你的 GitHub 用户名
   - 密码: GitHub Personal Access Token

2. Docker Registry 凭据
   - 类型: Username with password
   - ID: docker-registry-credentials
   - 用户名: admin
   - 密码: Registry 密码

3. 服务器 SSH 凭据
   - 类型: SSH Username with private key
   - ID: server-ssh-key
   - 用户名: deploy
   - Private Key: 粘贴 SSH 私钥
```

---

## 五、创建 Jenkins Pipeline

### 5.1 后端 Pipeline

在 Jenkins 中创建新任务：

```
1. 新建任务 → 输入名称: goledger-backend → 选择"流水线" → 确定

2. 配置：
   - 描述: GoLedger 后端自动构建和部署
   - 构建触发器: 勾选"GitHub hook trigger for GITScm polling"
   
3. 流水线配置：
   - 定义: Pipeline script
   - 脚本: 见下方
```

**后端 Jenkinsfile：**

```groovy
pipeline {
    agent any
    
    environment {
        REGISTRY = '115.190.125.177:5000'
        IMAGE_NAME = 'goledger-backend'
        PROJECT_DIR = '/opt/GoLedger'
    }
    
    stages {
        stage('拉取代码') {
            steps {
                git branch: 'main',
                    credentialsId: 'github-credentials',
                    url: 'https://github.com/OLRainM/GoLedger.git'
            }
        }
        
        stage('代码检查') {
            steps {
                dir('backend') {
                    sh '''
                        # Go 格式检查
                        if [ -n "$(gofmt -l .)" ]; then
                            echo "代码格式不规范"
                            gofmt -l .
                            exit 1
                        fi
                        
                        # 静态分析
                        go vet ./...
                    '''
                }
            }
        }
        
        stage('运行测试') {
            steps {
                dir('backend') {
                    sh 'go test -v ./...'
                }
            }
        }
        
        stage('构建镜像') {
            steps {
                dir('backend') {
                    script {
                        def imageTag = "${env.BUILD_NUMBER}"
                        sh """
                            docker build -t ${REGISTRY}/${IMAGE_NAME}:${imageTag} .
                            docker tag ${REGISTRY}/${IMAGE_NAME}:${imageTag} ${REGISTRY}/${IMAGE_NAME}:latest
                        """
                    }
                }
            }
        }
        
        stage('推送镜像') {
            steps {
                script {
                    docker.withRegistry("http://${REGISTRY}", 'docker-registry-credentials') {
                        def imageTag = "${env.BUILD_NUMBER}"
                        sh """
                            docker push ${REGISTRY}/${IMAGE_NAME}:${imageTag}
                            docker push ${REGISTRY}/${IMAGE_NAME}:latest
                        """
                    }
                }
            }
        }
        
        stage('部署') {
            steps {
                sh """
                    cd ${PROJECT_DIR}/backend
                    
                    # 更新 docker-compose.yml 中的镜像
                    sed -i 's|image:.*goledger-backend.*|image: ${REGISTRY}/${IMAGE_NAME}:latest|g' docker-compose.yml
                    
                    # 拉取新镜像
                    docker compose pull
                    
                    # 重启服务
                    docker compose down
                    docker compose up -d
                    
                    # 等待服务启动
                    sleep 10
                    
                    # 健康检查
                    if curl -f http://localhost:8080/health; then
                        echo "部署成功"
                    else
                        echo "健康检查失败"
                        exit 1
                    fi
                """
            }
        }
        
        stage('清理') {
            steps {
                sh '''
                    # 清理旧镜像
                    docker image prune -f
                '''
            }
        }
    }
    
    post {
        success {
            echo '构建成功！'
        }
        failure {
            echo '构建失败！'
        }
    }
}
```

### 5.2 前端 Pipeline

创建另一个任务：

```
新建任务 → 输入名称: goledger-frontend → 选择"流水线" → 确定
```

**前端 Jenkinsfile：**

```groovy
pipeline {
    agent any
    
    environment {
        BASE_URL = 'http://www.olraingin.com:8080'
    }
    
    stages {
        stage('拉取代码') {
            steps {
                git branch: 'main',
                    credentialsId: 'github-credentials',
                    url: 'https://github.com/OLRainM/GoLedger.git'
            }
        }
        
        stage('代码检查') {
            steps {
                dir('frontend') {
                    sh '''
                        flutter pub get
                        flutter analyze
                        dart format --set-exit-if-changed .
                    '''
                }
            }
        }
        
        stage('运行测试') {
            steps {
                dir('frontend') {
                    sh 'flutter test'
                }
            }
        }
        
        stage('构建 APK') {
            steps {
                dir('frontend') {
                    sh """
                        flutter build apk --release \\
                            --dart-define=BASE_URL=${BASE_URL}
                    """
                }
            }
        }
        
        stage('归档产物') {
            steps {
                archiveArtifacts artifacts: 'frontend/build/app/outputs/flutter-apk/*.apk',
                                 fingerprint: true
            }
        }
    }
    
    post {
        success {
            echo 'APK 构建成功！'
        }
        failure {
            echo 'APK 构建失败！'
        }
    }
}
```

---

## 六、配置 GitHub Webhook

### 6.1 在 GitHub 仓库中配置

```
1. 访问: https://github.com/OLRainM/GoLedger/settings/hooks

2. 点击"Add webhook"

3. 配置：
   - Payload URL: http://115.190.125.177:8081/github-webhook/
   - Content type: application/json
   - Secret: 留空或设置一个密钥
   - 触发事件: 选择"Just the push event"
   - Active: 勾选

4. 点击"Add webhook"
```

### 6.2 测试 Webhook

```bash
# 推送代码测试
git add .
git commit -m "test: 测试 Jenkins 自动构建"
git push origin main

# 在 Jenkins 中查看构建状态
# 访问: http://115.190.125.177:8081
```

---

## 七、日常使用流程

### 7.1 开发流程

```bash
# 1. 修改代码
# 在本地修改代码

# 2. 提交代码
git add .
git commit -m "feat: 添加新功能"
git push origin main

# 3. 自动触发构建
# Jenkins 自动检测到推送，开始构建

# 4. 查看构建状态
# 访问 Jenkins: http://115.190.125.177:8081
# 查看控制台输出

# 5. 验证部署
curl http://115.190.125.177:8080/health
```

### 7.2 手动触发构建

```
1. 访问 Jenkins: http://115.190.125.177:8081
2. 选择任务（goledger-backend 或 goledger-frontend）
3. 点击"立即构建"
4. 查看"控制台输出"
```

### 7.3 查看构建历史

```
1. 进入任务页面
2. 左侧"构建历史"
3. 点击具体构建号查看详情
4. "控制台输出"查看完整日志
```

---

## 八、监控与维护

### 8.1 查看 Jenkins 日志

```bash
# 查看 Jenkins 容器日志
docker logs -f jenkins

# 查看 Jenkins 系统日志
docker exec jenkins tail -f /var/jenkins_home/logs/jenkins.log
```

### 8.2 查看 Registry 镜像

```bash
# 查看所有镜像
curl -u admin:密码 http://115.190.125.177:5000/v2/_catalog

# 查看特定镜像的标签
curl -u admin:密码 http://115.190.125.177:5000/v2/goledger-backend/tags/list
```

### 8.3 清理旧镜像

```bash
# 清理 Docker 本地镜像
docker image prune -a -f

# 清理 Registry 中的镜像（需要手动）
# 1. 删除镜像清单
# 2. 运行垃圾回收
docker exec docker-registry bin/registry garbage-collect /etc/docker/registry/config.yml
```

### 8.4 备份

```bash
# 备份 Jenkins 配置
tar -czf jenkins-backup-$(date +%Y%m%d).tar.gz /opt/jenkins/home

# 备份 Registry 数据
tar -czf registry-backup-$(date +%Y%m%d).tar.gz /opt/docker-registry/data
```

---

## 九、故障排查

### 9.1 Jenkins 无法启动

```bash
# 查看日志
docker logs jenkins

# 常见问题：
# 1. 端口被占用
netstat -tlnp | grep 8081

# 2. 权限问题
chown -R 1000:1000 /opt/jenkins/home

# 3. 磁盘空间不足
df -h
```

### 9.2 构建失败

```bash
# 1. 查看 Jenkins 控制台输出
# 2. 检查 Docker 是否正常
docker ps
docker info

# 3. 检查网络连接
ping github.com
curl http://115.190.125.177:5000/v2/_catalog
```

### 9.3 镜像推送失败

```bash
# 1. 检查 Registry 是否运行
docker ps | grep registry

# 2. 检查认证
docker login 115.190.125.177:5000

# 3. 手动测试推送
docker tag hello-world 115.190.125.177:5000/test
docker push 115.190.125.177:5000/test
```

---

## 十、总结

### 优势

- ✅ **完全自主可控**：所有服务在自己服务器
- ✅ **速度快**：本地 Registry，镜像拉取秒级
- ✅ **无限制**：无构建时长和次数限制
- ✅ **私有安全**：镜像不会泄露

### 成本

- **服务器资源**：Jenkins + Registry 约占用 2GB 内存
- **磁盘空间**：建议预留 50GB+
- **维护成本**：需要定期清理镜像和备份

### 下一步

1. ✅ 安装 Docker Registry
2. ✅ 安装 Jenkins
3. ✅ 创建 Pipeline
4. ✅ 配置 Webhook
5. ✅ 测试完整流程

**配置完成后，你将拥有一套完全自主可控的 CI/CD 系统！** 🚀
