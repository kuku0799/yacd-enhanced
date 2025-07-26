#!/bin/bash

# Yacd Enhanced 自适应部署脚本
# 适配不同 OpenWrt 环境，不依赖 Python3 和 nginx-ssl

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

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

success() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] SUCCESS:${NC} $1"
}

# 检查环境
check_environment() {
    log "检查系统环境..."
    
    # 检查是否为 root 用户
    if [ "$EUID" -ne 0 ]; then
        error "请使用 root 用户运行此脚本"
        exit 1
    fi
    
    # 检查网络连接
    if ! ping -c 1 github.com > /dev/null 2>&1; then
        error "无法连接到 GitHub，请检查网络连接"
        exit 1
    fi
    
    # 检查磁盘空间
    local available_space=$(df /tmp | awk 'NR==2 {print $4}')
    if [ "$available_space" -lt 50000 ]; then
        warn "磁盘空间不足，建议清理后重试"
    fi
    
    # 检查系统架构
    local arch=$(uname -m)
    log "系统架构: $arch"
    
    success "环境检查完成"
}

# 安装基础依赖
install_basic_deps() {
    log "安装基础依赖..."
    
    # 更新包列表
    opkg update
    
    # 安装基础工具（这些通常都可用）
    opkg install wget curl unzip
    
    # 尝试安装 Python（如果可用）
    if opkg list-installed | grep -q python; then
        log "检测到已安装的 Python"
    elif opkg list-available | grep -q "^python3"; then
        opkg install python3
        if opkg list-available | grep -q "^python3-pip"; then
            opkg install python3-pip
        fi
    elif opkg list-available | grep -q "^python"; then
        opkg install python
        if opkg list-available | grep -q "^python-pip"; then
            opkg install python-pip
        fi
    else
        warn "未找到 Python 包，将使用轻量级部署方案"
    fi
    
    # 尝试安装 nginx（如果可用）
    if opkg list-available | grep -q "^nginx"; then
        opkg install nginx
    else
        warn "未找到 nginx 包，将跳过反向代理配置"
    fi
    
    success "基础依赖安装完成"
}

# 清理旧版本
cleanup_old_versions() {
    log "清理旧版本..."
    
    # 停止旧服务
    systemctl stop provider-api 2>/dev/null || true
    systemctl disable provider-api 2>/dev/null || true
    systemctl stop yacd-auto-sync 2>/dev/null || true
    systemctl disable yacd-auto-sync 2>/dev/null || true
    systemctl stop yacd-enhanced-provider 2>/dev/null || true
    systemctl disable yacd-enhanced-provider 2>/dev/null || true
    systemctl stop yacd-enhanced-monitor 2>/dev/null || true
    systemctl disable yacd-enhanced-monitor 2>/dev/null || true
    
    # 删除旧的服务文件
    rm -f /etc/systemd/system/provider-api.service
    rm -f /etc/systemd/system/yacd-auto-sync.service
    rm -f /etc/systemd/system/yacd-enhanced-provider.service
    rm -f /etc/systemd/system/yacd-enhanced-monitor.service
    
    # 删除旧的脚本和配置
    rm -rf /usr/local/bin/yacd-enhanced/
    rm -rf /usr/local/bin/provider_api.py
    rm -rf /usr/local/bin/provider_api_optimized.py
    rm -rf /usr/local/bin/auto-sync.js
    rm -rf /usr/local/bin/monitor.sh
    rm -rf /usr/local/bin/backup.sh
    rm -rf /etc/openclash/proxy_provider/custom_provider.yaml
    rm -rf /opt/yacd-enhanced/backups/
    rm -rf /var/log/yacd-enhanced/
    
    # 清理临时文件
    rm -rf /tmp/yacd*
    rm -rf /tmp/yacd-enhanced*
    rm -rf /tmp/yacd-files*
    rm -rf /tmp/yacd-enhanced-main*
    rm -rf /tmp/main.zip
    rm -rf /tmp/dist.zip
    
    # 重新加载服务（兼容 systemd 和 init.d）
    if command -v systemctl >/dev/null 2>&1; then
        systemctl daemon-reload
    elif command -v /etc/init.d/openclash >/dev/null 2>&1; then
        /etc/init.d/openclash reload
    fi
    
    success "旧版本清理完成"
}

