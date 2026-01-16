# ARM64 Helper Scripts

这个目录包含用于 ARM64 镜像构建和验证的辅助脚本。

This directory contains helper scripts for ARM64 image building and verification.

## Scripts

### verify-arm64-images.sh

验证 ARM64 镜像是否正确构建并推送到 GHCR。

Verifies that ARM64 images are correctly built and pushed to GHCR.

**用法 / Usage:**
```bash
./scripts/verify-arm64-images.sh
```

**功能 / Features:**
- 从 GHCR 拉取所有 ARM64 镜像
- 验证镜像架构为 arm64
- 显示镜像大小和创建日期
- 检查所有必需的镜像

**依赖 / Dependencies:**
- Docker
- jq (JSON 处理工具)

### setup-arm64-compose.sh

配置 docker-compose 使用 ARM64 镜像。

Configures docker-compose to use ARM64 images.

**用法 / Usage:**
```bash
./scripts/setup-arm64-compose.sh
```

**功能 / Features:**
- 自动备份现有的 .env 文件
- 更新 RAGFLOW_IMAGE 为 ARM64 版本
- 更新 Sandbox 镜像配置（如果启用）
- 显示所有更改

**回滚 / Rollback:**
脚本会创建备份文件，可以用以下命令回滚：
```bash
cp docker/.env.backup.YYYYMMDD-HHMMSS docker/.env
```

The script creates a backup that can be restored with:
```bash
cp docker/.env.backup.YYYYMMDD-HHMMSS docker/.env
```

## 完整工作流程 / Complete Workflow

### 1. 构建镜像 / Build Images

通过 GitHub Actions 手动触发工作流：
1. 访问仓库的 Actions 页面
2. 选择 "Build ARM64 Images"
3. 点击 "Run workflow"

Manually trigger the workflow via GitHub Actions:
1. Visit the repository's Actions page
2. Select "Build ARM64 Images"
3. Click "Run workflow"

### 2. 验证镜像 / Verify Images

等待构建完成后，运行验证脚本：
```bash
./scripts/verify-arm64-images.sh
```

After the build completes, run the verification script:
```bash
./scripts/verify-arm64-images.sh
```

### 3. 配置 Docker Compose / Configure Docker Compose

运行配置脚本更新 .env 文件：
```bash
./scripts/setup-arm64-compose.sh
```

Run the setup script to update the .env file:
```bash
./scripts/setup-arm64-compose.sh
```

### 4. 启动服务 / Start Services

```bash
cd docker
docker-compose --profile cpu up -d
```

### 5. 检查状态 / Check Status

```bash
# 查看所有服务状态 / View all services status
docker-compose ps

# 查看 RagFlow 日志 / View RagFlow logs
docker-compose logs -f ragflow-cpu

# 验证容器架构 / Verify container architecture
docker exec $(docker-compose ps -q ragflow-cpu) uname -m
# 应该输出 / Should output: aarch64
```

## 故障排查 / Troubleshooting

### 镜像拉取失败 / Image Pull Failed

**问题 / Issue:** 无法从 GHCR 拉取镜像

**解决方案 / Solution:**
1. 检查网络连接
2. 确保镜像已构建并推送
3. 检查 GitHub Actions 工作流状态

### 架构不匹配 / Architecture Mismatch

**问题 / Issue:** 镜像不是 ARM64 架构

**解决方案 / Solution:**
1. 确认使用 `--platform linux/arm64` 参数
2. 检查工作流日志确认构建平台
3. 重新触发工作流

### 服务启动失败 / Service Start Failed

**问题 / Issue:** RagFlow 容器无法启动

**解决方案 / Solution:**
1. 检查依赖服务（MySQL, Redis, MinIO）是否健康
2. 查看容器日志：`docker-compose logs ragflow-cpu`
3. 验证 .env 文件配置是否正确

## 相关文档 / Related Documentation

- [ARM64 构建文档（中文）](../docs/build-arm64-zh.md)
- [ARM64 Build Documentation (English)](../docs/build-arm64.md)
- [GitHub Actions Workflow](../.github/workflows/build-arm64.yml)
- [ARM64 Dockerfile](../Dockerfile.arm64)
