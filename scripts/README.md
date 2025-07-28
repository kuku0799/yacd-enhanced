# OpenClash 节点管理脚本

这个目录包含了从外部项目集成的OpenClash节点管理脚本。

## 文件说明

- `jx.py` - 节点解析器，支持SS、VMess、VLESS、Trojan协议
- `zw.py` - 节点注入器，将解析的节点注入OpenClash配置
- `zc.py` - 策略组注入器，自动生成手机002-254的策略组
- `zr.py` - 主控制器，协调整个更新流程
- `log.py` - 日志系统
- `jk.sh` - 守护进程脚本

## 使用方法

1. 确保Python3环境已安装
2. 安装依赖：`pip install ruamel.yaml`
3. 配置节点文件路径
4. 运行主脚本：`python3 zr.py` 