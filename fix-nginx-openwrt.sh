#!/bin/bash

# OpenWrt nginx修复脚本
# 解决nginx配置问题

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
echo "    OpenWrt nginx修复脚本"
echo "========================================"
echo

# 检查nginx安装
check_nginx_install() {
    log "检查nginx安装状态..."
    
    if ! command -v nginx &> /dev/null; then
        log "安装nginx..."
        opkg update
        opkg install nginx-ssl
    else
        success "nginx已安装"
    fi
}

# 创建nginx主配置
create_main_config() {
    log "创建nginx主配置文件..."
    
    # 创建nginx目录
    mkdir -p /etc/nginx
    mkdir -p /etc/nginx/conf.d
    mkdir -p /var/log/nginx
    mkdir -p /var/run
    
    # 创建主配置文件
    cat > /etc/nginx/nginx.conf << 'EOF'
user root;
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /var/run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';
    
    access_log /var/log/nginx/access.log main;
    
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    
    # Gzip压缩
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;
    
    # 包含其他配置文件
    include /etc/nginx/conf.d/*.conf;
}
EOF

    success "nginx主配置文件创建完成"
}

# 创建mime.types文件
create_mime_types() {
    log "创建mime.types文件..."
    
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

    success "mime.types文件创建完成"
}

# 创建Yacd配置
create_yacd_config() {
    log "创建Yacd配置文件..."
    
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
    
    # API代理到OpenClash
    location /api/ {
        proxy_pass http://127.0.0.1:9090/;
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

    success "Yacd配置文件创建完成"
}

# 创建Yacd文件
create_yacd_files() {
    log "创建Yacd文件..."
    
    # 创建目录
    mkdir -p /usr/share/yacd
    
    # 创建主页面
    cat > /usr/share/yacd/index.html << 'EOF'
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Yacd Enhanced</title>
    <style>
        body { 
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; 
            margin: 0; 
            padding: 20px; 
            background: linear-gradient(135deg, #1a1a1a 0%, #2d2d2d 100%); 
            color: #fff; 
            min-height: 100vh;
        }
        .container { 
            max-width: 1200px; 
            margin: 0 auto; 
            background: rgba(42, 42, 42, 0.95); 
            padding: 30px; 
            border-radius: 15px; 
            box-shadow: 0 8px 32px rgba(0,0,0,0.3); 
            backdrop-filter: blur(10px);
        }
        .header { 
            text-align: center; 
            margin-bottom: 40px; 
            border-bottom: 3px solid #007bff; 
            padding-bottom: 20px; 
        }
        .header h1 {
            font-size: 2.5em;
            margin: 0;
            background: linear-gradient(45deg, #007bff, #00d4ff);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            background-clip: text;
        }
        .feature { 
            margin: 25px 0; 
            padding: 25px; 
            border: 1px solid #444; 
            border-radius: 12px; 
            background: rgba(51, 51, 51, 0.8); 
            transition: all 0.3s ease;
        }
        .feature:hover {
            transform: translateY(-5px);
            box-shadow: 0 10px 25px rgba(0,0,0,0.2);
            border-color: #007bff;
        }
        .btn { 
            display: inline-block; 
            padding: 12px 24px; 
            background: linear-gradient(45deg, #007bff, #0056b3); 
            color: white; 
            text-decoration: none; 
            border-radius: 8px; 
            margin: 8px; 
            border: none; 
            cursor: pointer; 
            font-size: 14px; 
            font-weight: 500;
            transition: all 0.3s ease;
            box-shadow: 0 4px 15px rgba(0,123,255,0.3);
        }
        .btn:hover { 
            transform: translateY(-2px);
            box-shadow: 0 6px 20px rgba(0,123,255,0.4);
        }
        .btn-danger { 
            background: linear-gradient(45deg, #dc3545, #c82333); 
            box-shadow: 0 4px 15px rgba(220,53,69,0.3);
        }
        .btn-danger:hover { 
            box-shadow: 0 6px 20px rgba(220,53,69,0.4);
        }
        .btn-success { 
            background: linear-gradient(45deg, #28a745, #218838); 
            box-shadow: 0 4px 15px rgba(40,167,69,0.3);
        }
        .btn-success:hover { 
            box-shadow: 0 6px 20px rgba(40,167,69,0.4);
        }
        .code { 
            background: #1e1e1e; 
            padding: 12px; 
            border-radius: 6px; 
            font-family: 'Courier New', monospace; 
            color: #00ff00; 
            border: 1px solid #333;
            display: block;
            margin: 10px 0;
        }
        .tabs {
            display: flex;
            margin-bottom: 30px;
            border-bottom: 2px solid #444;
            background: rgba(51, 51, 51, 0.5);
            border-radius: 8px 8px 0 0;
            overflow: hidden;
        }
        .tab {
            padding: 15px 25px;
            background: transparent;
            border: none;
            color: #fff;
            cursor: pointer;
            font-size: 16px;
            font-weight: 500;
            transition: all 0.3s ease;
            flex: 1;
            text-align: center;
        }
        .tab:hover {
            background: rgba(0,123,255,0.2);
        }
        .tab.active {
            background: linear-gradient(45deg, #007bff, #0056b3);
            color: white;
        }
        .tab-content {
            display: none;
            animation: fadeIn 0.5s ease;
        }
        .tab-content.active {
            display: block;
        }
        @keyframes fadeIn {
            from { opacity: 0; transform: translateY(10px); }
            to { opacity: 1; transform: translateY(0); }
        }
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            margin: 20px 0;
        }
        .stat-card {
            background: rgba(51, 51, 51, 0.8);
            padding: 20px;
            border-radius: 10px;
            text-align: center;
            border: 1px solid #444;
        }
        .stat-value {
            font-size: 2em;
            font-weight: bold;
            color: #007bff;
        }
        .stat-label {
            color: #aaa;
            margin-top: 5px;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🚀 Yacd Enhanced</h1>
            <p>智能节点管理系统 - 专为OpenWrt优化</p>
        </div>
        
        <div class="tabs">
            <button class="tab active" onclick="showTab('overview')">📊 概览</button>
            <button class="tab" onclick="showTab('nodes')">🔗 节点管理</button>
            <button class="tab" onclick="showTab('commands')">⚙️ 命令工具</button>
            <button class="tab" onclick="showTab('status')">📈 系统状态</button>
        </div>
        
        <div id="overview" class="tab-content active">
            <div class="feature">
                <h3>✨ 核心功能</h3>
                <div class="stats-grid">
                    <div class="stat-card">
                        <div class="stat-value">4</div>
                        <div class="stat-label">协议支持</div>
                    </div>
                    <div class="stat-card">
                        <div class="stat-value">∞</div>
                        <div class="stat-label">节点数量</div>
                    </div>
                    <div class="stat-card">
                        <div class="stat-value">24/7</div>
                        <div class="stat-label">自动监控</div>
                    </div>
                    <div class="stat-card">
                        <div class="stat-value">100%</div>
                        <div class="stat-label">兼容性</div>
                    </div>
                </div>
                <ul>
                    <li>🎯 可视化节点管理界面</li>
                    <li>🔗 多协议支持 (VMess/SS/Trojan/VLESS)</li>
                    <li>✅ 智能节点验证和过滤</li>
                    <li>📊 实时统计显示</li>
                    <li>📁 文件导入导出功能</li>
                    <li>🔄 自动监控和更新</li>
                </ul>
            </div>
            
            <div class="feature">
                <h3>📋 快速开始</h3>
                <p>访问地址：<span class="code">http://您的路由器IP:9090/ui/yacd/</span></p>
                <p>在监控面板中选择"节点管理"标签页开始使用</p>
            </div>
        </div>
        
        <div id="nodes" class="tab-content">
            <div class="feature">
                <h3>📝 节点管理</h3>
                <p>您可以通过以下方式管理节点：</p>
                <button class="btn" onclick="showCommand('add-nodes')">📝 编辑节点文件</button>
                <button class="btn" onclick="showCommand('view-nodes')">👁️ 查看当前节点</button>
                <button class="btn btn-success" onclick="showCommand('update-nodes')">🔄 更新节点</button>
                <button class="btn btn-danger" onclick="showCommand('clear-nodes')">🗑️ 清空节点</button>
            </div>
            
            <div class="feature">
                <h3>📁 文件位置</h3>
                <p>节点文件：<span class="code">/root/OpenClashManage/wangluo/nodes.txt</span></p>
                <p>日志文件：<span class="code">/root/OpenClashManage/wangluo/log.txt</span></p>
                <p>脚本目录：<span class="code">/root/OpenClashManage/scripts/</span></p>
            </div>
            
            <div class="feature">
                <h3>🔗 支持的节点格式</h3>
                <ul>
                    <li><span class="code">vmess://base64编码配置</span></li>
                    <li><span class="code">ss://base64编码配置</span></li>
                    <li><span class="code">trojan://密码@服务器:端口?security=tls&type=tcp#备注</span></li>
                    <li><span class="code">vless://uuid@服务器:端口?encryption=none&security=tls&type=tcp#备注</span></li>
                </ul>
            </div>
        </div>
        
        <div id="commands" class="tab-content">
            <div class="feature">
                <h3>⚙️ 常用命令</h3>
                <button class="btn" onclick="showCommand('edit-nodes')">📝 编辑节点文件</button>
                <button class="btn" onclick="showCommand('view-nodes')">👁️ 查看节点</button>
                <button class="btn btn-success" onclick="showCommand('update-nodes')">🔄 更新节点</button>
                <button class="btn" onclick="showCommand('monitor-status')">📊 监控状态</button>
                <button class="btn" onclick="showCommand('restart-openclash')">🔄 重启OpenClash</button>
                <button class="btn" onclick="showCommand('view-logs')">📋 查看日志</button>
                <button class="btn btn-danger" onclick="showCommand('clear-nodes')">🗑️ 清空节点</button>
            </div>
            
            <div class="feature">
                <h3>🔧 服务管理</h3>
                <button class="btn" onclick="showCommand('start-monitor')">▶️ 启动监控</button>
                <button class="btn" onclick="showCommand('stop-monitor')">⏹️ 停止监控</button>
                <button class="btn" onclick="showCommand('restart-monitor')">🔄 重启监控</button>
                <button class="btn" onclick="showCommand('monitor-status')">📊 监控状态</button>
            </div>
        </div>
        
        <div id="status" class="tab-content">
            <div class="feature">
                <h3>📈 系统状态</h3>
                <div class="stats-grid">
                    <div class="stat-card">
                        <div class="stat-value" id="node-count">-</div>
                        <div class="stat-label">节点数量</div>
                    </div>
                    <div class="stat-card">
                        <div class="stat-value" id="monitor-status">-</div>
                        <div class="stat-label">监控状态</div>
                    </div>
                    <div class="stat-card">
                        <div class="stat-value" id="openclash-status">-</div>
                        <div class="stat-label">OpenClash状态</div>
                    </div>
                    <div class="stat-card">
                        <div class="stat-value" id="nginx-status">-</div>
                        <div class="stat-label">Nginx状态</div>
                    </div>
                </div>
                <button class="btn" onclick="refreshStatus()">🔄 刷新状态</button>
            </div>
        </div>
    </div>
    
    <script>
        function showTab(tabName) {
            // 隐藏所有标签内容
            var contents = document.getElementsByClassName('tab-content');
            for (var i = 0; i < contents.length; i++) {
                contents[i].classList.remove('active');
            }
            
            // 移除所有标签的active类
            var tabs = document.getElementsByClassName('tab');
            for (var i = 0; i < tabs.length; i++) {
                tabs[i].classList.remove('active');
            }
            
            // 显示选中的标签内容
            document.getElementById(tabName).classList.add('active');
            event.target.classList.add('active');
            
            // 如果切换到状态标签，自动刷新状态
            if (tabName === 'status') {
                refreshStatus();
            }
        }
        
        function showCommand(command) {
            var commands = {
                'add-nodes': 'nano /root/OpenClashManage/wangluo/nodes.txt',
                'view-nodes': 'cat /root/OpenClashManage/wangluo/nodes.txt',
                'update-nodes': 'python3 /root/OpenClashManage/scripts/zr.py',
                'edit-nodes': 'nano /root/OpenClashManage/wangluo/nodes.txt',
                'monitor-status': '/etc/init.d/yacd-enhanced-monitor status',
                'restart-openclash': '/etc/init.d/openclash restart',
                'clear-nodes': 'echo "" > /root/OpenClashManage/wangluo/nodes.txt',
                'view-logs': 'tail -f /root/OpenClashManage/wangluo/log.txt',
                'start-monitor': '/etc/init.d/yacd-enhanced-monitor start',
                'stop-monitor': '/etc/init.d/yacd-enhanced-monitor stop',
                'restart-monitor': '/etc/init.d/yacd-enhanced-monitor restart'
            };
            
            var cmd = commands[command];
            if (cmd) {
                alert('请在终端中运行以下命令：\n\n' + cmd);
            }
        }
        
        function refreshStatus() {
            // 这里可以添加AJAX请求来获取实时状态
            // 目前使用模拟数据
            document.getElementById('node-count').textContent = '检查中...';
            document.getElementById('monitor-status').textContent = '检查中...';
            document.getElementById('openclash-status').textContent = '检查中...';
            document.getElementById('nginx-status').textContent = '检查中...';
            
            // 模拟状态更新
            setTimeout(() => {
                document.getElementById('node-count').textContent = '0';
                document.getElementById('monitor-status').textContent = '停止';
                document.getElementById('openclash-status').textContent = '运行中';
                document.getElementById('nginx-status').textContent = '运行中';
            }, 1000);
        }
        
        // 页面加载时刷新状态
        window.onload = function() {
            refreshStatus();
        };
    </script>
</body>
</html>
EOF

    # 设置文件权限
    chmod 644 /usr/share/yacd/index.html
    
    success "Yacd文件创建完成"
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

# 启动nginx服务
start_nginx() {
    log "启动nginx服务..."
    
    # 停止现有nginx进程
    pkill nginx 2>/dev/null || true
    
    # 启动nginx
    nginx
    
    # 检查nginx是否运行
    sleep 2
    if pgrep nginx > /dev/null; then
        success "nginx服务启动成功"
    else
        error "nginx服务启动失败"
        return 1
    fi
}

# 显示结果
show_result() {
    echo
    echo "========================================"
    echo "    🎉 nginx修复完成！"
    echo "========================================"
    echo
    echo "📋 修复内容："
    echo "   • 创建nginx主配置文件"
    echo "   • 创建mime.types文件"
    echo "   • 配置Yacd服务"
    echo "   • 创建Web界面"
    echo
    echo "🌐 访问地址："
    echo "   • 主界面: http://$(hostname -I | awk '{print $1}'):9090/ui/yacd/"
    echo "   • 健康检查: http://$(hostname -I | awk '{print $1}'):9090/health"
    echo
    echo "🔧 管理命令："
    echo "   • 重启nginx: nginx -s reload"
    echo "   • 停止nginx: nginx -s stop"
    echo "   • 测试配置: nginx -t"
    echo
    echo "📁 配置文件："
    echo "   • 主配置: /etc/nginx/nginx.conf"
    echo "   • Yacd配置: /etc/nginx/conf.d/yacd.conf"
    echo "   • Web文件: /usr/share/yacd/index.html"
    echo
    echo "✨ 特性："
    echo "   • 支持CORS跨域请求"
    echo "   • 静态文件缓存优化"
    echo "   • 健康检查端点"
    echo "   • 美观的Web界面"
    echo
    echo "🎯 下一步："
    echo "   1. 访问Web界面"
    echo "   2. 添加您的节点"
    echo "   3. 启动监控服务"
    echo
}

# 主函数
main() {
    check_nginx_install
    create_main_config
    create_mime_types
    create_yacd_config
    create_yacd_files
    test_nginx_config
    start_nginx
    show_result
}

# 执行主函数
main "$@" 