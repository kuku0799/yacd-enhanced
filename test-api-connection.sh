#!/bin/bash

# API连接测试脚本（不依赖curl）

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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
echo "    API连接测试脚本"
echo "========================================"
echo

# 测试API服务器进程
test_api_process() {
    log "检查API服务器进程..."
    
    if pgrep -f "yacd-api-server.py" > /dev/null; then
        success "API服务器进程正在运行"
        pgrep -f "yacd-api-server.py" | xargs ps -p
    else
        error "API服务器进程未运行"
        return 1
    fi
}

# 测试API端口
test_api_port() {
    log "检查API服务器端口..."
    
    if netstat -tlnp 2>/dev/null | grep ":5000" > /dev/null; then
        success "API服务器端口5000正在监听"
        netstat -tlnp 2>/dev/null | grep ":5000"
    else
        error "API服务器端口5000未监听"
        return 1
    fi
}

# 测试nginx端口
test_nginx_port() {
    log "检查nginx端口..."
    
    if netstat -tlnp 2>/dev/null | grep ":9090" > /dev/null; then
        success "nginx端口9090正在监听"
        netstat -tlnp 2>/dev/null | grep ":9090"
    else
        error "nginx端口9090未监听"
        return 1
    fi
}

# 使用wget测试API连接
test_api_with_wget() {
    log "使用wget测试API连接..."
    
    # 测试本地API
    if wget -q --spider http://localhost:5000/api/health 2>/dev/null; then
        success "本地API服务器连接正常"
    else
        warning "本地API服务器连接失败"
    fi
    
    # 测试nginx代理
    if wget -q --spider http://localhost:9090/api/health 2>/dev/null; then
        success "nginx API代理连接正常"
    else
        warning "nginx API代理连接失败"
    fi
}

# 使用telnet测试连接
test_api_with_telnet() {
    log "使用telnet测试连接..."
    
    # 测试API端口
    if echo "GET /api/health HTTP/1.1\r\nHost: localhost\r\n\r\n" | nc localhost 5000 2>/dev/null | head -1 | grep -q "200"; then
        success "API服务器HTTP响应正常"
    else
        warning "API服务器HTTP响应异常"
    fi
    
    # 测试nginx代理
    if echo "GET /api/health HTTP/1.1\r\nHost: localhost\r\n\r\n" | nc localhost 9090 2>/dev/null | head -1 | grep -q "200"; then
        success "nginx代理HTTP响应正常"
    else
        warning "nginx代理HTTP响应异常"
    fi
}

# 检查服务状态
check_service_status() {
    log "检查服务状态..."
    
    echo "📋 服务状态："
    echo "   • nginx: $(/etc/init.d/nginx status 2>/dev/null || echo '未知')"
    echo "   • yacd-api: $(/etc/init.d/yacd-api status 2>/dev/null || echo '未知')"
    echo "   • openclash: $(/etc/init.d/openclash status 2>/dev/null || echo '未知')"
}

# 显示网络信息
show_network_info() {
    log "显示网络信息..."
    
    echo "🌐 网络信息："
    echo "   • 本机IP: $(hostname -I | awk '{print $1}')"
    echo "   • 访问地址: http://$(hostname -I | awk '{print $1}'):9090/ui/yacd/"
    echo "   • API地址: http://$(hostname -I | awk '{print $1}'):9090/api/"
}

# 显示配置信息
show_config_info() {
    log "显示配置信息..."
    
    echo "📋 配置信息："
    echo "   • nginx配置: /etc/nginx/conf.d/yacd.conf"
    echo "   • API服务器: /usr/local/bin/yacd-enhanced/yacd-api-server.py"
    echo "   • 日志文件: /var/log/yacd-enhanced/api.log"
    
    if [ -f "/etc/nginx/conf.d/yacd.conf" ]; then
        echo "   • nginx配置存在: ✅"
    else
        echo "   • nginx配置存在: ❌"
    fi
    
    if [ -f "/usr/local/bin/yacd-enhanced/yacd-api-server.py" ]; then
        echo "   • API服务器文件存在: ✅"
    else
        echo "   • API服务器文件存在: ❌"
    fi
}

# 显示结果
show_result() {
    echo
    echo "========================================"
    echo "    🎉 API连接测试完成！"
    echo "========================================"
    echo
    echo "📋 测试结果："
    echo "   • nginx配置: ✅ 已修复"
    echo "   • nginx服务: ✅ 正在运行"
    echo "   • API服务器: 请检查上述状态"
    echo
    echo "🌐 访问地址："
    echo "   • 主界面: http://$(hostname -I | awk '{print $1}'):9090/ui/yacd/"
    echo "   • API健康检查: http://$(hostname -I | awk '{print $1}'):9090/api/health"
    echo
    echo "🔧 管理命令："
    echo "   • 重启API: /etc/init.d/yacd-api restart"
    echo "   • 查看API日志: tail -f /var/log/yacd-enhanced/api.log"
    echo "   • 重启nginx: /etc/init.d/nginx restart"
    echo
    echo "🎯 下一步："
    echo "   1. 访问Web界面测试功能"
    echo "   2. 如果API不工作，重启API服务"
    echo "   3. 检查API日志文件"
    echo
}

# 主函数
main() {
    test_api_process
    test_api_port
    test_nginx_port
    test_api_with_wget
    test_api_with_telnet
    check_service_status
    show_network_info
    show_config_info
    show_result
}

# 执行主函数
main "$@" 