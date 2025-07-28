# Yacd-meta-master 部署指南

## 🚀 快速部署

### 方式一：一键部署（推荐）

```bash
# 1. 下载部署脚本
wget -O deploy-enhanced.sh https://raw.githubusercontent.com/kuku0799/yacd-enhanced/main/deploy-enhanced.sh

# 2. 设置执行权限
chmod +x deploy-enhanced.sh

# 3. 运行部署脚本
./deploy-enhanced.sh
```

### 方式二：监控功能部署

```bash
# 1. 下载监控部署脚本
wget -O deploy-monitor.sh https://raw.githubusercontent.com/kuku0799/yacd-enhanced/main/deploy-monitor.sh

# 2. 设置执行权限
chmod +x deploy-monitor.sh

# 3. 运行部署脚本
./deploy-monitor.sh
```

## 📋 部署前准备

### 系统要求
- **操作系统**: OpenWrt 21.02 或更高版本
- **内存**: 至少 128MB 可用内存
- **存储**: 至少 50MB 可用空间
- **网络**: 需要能访问 GitHub

### 环境检查
```bash
# 检查系统版本
cat /etc/openwrt_release

# 检查可用内存
free -h

# 检查可用存储
df -h

# 检查网络连接
ping -c 3 github.com
```

## 🔧 详细部署步骤

### 步骤 1: 环境准备

```bash
# 更新系统包
opkg update

# 安装基础依赖
opkg install wget curl unzip python3 python3-pip

# 安装 Python 依赖
pip3 install ruamel.yaml flask flask-cors
```

### 步骤 2: 下载项目

```bash
# 克隆项目
git clone https://github.com/kuku0799/yacd-enhanced.git
cd yacd-enhanced

# 或者直接下载
wget https://github.com/kuku0799/yacd-enhanced/archive/refs/heads/main.zip
unzip main.zip
cd yacd-enhanced-main
```

### 步骤 3: 部署 Web 界面

```bash
# 创建部署目录
mkdir -p /usr/share/openclash/ui/yacd-enhanced

# 复制 Web 文件
cp -r public/* /usr/share/openclash/ui/yacd-enhanced/

# 设置权限
chmod -R 755 /usr/share/openclash/ui/yacd-enhanced
```

### 步骤 4: 部署 Python 脚本

```bash
# 创建脚本目录
mkdir -p /root/OpenClashManage/scripts
mkdir -p /root/OpenClashManage/wangluo

# 复制脚本文件
cp scripts/*.py /root/OpenClashManage/scripts/
cp scripts/*.sh /root/OpenClashManage/scripts/

# 设置执行权限
chmod +x /root/OpenClashManage/scripts/*.py
chmod +x /root/OpenClashManage/scripts/*.sh

# 创建日志文件
touch /root/OpenClashManage/wangluo/log.txt
chmod 666 /root/OpenClashManage/wangluo/log.txt
```

### 步骤 5: 配置 OpenClash

```bash
# 确保 OpenClash 已安装
opkg list-installed | grep openclash

# 如果没有安装，先安装 OpenClash
opkg install luci-app-openclash

# 启动 OpenClash
/etc/init.d/openclash start
```

### 步骤 6: 启动监控服务

```bash
# 启动守护进程
nohup bash /root/OpenClashManage/scripts/jk.sh > /dev/null 2>&1 &

# 或者手动运行一次更新
python3 /root/OpenClashManage/scripts/zr.py
```

## 🌐 访问界面

### Web 界面访问
```
http://你的路由器IP:9090/ui/yacd-enhanced/
```

### 默认端口
- **Yacd 界面**: 9090
- **OpenClash API**: 9090

## 📁 文件结构

```
/root/OpenClashManage/
├── scripts/
│   ├── jx.py          # 节点解析器
│   ├── zw.py          # 节点注入器
│   ├── zc.py          # 策略组注入器
│   ├── zr.py          # 主控制器
│   ├── log.py         # 日志系统
│   └── jk.sh          # 守护进程
├── wangluo/
│   ├── nodes.txt      # 节点文件
│   └── log.txt        # 日志文件
└── config/
    └── openclash.yaml # OpenClash 配置
```

## 🔧 配置说明

### 节点文件格式
在 `/root/OpenClashManage/wangluo/nodes.txt` 中添加节点：

