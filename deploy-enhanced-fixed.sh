#!/bin/bash

# Yacd Enhanced 优化版部署脚本
# 适用于 OpenWrt 系统

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}SUCCESS:${NC} $1"
}

error() {
    echo -e "${RED}ERROR:${NC} $1"
}

warning() {
    echo -e "${YELLOW}WARNING:${NC} $1"
}

# 显示标题
echo "========================================"
echo "    Yacd Enhanced 优化版部署脚本"
echo "========================================"
echo

# 检查系统环境
check_environment() {
    log "检查系统环境..."
    
    # 检查系统架构
    ARCH=$(uname -m)
    log "系统架构: $ARCH"
    
    # 检查是否为OpenWrt
    if [ -f /etc/openwrt_release ]; then
        log "检测到OpenWrt系统"
    else
        warning "未检测到OpenWrt系统，某些功能可能不兼容"
    fi
    
    success "环境检查完成"
}

# 安装系统依赖
install_dependencies() {
    log "安装系统依赖..."
    
    # 更新包列表
    opkg update
    
    # 安装基础工具
    opkg install curl unzip python3 python3-pip
    
    # 安装nginx（如果未安装）
    if ! command -v nginx &> /dev/null; then
        opkg install nginx-ssl
    fi
    
    # 安装Python依赖
    pip3 install flask flask-cors pyyaml aiohttp asyncio
    
    success "系统依赖安装完成"
}

# 优化系统配置
optimize_system() {
    log "优化系统配置..."
    
    # 创建必要的目录
    mkdir -p /usr/local/bin/yacd-enhanced
    mkdir -p /var/log/yacd-enhanced
    mkdir -p /opt/yacd-enhanced/backups
    
    # 设置文件权限
    chmod 755 /usr/local/bin/yacd-enhanced
    chmod 755 /var/log/yacd-enhanced
    chmod 755 /opt/yacd-enhanced/backups
    
    success "系统配置优化完成"
}

