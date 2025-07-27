#!/bin/bash

# Yacd Enhanced 监控服务部署脚本
# 集成文件监控功能到 Yacd Enhanced

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
    
    # 检查 OpenClash 是否安装
    if ! opkg list-installed | grep -q openclash; then
        error "OpenClash 未安装，请先安装 OpenClash"
        exit 1
    fi
    
    success "环境检查完成"
}

# 安装系统依赖
install_dependencies() {
    log "安装系统依赖..."
    
    # 更新包列表
    opkg update
    
    # 安装基础工具
    opkg install wget curl unzip python3 python3-pip
    
    # 安装 Python 依赖
    pip3 install pyyaml watchdog
    
    success "系统依赖安装完成"
}

# 创建监控目录
create_monitor_dirs() {
    log "创建监控目录..."
    
    # 创建监控服务目录
    mkdir -p /root/yacd-monitor/{nodes,logs,backup,scripts}
    mkdir -p /usr/share/openclash/ui/yacd-monitor
    
    # 设置权限
    chmod 755 /root/yacd-monitor
    chown -R root:root /root/yacd-monitor
    
    success "监控目录创建完成"
}

# 下载监控脚本
download_monitor_scripts() {
    log "下载监控脚本..."
    
    cd /root/yacd-monitor/scripts
    
    # 下载文件监控脚本
    wget -O file_watcher.py https://raw.githubusercontent.com/kuku0799/yacd-enhanced/main/scripts/file_watcher.py
    
    # 下载节点解析脚本
    wget -O node_parser.py https://raw.githubusercontent.com/kuku0799/yacd-enhanced/main/scripts/node_parser.py
    
    # 下载配置注入脚本
    wget -O config_injector.py https://raw.githubusercontent.com/kuku0799/yacd-enhanced/main/scripts/config_injector.py
    
    # 下载监控服务脚本
    wget -O monitor_service.py https://raw.githubusercontent.com/kuku0799/yacd-enhanced/main/scripts/monitor_service.py
    
    chmod +x *.py
    
    success "监控脚本下载完成"
}

# 创建监控服务配置
create_monitor_config() {
    log "创建监控服务配置..."
    
    cat > /root/yacd-monitor/config.yaml << 'EOF'
# Yacd Enhanced 监控服务配置

# 监控设置
monitor:
  # 监控的文件路径
  nodes_file: "/root/yacd-monitor/nodes/nodes.txt"
  # 检查间隔（秒）
  check_interval: 5
  # 日志文件路径
  log_file: "/root/yacd-monitor/logs/monitor.log"

# OpenClash 配置
openclash:
  # 配置文件路径
  config_file: "/etc/openclash/config.yaml"
  # 备份目录
  backup_dir: "/root/yacd-monitor/backup"
  # 重启命令
  restart_cmd: "/etc/init.d/openclash restart"

# 节点解析设置
parser:
  # 支持的协议
  supported_protocols: ["vmess", "vless", "ss", "trojan"]
  # 最大节点名称长度
  max_name_length: 24
  # 是否跳过重复节点
  skip_duplicates: true

# 注入设置
injector:
  # 策略组名称模式
  group_pattern: "手机{number}"
  # 策略组范围
  group_range: [2, 254]
  # 是否自动注入到所有策略组
  inject_to_all_groups: true
EOF

    success "监控服务配置创建完成"
}

# 创建系统服务
create_system_service() {
    log "创建系统服务..."
    
    cat > /etc/init.d/yacd-monitor << 'EOF'
#!/bin/sh /etc/rc.common

START=99
STOP=10

start() {
    echo "启动 Yacd Enhanced 监控服务..."
    
    # 检查 PID 文件
    if [ -f /tmp/yacd-monitor.pid ]; then
        if kill -0 "$(cat /tmp/yacd-monitor.pid)" 2>/dev/null; then
            echo "监控服务已在运行中"
            return 0
        else
            rm -f /tmp/yacd-monitor.pid
        fi
    fi
    
    # 启动监控服务
    cd /root/yacd-monitor
    python3 scripts/monitor_service.py > logs/service.log 2>&1 &
    echo $! > /tmp/yacd-monitor.pid
    
    echo "监控服务已启动 (PID: $(cat /tmp/yacd-monitor.pid))"
}

stop() {
    echo "停止 Yacd Enhanced 监控服务..."
    
    if [ -f /tmp/yacd-monitor.pid ]; then
        local pid=$(cat /tmp/yacd-monitor.pid)
        if kill -0 "$pid" 2>/dev/null; then
            kill "$pid"
            echo "监控服务已停止 (PID: $pid)"
        else
            echo "监控服务未运行"
        fi
        rm -f /tmp/yacd-monitor.pid
    else
        echo "PID 文件不存在"
    fi
}

restart() {
    stop
    sleep 2
    start
}

status() {
    if [ -f /tmp/yacd-monitor.pid ]; then
        local pid=$(cat /tmp/yacd-monitor.pid)
        if kill -0 "$pid" 2>/dev/null; then
            echo "监控服务运行中 (PID: $pid)"
            return 0
        else
            echo "监控服务未运行 (PID 文件存在但进程不存在)"
            return 1
        fi
    else
        echo "监控服务未运行"
        return 1
    fi
}
EOF

    chmod +x /etc/init.d/yacd-monitor
    /etc/init.d/yacd-monitor enable
    
    success "系统服务创建完成"
}

