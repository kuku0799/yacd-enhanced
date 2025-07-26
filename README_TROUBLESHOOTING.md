# Yacd Enhanced 故障排除指南

## 问题：节点解析成功但在策略组中不显示

### 问题分析

当节点解析成功但在策略组中不显示时，通常有以下几个原因：

1. **Provider 文件缺失**：`/etc/openclash/proxy_provider/gfwairport5.yaml` 文件不存在
2. **策略组配置问题**：策略组没有正确引用 Provider
3. **OpenClash 配置问题**：配置文件可能有问题
4. **服务状态问题**：OpenClash 服务未正常运行

### 解决方案

#### 方案一：使用诊断脚本

```bash
# 下载并运行诊断脚本
wget -O diagnose-openclash.sh https://raw.githubusercontent.com/kuku0799/yacd-enhanced/dist/diagnose-openclash.sh
chmod +x diagnose-openclash.sh
./diagnose-openclash.sh
```

#### 方案二：使用修复脚本

```bash
# 下载并运行修复脚本
wget -O fix-openclash-proxy-groups.sh https://raw.githubusercontent.com/kuku0799/yacd-enhanced/dist/fix-openclash-proxy-groups.sh
chmod +x fix-openclash-proxy-groups.sh
./fix-openclash-proxy-groups.sh
```

#### 方案三：手动修复

1. **检查 Provider 文件**
```bash
ls -la /etc/openclash/proxy_provider/
```

2. **检查配置文件**
```bash
cat /etc/openclash/配置.yaml | grep -A 10 "proxy-providers:"
```

3. **检查策略组配置**
```bash
cat /etc/openclash/配置.yaml | grep -A 20 "proxy-groups:"
```

4. **手动修复策略组**
```bash
# 备份配置文件
cp /etc/openclash/配置.yaml /etc/openclash/配置.yaml.backup

# 编辑配置文件，在策略组中添加 use 字段
vi /etc/openclash/配置.yaml
```

在策略组中添加：
```yaml
proxy-groups:
  - name: "🚀 节点选择"
    type: select
    use:
      - gfwairport5
    proxies:
      - REJECT
      - DIRECT
```

5. **重启 OpenClash**
```bash
/etc/init.d/openclash restart
```

### 常见问题

#### 1. Provider 文件不存在

**症状**：诊断脚本显示 "❌ 未找到 Provider 文件: gfwairport5.yaml"

**解决方案**：
- 检查订阅是否正常更新
- 手动更新订阅
- 检查 OpenClash 的订阅配置

#### 2. 策略组未引用 Provider

**症状**：策略组只显示 REJECT 和 DIRECT，没有节点

**解决方案**：
- 运行修复脚本
- 手动编辑配置文件添加 `use` 字段

#### 3. API 连接失败

**症状**：Yacd 界面显示连接错误

**解决方案**：
- 检查 OpenClash 服务状态
- 确认 secret 配置正确
- 检查防火墙设置

### 验证方法

1. **访问 Yacd 界面**
```
http://192.168.5.1:9090/ui/yacd/
```

2. **检查节点列表**
- 进入 "代理" 页面
- 查看是否有节点显示

3. **检查策略组**
- 进入 "代理" 页面
- 查看策略组是否包含节点

4. **测试节点连接**
- 选择节点进行延迟测试
- 检查是否能正常连接

### 预防措施

1. **定期备份配置**
```bash
cp /etc/openclash/配置.yaml /etc/openclash/配置.yaml.backup.$(date +%Y%m%d)
```

2. **监控服务状态**
```bash
/etc/init.d/openclash status
```

3. **检查日志**
```bash
tail -f /var/log/openclash.log
```

### 联系支持

如果问题仍然存在，请提供以下信息：

1. 诊断脚本的完整输出
2. OpenClash 配置文件内容（隐藏敏感信息）
3. 系统日志信息
4. 错误截图

### 更新日志

- **v1.0.0**: 初始版本，包含基础诊断和修复功能
- **v1.1.0**: 添加了手动修复指南
- **v1.2.0**: 增加了预防措施和验证方法