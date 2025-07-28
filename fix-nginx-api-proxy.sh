#!/bin/bash

# 修复nginx API代理配置脚本

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
echo "    nginx API代理配置修复脚本"
echo "========================================"
echo

# 检查nginx配置
check_nginx_config() {
    log "检查nginx配置..."
    
    # 检查nginx是否运行
    if ! pgrep nginx > /dev/null; then
        error "nginx未运行"
        return 1
    fi
    
    # 检查配置文件
    if [ -f "/etc/nginx/conf.d/yacd.conf" ]; then
        success "找到yacd配置文件"
    else
        warning "未找到yacd配置文件，将创建新的配置"
        create_yacd_config
    fi
    
    # 测试nginx配置
    if nginx -t; then
        success "nginx配置测试通过"
    else
        error "nginx配置测试失败"
        return 1
    fi
}

# 创建yacd配置
create_yacd_config() {
    log "创建yacd配置文件..."
    
    # 创建conf.d目录
    mkdir -p /etc/nginx/conf.d
    
    # 创建配置文件
    cat > /etc/nginx/conf.d/yacd.conf << 'EOF'
server {
    listen 9090;
    server_name localhost;
    
    # 允许跨域请求
    add_header Access-Control-Allow-Origin *;
    add_header Access-Control-Allow-Methods "GET, POST, OPTIONS, DELETE";
    add_header Access-Control-Allow-Headers "DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization";
    
    # Yacd Enhanced 界面
    location /ui/yacd/ {
        alias /usr/share/yacd/;
        index index.html;
        try_files $uri $uri/ /ui/yacd/index.html;
        
        # 静态文件缓存
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
            add_header Access-Control-Allow-Origin *;
        }
    }
    
    # API代理到本地服务器
    location /api/ {
        proxy_pass http://127.0.0.1:5000/api/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
    }
    
    # 健康检查
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
    
    # 默认页面重定向
    location = / {
        return 301 /ui/yacd/;
    }
}
EOF

    success "yacd配置文件创建完成"
}

# 更新现有配置
update_existing_config() {
    log "更新现有nginx配置..."
    
    if [ -f "/etc/nginx/conf.d/yacd.conf" ]; then
        # 备份原配置
        cp /etc/nginx/conf.d/yacd.conf /etc/nginx/conf.d/yacd.conf.backup
        
        # 检查是否已有API代理配置
        if grep -q "location /api/" /etc/nginx/conf.d/yacd.conf; then
            log "API代理配置已存在，跳过更新"
        else
            # 在server块中添加API代理配置
            sed -i '/location \/health/a\
    # API代理到本地服务器\
    location /api/ {\
        proxy_pass http://127.0.0.1:5000/api/;\
        proxy_set_header Host $host;\
        proxy_set_header X-Real-IP $remote_addr;\
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;\
        proxy_set_header X-Forwarded-Proto $scheme;\
        proxy_connect_timeout 30s;\
        proxy_send_timeout 30s;\
        proxy_read_timeout 30s;\
    }' /etc/nginx/conf.d/yacd.conf
            
            success "API代理配置已添加"
        fi
    else
        create_yacd_config
    fi
}

# 测试API连接
test_api_connection() {
    log "测试API连接..."
    
    # 等待API服务器启动
    sleep 3
    
    # 测试API健康检查
    if curl -s http://localhost:5000/api/health > /dev/null; then
        success "API服务器连接正常"
    else
        warning "API服务器连接失败，请检查API服务器状态"
        return 1
    fi
    
    # 测试nginx代理
    if curl -s http://localhost:9090/api/health > /dev/null; then
        success "nginx API代理工作正常"
    else
        warning "nginx API代理可能有问题"
        return 1
    fi
}

# 重启nginx
restart_nginx() {
    log "重启nginx服务..."
    
    /etc/init.d/nginx restart
    
    # 检查nginx是否运行
    sleep 2
    if pgrep nginx > /dev/null; then
        success "nginx服务重启成功"
    else
        error "nginx服务重启失败"
        return 1
    fi
}

# 显示结果
show_result() {
    echo
    echo "========================================"
    echo "    🎉 nginx API代理配置完成！"
    echo "========================================"
    echo
    echo "📋 配置信息："
    echo "   • nginx配置文件: /etc/nginx/conf.d/yacd.conf"
    echo "   • API服务器: http://localhost:5000"
    echo "   • 代理地址: http://localhost:9090/api/"
    echo
    echo "🌐 访问地址："
    echo "   • 主界面: http://$(hostname -I | awk '{print $1}'):9090/ui/yacd/"
    echo "   • API健康检查: http://$(hostname -I | awk '{print $1}'):9090/api/health"
    echo
    echo "🔧 管理命令："
    echo "   • 重启nginx: /etc/init.d/nginx restart"
    echo "   • 查看nginx状态: /etc/init.d/nginx status"
    echo "   • 测试nginx配置: nginx -t"
    echo "   • 查看API状态: /etc/init.d/yacd-api status"
    echo
    echo "✨ 功能特性："
    echo "   • API请求自动代理到本地服务器"
    echo "   • 支持CORS跨域请求"
    echo "   • 静态文件缓存优化"
    echo "   • 健康检查端点"
    echo
    echo "🎯 测试步骤："
    echo "   1. 访问Web界面"
    echo "   2. 点击节点管理按钮"
    echo "   3. 测试节点添加功能"
    echo
}

# 主函数
main() {
    check_nginx_config
    update_existing_config
    restart_nginx
    test_api_connection
    show_result
}

# 执行主函数
main "$@" 