# 部署 Yacd Enhanced
deploy_yacd_enhanced() {
    log "部署 Yacd Enhanced..."
    
    # 备份原版
    if [ -d "/usr/share/openclash/ui/yacd" ]; then
        cp -r /usr/share/openclash/ui/yacd /usr/share/openclash/ui/yacd_backup_$(date +%Y%m%d_%H%M%S)
        log "原版 Yacd 已备份"
    fi
    
    # 下载最新版本
    local temp_dir="/tmp/yacd-enhanced"
    rm -rf "$temp_dir"
    mkdir -p "$temp_dir"
    cd "$temp_dir"
    
    wget -O yacd-enhanced.zip "https://github.com/kuku0799/yacd-enhanced/archive/refs/heads/main.zip"
    unzip -o yacd-enhanced.zip
    
    # 检查是否有构建好的文件
    if [ -d "yacd-enhanced-main/public" ]; then
        log "使用预构建文件"
        cp -r yacd-enhanced-main/public/* /usr/share/openclash/ui/yacd/
    else
        log "未找到预构建文件，将使用静态文件"
        # 创建基本的静态文件
        mkdir -p /usr/share/openclash/ui/yacd/
        echo "<!DOCTYPE html><html><head><title>Yacd Enhanced</title></head><body><h1>Yacd Enhanced 部署中...</h1></body></html>" > /usr/share/openclash/ui/yacd/index.html
    fi
    
    # 设置权限
    chown -R root:root /usr/share/openclash/ui/yacd
    chmod -R 755 /usr/share/openclash/ui/yacd
    
    # 清理临时文件
    cd /
    rm -rf "$temp_dir"
    
    success "Yacd Enhanced 部署完成"
}

# 创建轻量级监控脚本
setup_lightweight_monitoring() {
    log "设置轻量级监控..."
    
    # 创建监控目录
    mkdir -p /usr/local/bin/yacd-enhanced
    mkdir -p /var/log/yacd-enhanced
    
    # 创建简单的监控脚本
    cat > /usr/local/bin/yacd-enhanced/monitor.sh << 'EOF'
#!/bin/bash

# 轻量级监控脚本

LOG_FILE="/var/log/yacd-enhanced/monitor.log"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# 检查 OpenClash 服务
check_openclash() {
    local service_running=false
    
    # 检查 systemd 服务
    if command -v systemctl >/dev/null 2>&1; then
        if systemctl is-active --quiet openclash; then
            service_running=true
        fi
    # 检查 init.d 服务
    elif [ -f "/etc/init.d/openclash" ]; then
        if /etc/init.d/openclash status >/dev/null 2>&1; then
            service_running=true
        fi
    fi
    
    if [ "$service_running" = false ]; then
        log "ERROR: OpenClash 服务未运行"
        if command -v systemctl >/dev/null 2>&1; then
            systemctl restart openclash
        elif [ -f "/etc/init.d/openclash" ]; then
            /etc/init.d/openclash restart
        fi
    fi
}

# 检查内存使用
check_memory() {
    local mem_usage=$(free | awk 'NR==2{printf "%.0f", $3*100/$2}')
    if [ "$mem_usage" -gt 80 ]; then
        log "WARNING: 内存使用率过高: ${mem_usage}%"
    fi
}

# 检查磁盘空间
check_disk() {
    local disk_usage=$(df / | awk 'NR==2{printf "%.0f", $5}')
    if [ "$disk_usage" -gt 80 ]; then
        log "WARNING: 磁盘使用率过高: ${disk_usage}%"
    fi
}

# 主监控循环
while true; do
    check_openclash
    check_memory
    check_disk
    sleep 60
done
EOF

    chmod +x /usr/local/bin/yacd-enhanced/monitor.sh
    
    # 创建监控服务（兼容 systemd 和 init.d）
    if [ -d "/etc/systemd/system" ]; then
        cat > /etc/systemd/system/yacd-enhanced-monitor.service << EOF
[Unit]
Description=Yacd Enhanced Monitor Service
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/yacd-enhanced/monitor.sh
Restart=always
RestartSec=10
StandardOutput=append:/var/log/yacd-enhanced/monitor.log
StandardError=append:/var/log/yacd-enhanced/monitor.log

[Install]
WantedBy=multi-user.target
EOF
        systemctl daemon-reload
        systemctl enable yacd-enhanced-monitor
        systemctl start yacd-enhanced-monitor
    else
        # 创建 init.d 脚本
        cat > /etc/init.d/yacd-enhanced-monitor << 'EOF'
#!/bin/sh /etc/rc.common

START=99
STOP=10

start() {
    /usr/local/bin/yacd-enhanced/monitor.sh &
    echo $! > /var/run/yacd-enhanced-monitor.pid
}

stop() {
    if [ -f /var/run/yacd-enhanced-monitor.pid ]; then
        kill $(cat /var/run/yacd-enhanced-monitor.pid)
        rm -f /var/run/yacd-enhanced-monitor.pid
    fi
}

restart() {
    stop
    start
}
EOF
        chmod +x /etc/init.d/yacd-enhanced-monitor
        /etc/init.d/yacd-enhanced-monitor enable
        /etc/init.d/yacd-enhanced-monitor start
    fi
    
    success "轻量级监控设置完成"
}

# 创建简单的备份脚本
setup_backup() {
    log "设置备份脚本..."
    
    cat > /usr/local/bin/yacd-enhanced/backup.sh << 'EOF'
#!/bin/bash

# 简单备份脚本

BACKUP_DIR="/opt/yacd-enhanced/backups"
DATE=$(date +%Y%m%d_%H%M%S)

# 创建备份目录
mkdir -p "$BACKUP_DIR"

# 备份 Yacd 文件
if [ -d "/usr/share/openclash/ui/yacd" ]; then
    tar -czf "$BACKUP_DIR/yacd_backup_$DATE.tar.gz" -C /usr/share/openclash/ui yacd
    echo "Yacd 备份完成: yacd_backup_$DATE.tar.gz"
fi

# 备份 OpenClash 配置
if [ -f "/etc/openclash/config.yaml" ]; then
    cp "/etc/openclash/config.yaml" "$BACKUP_DIR/config_backup_$DATE.yaml"
    echo "配置备份完成: config_backup_$DATE.yaml"
fi

# 清理旧备份（保留最近3天）
find "$BACKUP_DIR" -name "*.tar.gz" -mtime +3 -delete
find "$BACKUP_DIR" -name "*.yaml" -mtime +3 -delete

echo "备份完成，时间: $DATE"
EOF

    chmod +x /usr/local/bin/yacd-enhanced/backup.sh
    
    # 添加到 crontab（每天凌晨2点备份）
    (crontab -l 2>/dev/null; echo "0 2 * * * /usr/local/bin/yacd-enhanced/backup.sh") | crontab -
    
    success "备份脚本设置完成"
}

# 显示部署结果
show_deployment_result() {
    echo ""
    echo -e "${PURPLE}========================================${NC}"
    echo -e "${PURPLE}    Yacd Enhanced 自适应部署完成！🎉${NC}"
    echo -e "${PURPLE}========================================${NC}"
    echo ""
    echo -e "${CYAN}📁 文件位置:${NC}"
    echo -e "  Yacd Enhanced: /usr/share/openclash/ui/yacd/"
    echo -e "  监控脚本: /usr/local/bin/yacd-enhanced/"
    echo -e "  日志文件: /var/log/yacd-enhanced/"
    echo -e "  备份文件: /opt/yacd-enhanced/backups/"
    echo ""
    echo -e "${CYAN}🌐 访问地址:${NC}"
    echo -e "  Yacd Enhanced: http://你的路由器IP:9090/ui/yacd/"
    echo ""
    echo -e "${CYAN}🔧 管理命令:${NC}"
    echo -e "  查看服务状态: systemctl status yacd-enhanced-monitor"
    echo -e "  重启服务: systemctl restart openclash"
    echo -e "  查看日志: tail -f /var/log/yacd-enhanced/monitor.log"
    echo -e "  手动备份: /usr/local/bin/yacd-enhanced/backup.sh"
    echo ""
    echo -e "${CYAN}✨ 部署特性:${NC}"
    echo -e "  ✅ 自适应环境：自动检测可用包"
    echo -e "  ✅ 轻量级部署：最小化依赖"
    echo -e "  ✅ 自动监控：内存、磁盘、服务监控"
    echo -e "  ✅ 自动备份：每日自动备份配置"
    echo -e "  ✅ 一键部署：完全自动化部署流程"
    echo ""
    echo -e "${GREEN}现在你可以享受优化版的 Yacd Enhanced！${NC}"
    echo ""
}

# 主函数
main() {
    echo -e "${PURPLE}========================================${NC}"
    echo -e "${PURPLE}    Yacd Enhanced 自适应部署脚本${NC}"
    echo -e "${PURPLE}========================================${NC}"
    echo ""
    
    # 检查环境
    check_environment
    
    # 安装基础依赖
    install_basic_deps
    
    # 清理旧版本
    cleanup_old_versions
    
    # 部署 Yacd Enhanced
    deploy_yacd_enhanced
    
    # 设置轻量级监控
    setup_lightweight_monitoring
    
    # 设置备份
    setup_backup
    
    # 显示结果
    show_deployment_result
}

# 运行主函数
main "$@" 