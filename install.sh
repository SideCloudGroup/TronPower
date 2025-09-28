#!/bin/sh
# TronPower 安装脚本
IFS=$'\n\t'
if [ -t 0 ]; then stty erase ^H; fi
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
repo="SideCloudGroup/TronPower"
filename="TronPower"

check_docker_permission() {
  current_user=$(whoami)
  if [ "$current_user" != "root" ]; then
    if [ "$(uname)" = "Darwin" ]; then
      echo -e "${BLUE}已检测到系统为${YELLOW}macOS${NC}"
      if ! docker info &>/dev/null; then
        echo -e "${RED}当前无法连接到Docker进程${NC}"
        echo -e "${YELLOW}请检查是否已安装Docker Desktop以及Docker Desktop服务是否已启动！${NC}"
        echo -e "${RED}如果您确信Docker Desktop已在运行，请尝试使用root(sudo)运行此脚本！${NC}"
        exit 1
      fi
    else
      echo -e "${BLUE}已检测到系统为${YELLOW}Linux${NC}"
      if ! id -nG "$current_user" | grep -qw docker; then
        echo -e "${RED}当前用户非root且不在docker用户组中，没有使用docker的权限${NC}"
        echo -e "${YELLOW}解决方法：${NC}"
        echo -e "1.${BLUE}将当前用户加入docker用户组并重新进入终端${YELLOW}(sudo gpasswd -a 用户名 docker)${NC}"
        echo -e "2.${BLUE}直接使用root(sudo)运行此脚本！${NC}"
        exit 1
      fi
    fi
  else
    echo -e "${BLUE}已检测到当前用户为${YELLOW}root${NC}"
  fi
}

check_docker_permission

if ! command -v unzip &> /dev/null || ! command -v curl &> /dev/null || ! command -v wget &> /dev/null || ! command -v rsync &> /dev/null; then
    echo -e "${YELLOW}缺少必要的工具，正在安装……${NC}"
    if [ -f /etc/debian_version ]; then
        apt update
        apt -y install unzip curl wget jq rsync
    elif [ -f /etc/redhat-release ]; then
        yum -y install unzip curl wget jq rsync
    else
       echo -e "${RED}无法检测到当前系统，已退出${NC}"
       exit;
    fi
fi
LATEST_TAG=$(curl -m 10 -s "https://api.github.com/repos/$repo/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
if [ -z "$LATEST_TAG" ]; then
    echo -e "${RED}获取版本号失败或超时，请手动输入版本号（例如：4.0.0）：${NC}"
    read manual_tag
    if [[ "$manual_tag" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        LATEST_TAG="$manual_tag"
    else
        echo -e "${RED}输入的版本号格式不正确，退出脚本${NC}"
        exit 1
    fi
fi
echo -e "${YELLOW}请输入安装路径（回车默认安装到/opt/TronPower）:${NC}"
read install_path
install_path=${install_path:-/opt/TronPower}
if [ -d "$install_path" ]; then
    echo -e "${RED}$install_path 文件夹已存在，退出脚本${NC}"
    exit 1
fi
mkdir -p $install_path
echo -e "${BLUE}检查并安装必要的软件包...${NC}"
if docker >/dev/null 2>&1; then
    echo -e "${GREEN}Docker已安装${NC}"
else
    echo -e "${YELLOW}Docker未安装，开始安装……${NC}"
    systemctl enable docker && systemctl restart docker
    echo -e "${GREEN}Docker安装完成${NC}"
fi
if ! docker >/dev/null 2>&1; then
    echo -e "${RED}Docker安装失败，请检查错误信息${NC}"
    exit 1
fi
cd $install_path
wget -T 20 -q "https://github.com/$repo/archive/refs/heads/main.zip" -O "main.zip"
wget -T 20 -q "https://github.com/$repo/releases/download/$LATEST_TAG/$filename.zip" -O "$filename.zip"
if [ $? -ne 0 ]; then
    echo -e "${RED}wget失败或超时，退出程序${NC}"
    exit 1
fi
unzip -q -o "main.zip"
rsync -av --remove-source-files "$filename-main"/ ./
rm -rf "$filename-main"
rm -rf "main.zip"
unzip -q -o "$filename.zip"
if [ ! -d "$filename" ]; then
    echo -e "${RED}$filename 目录不存在，退出更新……${NC}"
    exit 1
fi
mv "$filename" web
rm -rf "$filename.zip"
mv .example.env .env
mv backend-config.example.toml backend-config.toml
docker compose pull
chmod +x ./data/entrypoint.sh
echo -e "${GREEN}下载完成！请继续按照教程完成接下来的步骤${NC}"
exit 0