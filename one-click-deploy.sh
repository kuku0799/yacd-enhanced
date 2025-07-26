#!/bin/bash

# Yacd-meta 一键部署脚本
# 包含自动同步功能的完整部署

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 配置
GITHUB_REPO="kuku0799/yacd-enhanced"
GITHUB_BRANCH="dist"
YACD_PATH="/usr/share/openclash/ui/yacd"
BACKUP_PATH="/usr/share/openclash/ui/yacd_backup"
AUTO_SYNC_DIR="/root/yacd-auto-sync"

# 日志函数
log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] WARNING:${NC} $1"
}

error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1"
}

info() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')] INFO:${NC} $1"
}

success() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] SUCCESS:${NC} $1"
}

# 检查是否为 root 用户
check_root() {
    if [ "$EUID" -ne 0 ]; then
        error "请使用 root 用户运行此脚本"
        exit 1
    fi
}

# 检查网络连接
check_network() {
    log "检查网络连接..."
    if ! ping -c 1 github.com > /dev/null 2>&1; then
        error "无法连接到 GitHub，请检查网络连接"
        exit 1
    fi
    success "网络连接正常"
}

# 安装依赖
install_dependencies() {
    log "安装依赖包..."
    
    # 更新包列表
    opkg update
    
    # 安装基本的包
    opkg install wget curl unzip
    
    # 自动安装 Node.js
    install_nodejs
    
    success "依赖安装完成"
}

# 自动安装 Node.js
install_nodejs() {
    log "检查 Node.js 安装..."
    
    # 检查是否已安装
    if command -v node &> /dev/null; then
        log "Node.js 已安装: $(node --version)"
        return 0
    fi
    
    # 尝试从包管理器安装
    log "尝试从包管理器安装 Node.js..."
    if opkg install node 2>/dev/null || opkg install nodejs 2>/dev/null; then
        log "Node.js 安装成功"
        return 0
    fi
    
    # 如果包管理器安装失败，使用预编译二进制文件
    log "包管理器安装失败，使用预编译二进制文件..."
    install_nodejs_binary
}

