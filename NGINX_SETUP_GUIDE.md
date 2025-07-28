# Nginx配置指南

## 概述

本指南介绍如何为Yacd Enhanced项目配置nginx服务器，确保Web界面能够正常访问和使用。

## 配置说明

### 1. 配置文件位置
- 主配置文件：`/etc/nginx/conf.d/yacd.conf`
- 由部署脚本自动创建

### 2. 配置内容

```nginx
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
```

### 3. 配置特性

#### 跨域支持
- 允许所有来源的跨域请求
- 支持多种HTTP方法
- 包含必要的请求头

#### 静态文件优化
- 对JS、CSS、图片等静态文件设置1年缓存
- 启用gzip压缩
- 优化加载性能

#### API代理
- 将`/api/`路径的请求代理到OpenClash
- 保持原始请求头信息
- 设置合理的超时时间

#### 健康检查
- 提供`/health`端点用于监控
- 返回简单的健康状态

#### 自动重定向
- 访问根路径时自动重定向到Yacd界面

## 使用方法

### 1. 自动配置（推荐）
使用部署脚本自动配置：
```bash
./deploy-enhanced-fixed.sh
```

### 2. 手动配置
如果需要手动配置：

```bash
# 创建配置目录
mkdir -p /etc/nginx/conf.d

# 创建配置文件
cat > /etc/nginx/conf.d/yacd.conf << 'EOF'
# 配置内容（见上方）
EOF

# 测试配置
nginx -t

# 重启nginx
/etc/init.d/nginx restart
```

### 3. 验证配置

```bash
# 检查nginx状态
/etc/init.d/nginx status

# 检查端口监听
netstat -tlnp | grep 9090

# 测试健康检查
curl http://localhost:9090/health
```

## 访问地址

- **主界面**：`http://您的路由器IP:9090/ui/yacd/`
- **健康检查**：`http://您的路由器IP:9090/health`
- **API接口**：`http://您的路由器IP:9090/api/`

## 故障排除

### 1. nginx未启动
```bash
# 检查nginx是否安装
which nginx

# 安装nginx（如果未安装）
opkg install nginx-ssl

# 启动nginx
/etc/init.d/nginx start
```

### 2. 配置语法错误
```bash
# 测试配置语法
nginx -t

# 查看错误日志
tail -f /var/log/nginx/error.log
```

### 3. 端口被占用
```bash
# 检查端口占用
netstat -tlnp | grep 9090

# 修改配置文件中的端口号
# 编辑 /etc/nginx/conf.d/yacd.conf
# 将 listen 9090; 改为其他端口
```

### 4. 文件权限问题
```bash
# 检查文件权限
ls -la /usr/share/yacd/

# 修复权限
chmod -R 755 /usr/share/yacd/
chown -R root:root /usr/share/yacd/
```

### 5. 防火墙问题
```bash
# 检查防火墙规则
iptables -L -n | grep 9090

# 添加防火墙规则（如果需要）
iptables -A INPUT -p tcp --dport 9090 -j ACCEPT
```

## 性能优化

### 1. 启用gzip压缩
在nginx主配置文件中添加：
```nginx
gzip on;
gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;
```

### 2. 调整缓存设置
根据实际需求调整静态文件的缓存时间：
```nginx
# 短期缓存
location ~* \.(js|css)$ {
    expires 1d;
}

# 长期缓存
location ~* \.(png|jpg|jpeg|gif|ico|svg)$ {
    expires 1y;
}
```

### 3. 连接数优化
在nginx主配置文件中调整：
```nginx
worker_connections 1024;
keepalive_timeout 65;
```

## 安全建议

### 1. 限制访问来源
```nginx
# 只允许特定IP访问
allow 192.168.1.0/24;
deny all;
```

### 2. 启用HTTPS
```nginx
# 添加SSL配置
ssl_certificate /path/to/cert.pem;
ssl_certificate_key /path/to/key.pem;
listen 9090 ssl;
```

### 3. 隐藏版本信息
```nginx
# 在http块中添加
server_tokens off;
```

## 监控和维护

### 1. 日志监控
```bash
# 查看访问日志
tail -f /var/log/nginx/access.log

# 查看错误日志
tail -f /var/log/nginx/error.log
```

### 2. 性能监控
```bash
# 检查nginx进程
ps aux | grep nginx

# 检查连接数
netstat -an | grep :9090 | wc -l
```

### 3. 定期维护
```bash
# 重启nginx服务
/etc/init.d/nginx restart

# 重新加载配置
nginx -s reload

# 检查配置
nginx -t
```

## 更新日志

### v1.0.0 (2024-07-28)
- 初始nginx配置
- 支持Yacd Enhanced界面
- 集成API代理功能
- 添加健康检查端点
- 优化静态文件缓存

## 技术支持

如果遇到问题，请检查：
1. nginx服务状态
2. 配置文件语法
3. 文件权限设置
4. 防火墙规则
5. 端口占用情况

更多信息请参考：
- [Nginx官方文档](https://nginx.org/en/docs/)
- [OpenWrt Wiki](https://openwrt.org/docs/start) 