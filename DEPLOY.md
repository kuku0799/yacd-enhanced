# Yacd 增强版一键部署指南

## 🚀 快速部署

### 方法一：在线部署（推荐）

直接在 OpenWrt 设备上运行以下命令：

```bash
curl -sSL https://raw.githubusercontent.com/kuku0799/yacd-enhanced/dist/deploy-online.sh | bash
```

### 方法二：下载脚本部署

1. **下载部署脚本**：
   ```bash
   wget https://raw.githubusercontent.com/kuku0799/yacd-enhanced/dist/deploy-simple.sh
   ```

2. **设置执行权限**：
   ```bash
   chmod +x deploy-simple.sh
   ```

3. **运行部署脚本**：
   ```bash
   ./deploy-simple.sh
   ```

### 方法三：完整版部署脚本

1. **下载完整版脚本**：
   ```bash
   wget https://raw.githubusercontent.com/kuku0799/yacd-enhanced/dist/deploy.sh
   chmod +x deploy.sh
   ```

2. **运行脚本**：
   ```bash
   ./deploy.sh
   ```

3. **查看帮助**：
   ```bash
   ./deploy.sh --help
   ```

## 📋 部署前准备

### 系统要求
- ✅ OpenWrt/LEDE 系统
- ✅ 已安装 OpenClash
- ✅ 网络连接正常
- ✅ root 用户权限

### 检查 OpenClash 安装
```bash
# 检查 OpenClash 是否已安装
opkg list-installed | grep openclash

# 检查 Yacd 目录是否存在
ls -la /usr/share/openclash/ui/yacd/
```

## 🔧 手动部署步骤

如果自动部署失败，可以手动执行以下步骤：

### 1. 备份原版
```bash
cp -r /usr/share/openclash/ui/yacd /usr/share/openclash/ui/yacd_backup
```

### 2. 下载增强版
```bash
cd /tmp
wget https://github.com/kuku0799/yacd-enhanced/archive/dist.zip
unzip -o dist.zip
```

### 3. 部署文件
```bash
# 清空原目录
rm -rf /usr/share/openclash/ui/yacd/*

# 复制新文件
cp -r yacd-enhanced-dist/dist/* /usr/share/openclash/ui/yacd/

# 设置权限
chmod -R 755 /usr/share/openclash/ui/yacd/
chown -R root:root /usr/share/openclash/ui/yacd/
```

### 4. 重启服务
```bash
/etc/init.d/openclash restart
```

## ✅ 验证部署

部署完成后，验证以下文件是否存在：

```bash
ls -la /usr/share/openclash/ui/yacd/
# 应该看到：
# index.html
# assets/
# manifest.webmanifest
# sw.js
# README_CUSTOM.md
```

## 🎯 使用新功能

### 1. 访问界面
- 打开 OpenClash 管理界面
- 进入 Yacd 界面

### 2. 测试功能
- 点击代理页面顶部的 "+" 按钮
- 测试以下功能：
  - **添加节点**：手动添加、链接导入、文本导入
  - **删除节点**：从指定策略组或所有策略组删除

## 🔄 更新部署

### 自动更新
```bash
# 重新运行部署脚本
curl -sSL https://raw.githubusercontent.com/kuku0799/yacd-enhanced/dist/deploy-online.sh | bash
```

### 手动更新
```bash
cd /tmp
wget https://github.com/kuku0799/yacd-enhanced/archive/dist.zip
unzip -o dist.zip
cp -r yacd-enhanced-dist/dist/* /usr/share/openclash/ui/yacd/
chmod -R 755 /usr/share/openclash/ui/yacd/
/etc/init.d/openclash restart
```

## 🛠️ 故障排除

### 常见问题

#### 1. 下载失败
```bash
# 检查网络连接
ping github.com

# 尝试备用下载方式
wget https://github.com/kuku0799/yacd-enhanced/archive/refs/heads/dist.zip
```

#### 2. 权限问题
```bash
# 重新设置权限
chmod -R 755 /usr/share/openclash/ui/yacd/
chown -R root:root /usr/share/openclash/ui/yacd/
```

#### 3. 服务重启失败
```bash
# 检查 OpenClash 状态
/etc/init.d/openclash status

# 手动重启
/etc/init.d/openclash stop
/etc/init.d/openclash start
```

#### 4. 浏览器缓存问题
- 清除浏览器缓存
- 强制刷新页面 (Ctrl+F5)
- 尝试无痕模式访问

### 恢复原版

如果遇到问题，可以恢复原版：

```bash
# 查找备份文件
find /usr/share/openclash/ui/ -name "*backup*" -type d

# 恢复备份
cp -r /usr/share/openclash/ui/yacd_backup_* /usr/share/openclash/ui/yacd/
chmod -R 755 /usr/share/openclash/ui/yacd/
/etc/init.d/openclash restart
```

## 📞 获取帮助

如果遇到问题，可以：

1. **查看日志**：
   ```bash
   logread | grep openclash
   ```

2. **检查文件**：
   ```bash
   ls -la /usr/share/openclash/ui/yacd/
   ```

3. **重新部署**：
   ```bash
   curl -sSL https://raw.githubusercontent.com/kuku0799/yacd-enhanced/dist/deploy-online.sh | bash
   ```

## 🎉 部署成功

部署成功后，你将拥有：

- ✅ **节点添加功能**：支持全协议节点添加
- ✅ **节点删除功能**：支持批量删除节点
- ✅ **智能解析**：自动识别各种节点格式
- ✅ **用户友好**：现代化界面设计
- ✅ **安全可靠**：完善的错误处理和备份机制

享受你的增强版 Yacd 吧！🚀 