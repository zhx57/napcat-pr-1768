#!/bin/bash
set -e

# =============================================================================
# NapCat PR #1768 Docker 测试镜像构建脚本
# =============================================================================
# 从本地已构建的 NapCat.Shell.zip 构建 Docker 测试镜像
#
# 用法:
#   ./build-docker.sh              # 构建当前平台镜像
#   ./build-docker.sh --multi-arch # 构建 amd64 + arm64 多平台镜像 (需要 buildx)
#   ./build-docker.sh --push       # 构建并推送到 Docker Hub (需要先 docker login)
# =============================================================================

IMAGE_NAME="mlikiowa/napcat-docker"
IMAGE_TAG="pr-1768-e310a57"
FULL_IMAGE="${IMAGE_NAME}:${IMAGE_TAG}"

MULTI_ARCH=false
PUSH=false

# 解析参数
while [[ $# -gt 0 ]]; do
    case $1 in
        --multi-arch)
            MULTI_ARCH=true
            shift
            ;;
        --push)
            PUSH=true
            shift
            ;;
        *)
            echo "未知参数: $1"
            echo "用法: ./build-docker.sh [--multi-arch] [--push]"
            exit 1
            ;;
    esac
done

echo "============================================"
echo "  NapCat PR #1768 Docker 镜像构建"
echo "  镜像: ${FULL_IMAGE}"
echo "  提交: e310a57 (demo/win-bypass-test-20260416)"
echo "============================================"
echo ""

# 检查 Docker
if ! command -v docker &> /dev/null; then
    echo "[错误] 未找到 Docker，请先安装 Docker"
    exit 1
fi

# 切换到脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# 检查必要文件
for f in NapCat.Shell.zip Dockerfile entrypoint.sh; do
    if [ ! -f "$f" ]; then
        echo "[错误] 缺少文件: $f"
        exit 1
    fi
done

if [ ! -d "templates/templates" ]; then
    echo "[错误] 缺少 templates/templates 目录"
    exit 1
fi

echo "[1/3] 检查 base 镜像..."
if ! docker pull mlikiowa/napcat-docker:base 2>/dev/null; then
    echo "  base 镜像拉取失败，尝试本地构建..."
    docker build -t mlikiowa/napcat-docker:base -f base/Dockerfile base/
else
    echo "  base 镜像已就绪"
fi

echo ""
echo "[2/3] 构建 NapCat 测试镜像..."

if [ "$MULTI_ARCH" = true ]; then
    echo "  多平台构建: linux/amd64, linux/arm64"
    if ! docker buildx version &> /dev/null; then
        echo "  [警告] buildx 不可用，安装中..."
        docker buildx create --use --name napcat-builder 2>/dev/null || true
    fi

    if [ "$PUSH" = true ]; then
        echo "  构建并推送到 Docker Hub..."
        docker buildx build \
            --platform linux/amd64,linux/arm64 \
            --push \
            -t "${FULL_IMAGE}" \
            .
    else
        echo "  多平台构建 (仅本地加载 amd64)..."
        docker buildx build \
            --platform linux/amd64,linux/arm64 \
            --output type=docker \
            -t "${FULL_IMAGE}" \
            .
    fi
else
    echo "  单平台构建: $(uname -m)"
    docker build \
        -t "${FULL_IMAGE}" \
        .
fi

echo ""
echo "[3/3] 构建完成!"
echo ""
echo "============================================"
echo "  镜像已就绪: ${FULL_IMAGE}"
echo "============================================"
echo ""
echo "快速启动:"
echo ""
echo "  docker run -d \\"
echo "    --name napcat-pr-test \\"
echo "    -e NAPCAT_UID=\$(id -u) \\"
echo "    -e NAPCAT_GID=\$(id -g) \\"
echo "    -e WEBUI_TOKEN=napcat \\"
echo "    -p 6099:6099 \\"
echo "    -p 3000:3000 \\"
echo "    -p 3001:3001 \\"
echo "    -v ./napcat/config:/app/napcat/config \\"
echo "    -v ./napcat/QQ:/app/.config/QQ \\"
echo "    ${FULL_IMAGE}"
echo ""
echo "WebUI 地址: http://localhost:6099/webui"
echo "Token: napcat"
echo ""
echo "如需推送到 Docker Hub:"
echo "  docker tag ${FULL_IMAGE} ${FULL_IMAGE}"
echo "  docker push ${FULL_IMAGE}"
echo ""
