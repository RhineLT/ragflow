# RagFlow ARM64 镜像构建指南

## 概述

本仓库已配置 GitHub Actions 工作流，用于自动构建和发布 ARM64 架构的 RagFlow 镜像。

## 构建的镜像

工作流会构建并推送以下 ARM64 镜像到 GitHub Container Registry (GHCR):

1. **RagFlow 主镜像**: `ghcr.io/rhinelt/ragflow:arm64-latest`
2. **Sandbox Python 基础镜像**: `ghcr.io/rhinelt/ragflow-sandbox-base-python:arm64-latest`
3. **Sandbox Node.js 基础镜像**: `ghcr.io/rhinelt/ragflow-sandbox-base-nodejs:arm64-latest`
4. **Sandbox 执行器管理器**: `ghcr.io/rhinelt/ragflow-sandbox-executor-manager:arm64-latest`

## 触发构建

### 方法 1: 手动触发（推荐用于测试）

1. 访问 GitHub 仓库的 Actions 页面
2. 选择 "Build ARM64 Images" 工作流
3. 点击 "Run workflow" 按钮
4. 选择分支（通常是 main）
5. 点击绿色的 "Run workflow" 按钮

### 方法 2: 自动触发

工作流会在以下情况自动运行：
- 推送到 `main` 或 `master` 分支
- 修改了 Dockerfile 相关文件的 PR

## 使用 ARM64 镜像

### 拉取镜像

```bash
# 拉取主镜像
docker pull --platform linux/arm64 ghcr.io/rhinelt/ragflow:arm64-latest

# 验证架构
docker inspect ghcr.io/rhinelt/ragflow:arm64-latest | jq '.[0].Architecture'
# 应该输出: "arm64"
```

### 使用 Docker Compose

1. 进入 docker 目录:
```bash
cd docker
```

2. 修改 `.env` 文件:
```bash
# 备份原文件
cp .env .env.backup

# 更新镜像地址
sed -i 's|RAGFLOW_IMAGE=.*|RAGFLOW_IMAGE=ghcr.io/rhinelt/ragflow:arm64-latest|g' .env
```

3. 启动服务:
```bash
docker-compose --profile cpu up -d
```

4. 检查服务状态:
```bash
docker-compose ps
docker-compose logs ragflow-cpu
```

## 构建流程说明

### 阶段 1: 构建镜像

工作流使用 Docker Buildx 和 QEMU 模拟器构建 ARM64 镜像：

1. **RagFlow 主镜像构建** (约 30-60 分钟首次构建)
   - 使用 `Dockerfile.arm64` 专门优化的 ARM64 构建文件
   - 在构建过程中下载所有依赖（HuggingFace 模型、NLTK 数据等）
   - 跳过 ARM64 不支持的 Chrome/ChromeDriver

2. **Sandbox 镜像构建** (并行执行，约 5-10 分钟)
   - Python 基础镜像
   - Node.js 基础镜像
   - 执行器管理器镜像

### 阶段 2: 验证镜像

工作流会自动验证构建的镜像：

1. 拉取构建的 ARM64 镜像
2. 检查镜像元数据确认架构为 arm64
3. 使用 docker-compose 启动服务
4. 验证容器能够正常启动
5. 检查容器内部的架构信息

### 阶段 3: 推送镜像

验证通过后，镜像会自动推送到 GHCR，带有以下标签：
- `arm64-latest`: 最新的 ARM64 构建
- `arm64-YYYYMMDD-HHmmss`: 带时间戳的构建
- `arm64-<sha>`: 基于 Git 提交 SHA 的标签

## 镜像标签说明

| 标签格式 | 示例 | 说明 |
|---------|------|------|
| `arm64-latest` | `ghcr.io/rhinelt/ragflow:arm64-latest` | 最新的 ARM64 版本 |
| `arm64-YYYYMMDD-HHmmss` | `ghcr.io/rhinelt/ragflow:arm64-20260116-154430` | 特定时间的构建 |
| `arm64-<sha>` | `ghcr.io/rhinelt/ragflow:arm64-sha-abc1234` | 特定提交的构建 |

## 与 x86_64 版本的差异

### 依赖处理
ARM64 版本在构建时下载依赖，而不是使用预构建的 deps 镜像：
- HuggingFace 模型通过 `huggingface-hub` 下载
- NLTK 数据通过 Python 下载
- Tika JAR 文件通过 wget 下载
- UV 二进制文件下载 ARM64 版本

### Chrome 支持
由于 Chrome 和 ChromeDriver 不支持 ARM64 架构，这些组件在 ARM64 构建中被跳过。

### ODBC 驱动
ARM64 使用 `msodbcsql18`，而 x86_64 使用 `msodbcsql17`。

## 性能说明

- **首次构建**: 30-60 分钟（需要下载所有依赖）
- **后续构建**: 10-15 分钟（利用缓存）
- **构建开销**: 在 x86_64 运行器上使用 QEMU 模拟，会有性能开销

## 缓存策略

工作流使用 GitHub Actions 缓存加速构建：
- APT 包缓存
- UV/Python 包缓存
- NPM 包缓存
- Docker 层缓存

## 故障排查

### 构建失败

**问题**: HuggingFace 模型下载超时
**解决方案**: GitHub Actions 运行器有良好的网络连接。如果超时，重新触发工作流。

**问题**: APT 包安装失败
**解决方案**: 检查镜像源是否可访问。可以通过 `NEED_MIRROR` 参数切换到中国镜像。

### 验证失败

**问题**: 容器无法启动
**解决方案**: 使用 `docker-compose logs ragflow-cpu` 查看日志。确保依赖服务（MySQL、Redis、MinIO）健康。

**问题**: 架构不匹配
**解决方案**: 确保使用 `--platform linux/arm64` 参数拉取镜像。

## 查看构建进度

1. 访问仓库的 Actions 页面
2. 点击最新的 "Build ARM64 Images" 工作流运行
3. 查看各个作业的进度：
   - `Build RagFlow ARM64`: 主镜像构建
   - `Build Sandbox Images ARM64`: Sandbox 镜像构建
   - `Verify ARM64 Images`: 镜像验证
   - `Build Summary`: 构建摘要

## 相关文件

- `.github/workflows/build-arm64.yml`: 工作流配置
- `Dockerfile.arm64`: ARM64 专用 Dockerfile
- `docs/build-arm64.md`: 英文详细文档
- `docker/docker-compose.yml`: Docker Compose 配置
- `docker/.env`: 环境变量配置

## 注意事项

1. 首次构建时间较长，请耐心等待
2. 镜像大小约 3-5 GB，请确保有足够的存储空间
3. 使用 ARM64 镜像需要 ARM64 硬件或 QEMU 模拟器
4. 建议在 Apple Silicon Mac 或 AWS Graviton 实例上使用以获得最佳性能
