#!/usr/bin/env bash
# ==============================================================================
# Atuzz CertAgent Private - 纯内网物理隔离一键极速部署与启动脚本
# 适用平台: CentOS / RHEL / Ubuntu / Debian / 统信 UOS / 银河麒麟 Linux
# ==============================================================================

set -e

# ANSI 颜色与高亮
BOLD="\033[1m"
GREEN="\033[32m"
BLUE="\033[34m"
YELLOW="\033[33m"
CYAN="\033[36m"
RED="\033[31m"
RESET="\033[0m"

echo -e "\n${BOLD}${CYAN}================================================================${RESET}"
echo -e "${BOLD}${CYAN}   🚀 正在启动 Atuzz CertAgent Private 企业离线一体机容器...    ${RESET}"
echo -e "${BOLD}${CYAN}================================================================${RESET}\n"

# 1. 检查 Docker 环境
if ! command -v docker &> /dev/null; then
    echo -e "${RED}[错误] 未检测到 Docker 运行环境！${RESET}"
    echo -e "内网一体机需依赖 Docker 引擎。请先在宿主机安装并启动 Docker 服务后再运行本脚本。"
    exit 1
fi

# 2. 检查 Docker Compose
COMPOSE_CMD=""
if docker compose version &> /dev/null; then
    COMPOSE_CMD="docker compose"
elif command -v docker-compose &> /dev/null; then
    COMPOSE_CMD="docker-compose"
else
    echo -e "${RED}[错误] 未检测到 docker compose 插件或 docker-compose 二进制！${RESET}"
    echo -e "请确保宿主机安装了 Docker Compose (v2.0+ 推荐)。"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# 3. 寻找离线镜像压缩包并载入
IMAGE_ARCHIVE=""
if [ -f "certagent-private-image.tar.gz" ]; then
    IMAGE_ARCHIVE="certagent-private-image.tar.gz"
elif [ -f "certagent-private-latest.tar.gz" ]; then
    IMAGE_ARCHIVE="certagent-private-latest.tar.gz"
fi

if [ -n "$IMAGE_ARCHIVE" ]; then
    echo -e "${BLUE}📦 检测到离线镜像包: ${IMAGE_ARCHIVE}，正在载入本地 Docker 镜像库...${RESET}"
    docker load -i "$IMAGE_ARCHIVE"
    echo -e "${GREEN}✓ 离线镜像已成功载入！${RESET}\n"
else
    echo -e "${YELLOW}ℹ️ 未在当前目录发现离线镜像包，将使用本地已有镜像或自动从镜像源拉取...${RESET}"
fi

# 4. 准备持久化数据目录
mkdir -p data
chmod 755 data 2>/dev/null || true

# 5. 启动一体机容器编排
echo -e "${BLUE}⚙️ 正在执行编排启动 (${COMPOSE_CMD} up -d)...${RESET}"
$COMPOSE_CMD up -d

# 6. 探测内网真实 IP
SERVER_IP=""
if command -v hostname &> /dev/null; then
    SERVER_IP=$(hostname -I 2>/dev/null | awk '{print $1}') || true
fi
if [ -z "$SERVER_IP" ] && command -v ip &> /dev/null; then
    SERVER_IP=$(ip route get 1.1.1.1 2>/dev/null | awk '{print $7}') || true
fi
if [ -z "$SERVER_IP" ]; then
    SERVER_IP="<服务器内网IP>"
fi

# 7. 呈现高颜值就绪战报
echo -e "\n${BOLD}${GREEN}================================================================${RESET}"
echo -e "${BOLD}${GREEN}   🎉 Atuzz CertAgent Private 企业离线一体机已成功启动！        ${RESET}"
echo -e "${BOLD}${GREEN}================================================================${RESET}"
echo -e "\n${BOLD}请在内网电脑浏览器中访问本地 Web 管理控制台：${RESET}"
echo -e "👉 ${BOLD}${CYAN}https://${SERVER_IP}:3443${RESET} (HTTPS 绿锁管理控制台)"
echo -e "👉 ${BOLD}${BLUE}http://${SERVER_IP}:3000${RESET} (HTTP 探针中枢与根证书极速分发)"
echo -e "\n${YELLOW}💡 首次登录提示：${RESET}"
echo -e "   系统已内置开箱即用的「首次安全向导」，首次打开页面时直接自主设定专属管理员密码，"
echo -e "   无需翻查容器日志。内网数据 0 上传、不依赖任何外网服务，100% 物理隔离运行。\n"
