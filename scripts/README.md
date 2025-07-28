# OpenClash 节点管理脚本

这个目录包含了从外部项目集成的OpenClash节点管理脚本，提供完整的节点解析、注入和监控功能。

## 文件说明

### 核心脚本
- `jx.py` - 节点解析器，支持SS、VMess、VLESS、Trojan协议
- `zw.py` - 节点注入器，将解析的节点注入OpenClash配置
- `zc.py` - 策略组注入器，自动识别现有策略组并注入节点
- `zr.py` - 主控制器，协调整个更新流程
- `log.py` - 统一日志系统
- `jk.sh` - 守护进程脚本，监控文件变化

### 功能特性

#### 节点解析 (`jx.py`)
- 支持多种代理协议：SS、VMess、VLESS、Trojan
- 自动提取节点名称和配置信息
- 智能处理Base64编码和URL解析
- 详细的错误日志记录

#### 节点注入 (`zw.py`)
- 将解析的节点安全注入OpenClash配置
- 防止重复节点和非法节点名
- 保持现有配置结构不变
- 提供详细的注入统计信息

#### 策略组管理 (`zc.py`)
- 自动识别现有策略组并注入节点
- 智能跳过特殊策略组（DIRECT、REJECT、GLOBAL、PROXY）
- 保持REJECT和DIRECT规则优先级
- 支持自定义策略组配置
- 详细的注入日志记录

#### 主控制器 (`zr.py`)
- MD5文件变化检测
- 配置验证和备份
- 自动重启OpenClash服务
- 错误回滚机制

#### 守护进程 (`jk.sh`)
- 实时文件监控
- 防止多进程冲突
- 自动错误恢复
- 详细的运行日志

## 使用方法

### 1. 环境准备
```bash
# 确保Python3环境已安装
python3 --version

# 安装依赖
pip install ruamel.yaml

# 设置执行权限
chmod +x scripts/*.sh
chmod +x scripts/*.py
```

### 2. 配置路径
默认配置路径：
- 节点文件：`/root/OpenClashManage/wangluo/nodes.txt`
- 配置文件：`/etc/openclash/config.yaml`
- 日志文件：`/root/OpenClashManage/wangluo/log.txt`

### 3. 运行方式

#### 手动运行
```bash
# 直接执行主脚本
python3 scripts/zr.py

# 或启动守护进程
bash scripts/jk.sh
```

#### 通过Web界面
在Yacd-meta-master的监控面板中，可以通过OpenClash监控组件来管理节点更新。

### 4. 日志查看
```bash
# 查看实时日志
tail -f /root/OpenClashManage/wangluo/log.txt

# 查看系统日志
logread | grep openclash
```

## 策略组注入说明

脚本会自动识别OpenClash配置文件中的现有策略组，并将解析的节点注入到这些策略组中：

- **自动识别**：扫描所有现有的proxy-groups
- **智能过滤**：跳过DIRECT、REJECT、GLOBAL、PROXY等特殊策略组
- **保持规则**：保留原有的REJECT和DIRECT规则优先级
- **节点去重**：避免重复添加相同节点
- **详细日志**：记录每个策略组的注入情况

## 注意事项

1. **权限要求**：脚本需要读写OpenClash配置文件的权限
2. **路径配置**：确保所有路径配置正确且文件存在
3. **依赖检查**：确保Python3和ruamel.yaml已正确安装
4. **备份机制**：脚本会自动备份配置文件，建议定期手动备份
5. **错误处理**：如遇到配置错误，会自动回滚到备份配置
6. **策略组配置**：确保OpenClash配置中有有效的策略组定义

## 故障排除

### 常见问题
1. **权限错误**：检查文件权限和用户权限
2. **路径错误**：确认所有路径配置正确
3. **依赖缺失**：安装所需的Python包
4. **配置冲突**：检查OpenClash配置文件格式
5. **策略组为空**：确保配置文件中定义了有效的策略组

### 调试方法
1. 查看详细日志：`tail -f /root/OpenClashManage/wangluo/log.txt`
2. 手动测试：`python3 scripts/zr.py`
3. 检查配置：`/etc/init.d/openclash verify_config`
4. 重启服务：`/etc/init.d/openclash restart` 