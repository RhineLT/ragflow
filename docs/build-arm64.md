# ARM64 Image Build Documentation

This document describes the ARM64 image build process for RagFlow.

## Overview

The ARM64 build workflow creates multi-architecture Docker images for RagFlow and its dependencies, optimized for ARM64 platforms (Apple Silicon, AWS Graviton, etc.).

> 🚀 **Latest Optimization**: The workflow now uses GitHub Actions native ARM64 runners (`ubuntu-24.04-arm`) for 3-4x faster builds compared to QEMU emulation!

## Images Built

The workflow builds and pushes the following ARM64 images to GitHub Container Registry (GHCR):

1. **RagFlow Main Image**: `ghcr.io/rhinelt/ragflow:arm64-latest`
2. **Sandbox Base Python**: `ghcr.io/rhinelt/ragflow-sandbox-base-python:arm64-latest`
3. **Sandbox Base Node.js**: `ghcr.io/rhinelt/ragflow-sandbox-base-nodejs:arm64-latest`
4. **Sandbox Executor Manager**: `ghcr.io/rhinelt/ragflow-sandbox-executor-manager:arm64-latest`

## Workflow Triggers

The workflow is triggered by:
- Manual dispatch (`workflow_dispatch`)
- Push to `main` or `master` branches
- Pull requests modifying Docker-related files

## Key Features

### 1. Native ARM64 Runner

The workflow uses GitHub Actions native ARM64 runner:
- **Runner**: `ubuntu-24.04-arm` (4 CPU, 16GB RAM, 14GB SSD)
- **Architecture**: Native ARM64 (no QEMU emulation needed)
- **Cost**: Free for public repositories
- **Performance**: 3-4x faster than QEMU-based builds

### 2. ARM64-Specific Dockerfile

The `Dockerfile.arm64` is optimized for ARM64 builds:
- Downloads dependencies during build (no separate deps image required)
- Handles HuggingFace models download
- Downloads NLTK data
- Skips Chrome/ChromeDriver for ARM64 (not available)
- Installs correct architecture-specific packages

### 3. Multi-stage Verification

The workflow includes:
1. **Build Stage**: Builds ARM64 images natively on ARM64 runner
2. **Verification Stage**:
   - Pulls and inspects images to verify ARM64 architecture
   - Tests images with docker compose
   - Validates container startup and health
3. **Summary Stage**: Provides build summary with image tags

### 4. Caching Strategy

Build caching is enabled using GitHub Actions cache:
- Docker layer cache: `type=gha,scope=ragflow-arm64-native`
- APT packages cache in Dockerfile
- UV/Python packages cache in Dockerfile
- NPM packages cache in Dockerfile

## Expected Build Times

| Task | QEMU (old) | Native ARM64 (new) |
|------|------------|-------------------|
| RagFlow main image | 60-70 min | 15-25 min |
| Sandbox images | 5-10 min | 2-3 min |
| Total | 70-80 min | 20-30 min |

## Usage

### Pulling Images

```bash
# Pull the main RagFlow ARM64 image
docker pull ghcr.io/rhinelt/ragflow:arm64-latest

# Pull sandbox images
docker pull --platform linux/arm64 ghcr.io/rhinelt/ragflow-sandbox-base-python:arm64-latest
docker pull --platform linux/arm64 ghcr.io/rhinelt/ragflow-sandbox-base-nodejs:arm64-latest
docker pull --platform linux/arm64 ghcr.io/rhinelt/ragflow-sandbox-executor-manager:arm64-latest
```

### Using with Docker Compose

Update your `.env` file in the `docker` directory:

```bash
cd docker
cp .env .env.backup

# Update the RAGFLOW_IMAGE variable
sed -i 's|RAGFLOW_IMAGE=.*|RAGFLOW_IMAGE=ghcr.io/rhinelt/ragflow:arm64-latest|g' .env
```

Then start the services:

```bash
docker-compose --profile cpu up -d
```

### Verifying Architecture

Inspect the image to verify it's ARM64:

```bash
docker inspect ghcr.io/rhinelt/ragflow:arm64-latest | jq '.[0].Architecture'
# Should output: "arm64"

# Or check inside a running container
docker run --rm ghcr.io/rhinelt/ragflow:arm64-latest uname -m
# Should output: "aarch64"
```

## Build Process

### 1. Setup Phase
- Checkout code with full git history
- Set up QEMU for ARM64 emulation
- Configure Docker Buildx for multi-platform builds
- Authenticate to GHCR

### 2. Build Phase
- Extract image metadata and generate tags
- Build using `Dockerfile.arm64` with BuildKit
- Push to GHCR with multiple tags:
  - `arm64-latest`: Latest ARM64 build
  - `arm64-YYYYMMDD-HHmmss`: Timestamped build
  - `arm64-<sha>`: Git commit SHA build
  - `arm64-<branch>`: Branch-based tag
  - `arm64-pr-<number>`: PR-based tag

### 3. Verification Phase
- Pull the built image
- Inspect architecture metadata
- Start supporting services (MySQL, Redis, MinIO)
- Start RagFlow container
- Verify container health and architecture

## Differences from x86_64 Build

### Dependencies Download
The ARM64 Dockerfile downloads dependencies during build instead of using a pre-built deps image:
- HuggingFace models via `huggingface-hub`
- NLTK data via Python
- Tika JAR files via wget
- UV binary for ARM64

### Chrome Support
Chrome and ChromeDriver are skipped for ARM64 as they're not available for this architecture.

### ODBC Driver
Uses `msodbcsql18` for ARM64 instead of `msodbcsql17` used on x86_64.

### libssl Package
Uses the ARM64-specific `libssl1.1_1.1.1f-1ubuntu2_arm64.deb` package.

## Troubleshooting

### Build Failures

**Issue**: HuggingFace model download timeout
**Solution**: The workflow uses GitHub Actions runners which have good bandwidth. If timeout occurs, try manually triggering the workflow again.

**Issue**: APT package installation failures
**Solution**: Check if mirrors are accessible. The workflow supports both default mirrors and China mirrors via `NEED_MIRROR` build arg.

### Verification Failures

**Issue**: Container fails to start
**Solution**: Check logs with `docker-compose logs ragflow-cpu`. Ensure all dependencies (MySQL, Redis, MinIO) are healthy.

**Issue**: Architecture mismatch
**Solution**: Ensure you're using `docker pull --platform linux/arm64` when pulling images manually.

## Performance Notes

- Initial build may take 30-60 minutes due to dependency downloads
- Subsequent builds leverage caching and typically complete in 10-15 minutes
- ARM64 builds use QEMU emulation on x86_64 runners, which adds overhead

## Contributing

When modifying the ARM64 build:
1. Test changes locally if possible using Docker Buildx
2. Update `Dockerfile.arm64` for ARM64-specific changes
3. Update this documentation if adding new features
4. Ensure all lint checks pass

## Related Files

- `.github/workflows/build-arm64.yml`: Main workflow file
- `Dockerfile.arm64`: ARM64-specific Dockerfile
- `docker/docker-compose.yml`: Docker Compose configuration
- `docker/.env`: Environment configuration
