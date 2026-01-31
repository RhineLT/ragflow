# ARM64 构建优化 TODO 清单 / ARM64 Build Optimization TODO List

## 📌 概述 / Overview

本文档列出了 RagFlow ARM64 镜像构建的优化任务和路线图。目前已具备 ARM 打包能力（使用 QEMU 模拟），下一步将探索使用 GitHub Actions 原生 ARM64 runners 以提升构建性能。

This document lists optimization tasks and roadmap for RagFlow ARM64 image building. Currently, ARM packaging is available using QEMU emulation. The next step is to explore using GitHub Actions native ARM64 runners to improve build performance.

---

## ✅ 已完成 / Completed

- [x] 创建 ARM64 专用 Dockerfile (`Dockerfile.arm64`)
- [x] 创建 ARM64 构建工作流 (`.github/workflows/build-arm64.yml`)
- [x] 使用 QEMU 实现 ARM64 交叉编译
- [x] 构建 ARM64 主镜像和 Sandbox 镜像
- [x] 添加构建验证步骤
- [x] 创建辅助脚本和文档

---

## 🚀 优化路线图 / Optimization Roadmap

### 阶段 1: 使用原生 ARM64 Runners (高优先级)

GitHub Actions 现已提供免费的原生 ARM64 runners（适用于公共仓库）：

| Runner 标签 | 架构 | 规格 | 可用性 |
|------------|------|------|--------|
| `ubuntu-24.04-arm` | arm64 | 4 CPU, 16GB RAM, 14GB SSD | 公共仓库免费 |
| `ubuntu-22.04-arm` | arm64 | 4 CPU, 16GB RAM, 14GB SSD | 公共仓库免费 |
| `windows-11-arm` | arm64 | 4 CPU, 16GB RAM, 14GB SSD | 公共仓库免费 |

**优化任务:**

- [x] **将 `runs-on: ubuntu-latest` 改为 `runs-on: ubuntu-24.04-arm`** ✅ 已完成
  - 预期收益: 构建时间从 60-70 分钟减少到 15-25 分钟
  - 原因: 无需 QEMU 模拟，原生执行速度快 3-5 倍
  
- [x] **移除 QEMU 设置步骤** ✅ 已完成
  - 原生 ARM64 runner 不需要 QEMU 模拟
  - 简化工作流配置
  
- [x] **保留 `platforms` 参数用于显式指定架构** ✅ 已完成
  - 原生 runner 上使用 `--platform linux/arm64` 显式指定
  - 确保镜像标记正确的目标架构

- [x] **更新缓存 scope 命名** ✅ 已完成
  - 将缓存 scope 改为 `*-arm64-native` 格式
  - 确保缓存在新 runner 上正常工作

### 阶段 2: 构建流程优化 (中优先级)

- [ ] **并行化依赖下载**
  - HuggingFace 模型下载和 NLTK 数据下载可以并行执行
  - 使用 `&` 和 `wait` 实现并行

- [ ] **优化 Docker 层缓存**
  - 将不常变化的依赖放在 Dockerfile 前面
  - 将经常变化的代码放在后面

- [ ] **探索多阶段并行构建**
  - 基础镜像构建和 Web 前端构建可以并行
  - 使用 Docker Buildx bake 或 matrix strategy

- [ ] **添加构建时间监控**
  - 在工作流中添加时间戳
  - 生成构建性能报告

### 阶段 3: 镜像优化 (低优先级)

- [ ] **减小镜像大小**
  - 清理不必要的包和缓存
  - 使用 `.dockerignore` 排除不需要的文件
  - 考虑使用 `docker-slim` 工具

- [ ] **实现多架构镜像 (manifest list)**
  - 创建同时包含 amd64 和 arm64 的镜像
  - 用户可以使用相同的镜像标签，Docker 自动选择架构

- [ ] **添加镜像安全扫描**
  - 集成 Trivy 或 Grype 进行漏洞扫描
  - 在推送前检查已知漏洞

### 阶段 4: CI/CD 增强 (可选)

