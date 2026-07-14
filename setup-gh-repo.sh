#!/bin/bash
set -e

# =============================================================================
# 一键创建 GitHub 仓库并上传构建上下文
# =============================================================================
# 用法:
#   ./setup-gh-repo.sh
#
# 前提:
#   1. 已安装 gh CLI (GitHub CLI)
#      - 安装: https://cli.github.com/
#      - 登录: gh auth login
#   2. 或已安装 git 并配置了 GitHub 远程仓库
#
# 安全说明:
#   - 本脚本使用 gh CLI 的交互式登录，不会要求你输入明文 token
#   - 登录后 token 由 gh CLI 安全存储，不会出现在命令行历史中
# =============================================================================

REPO_NAME="napcat-pr-1768"
REPO_DESC="NapCat PR #1768 Docker test image (anti-detect/anti-kickoff)"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "============================================"
echo "  NapCat PR #1768 -> GitHub 仓库初始化"
echo "============================================"
echo ""

# 检查 gh CLI
if command -v gh &> /dev/null; then
    echo "[检测到 gh CLI]"

    # 检查是否已登录
    if ! gh auth status &> /dev/null; then
        echo "  未登录 GitHub，开始登录..."
        echo ""
        echo "  >>> gh auth login <<<"
        echo "  按提示操作，推荐选择:"
        echo "    - GitHub.com"
        echo "    - HTTPS"
        echo "    - Login with a web browser (浏览器登录，最安全)"
        echo ""
        gh auth login
    fi

    GH_USER=$(gh api user --jq '.login')
    echo "  当前用户: ${GH_USER}"

    # 检查仓库是否已存在
    if gh repo view "${GH_USER}/${REPO_NAME}" &> /dev/null; then
        echo "  仓库 ${GH_USER}/${REPO_NAME} 已存在"
    else
        echo "  创建仓库 ${REPO_NAME}..."
        gh repo create "${REPO_NAME}" --public --description "${REPO_DESC}"
        echo "  仓库已创建: https://github.com/${GH_USER}/${REPO_NAME}"
    fi

    # 初始化 git 仓库
    if [ ! -d ".git" ]; then
        git init
        git branch -M main
    fi

    # 配置 remote
    REMOTE_URL="https://github.com/${GH_USER}/${REPO_NAME}.git"
    git remote remove origin 2>/dev/null || true
    git remote add origin "${REMOTE_URL}"

    # 添加文件
    git add -A
    git commit -m "NapCat PR #1768 Docker build context (commit e310a57)" || echo "  无需提交"

    # 推送
    echo ""
    echo "  推送到 GitHub..."
    git push -u origin main

    echo ""
    echo "============================================"
    echo "  ✅ 仓库已就绪: https://github.com/${GH_USER}/${REPO_NAME}"
    echo "============================================"
    echo ""
    echo "下一步:"
    echo "  1. 打开 https://github.com/${GH_USER}/${REPO_NAME}/actions"
    echo "  2. 选择 'Build & Push to GHCR' workflow"
    echo "  3. 点击 'Run workflow' -> 'Run workflow'"
    echo "  4. 等待构建完成 (约 5-10 分钟)"
    echo "  5. 镜像地址: ghcr.io/${GH_USER}/${REPO_NAME}:pr-1768-e310a57"
    echo ""

# 如果没有 gh CLI，用 git 方式
elif command -v git &> /dev/null; then
    echo "[未检测到 gh CLI，使用 git 方式]"
    echo ""
    echo "请手动创建一个 GitHub 仓库，然后执行:"
    echo ""
    echo "  cd ${SCRIPT_DIR}"
    echo "  git init"
    echo "  git branch -M main"
    echo "  git add -A"
    echo "  git commit -m 'NapCat PR #1768 Docker build context'"
    echo "  git remote add origin https://github.com/你的用户名/napcat-pr-1768.git"
    echo "  git push -u origin main"
    echo ""
    echo "推荐安装 gh CLI 简化操作:"
    echo "  https://cli.github.com/"
    echo ""

else
    echo "[错误] 需要安装 git 或 gh CLI"
    exit 1
fi
