#!/bin/sh
# TronPower 更新脚本
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
repo="SideCloudGroup/TronPower"
filename="TronPower"
LATEST_TAG=$(curl -s "https://api.github.com/repos/$repo/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')

echo -e "${BLUE}如文件存在改动，一键更新后将会被替换至最新版本，改动将会消失，请注意备份${NC}"
echo -e "${BLUE}If there are changes in the file, it will be replaced with the latest version after one-click update, and the changes will disappear. Please backup.${NC}"
echo -e "${YELLOW}请按回车继续执行更新 | Press enter to continue...${NC}"
read
echo -e "${GREEN}正在升级到最新版本：$LATEST_TAG${NC}"

docker compose down
git pull
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
cp ./web/.env "$filename/.env"
rm -rf web
mv "$filename" web
rm -rf "$filename.zip"

echo -e "${GREEN}更新完成，请查看更新日志，检查前端配置文件是否需要改动。${NC}"
echo -e "${yellow}若前端配置文件有更新，请与web/.example.env对比，手动修改web/.env文件${NC}"

docker compose pull
docker compose up -d

echo -e "${GREEN}升级完成！${NC}"
exit 0