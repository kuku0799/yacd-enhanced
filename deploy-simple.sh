#!/bin/bash

echo "=========================================="
echo "    Yacd 增强版一键部署脚本"
echo "=========================================="
echo

# 检查是否为 root 用户
if [ "$EUID" -ne 0 ]; then
    echo "[ERROR] 请使用 root 用户运行此脚本"
    exit 1
fi

# 查找 Yacd 路径
echo "[STEP] 查找 OpenClash 安装路径..."

YACD_PATH=""
for path in "/usr/share/openclash/ui/yacd" "/usr/lib/lua/luci/view/openclash/yacd" "/www/luci-static/openclash/yacd"; do
    if [ -d "$path" ]; then
        YACD_PATH="$path"
        echo "[INFO] 找到 Yacd 路径: $YACD_PATH"
        break
    fi
done

if [ -z "$YACD_PATH" ]; then
    echo "[ERROR] 未找到 OpenClash 的 Yacd 目录"
    echo "[INFO] 请确保已安装 OpenClash"
    exit 1
fi

# 备份原版
echo "[STEP] 备份原版 Yacd..."
if [ -d "$YACD_PATH" ]; then
    backup_path="${YACD_PATH}_backup_$(date +%Y%m%d_%H%M%S)"
    cp -r "$YACD_PATH" "$backup_path"
    echo "[INFO] 原版已备份到: $backup_path"
fi

# 下载增强版
echo "[STEP] 下载增强版 Yacd..."
cd /tmp
rm -rf yacd-enhanced-dist dist.zip

if wget -O dist.zip https://github.com/kuku0799/yacd-enhanced/archive/dist.zip; then
    echo "[INFO] 下载完成"
else
    echo "[ERROR] 下载失败"
    exit 1
fi

# 解压文件
echo "[STEP] 解压文件..."
unzip -o dist.zip

if [ ! -d "yacd-enhanced-dist" ]; then
    echo "[ERROR] 解压失败"
    exit 1
fi

# 部署文件
echo "[STEP] 部署增强版文件..."
mkdir -p "$YACD_PATH"
rm -rf "$YACD_PATH"/*
cp -r yacd-enhanced-dist/dist/* "$YACD_PATH/"
chmod -R 755 "$YACD_PATH/"
chown -R root:root "$YACD_PATH/"

# 重启服务
echo "[STEP] 重启相关服务..."
if [ -f /etc/init.d/openclash ]; then
    /etc/init.d/openclash restart
fi

# 清理临时文件
echo "[STEP] 清理临时文件..."
rm -rf yacd-enhanced-dist dist.zip

echo
echo "[SUCCESS] 部署完成！"
echo
echo "使用方法："
echo "1. 访问 OpenClash 管理界面"
echo "2. 进入 Yacd 界面"
echo "3. 点击代理页面顶部的 '+' 按钮"
echo "4. 测试新功能："
echo "   - 添加节点（手动/链接/文本）"
echo "   - 删除节点（指定/全部策略组）"
echo
echo "备份文件位置: $backup_path" 