# 安装 Node.js 二进制文件
install_nodejs_binary() {
    log "下载并安装 Node.js 二进制文件..."
    
    # 创建目录
    mkdir -p /usr/local/nodejs
    cd /usr/local/nodejs
    
    # 检测架构
    local arch=$(uname -m)
    local node_version="v18.19.0"
    local download_url=""
    
    case $arch in
        x86_64)
            download_url="https://nodejs.org/dist/$node_version/node-$node_version-linux-x64.tar.xz"
            ;;
        aarch64|arm64)
            download_url="https://nodejs.org/dist/$node_version/node-$node_version-linux-arm64.tar.xz"
            ;;
        armv7l|armv6l)
            download_url="https://nodejs.org/dist/$node_version/node-$node_version-linux-armv7l.tar.xz"
            ;;
        *)
            error "不支持的架构: $arch"
            return 1
            ;;
    esac
    
    log "检测到架构: $arch"
    log "下载地址: $download_url"
    
    # 尝试下载
    if wget -O node.tar.xz "$download_url"; then
        log "下载成功"
    else
        log "官方下载失败，尝试国内镜像..."
        # 尝试国内镜像
        local mirror_urls=(
            "https://npm.taobao.org/mirrors/node/$node_version/node-$node_version-linux-x64.tar.xz"
            "https://mirrors.huaweicloud.com/nodejs/$node_version/node-$node_version-linux-x64.tar.xz"
            "https://mirrors.ustc.edu.cn/nodejs-release/$node_version/node-$node_version-linux-x64.tar.xz"
        )
        
        local download_success=false
        for url in "${mirror_urls[@]}"; do
            if wget -O node.tar.xz "$url"; then
                log "镜像下载成功: $url"
                download_success=true
                break
            fi
        done
        
        if [ "$download_success" = false ]; then
            error "所有下载方式都失败了"
            return 1
        fi
    fi
    
    # 解压
    log "解压 Node.js..."
    tar -xf node.tar.xz
    
    # 查找解压后的目录
    local extracted_dir=$(find . -name "node-$node_version-*" -type d | head -1)
    if [ -z "$extracted_dir" ]; then
        error "解压后未找到正确的目录"
        return 1
    fi
    
    # 移动到正确位置
    log "安装 Node.js..."
    mv "$extracted_dir"/* /usr/local/nodejs/
    
    # 创建软链接
    ln -sf /usr/local/nodejs/bin/node /usr/bin/node
    ln -sf /usr/local/nodejs/bin/npm /usr/bin/npm
    
    # 验证安装
    if node --version &> /dev/null; then
        log "Node.js 安装成功: $(node --version)"
        
        # 安装 js-yaml
        install_js_yaml
        
        success "Node.js 安装完成"
        return 0
    else
        error "Node.js 安装验证失败"
        return 1
    fi
}

# 安装 js-yaml
install_js_yaml() {
    log "安装 js-yaml..."
    
    # 检查是否已安装
    if npm list -g js-yaml &> /dev/null; then
        log "js-yaml 已安装"
        return 0
    fi
    
    # 尝试安装
    if npm install -g js-yaml; then
        log "js-yaml 安装成功"
        return 0
    else
        warn "js-yaml 安装失败，但可以继续部署"
        return 1
    fi
}

# 备份原版 Yacd
backup_original_yacd() {
    log "备份原版 Yacd..."
    
    if [ -d "$YACD_PATH" ]; then
        if [ -d "$BACKUP_PATH" ]; then
            rm -rf "$BACKUP_PATH"
        fi
        cp -r "$YACD_PATH" "$BACKUP_PATH"
        success "原版 Yacd 已备份到: $BACKUP_PATH"
    else
        warn "未找到原版 Yacd，跳过备份"
    fi
}

# 下载增强版 Yacd
download_enhanced_yacd() {
    log "下载增强版 Yacd..."
    
    # 创建临时目录
    local temp_dir="/tmp/yacd-enhanced"
    rm -rf "$temp_dir"
    mkdir -p "$temp_dir"
    cd "$temp_dir"
    
    # 下载 dist 分支
    local download_url="https://github.com/$GITHUB_REPO/archive/refs/heads/$GITHUB_BRANCH.zip"
    log "下载地址: $download_url"
    
    if wget -O yacd-enhanced.zip "$download_url"; then
        success "下载完成"
    else
        error "下载失败，尝试备用方案..."
        # 备用下载方案
        if curl -L -o yacd-enhanced.zip "$download_url"; then
            success "备用下载完成"
        else
            error "所有下载方式都失败了"
            exit 1
        fi
    fi
    
    # 解压文件
    log "解压文件..."
    unzip -o yacd-enhanced.zip
    
    # 查找正确的目录
    local extracted_dir=$(find . -name "yacd-enhanced-*" -type d | head -1)
    if [ -z "$extracted_dir" ]; then
        error "解压后未找到正确的目录"
        exit 1
    fi
    
    success "文件解压完成: $extracted_dir"
    
    # 返回解压后的目录路径
    echo "$temp_dir/$extracted_dir"
}

# 部署 Yacd 文件
deploy_yacd_files() {
    local source_dir="$1"
    
    log "部署 Yacd 文件..."
    
    # 清空目标目录
    if [ -d "$YACD_PATH" ]; then
        rm -rf "$YACD_PATH"/*
    else
        mkdir -p "$YACD_PATH"
    fi
    
    # 复制文件
    if [ -d "$source_dir/public" ]; then
        cp -r "$source_dir/public"/* "$YACD_PATH/"
    else
        cp -r "$source_dir"/* "$YACD_PATH/"
    fi
    
    # 设置权限
    chown -R root:root "$YACD_PATH"
    chmod -R 755 "$YACD_PATH"
    
    success "Yacd 文件部署完成"
}

# 部署自动同步功能
deploy_auto_sync() {
    log "部署自动同步功能..."
    
    # 创建自动同步目录
    mkdir -p "$AUTO_SYNC_DIR"
    cd "$AUTO_SYNC_DIR"
    
    # 下载自动同步脚本
    local auto_sync_url="https://raw.githubusercontent.com/$GITHUB_REPO/$GITHUB_BRANCH/auto-sync.js"
    log "下载自动同步脚本..."
    
    if wget -O auto-sync.js "$auto_sync_url"; then
        chmod +x auto-sync.js
        success "自动同步脚本下载完成"
    else
        error "自动同步脚本下载失败"
        return 1
    fi
    
    # 创建配置文件
    cat > config.json << EOF
{
  "openclash_config_path": "/etc/openclash/config.yaml",
  "backup_dir": "$AUTO_SYNC_DIR/backup",
  "log_file": "$AUTO_SYNC_DIR/sync.log",
  "check_interval": 5000,
  "auto_restart": true
}
EOF
    
    # 创建备份目录
    mkdir -p backup
    
    # 创建系统服务
    cat > /etc/systemd/system/yacd-auto-sync.service << EOF
[Unit]
Description=Yacd-meta Auto Sync Service
After=network.target openclash.service
Wants=openclash.service

[Service]
Type=simple
User=root
WorkingDirectory=$AUTO_SYNC_DIR
ExecStart=/usr/bin/node $AUTO_SYNC_DIR/auto-sync.js watch
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
    
    # 重新加载 systemd
    systemctl daemon-reload
    
    # 启用服务
    systemctl enable yacd-auto-sync.service
    
    success "自动同步功能部署完成"
}

# 创建定时任务
setup_crontab() {
    log "设置定时任务..."
    
    # 添加定时同步任务（每小时执行一次）
    (crontab -l 2>/dev/null; echo "0 * * * * /usr/bin/node $AUTO_SYNC_DIR/auto-sync.js sync") | crontab -
    
    success "定时任务设置完成"
}

# 重启 OpenClash
restart_openclash() {
    log "重启 OpenClash..."
    
    if [ -f "/etc/init.d/openclash" ]; then
        /etc/init.d/openclash restart
        success "OpenClash 重启完成"
    else
        warn "未找到 OpenClash 服务"
    fi
}

# 启动自动同步服务
start_auto_sync() {
    log "启动自动同步服务..."
    
    systemctl start yacd-auto-sync.service
    
    # 检查服务状态
    if systemctl is-active --quiet yacd-auto-sync.service; then
        success "自动同步服务启动成功"
    else
        error "自动同步服务启动失败"
        systemctl status yacd-auto-sync.service
    fi
}

# 显示部署结果
show_deployment_result() {
    echo ""
    echo -e "${PURPLE}========================================${NC}"
    echo -e "${PURPLE}       部署完成！🎉${NC}"
    echo -e "${PURPLE}========================================${NC}"
    echo ""
    echo -e "${CYAN}📁 文件位置:${NC}"
    echo -e "  Yacd-meta: $YACD_PATH"
    echo -e "  自动同步: $AUTO_SYNC_DIR"
    echo -e "  备份文件: $BACKUP_PATH"
    echo ""
    echo -e "${CYAN}🔧 服务管理:${NC}"
    echo -e "  启动服务: systemctl start yacd-auto-sync"
    echo -e "  停止服务: systemctl stop yacd-auto-sync"
    echo -e "  查看状态: systemctl status yacd-auto-sync"
    echo -e "  查看日志: tail -f $AUTO_SYNC_DIR/sync.log"
    echo ""
    echo -e "${CYAN}🌐 访问地址:${NC}"
    echo -e "  Yacd-meta: http://你的路由器IP:9090"
    echo ""
    echo -e "${CYAN}✨ 新功能:${NC}"
    echo -e "  ✅ 节点添加功能"
    echo -e "  ✅ 支持所有协议"
    echo -e "  ✅ 订阅链接导入"
    echo -e "  ✅ 自动同步到配置文件"
    echo -e "  ✅ 自动添加到所有策略组"
    echo ""
    echo -e "${GREEN}现在你可以在 Yacd-meta 中正常添加节点了！${NC}"
    echo -e "${GREEN}节点会自动同步到配置文件并永久保存！${NC}"
    echo ""
}

# 清理临时文件
cleanup() {
    log "清理临时文件..."
    rm -rf /tmp/yacd-enhanced
    success "清理完成"
}

# 主函数
main() {
    echo -e "${PURPLE}========================================${NC}"
    echo -e "${PURPLE}    Yacd-meta 一键部署脚本${NC}"
    echo -e "${PURPLE}========================================${NC}"
    echo ""
    
    # 检查环境
    check_root
    check_network
    
    # 安装依赖
    install_dependencies
    
    # 备份原版
    backup_original_yacd
    
    # 下载并部署
    local source_dir=$(download_enhanced_yacd)
    deploy_yacd_files "$source_dir"
    
    # 部署自动同步
    deploy_auto_sync
    
    # 设置定时任务
    setup_crontab
    
    # 重启服务
    restart_openclash
    
    # 启动自动同步
    start_auto_sync
    
    # 清理
    cleanup
    
    # 显示结果
    show_deployment_result
}

# 错误处理
trap 'error "部署过程中发生错误，请检查日志"; exit 1' ERR

# 运行主函数
main "$@" 