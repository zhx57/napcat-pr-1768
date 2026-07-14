# NapCat PR #1768 Docker 测试镜像

> **PR**: [NapNeko/NapCatQQ#1768](https://github.com/NapNeko/NapCatQQ/pull/1768)
> **分支**: `demo/win-bypass-test-20260416`
> **提交**: `e310a57` (最新)
> **镜像标签**: `mlikiowa/napcat-docker:pr-1768-e310a57`

原 PR 的 CI 测试镜像 (`pr-1768-4e1c87f`) 已被自动清理。本包从 PR 最新源码重新构建了 `NapCat.Shell.zip`，可用于本地构建 Docker 测试镜像。

## 文件说明

| 文件 | 说明 |
|------|------|
| `NapCat.Shell.zip` | 从 PR 分支源码构建的 Shell 包 (35MB) |
| `Dockerfile` | 来自 NapCat-Docker 仓库，构建镜像的 Dockerfile |
| `entrypoint.sh` | 容器入口脚本，含容器特征移除逻辑 |
| `templates/` | 预设连接模式模板 (ws/astrbot/koishi 等) |
| `base/Dockerfile` | base 镜像 Dockerfile (Ubuntu 22.04 + 依赖) |
| `build-docker.sh` | 本地一键构建脚本 |
| `docker-compose.yml` | docker-compose 编排文件 |
| `setup-gh-repo.sh` | GitHub 仓库一键初始化脚本 |
| `.github/workflows/build-push-ghcr.yml` | GitHub Actions 构建推送 workflow |

## 快速开始

### 方式一：GitHub Actions 自动构建并推送到 ghcr.io（推荐）

无需本地安装 Docker，通过 GitHub Actions 在云端构建并推送到 GitHub Container Registry。

**步骤 1：上传到 GitHub 仓库**

```bash
cd napcat-pr-1768-docker

# 方法 A：使用 gh CLI 一键创建仓库并上传（推荐）
# 安装 gh CLI: https://cli.github.com/
gh auth login          # 浏览器登录，安全无需明文 token
./setup-gh-repo.sh     # 自动创建仓库、提交、推送

# 方法 B：手动创建仓库后用 git 推送
git init && git branch -M main
git add -A
git commit -m "NapCat PR #1768 Docker build context"
git remote add origin https://github.com/你的用户名/napcat-pr-1768.git
git push -u origin main
```

**步骤 2：确保仓库权限设置正确**

进入仓库 `Settings` -> `Actions` -> `General` -> `Workflow permissions`，设置为 `Read and write permissions`。

**步骤 3：触发构建**

进入仓库 `Actions` 页面 -> 选择 `Build & Push to GHCR` -> 点击 `Run workflow`。

构建完成后（约 5-10 分钟），镜像地址为：
```
ghcr.io/你的用户名/napcat-pr-1768:pr-1768-e310a57
```

**步骤 4：拉取并运行**

```bash
docker pull ghcr.io/你的用户名/napcat-pr-1768:pr-1768-e310a57

docker run -d \
  --name napcat-pr-test \
  -e NAPCAT_UID=$(id -u) \
  -e NAPCAT_GID=$(id -g) \
  -e WEBUI_TOKEN=napcat \
  -p 6099:6099 -p 3000:3000 -p 3001:3001 \
  -v ./napcat/config:/app/napcat/config \
  -v ./napcat/QQ:/app/.config/QQ \
  ghcr.io/你的用户名/napcat-pr-1768:pr-1768-e310a57
```

### 方式二：本地构建

```bash
cd napcat-pr-1768-docker

# 构建当前平台镜像
./build-docker.sh

# 或构建多平台镜像 (需要 buildx)
./build-docker.sh --multi-arch

# 或构建并推送到 Docker Hub
./build-docker.sh --multi-arch --push
```

### 方式三：手动 docker build

```bash
cd napcat-pr-1768-docker

# 拉取 base 镜像 (如果拉取失败，见下方说明)
docker pull mlikiowa/napcat-docker:base

# 构建镜像
docker build -t mlikiowa/napcat-docker:pr-1768-e310a57 .
```

### 方式四：docker-compose

```bash
cd napcat-pr-1768-docker

# 构建并启动
NAPCAT_UID=$(id -u) NAPCAT_GID=$(id -g) docker-compose up -d --build

# 查看日志
docker logs -f napcat-pr-test

# 停止
docker-compose down
```

## 启动容器

```bash
docker run -d \
  --name napcat-pr-test \
  -e NAPCAT_UID=$(id -u) \
  -e NAPCAT_GID=$(id -g) \
  -e WEBUI_TOKEN=napcat \
  -p 6099:6099 \
  -p 3000:3000 \
  -p 3001:3001 \
  -v ./napcat/config:/app/napcat/config \
  -v ./napcat/QQ:/app/.config/QQ \
  mlikiowa/napcat-docker:pr-1768-e310a57
```

## 访问

- **WebUI**: http://localhost:6099/webui
- **Token**: `napcat` (可通过 `WEBUI_TOKEN` 环境变量修改)

## 环境变量

| 变量 | 说明 | 默认值 |
|------|------|--------|
| `WEBUI_TOKEN` | WebUI 登录 Token | `napcat` |
| `ACCOUNT` | 自动登录的 QQ 号 | (空则手动扫码) |
| `NAPCAT_UID` / `NAPCAT_GID` | 容器内运行用户的 UID/GID | `0` |
| `MODE` | 预设连接模式 (`ws` / `astrbot` / `koishi` 等) | (空) |
| `WEBUI_PREFIX` | WebUI 路径前缀 | (空) |

## 持久化路径

- **QQ 数据**: `/app/.config/QQ`
- **NapCat 配置**: `/app/napcat/config`
- **NapCat 插件**: `/app/napcat/plugins`

## base 镜像说明

Dockerfile 使用 `mlikiowa/napcat-docker:base` 作为基础镜像。如果 Docker Hub 上该镜像不可用，可以使用本地构建：

```bash
docker build -t mlikiowa/napcat-docker:base -f base/Dockerfile base/
```

base 镜像基于 Ubuntu 22.04，包含 Xvfb、ffmpeg、libnss3 等 QQ 运行所需依赖。

## 注意事项

- 此镜像仅用于测试 PR #1768 的反风控/反掉线功能
- 镜像内含容器特征移除逻辑 (entrypoint.sh)，会修改 `/proc`、`/.dockerenv` 等容器标识
- Linux QQ 版本: 3.2.28-48517
- 如遇 QQ 下载失败，可检查网络或使用代理