- [ ] **添加构建失败通知**
  - 集成 Slack/Discord/邮件通知
  - 构建失败时自动通知维护者

- [ ] **实现版本自动发布**
  - 根据 Git tag 自动发布正式版本
  - 使用语义化版本号

- [ ] **添加自动化测试**
  - 在构建后运行基本功能测试
  - 确保镜像可以正常启动和运行

---

## 📊 预期性能提升 / Expected Performance Improvements

### 当前状态 (QEMU 模拟)

| 任务 | 时间 |
|------|------|
| RagFlow 主镜像构建 | 60-70 分钟 (首次) |
| RagFlow 主镜像构建 | 10-15 分钟 (增量) |
| Sandbox 镜像构建 | 5-10 分钟 |
| 总构建时间 | 70-80 分钟 (首次) |

### 优化后预期 (原生 ARM64 Runner)

| 任务 | 时间 | 提升 |
|------|------|------|
| RagFlow 主镜像构建 | 15-25 分钟 (首次) | **3-4x 更快** |
| RagFlow 主镜像构建 | 3-5 分钟 (增量) | **3-4x 更快** |
| Sandbox 镜像构建 | 2-3 分钟 | **2x 更快** |
| 总构建时间 | 20-30 分钟 (首次) | **3x 更快** |

---

## 🔗 参考资料 / References

### GitHub Actions ARM64 Runners

- [About GitHub-hosted runners](https://docs.github.com/en/actions/using-github-hosted-runners/using-github-hosted-runners/about-github-hosted-runners)
- [GitHub-hosted runners reference](https://docs.github.com/en/actions/reference/github-hosted-runners-reference)
- [ARM64 runner images](https://github.com/actions/partner-runner-images)

### Runner 规格

**公共仓库免费 ARM64 Runners:**
```yaml
# Ubuntu ARM64
runs-on: ubuntu-24.04-arm  # 推荐
runs-on: ubuntu-22.04-arm  # 备选

# Windows ARM64
runs-on: windows-11-arm
```

**规格详情:**
- CPU: 4 cores
- RAM: 16 GB
- Storage: 14 GB SSD
- 架构: ARM64 (aarch64)

### 镜像信息

- [ubuntu-24.04-arm image](https://github.com/actions/partner-runner-images/blob/main/images/arm-ubuntu-24-image.md)
- [ubuntu-22.04-arm image](https://github.com/actions/partner-runner-images/blob/main/images/arm-ubuntu-22-image.md)

---

## 📝 实施说明 / Implementation Notes

### 工作流更新示例

**Before (QEMU 模拟):**
```yaml
jobs:
  build-ragflow-arm64:
    runs-on: ubuntu-latest
    steps:
      - name: Set up QEMU
        uses: docker/setup-qemu-action@v3
        with:
          platforms: linux/arm64
      
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3
      
      - name: Build and push
        uses: docker/build-push-action@v5
        with:
          platforms: linux/arm64
          ...
```

**After (原生 ARM64):**
```yaml
jobs:
  build-ragflow-arm64:
    runs-on: ubuntu-24.04-arm  # 使用原生 ARM64 runner
    steps:
      # 无需 QEMU 设置
      
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3
      
      - name: Build and push
        uses: docker/build-push-action@v5
        with:
          # 无需指定 platforms，默认为当前架构 (arm64)
          ...
```

### 注意事项

1. **兼容性检查**
   - 确保所有 GitHub Actions 支持 ARM64
   - 部分第三方 actions 可能需要更新

2. **缓存策略**
   - ARM64 runner 的缓存与 x64 runner 分开
   - 需要重新构建缓存

3. **回退方案**
   - 如果原生 runner 不可用，可以回退到 QEMU 模拟
   - 建议保留 QEMU 配置作为备份

---

## ✨ 更新日志 / Changelog

### 2026-01-27
- 创建 ARM64 优化 TODO 文档
- 研究 GitHub Actions 原生 ARM64 runners
- 规划优化路线图

---

**文档版本 / Version:** 1.0.0  
**最后更新 / Last Updated:** 2026-01-27  
**维护者 / Maintainer:** @copilot
