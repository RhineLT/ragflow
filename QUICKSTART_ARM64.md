# 🚀 ARM64 镜像快速开始指南 / Quick Start Guide

## 5 分钟快速上手 / 5-Minute Quick Start

### 步骤 1：触发构建 / Step 1: Trigger Build (2 分钟)

1. 打开浏览器，访问：
   ```
   https://github.com/RhineLT/ragflow/actions/workflows/build-arm64.yml
   ```

2. 点击右侧绿色的 **"Run workflow"** 按钮

3. 保持默认设置，点击绿色的 **"Run workflow"** 按钮确认

4. 等待构建开始（约 5-10 秒后页面会刷新显示新的工作流运行）

**⏱️ 预计等待时间**：
- 首次构建：30-60 分钟
- 后续构建：10-15 分钟（有缓存）

### 步骤 2：检查构建状态 / Step 2: Check Build Status (持续)

在工作流页面可以看到：
- 🟡 黄色圆点 = 正在构建
- ✅ 绿色对勾 = 构建成功
- ❌ 红色叉号 = 构建失败（需要查看日志）

点击工作流名称可以查看详细进度和日志。

### 步骤 3：验证镜像 / Step 3: Verify Images (1 分钟)

构建成功后，在本地运行：

```bash
./scripts/verify-arm64-images.sh
```

如果看到所有镜像都显示 ✓，说明镜像构建成功！

### 步骤 4：配置使用 / Step 4: Configure (1 分钟)

```bash
./scripts/setup-arm64-compose.sh
```

这会自动更新 `docker/.env` 文件使用 ARM64 镜像。

### 步骤 5：启动服务 / Step 5: Start Services (1 分钟)

```bash
cd docker
docker-compose --profile cpu up -d
```

### 步骤 6：验证运行 / Step 6: Verify Running (1 分钟)

```bash
# 检查所有服务是否正常运行
docker-compose ps

# 查看 RagFlow 日志
docker-compose logs -f ragflow-cpu

# 验证容器是 ARM64 架构
docker exec $(docker-compose ps -q ragflow-cpu) uname -m
# 应该输出：aarch64
```

## 🎯 成功标志 / Success Indicators

### ✅ 构建成功

在 GitHub Actions 中看到：
- ✅ Build RagFlow ARM64 - 绿色
- ✅ Build Sandbox Images ARM64 - 绿色
- ✅ Verify ARM64 Images - 绿色
- ✅ Build Summary - 绿色

### ✅ 镜像可用

运行验证脚本后看到：
```
✓ Pull successful
✓ Architecture verified as arm64
✓ Image verified successfully
```

### ✅ 服务运行正常

```bash
$ docker-compose ps
NAME                   STATUS
ragflow-cpu-1          Up (healthy)
mysql-1                Up (healthy)
redis-1                Up
minio-1                Up (healthy)
```

## 🔍 故障排查 / Troubleshooting

### 问题 1：构建失败

**症状**：GitHub Actions 显示红色 ❌

**解决方案**：
1. 点击失败的作业查看详细日志
2. 常见问题：
   - HuggingFace 下载超时 → 重新运行工作流
   - 磁盘空间不足 → 等待 GitHub Actions 清理，然后重试
   - 依赖安装失败 → 检查日志中的具体错误信息

### 问题 2：镜像拉取失败

**症状**：`docker pull` 失败

**解决方案**：
1. 确认镜像已构建成功（检查 GitHub Actions）
2. 检查网络连接
3. 如果是私有仓库，确认已登录：
   ```bash
   echo $GITHUB_TOKEN | docker login ghcr.io -u USERNAME --password-stdin
   ```

### 问题 3：容器启动失败

**症状**：`docker-compose ps` 显示容器状态不健康

**解决方案**：
1. 查看容器日志：
   ```bash
   docker-compose logs ragflow-cpu
   ```
2. 检查依赖服务是否健康：
   ```bash
   docker-compose ps mysql redis minio
   ```
3. 验证 .env 配置是否正确

## 📚 完整文档 / Full Documentation

- 📖 [完整构建文档（中文）](docs/build-arm64-zh.md)
- 📖 [Full Build Documentation (English)](docs/build-arm64.md)
- 📋 [项目总结](ARM64_BUILD_SUMMARY.md)
- 🛠️ [脚本使用说明](scripts/README.md)

## 🆘 获取帮助 / Get Help

如果遇到问题：

1. **查看日志**：
   - GitHub Actions 构建日志
   - Docker 容器日志：`docker-compose logs`

2. **运行诊断**：
   ```bash
   # 检查 Docker
   docker info
   
   # 检查镜像
   docker images | grep ragflow
   
   # 检查架构
   docker inspect <image-id> | jq '.[0].Architecture'
   ```

3. **重新开始**：
   ```bash
   # 清理容器
   cd docker
   docker-compose down -v
   
   # 清理镜像
   docker rmi $(docker images | grep ragflow | awk '{print $3}')
   
   # 重新开始
   ./scripts/setup-arm64-compose.sh
   cd docker
   docker-compose --profile cpu up -d
   ```

## 🎉 完成！/ Done!

如果所有步骤都成功，你现在已经有了：
- ✅ ARM64 架构的 RagFlow 镜像
- ✅ 在 GHCR 上的镜像仓库
- ✅ 本地运行的 RagFlow 服务
- ✅ 完整的自动化构建流程

享受使用 RagFlow 的 ARM64 版本吧！🚀

Enjoy using RagFlow on ARM64! 🚀
