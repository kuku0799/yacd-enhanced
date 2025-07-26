# Yacd 增强版 - 节点管理功能

这是一个基于 [Yacd-meta](https://github.com/MetaCubeX/yacd) 的增强版本，添加了强大的节点管理功能。

## 🚀 新增功能

### 1. 节点添加功能
- **手动添加**：支持全协议节点配置
- **链接导入**：支持订阅链接解析
- **文本导入**：支持粘贴节点配置文本

### 2. 全协议支持
- **VMess**：支持 TCP、WebSocket、HTTP/2、gRPC 传输
- **VLESS**：支持 TLS/XTLS 和多种传输协议
- **Shadowsocks**：支持多种加密方法
- **ShadowsocksR**：支持协议和混淆
- **Trojan**：支持 TLS 配置
- **HTTP/SOCKS5**：支持认证

### 3. 批量策略组管理
- 支持添加到所有策略组
- 支持选择特定策略组
- 智能策略组选择界面

### 4. 用户友好界面
- 现代化的标签页设计
- 响应式表单布局
- 实时状态反馈
- 完善的错误处理

## 📦 安装和使用

### 方法一：直接使用构建版本

1. **下载构建文件**：
   ```bash
   git clone https://github.com/你的用户名/yacd-enhanced.git
   cd yacd-enhanced
   ```

2. **使用构建版本**：
   - 直接使用 `public/` 目录下的文件
   - 部署到任何 Web 服务器

### 方法二：从源码构建

1. **安装依赖**：
   ```bash
   npm install -g pnpm
   pnpm install
   ```

2. **开发模式**：
   ```bash
   pnpm dev
   ```

3. **构建生产版本**：
   ```bash
   pnpm build
   ```

## 🔧 在 OpenClash 中使用

1. **备份原版**：
   ```bash
   cp -r /path/to/openclash/yacd /path/to/openclash/yacd_backup
   ```

2. **替换文件**：
   ```bash
   cp -r public/* /path/to/openclash/yacd/
   ```

3. **重启 OpenClash**：
   - 在 OpenClash 管理界面重启服务
   - 清除浏览器缓存

4. **验证功能**：
   - 访问 OpenClash 的 Yacd 界面
   - 点击代理页面顶部的 "+" 按钮测试新功能

## 🎯 功能特色

### 节点添加界面
- **三个标签页**：手动添加、链接导入、文本导入
- **智能表单**：根据节点类型动态显示相关字段
- **实时验证**：输入时进行格式验证
- **批量操作**：支持一次性添加到多个策略组

### 协议解析能力
- **自动识别**：自动识别各种协议格式
- **智能解析**：解析订阅链接和配置文本
- **格式转换**：支持多种配置格式

### 用户体验
- **响应式设计**：适配各种屏幕尺寸
- **主题支持**：支持明暗主题切换
- **国际化**：完整的中文界面
- **错误处理**：友好的错误提示

## 📋 支持的协议格式

### VMess
```
vmess://base64(json)
```

### VLESS
```
vless://uuid@server:port?security=tls&type=ws&path=/path#remarks
```

### Shadowsocks
```
ss://method:password@server:port#remarks
```

### ShadowsocksR
```
ssr://server:port:protocol:method:obfs:password/?remarks=remarks
```

### Trojan
```
trojan://password@server:port?security=tls&sni=example.com#remarks
```

### HTTP/SOCKS5
```
http://username:password@server:port
socks5://username:password@server:port
```

## 🔄 更新日志

### v1.0.0 (2024-01-XX)
- ✨ 新增节点管理功能
- ✨ 支持全协议节点添加
- ✨ 支持订阅链接导入
- ✨ 支持文本配置导入
- ✨ 支持批量添加到策略组
- ✨ 完整的国际化支持
- ✨ 响应式界面设计

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 📄 许可证

基于原项目 MIT 许可证。

## 🙏 致谢

- 基于 [Yacd-meta](https://github.com/MetaCubeX/yacd) 项目
- 感谢所有贡献者的工作

## 📞 联系方式

如有问题或建议，请通过 GitHub Issues 联系。 