```
# VMess 节点
vmess://eyJhZGQiOiIxMjMuNDUuNjc4LjkwIiwicG9ydCI6IjQ0MyIsImlkIjoiMTIzNDU2Nzg5MCIsImFpZCI6IjAiLCJuZXQiOiJ3cyIsInR5cGUiOiJub25lIiwiaG9zdCI6IiIsInBhdGgiOiIvIiwidGxzIjoidGxzIn0=

# Shadowsocks 节点
ss://YWVzLTI1Ni1nY206cGFzc3dvcmQ@MTIzLjQ1LjY3OC45MDo0NDM=

# Trojan 节点
trojan://password@123.45.67.89:443?sni=example.com

# VLESS 节点
vless://uuid@server:port?security=tls&sni=example.com
```

### 支持的协议
- **VMess**: `vmess://`
- **Shadowsocks**: `ss://`
- **Trojan**: `trojan://`
- **VLESS**: `vless://`

## 📊 监控和日志

### 查看实时日志
```bash
# 查看节点更新日志
tail -f /root/OpenClashManage/wangluo/log.txt

# 查看系统日志
logread | grep openclash
```

### 手动执行更新
```bash
# 手动运行节点更新
python3 /root/OpenClashManage/scripts/zr.py

# 手动运行节点解析
python3 /root/OpenClashManage/scripts/jx.py

# 手动运行节点注入
python3 /root/OpenClashManage/scripts/zw.py
```

## 🔍 故障排除

### 常见问题

#### 1. 权限问题
```bash
# 检查文件权限
ls -la /root/OpenClashManage/scripts/
ls -la /root/OpenClashManage/wangluo/

# 修复权限
chmod +x /root/OpenClashManage/scripts/*.py
chmod +x /root/OpenClashManage/scripts/*.sh
chmod 666 /root/OpenClashManage/wangluo/log.txt
```

#### 2. Python 依赖问题
```bash
# 检查 Python 版本
python3 --version

# 安装依赖
pip3 install ruamel.yaml

# 如果 pip 不可用，使用 opkg
opkg install python3-yaml
```

#### 3. OpenClash 配置问题
```bash
# 检查 OpenClash 状态
/etc/init.d/openclash status

# 重启 OpenClash
/etc/init.d/openclash restart

# 验证配置
/etc/init.d/openclash verify_config
```

#### 4. 网络连接问题
```bash
# 检查网络连接
ping -c 3 github.com

# 检查 DNS
nslookup github.com

# 如果 DNS 有问题，使用 IP 地址
echo "140.82.112.3 github.com" >> /etc/hosts
```

### 调试命令

```bash
# 查看进程状态
ps aux | grep python
ps aux | grep jk.sh

# 查看端口占用
netstat -tlnp | grep 9090

# 查看磁盘空间
df -h

# 查看内存使用
free -h
```

## 🔄 更新和维护

### 更新项目
```bash
# 进入项目目录
cd /root/yacd-enhanced

# 拉取最新代码
git pull origin main

# 重新部署
./deploy-enhanced.sh
```

### 备份配置
```bash
# 备份 OpenClash 配置
cp /etc/openclash/config.yaml /root/backup/openclash_config_$(date +%Y%m%d).yaml

# 备份节点文件
cp /root/OpenClashManage/wangluo/nodes.txt /root/backup/nodes_$(date +%Y%m%d).txt
```

### 清理日志
```bash
# 清理旧日志
find /root/OpenClashManage/wangluo/ -name "*.log" -mtime +7 -delete

# 清理临时文件
rm -rf /tmp/openclash_*
```

## 📞 技术支持

如果遇到问题，可以：

1. **查看日志**: `tail -f /root/OpenClashManage/wangluo/log.txt`
2. **提交 Issue**: [GitHub Issues](https://github.com/kuku0799/yacd-enhanced/issues)
3. **查看文档**: [项目 Wiki](https://github.com/kuku0799/yacd-enhanced/wiki)

## 🎯 使用建议

1. **定期备份**: 建议每周备份一次配置文件
2. **监控日志**: 定期查看日志文件，及时发现问题
3. **更新节点**: 定期更新节点文件，保持节点新鲜度
4. **性能优化**: 如果节点较多，建议使用虚拟滚动功能
5. **安全考虑**: 确保路由器防火墙配置正确

---

**⭐ 如果这个项目对您有帮助，请给个 Star 支持一下！** 