# 创建示例节点文件
create_sample_nodes() {
    log "创建示例节点文件..."
    
    cat > /root/yacd-monitor/nodes/nodes.txt << 'EOF'
# Yacd Enhanced 节点文件示例
# 支持 VMess、VLESS、Shadowsocks、Trojan 等协议
# 每行一个节点，以 # 开头的行为注释

# VMess 示例
# vmess://eyJhZGQiOiIxMjMuNDUuNjc4LjkwIiwicG9ydCI6IjQ0MyIsImlkIjoiMTIzNDU2Nzg5MCIsImFpZCI6IjAiLCJuZXQiOiJ3cyIsInR5cGUiOiJub25lIiwiaG9zdCI6IiIsInBhdGgiOiIvIiwidGxzIjoidGxzIn0=

# Shadowsocks 示例
# ss://YWVzLTI1Ni1nY206cGFzc3dvcmQ@MTIzLjQ1LjY3OC45MDo0NDM=

# Trojan 示例
# trojan://password@123.45.67.89:443?sni=example.com

# VLESS 示例
# vless://uuid@server:port?security=tls&sni=example.com
EOF

    success "示例节点文件创建完成"
}

# 创建使用说明
create_usage_guide() {
    log "创建使用说明..."
    
    cat > /root/yacd-monitor/README.md << 'EOF'
# Yacd Enhanced 监控服务使用说明

## 快速开始

### 1. 启动监控服务
```bash
/etc/init.d/yacd-monitor start
```

### 2. 添加节点
将节点链接添加到文件：
```bash
echo "vmess://..." >> /root/yacd-monitor/nodes/nodes.txt
```

### 3. 查看状态
```bash
/etc/init.d/yacd-monitor status
```

### 4. 查看日志
```bash
tail -f /root/yacd-monitor/logs/monitor.log
```

## 支持的协议

- **VMess**: `vmess://` 链接
- **VLESS**: `vless://` 链接
- **Shadowsocks**: `ss://` 链接
- **Trojan**: `trojan://` 链接

## 文件结构

```
/root/yacd-monitor/
├── nodes/           # 节点文件目录
│   └── nodes.txt    # 节点文件
├── logs/            # 日志目录
│   ├── monitor.log  # 监控日志
│   └── service.log  # 服务日志
├── backup/          # 备份目录
├── scripts/         # 脚本目录
│   ├── file_watcher.py
│   ├── node_parser.py
│   ├── config_injector.py
│   └── monitor_service.py
└── config.yaml      # 配置文件
```

## 配置说明

编辑 `/root/yacd-monitor/config.yaml` 可以修改监控设置：

- `monitor.check_interval`: 文件检查间隔（秒）
- `monitor.nodes_file`: 监控的节点文件路径
- `injector.group_pattern`: 策略组名称模式
- `injector.group_range`: 策略组范围

## 故障排除

### 1. 服务无法启动
```bash
# 检查日志
tail -f /root/yacd-monitor/logs/service.log

# 检查配置
cat /root/yacd-monitor/config.yaml
```

### 2. 节点未注入
```bash
# 检查节点文件
cat /root/yacd-monitor/nodes/nodes.txt

# 检查 OpenClash 配置
cat /etc/openclash/config.yaml
```

### 3. 配置验证失败
```bash
# 检查 OpenClash 状态
/etc/init.d/openclash status

# 查看系统日志
logread | grep openclash
```
EOF

    success "使用说明创建完成"
}

# 测试监控服务
test_monitor_service() {
    log "测试监控服务..."
    
    # 启动服务
    /etc/init.d/yacd-monitor start
    
    # 等待服务启动
    sleep 3
    
    # 检查服务状态
    if /etc/init.d/yacd-monitor status; then
        success "监控服务测试成功"
    else
        error "监控服务测试失败"
        return 1
    fi
}

# 显示完成信息
show_completion_info() {
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}    Yacd Enhanced 监控服务部署完成${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo -e "${BLUE}📁 监控目录:${NC} /root/yacd-monitor/"
    echo -e "${BLUE}📄 节点文件:${NC} /root/yacd-monitor/nodes/nodes.txt"
    echo -e "${BLUE}📋 配置文件:${NC} /root/yacd-monitor/config.yaml"
    echo -e "${BLUE}📖 使用说明:${NC} /root/yacd-monitor/README.md"
    echo ""
    echo -e "${BLUE}🔧 管理命令:${NC}"
    echo -e "  /etc/init.d/yacd-monitor start   # 启动服务"
    echo -e "  /etc/init.d/yacd-monitor stop    # 停止服务"
    echo -e "  /etc/init.d/yacd-monitor restart # 重启服务"
    echo -e "  /etc/init.d/yacd-monitor status  # 查看状态"
    echo ""
    echo -e "${BLUE}📊 查看日志:${NC}"
    echo -e "  tail -f /root/yacd-monitor/logs/monitor.log"
    echo ""
    echo -e "${BLUE}🎯 添加节点:${NC}"
    echo -e "  echo 'vmess://...' >> /root/yacd-monitor/nodes/nodes.txt"
    echo ""
    echo -e "${GREEN}✅ 部署完成！监控服务已启动并运行中。${NC}"
}

# 主函数
main() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}    Yacd Enhanced 监控服务部署${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    
    check_environment
    install_dependencies
    create_monitor_dirs
    download_monitor_scripts
    create_monitor_config
    create_system_service
    create_sample_nodes
    create_usage_guide
    test_monitor_service
    show_completion_info
}

# 运行主函数
main "$@" 