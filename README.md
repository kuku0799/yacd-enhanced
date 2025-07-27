# Yacd Enhanced - 增强版 Clash 管理界面

## 🚀 项目简介

Yacd Enhanced 是一个基于原版 Yacd 的增强版 Clash 管理界面，专门为 OpenWrt 环境优化，提供了更强大的节点管理功能和智能故障诊断能力。

## ✨ 主要功能

### 📊 节点管理
- **智能节点添加**：支持手动添加、链接导入、文本导入
- **多协议支持**：VMess、VLESS、Shadowsocks、Trojan、HTTP/SOCKS5
- **批量操作**：支持批量添加、删除、测试节点
- **实时监控**：节点状态实时更新，延迟测试

### 🔧 智能诊断
- **自动故障检测**：Provider 文件缺失、策略组配置问题
- **一键修复**：自动修复常见配置问题
- **详细报告**：提供完整的诊断报告和解决方案

### 📁 文件监控（新增）
- **实时文件监控**：监控节点文件变化，自动同步
- **智能解析**：支持多种订阅格式解析
- **自动注入**：自动注入节点到策略组
- **安全回滚**：配置验证失败时自动回滚

### ⚡ 性能优化
- **虚拟滚动**：大量节点时的性能优化
- **智能缓存**：减少重复请求
- **防抖搜索**：提升搜索响应速度
- **内存优化**：减少内存占用

## 🛠️ 安装部署

### 方式一：一键部署（推荐）

```bash
# 下载部署脚本
wget -O deploy-enhanced.sh https://raw.githubusercontent.com/kuku0799/yacd-enhanced/main/deploy-enhanced.sh

# 运行部署脚本
chmod +x deploy-enhanced.sh
./deploy-enhanced.sh
```

### 方式二：自适应部署

```bash
# 下载自适应部署脚本
wget -O deploy-adaptive.sh https://raw.githubusercontent.com/kuku0799/yacd-enhanced/main/deploy-adaptive.sh

# 运行部署脚本
chmod +x deploy-adaptive.sh
./deploy-adaptive.sh
```

### 方式三：手动部署

```bash
# 1. 克隆项目
git clone https://github.com/kuku0799/yacd-enhanced.git
cd yacd-enhanced

# 2. 安装依赖
npm install

# 3. 构建项目
npm run build

# 4. 部署到 OpenWrt
cp -r dist/* /usr/share/openclash/ui/yacd/
```

## 📁 文件监控功能

### 启动监控服务

```bash
# 启动文件监控
/etc/init.d/yacd-monitor start

# 查看监控状态
/etc/init.d/yacd-monitor status

# 查看监控日志
tail -f /root/yacd-monitor/logs/monitor.log
```

### 添加节点

```bash
# 方式1：直接编辑文件
echo "vmess://..." >> /root/yacd-monitor/nodes/nodes.txt

# 方式2：通过 Web 界面上传
# 访问 http://192.168.1.1:9090/ui/yacd/ 进入监控面板
```

### 支持的节点格式

```
# VMess
vmess://eyJhZGQiOiIxMjMuNDUuNjc4LjkwIiwicG9ydCI6IjQ0MyIsImlkIjoiMTIzNDU2Nzg5MCIsImFpZCI6IjAiLCJuZXQiOiJ3cyIsInR5cGUiOiJub25lIiwiaG9zdCI6IiIsInBhdGgiOiIvIiwidGxzIjoidGxzIn0=

# Shadowsocks
ss://YWVzLTI1Ni1nY206cGFzc3dvcmQ@MTIzLjQ1LjY3OC45MDo0NDM=

# Trojan
trojan://password@123.45.67.89:443?sni=example.com

# VLESS
vless://uuid@server:port?security=tls&sni=example.com
```

## 🔧 故障诊断

### 使用诊断脚本

```bash
# 下载诊断脚本
wget -O diagnose-openclash.sh https://raw.githubusercontent.com/kuku0799/yacd-enhanced/main/diagnose-openclash.sh

# 运行诊断
chmod +x diagnose-openclash.sh
./diagnose-openclash.sh
```

### 使用修复脚本

```bash
# 下载修复脚本
wget -O fix-openclash-proxy-groups.sh https://raw.githubusercontent.com/kuku0799/yacd-enhanced/main/fix-openclash-proxy-groups.sh

# 运行修复
chmod +x fix-openclash-proxy-groups.sh
./fix-openclash-proxy-groups.sh
```

## 📊 功能对比

| 功能 | 原版 Yacd | Yacd Enhanced |
|------|-----------|---------------|
| 节点管理 | 基础功能 | 增强功能 + 文件监控 |
| 故障诊断 | 无 | 智能诊断 + 一键修复 |
| 性能优化 | 基础 | 虚拟滚动 + 智能缓存 |
| 用户体验 | 基础 | 快捷键 + 拖拽 + 通知 |
| 部署便利性 | 手动 | 一键部署 + 自适应 |

## 🎯 使用场景

1. **OpenWrt 路由器管理**：在 OpenWrt 上管理 Clash 代理
2. **代理服务管理**：管理大量代理节点和策略
3. **故障诊断**：快速定位和解决 OpenClash 问题
4. **性能优化**：提升 Clash 管理界面的使用体验

## 📝 更新日志

### v2.0.0 (2024-01-XX)
- ✨ 新增文件监控功能
- 🔧 优化节点管理流程
- 🐛 修复配置同步问题
- 📊 改进性能监控

### v1.0.0 (2024-01-XX)
- 🎉 初始版本发布
- 📊 基础节点管理功能
- 🔧 智能故障诊断
- ⚡ 性能优化

## 🤝 贡献指南

欢迎提交 Issue 和 Pull Request！

1. Fork 本仓库
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 打开 Pull Request

## 📄 许可证

本项目基于 MIT 许可证开源。

## 🙏 致谢

- 感谢原版 [Yacd](https://github.com/haishanh/yacd) 项目
- 感谢 [OpenClash](https://github.com/vernesong/OpenClash) 项目
- 感谢所有贡献者的支持

## 📞 联系方式

- GitHub Issues: [提交问题](https://github.com/kuku0799/yacd-enhanced/issues)
- 项目主页: [https://github.com/kuku0799/yacd-enhanced](https://github.com/kuku0799/yacd-enhanced)

---

**⭐ 如果这个项目对您有帮助，请给个 Star 支持一下！** 