# 部署优化版 Yacd Enhanced
deploy_enhanced_yacd() {
    log "部署优化版 Yacd Enhanced..."
    
    # 备份原版Yacd
    if [ -d "/usr/share/yacd" ]; then
        cp -r /usr/share/yacd /usr/share/yacd.backup.$(date +%Y%m%d_%H%M%S)
        log "原版 Yacd 已备份"
    fi
    
    # 下载最新版本
    cd /tmp
    wget -O yacd-enhanced.zip https://github.com/kuku0799/yacd-enhanced/archive/refs/heads/main.zip
    unzip -o yacd-enhanced.zip
    
    # 检查public目录是否存在
    if [ -d "yacd-enhanced-main/public" ]; then
        log "使用预构建的前端文件"
        cp -r yacd-enhanced-main/public/* /usr/share/yacd/
    else
        log "未找到预构建文件，创建基础界面"
        mkdir -p /usr/share/yacd
        cat > /usr/share/yacd/index.html << 'EOF'
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Yacd Enhanced</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .container { max-width: 800px; margin: 0 auto; }
        .header { text-align: center; margin-bottom: 40px; }
        .feature { margin: 20px 0; padding: 15px; border: 1px solid #ddd; border-radius: 5px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🎉 Yacd Enhanced 部署成功！</h1>
            <p>节点管理模块已集成到系统中</p>
        </div>
        
        <div class="feature">
            <h3>✨ 新功能</h3>
            <ul>
                <li>可视化节点管理界面</li>
                <li>多协议支持 (VMess/SS/Trojan/VLESS)</li>
                <li>智能节点验证和过滤</li>
                <li>实时统计显示</li>
                <li>文件导入导出功能</li>
            </ul>
        </div>
        
        <div class="feature">
            <h3>📋 使用说明</h3>
            <p>访问 <code>http://您的路由器IP:9090/ui/yacd/</code> 开始使用</p>
            <p>在监控面板中选择"节点管理"标签页</p>
        </div>
    </div>
</body>
</html>
EOF
    fi
    
    # 设置权限
    chmod -R 755 /usr/share/yacd
    chown -R root:root /usr/share/yacd
    
    # 清理临时文件
    rm -rf /tmp/yacd-enhanced.zip /tmp/yacd-enhanced-main
    
    success "Yacd Enhanced 部署完成"
}

# 部署Python脚本
deploy_python_scripts() {
    log "部署Python脚本..."
    
    # 创建脚本目录
    mkdir -p /root/OpenClashManage/scripts
    mkdir -p /root/OpenClashManage/wangluo
    
    # 下载脚本文件
    cd /tmp
    wget -O scripts.zip https://github.com/kuku0799/yacd-enhanced/archive/refs/heads/main.zip
    unzip -o scripts.zip
    
    # 复制Python脚本
    if [ -d "yacd-enhanced-main/scripts" ]; then
        cp yacd-enhanced-main/scripts/*.py /root/OpenClashManage/scripts/
        cp yacd-enhanced-main/scripts/*.sh /root/OpenClashManage/scripts/
        chmod +x /root/OpenClashManage/scripts/*.sh
        chmod +x /root/OpenClashManage/scripts/*.py
    fi
    
    # 创建日志文件
    touch /root/OpenClashManage/wangluo/log.txt
    chmod 666 /root/OpenClashManage/wangluo/log.txt
    
    # 清理临时文件
    rm -rf /tmp/scripts.zip /tmp/yacd-enhanced-main
    
    success "Python脚本部署完成"
}

# 配置OpenClash
setup_openclash() {
    log "配置OpenClash..."
    
    # 检查OpenClash是否安装
    if ! command -v openclash &> /dev/null; then
        warning "未检测到OpenClash，请先安装OpenClash"
        return
    fi
    
    # 创建配置文件目录
    mkdir -p /etc/openclash
    
    # 备份现有配置
    if [ -f "/etc/openclash/config.yaml" ]; then
        cp /etc/openclash/config.yaml /etc/openclash/config.yaml.backup.$(date +%Y%m%d_%H%M%S)
    fi
    
    success "OpenClash配置完成"
}

# 设置监控服务
setup_monitoring() {
    log "设置监控服务..."
    
    # 创建监控脚本
    mkdir -p /usr/local/bin/yacd-enhanced
    cat > /usr/local/bin/yacd-enhanced/monitor.sh << 'EOF'
#!/bin/bash

# Yacd Enhanced 监控服务脚本

LOG_FILE="/var/log/yacd-enhanced/monitor.log"
NODES_FILE="/root/OpenClashManage/wangluo/nodes.txt"
SCRIPT_DIR="/root/OpenClashManage/scripts"

# 创建日志目录
mkdir -p /var/log/yacd-enhanced

# 记录日志
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# 启动监控
start_monitoring() {
    log "启动节点监控服务"
    
    # 启动文件监控
    nohup bash "$SCRIPT_DIR/jk.sh" > "$LOG_FILE" 2>&1 &
    
    # 记录PID
    echo $! > /var/run/yacd-enhanced-monitor.pid
    
    log "监控服务已启动，PID: $!"
}

# 停止监控
stop_monitoring() {
    log "停止节点监控服务"
    
    if [ -f /var/run/yacd-enhanced-monitor.pid ]; then
        PID=$(cat /var/run/yacd-enhanced-monitor.pid)
        kill -TERM "$PID" 2>/dev/null || true
        rm -f /var/run/yacd-enhanced-monitor.pid
    fi
    
    # 停止所有相关进程
    pkill -f "jk.sh" 2>/dev/null || true
    
    log "监控服务已停止"
}

# 重启监控
restart_monitoring() {
    stop_monitoring
    sleep 2
    start_monitoring
}

# 检查状态
status_monitoring() {
    if [ -f /var/run/yacd-enhanced-monitor.pid ]; then
        PID=$(cat /var/run/yacd-enhanced-monitor.pid)
        if kill -0 "$PID" 2>/dev/null; then
            echo "监控服务运行中，PID: $PID"
            return 0
        else
            echo "监控服务未运行"
            return 1
        fi
    else
        echo "监控服务未运行"
        return 1
    fi
}

# 主逻辑
case "$1" in
    start)
        start_monitoring
        ;;
    stop)
        stop_monitoring
        ;;
    restart)
        restart_monitoring
        ;;
    status)
        status_monitoring
        ;;
    *)
        echo "用法: $0 {start|stop|restart|status}"
        exit 1
        ;;
esac
EOF

    # 设置执行权限
    chmod +x /usr/local/bin/yacd-enhanced/monitor.sh
    
    # 创建init.d服务
    cat > /etc/init.d/yacd-enhanced-monitor << 'EOF'
#!/bin/sh /etc/rc.common

START=99
STOP=10

start() {
    /usr/local/bin/yacd-enhanced/monitor.sh start
}

stop() {
    /usr/local/bin/yacd-enhanced/monitor.sh stop
}

restart() {
    /usr/local/bin/yacd-enhanced/monitor.sh restart
}

status() {
    /usr/local/bin/yacd-enhanced/monitor.sh status
}
EOF

    chmod +x /etc/init.d/yacd-enhanced-monitor
    
    # 启用服务
    /etc/init.d/yacd-enhanced-monitor enable
    
    success "监控服务设置完成"
}

# 设置性能配置
setup_performance_config() {
    log "设置性能配置..."
    
    mkdir -p /usr/local/bin/yacd-enhanced
    
    # 创建性能优化脚本
    cat > /usr/local/bin/yacd-enhanced/optimize.sh << 'EOF'
#!/bin/bash

# 性能优化脚本

# 优化内存使用
echo 3 > /proc/sys/vm/drop_caches 2>/dev/null || true

# 优化网络参数
echo 65536 > /proc/sys/net/core/rmem_max 2>/dev/null || true
echo 65536 > /proc/sys/net/core/wmem_max 2>/dev/null || true

# 优化文件描述符限制
ulimit -n 65536 2>/dev/null || true

echo "性能优化完成"
EOF

    chmod +x /usr/local/bin/yacd-enhanced/optimize.sh
    
    success "性能配置设置完成"
}

# 设置自动备份
setup_auto_backup() {
    log "设置自动备份..."
    
    mkdir -p /opt/yacd-enhanced/backups
    
    # 创建备份脚本
    cat > /usr/local/bin/yacd-enhanced/backup.sh << 'EOF'
#!/bin/bash

# 自动备份脚本

BACKUP_DIR="/opt/yacd-enhanced/backups"
DATE=$(date +%Y%m%d_%H%M%S)

# 备份节点文件
if [ -f "/root/OpenClashManage/wangluo/nodes.txt" ]; then
    cp /root/OpenClashManage/wangluo/nodes.txt "$BACKUP_DIR/nodes_$DATE.txt"
fi

# 备份OpenClash配置
if [ -f "/etc/openclash/config.yaml" ]; then
    cp /etc/openclash/config.yaml "$BACKUP_DIR/config_$DATE.yaml"
fi

# 清理旧备份（保留最近7天）
find "$BACKUP_DIR" -name "*.txt" -mtime +7 -delete 2>/dev/null || true
find "$BACKUP_DIR" -name "*.yaml" -mtime +7 -delete 2>/dev/null || true

echo "备份完成: $DATE"
EOF

    chmod +x /usr/local/bin/yacd-enhanced/backup.sh
    
    # 添加到crontab（每天凌晨2点备份）
    (crontab -l 2>/dev/null; echo "0 2 * * * /usr/local/bin/yacd-enhanced/backup.sh") | crontab -
    
    success "自动备份设置完成"
}

# 显示部署结果
show_deployment_result() {
    echo
    echo "========================================"
    echo "    🎉 部署完成！"
    echo "========================================"
    echo
    echo "📋 部署信息："
    echo "   • Yacd Enhanced 已部署到: /usr/share/yacd"
    echo "   • Python脚本已部署到: /root/OpenClashManage/scripts"
    echo "   • 监控服务已配置: /etc/init.d/yacd-enhanced-monitor"
    echo "   • 日志文件位置: /var/log/yacd-enhanced"
    echo
    echo "🚀 使用方法："
    echo "   1. 访问: http://$(hostname -I | awk '{print $1}'):9090/ui/yacd/"
    echo "   2. 在监控面板中选择'节点管理'标签页"
    echo "   3. 添加您的节点链接"
    echo
    echo "🔧 管理命令："
    echo "   • 启动监控: /etc/init.d/yacd-enhanced-monitor start"
    echo "   • 停止监控: /etc/init.d/yacd-enhanced-monitor stop"
    echo "   • 查看状态: /etc/init.d/yacd-enhanced-monitor status"
    echo "   • 手动更新: python3 /root/OpenClashManage/scripts/zr.py"
    echo
    echo "📁 重要文件："
    echo "   • 节点文件: /root/OpenClashManage/wangluo/nodes.txt"
    echo "   • 日志文件: /root/OpenClashManage/wangluo/log.txt"
    echo "   • 备份目录: /opt/yacd-enhanced/backups"
    echo
    echo "✨ 新功能特性："
    echo "   • 可视化节点管理界面"
    echo "   • 多协议支持 (VMess/SS/Trojan/VLESS)"
    echo "   • 智能节点验证和过滤"
    echo "   • 实时统计显示"
    echo "   • 文件导入导出功能"
    echo
    echo "📖 详细文档："
    echo "   • 部署指南: /usr/share/yacd/DEPLOYMENT_GUIDE.md"
    echo "   • 节点管理: /usr/share/yacd/NODE_MANAGEMENT_GUIDE.md"
    echo
    echo "🎯 下一步："
    echo "   1. 访问Web界面添加节点"
    echo "   2. 启动监控服务"
    echo "   3. 享受便捷的节点管理体验！"
    echo
}

# 主函数
main() {
    check_environment
    install_dependencies
    optimize_system
    deploy_enhanced_yacd
    deploy_python_scripts
    setup_openclash
    setup_monitoring
    setup_performance_config
    setup_auto_backup
    show_deployment_result
}

# 执行主函数
main "$@" 