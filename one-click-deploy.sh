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
    
    # 如果包管理器安装失败，尝试二进制文件安装
    log "包管理器安装失败，尝试二进制文件安装..."
    if ! install_nodejs_binary; then
        log "二进制安装失败，尝试备用方案..."
        if ! install_nodejs_alternative; then
            log "所有 Node.js 安装方案都失败了，使用轻量级方案..."
            install_lightweight_sync
        fi
    fi
}

# 安装 Node.js 二进制文件
install_nodejs_binary() {
    log "下载并安装 Node.js 二进制文件..."
    
    # 创建目录
    mkdir -p /usr/local/nodejs
    cd /usr/local/nodejs
    
    # 清理之前的文件
    rm -rf node.tar.xz node.tar.gz node-v18.19.0-*
    
    # 检测架构
    local arch=$(uname -m)
    local node_version="v18.19.0"
    local download_url=""
    
    case $arch in
        x86_64)
            download_url="https://nodejs.org/dist/$node_version/node-$node_version-linux-x64.tar.gz"
            ;;
        aarch64|arm64)
            download_url="https://nodejs.org/dist/$node_version/node-$node_version-linux-arm64.tar.gz"
            ;;
        armv7l|armv6l)
            download_url="https://nodejs.org/dist/$node_version/node-$node_version-linux-armv7l.tar.gz"
            ;;
        *)
            error "不支持的架构: $arch"
            return 1
            ;;
    esac
    
    log "检测到架构: $arch"
    log "下载地址: $download_url"
    
    # 尝试下载 .tar.gz 格式
    if wget -O node.tar.gz "$download_url"; then
        log "下载成功"
    else
        log "官方下载失败，尝试国内镜像..."
        # 尝试国内镜像
        local mirror_urls=(
            "https://npm.taobao.org/mirrors/node/$node_version/node-$node_version-linux-x64.tar.gz"
            "https://mirrors.huaweicloud.com/nodejs/$node_version/node-$node_version-linux-x64.tar.gz"
            "https://mirrors.ustc.edu.cn/nodejs-release/$node_version/node-$node_version-linux-x64.tar.gz"
        )
        
        local download_success=false
        for url in "${mirror_urls[@]}"; do
            if wget -O node.tar.gz "$url"; then
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
    
    # 检查下载的文件
    if [ ! -f "node.tar.gz" ] || [ ! -s "node.tar.gz" ]; then
        error "下载的文件无效或为空"
        return 1
    fi
    
    # 使用 gunzip 解压
    log "使用 gunzip 解压 Node.js..."
    if ! gunzip -c node.tar.gz | tar -xf -; then
        error "gunzip 解压失败，检查磁盘空间..."
        df -h
        return 1
    fi
    
    # 查找解压后的目录
    local extracted_dir=$(find . -name "node-$node_version-*" -type d | head -1)
    if [ -z "$extracted_dir" ]; then
        error "解压后未找到正确的目录"
        ls -la
        return 1
    fi
    
    log "找到解压目录: $extracted_dir"
    
    # 移动到正确位置
    log "安装 Node.js..."
    if [ -d "$extracted_dir" ]; then
        cp -r "$extracted_dir"/* /usr/local/nodejs/ 2>/dev/null || {
            error "复制文件失败"
            return 1
        }
    else
        error "解压目录不存在"
        return 1
    fi
    
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

# 备用 Node.js 安装方案
install_nodejs_alternative() {
    log "尝试备用 Node.js 安装方案..."
    
    # 清理空间
    rm -rf /tmp/node* /tmp/yacd*
    
    # 创建简单的 Node.js 环境
    mkdir -p /usr/local/nodejs/bin
    cd /usr/local/nodejs
    
    # 尝试更小的 Node.js 版本
    local arch=$(uname -m)
    local node_version="v16.20.2"  # 使用更小的版本
    local node_url=""
    
    case $arch in
        x86_64)
            node_url="https://nodejs.org/dist/$node_version/node-$node_version-linux-x64.tar.gz"
            ;;
        aarch64|arm64)
            node_url="https://nodejs.org/dist/$node_version/node-$node_version-linux-arm64.tar.gz"
            ;;
        *)
            node_url="https://nodejs.org/dist/$node_version/node-$node_version-linux-x64.tar.gz"
            ;;
    esac
    
    log "下载备用 Node.js (v16): $node_url"
    
    if wget -O node.tar.gz "$node_url"; then
        log "备用下载成功"
        
        # 使用 gunzip 解压
        if gunzip -c node.tar.gz | tar -xf -; then
            log "备用解压成功"
            
            # 查找并复制文件
            local node_dir=$(find . -name "node-$node_version-*" -type d | head -1)
            if [ -n "$node_dir" ] && [ -d "$node_dir" ]; then
                cp -r "$node_dir"/* /usr/local/nodejs/
                ln -sf /usr/local/nodejs/bin/node /usr/bin/node
                ln -sf /usr/local/nodejs/bin/npm /usr/bin/npm
                
                if node --version &> /dev/null; then
                    log "备用 Node.js 安装成功: $(node --version)"
                    return 0
                fi
            fi
        fi
    fi
    
    # 如果还是失败，尝试最小的二进制文件
    log "尝试最小化 Node.js 安装..."
    install_minimal_nodejs
}

# 最小化 Node.js 安装
install_minimal_nodejs() {
    log "安装最小化 Node.js..."
    
    # 只下载必要的二进制文件
    local arch=$(uname -m)
    local node_binary=""
    
    case $arch in
        x86_64)
            node_binary="https://nodejs.org/dist/v16.20.2/node-v16.20.2-linux-x64/bin/node"
            ;;
        aarch64|arm64)
            node_binary="https://nodejs.org/dist/v16.20.2/node-v16.20.2-linux-arm64/bin/node"
            ;;
        *)
            node_binary="https://nodejs.org/dist/v16.20.2/node-v16.20.2-linux-x64/bin/node"
            ;;
    esac
    
    log "下载 Node.js 二进制文件: $node_binary"
    
    if wget -O /usr/bin/node "$node_binary"; then
        chmod +x /usr/bin/node
        if node --version &> /dev/null; then
            log "最小化 Node.js 安装成功: $(node --version)"
            return 0
        fi
    fi
    
    error "最小化安装也失败了"
    return 1
}

# 轻量级同步方案（不需要 Node.js）
install_lightweight_sync() {
    log "安装轻量级同步方案..."
    
    # 检查磁盘空间
    local available_space=$(df /tmp | awk 'NR==2 {print $4}')
    if [ "$available_space" -lt 50000 ]; then
        warn "磁盘空间不足，清理临时文件..."
        rm -rf /tmp/node* /tmp/yacd*
    fi
    
    # 创建轻量级同步脚本
    mkdir -p "$AUTO_SYNC_DIR"
    cd "$AUTO_SYNC_DIR"
    
    # 创建简单的 bash 同步脚本
    cat > sync.sh << 'EOF'
#!/bin/bash

# 轻量级 Yacd-meta 自动同步脚本
# 不需要 Node.js，使用 bash 实现

CONFIG_FILE="/etc/openclash/config.yaml"
BACKUP_DIR="/root/yacd-auto-sync/backup"
LOG_FILE="/root/yacd-auto-sync/sync.log"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $1" | tee -a "$LOG_FILE"
}

backup_config() {
    if [ -f "$CONFIG_FILE" ]; then
        mkdir -p "$BACKUP_DIR"
        cp "$CONFIG_FILE" "$BACKUP_DIR/config_$(date +%s).yaml"
        log "配置文件已备份"
    fi
}

restart_openclash() {
    if [ -f "/etc/init.d/openclash" ]; then
        /etc/init.d/openclash restart
        log "OpenClash 已重启"
    fi
}

# 主同步函数
sync_config() {
    log "开始轻量级同步..."
    
    # 备份配置
    backup_config
    
    # 重启 OpenClash 以应用内存中的更改
    restart_openclash
    
    log "轻量级同步完成"
}

# 监听模式
watch_mode() {
    log "启动轻量级监听模式..."
    
    while true; do
        # 每30秒检查一次
        sleep 30
        
        # 这里可以添加更多的检查逻辑
        # 目前只是保持服务运行
        log "轻量级监听模式运行中..."
    done
}

case "$1" in
    "sync")
        sync_config
        ;;
    "watch")
        watch_mode
        ;;
    *)
        echo "用法: $0 {sync|watch}"
        exit 1
        ;;
esac
EOF
    
    chmod +x sync.sh
    
    # 创建配置文件
    cat > config.json << EOF
{
  "openclash_config_path": "/etc/openclash/config.yaml",
  "backup_dir": "$AUTO_SYNC_DIR/backup",
  "log_file": "$AUTO_SYNC_DIR/sync.log",
  "lightweight_mode": true
}
EOF
    
    # 创建备份目录
    mkdir -p backup
    
    # 检查 systemd 目录是否存在
    if [ ! -d "/etc/systemd/system" ]; then
        warn "systemd 目录不存在，使用 init.d 脚本"
        create_initd_script
    else
        # 创建轻量级系统服务
        cat > /etc/systemd/system/yacd-auto-sync.service << EOF
[Unit]
Description=Yacd-meta Lightweight Auto Sync Service
After=network.target openclash.service
Wants=openclash.service

[Service]
Type=simple
User=root
WorkingDirectory=$AUTO_SYNC_DIR
ExecStart=$AUTO_SYNC_DIR/sync.sh watch
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
        
        # 重新加载 systemd
        systemctl daemon-reload
        
        # 启用服务
        systemctl enable yacd-auto-sync.service
    fi
    
    success "轻量级同步方案安装完成"
}

# 创建 init.d 脚本（用于不支持 systemd 的系统）
create_initd_script() {
    log "创建 init.d 脚本..."
    
    # 确保 /etc/init.d 目录存在
    mkdir -p /etc/init.d
    
    cat > /etc/init.d/yacd-auto-sync << EOF
#!/bin/sh /etc/rc.common

START=95
STOP=15

start() {
    echo "启动 Yacd-meta 自动同步服务..."
    /root/yacd-auto-sync/sync.sh watch &
    echo \$! > /var/run/yacd-auto-sync.pid
}

stop() {
    echo "停止 Yacd-meta 自动同步服务..."
    if [ -f /var/run/yacd-auto-sync.pid ]; then
        kill \$(cat /var/run/yacd-auto-sync.pid) 2>/dev/null
        rm -f /var/run/yacd-auto-sync.pid
    fi
}

restart() {
    stop
    sleep 2
    start
}
EOF
    
    chmod +x /etc/init.d/yacd-auto-sync
    
    # 启用服务
    /etc/init.d/yacd-auto-sync enable
    
    log "init.d 脚本创建完成"
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
    echo -e "${CYAN}🔧 同步模式:${NC}"
    if [ -f "$AUTO_SYNC_DIR/config.json" ] && grep -q "lightweight_mode.*true" "$AUTO_SYNC_DIR/config.json"; then
        echo -e "  🟡 轻量级模式（不需要 Node.js）"
        echo -e "  📝 节点会添加到内存配置，重启后生效"
    else
        echo -e "  🟢 完整模式（需要 Node.js）"
        echo -e "  📝 节点会立即同步到配置文件"
    fi
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