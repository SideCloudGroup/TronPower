#!/bin/sh
# TronPower 安装脚本
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
repo="SideCloudGroup/TronPower"
filename="TronPower"
LATEST_TAG=$(curl -s "https://api.github.com/repos/$repo/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')

if [ -d "/opt/TronPower" ]; then
    echo -e "${RED}/opt/TronPower 文件夹已存在，退出脚本${NC}"
    exit 1
fi

echo -e "${BLUE}检查并安装必要的软件包...${NC}"

if docker >/dev/null 2>&1; then
    echo -e "${GREEN}Docker已安装${NC}"
else
    echo -e "${YELLOW}Docker未安装，开始安装……${NC}"
    docker version > /dev/null || curl -fsSL get.docker.com | bash
    systemctl enable docker && systemctl restart docker
    echo -e "${GREEN}Docker安装完成${NC}"
fi
if ! docker >/dev/null 2>&1; then
    echo -e "${RED}Docker安装失败，请检查错误信息${NC}"
    exit 1
fi
if ! git --version >/dev/null 2>&1; then
    echo -e "${YELLOW}git未安装，开始安装……${NC}"
    apt-get update && apt-get install -y git
    echo -e "${GREEN}git安装完成${NC}"
fi
if ! unzip -v >/dev/null 2>&1; then
    echo -e "${YELLOW}unzip未安装，开始安装……${NC}"
    apt-get update && apt-get install -y unzip
    echo -e "${GREEN}unzip安装完成${NC}"
fi
if ! wget --version >/dev/null 2>&1; then
    echo -e "${YELLOW}wget未安装，开始安装……${NC}"
    apt-get update && apt-get install -y wget
    echo -e "${GREEN}wget安装完成${NC}"
fi
git clone https://github.com/SideCloudGroup/TronPower.git /opt/TronPower
cd /opt/TronPower
cp ./data/backend-config.example.toml ./data/backend-config.toml
wget -T 20 -q "https://github.com/$repo/releases/download/$LATEST_TAG/$filename.zip" -O "$filename.zip"
if [ $? -ne 0 ]; then
    echo -e "${RED}wget失败或超时，退出程序${NC}"
    exit 1
fi
rm -rf "$filename"
unzip -q -o "$filename.zip"
if [ ! -d "$filename" ]; then
    echo -e "${RED}$filename 目录不存在，退出更新……${NC}"
    exit 1
fi
mv "$filename" web
rm -rf "$filename.zip"
cp ./web/.example.env ./web/.env
docker compose pull
echo -e "${GREEN}下载完成！请继续按照教程完成接下来的步骤${NC}"
exit 0