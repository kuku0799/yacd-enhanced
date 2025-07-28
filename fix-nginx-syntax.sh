#!/bin/bash

# 修复nginx语法错误脚本

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
echo "    nginx语法错误修复脚本"
echo "========================================"
echo

# 备份原配置
backup_config() {
    log "备份原配置..."
    
    if [ -f "/etc/nginx/conf.d/yacd.conf" ]; then
        cp /etc/nginx/conf.d/yacd.conf /etc/nginx/conf.d/yacd.conf.backup.$(date +%Y%m%d_%H%M%S)
        success "配置已备份"
    fi
}

# 修复nginx配置
fix_nginx_config() {
    log "修复nginx配置..."
    
    # 创建正确的配置文件
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

    success "nginx配置已修复"
}

# 修复mime.types
fix_mime_types() {
    log "修复mime.types文件..."
    
    # 备份原文件
    cp /etc/nginx/mime.types /etc/nginx/mime.types.backup
    
    # 创建新的mime.types文件
    cat > /etc/nginx/mime.types << 'EOF'
types {
    text/html                             html htm shtml;
    text/css                              css;
    text/xml                              xml;
    image/gif                             gif;
    image/jpeg                            jpeg jpg;
    application/javascript                js;
    application/atom+xml                  atom;
    application/rss+xml                   rss;
    text/mathml                           mml;
    text/plain                            txt;
    text/vnd.sun.j2me.app-descriptor     jad;
    text/vnd.wap.wml                      wml;
    text/x-component                      htc;
    image/png                             png;
    image/tiff                            tif tiff;
    image/vnd.wap.wbmp                    wbmp;
    image/x-icon                          ico;
    image/x-jng                           jng;
    image/x-ms-bmp                        bmp;
    image/svg+xml                         svg svgz;
    image/webp                            webp;
    application/font-woff                 woff;
    application/font-woff2                woff2;
    application/java-archive              jar war ear;
    application/json                      json;
    application/mac-binhex40              hqx;
    application/msword                    doc;
    application/pdf                       pdf;
    application/postscript                ps eps ai;
    application/rtf                       rtf;
    application/vnd.apple.mpegurl        m3u8;
    application/vnd.ms-excel             xls;
    application/vnd.ms-fontobject        eot;
    application/vnd.ms-powerpoint        ppt;
    application/vnd.wap.wmlc             wmlc;
    application/vnd.wap.xhtml+xml        xhtml;
    application/x-7z-compressed          7z;
    application/x-cocoa                   cco;
    application/x-java-archive-diff      jardiff;
    application/x-java-jnlp-file         jnlp;
    application/x-makeself                run;
    application/x-perl                    pl pm;
    application/x-pilot                   prc pdb;
    application/x-rar-compressed          rar;
    application/x-redhat-package-manager rpm;
    application/x-sea                     sea;
    application/x-shockwave-flash        swf;
    application/x-stuffit                 sit;
    application/x-tcl                     tcl tk;
    application/x-x509-ca-cert           der pem crt;
    application/x-xpinstall               xpi;
    application/xhtml+xml                xhtml;
    application/xspf+xml                 xspf;
    application/zip                       zip;
    application/octet-stream             bin exe dll;
    application/octet-stream             deb;
    application/octet-stream             dmg;
    application/octet-stream             iso img;
    application/octet-stream             msi msp msm;
    audio/midi                            mid midi kar;
    audio/mpeg                            mp3;
    audio/ogg                             oga ogg;
    audio/x-m4a                           m4a;
    audio/x-realaudio                     ra;
    video/3gpp                            3gpp 3gp;
    video/mp2t                           ts;
    video/mp4                            mp4;
    video/mpeg                           mpeg mpg;
    video/quicktime                      mov;
    video/webm                           webm;
    video/x-flv                          flv;
    video/x-m4v                          m4v;
    video/x-mng                          mng;
    video/x-ms-asf                       asx asf;
    video/x-ms-wmv                       wmv;
    video/x-msvideo                      avi;
}
EOF

    success "mime.types文件已修复"
}

# 测试nginx配置
test_nginx_config() {
    log "测试nginx配置..."
    
    if nginx -t; then
        success "nginx配置测试通过"
    else
        error "nginx配置测试失败"
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

# 显示结果
show_result() {
    echo
    echo "========================================"
    echo "    🎉 nginx语法错误修复完成！"
    echo "========================================"
    echo
    echo "📋 修复内容："
    echo "   • 修复了location嵌套错误"
    echo "   • 修复了mime.types重复定义"
    echo "   • 重新创建了正确的nginx配置"
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
    backup_config
    fix_mime_types
    fix_nginx_config
    test_nginx_config
    restart_nginx
    test_api_connection
    show_result
}

# 执行主函数
main "$@" 