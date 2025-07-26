#!/bin/bash

# Yacd-meta 一键部署脚本
# 专门用于部署构建产物

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 配置
YACD_PATH="/usr/share/openclash/ui/yacd"
BACKUP_PATH="/usr/share/openclash/ui/yacd_backup"

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

# 检查是否为 root 用户
check_root() {
    if [ "$EUID" -ne 0 ]; then
        error "请使用 root 用户运行此脚本"
        exit 1
    fi
}

# 检查网络连接
check_network() {
    log "检查网络连接..."
    if ! ping -c 1 github.com > /dev/null 2>&1; then
        error "无法连接到 GitHub，请检查网络连接"
        exit 1
    fi
    success "网络连接正常"
}

# 备份原版 Yacd
backup_original_yacd() {
    log "备份原版 Yacd..."
    if [ -d "$YACD_PATH" ]; then
        if [ -d "$BACKUP_PATH" ]; then
            rm -rf "$BACKUP_PATH"
        fi
        cp -r "$YACD_PATH" "$BACKUP_PATH"
        success "原版 Yacd 已备份到: $BACKUP_PATH"
    else
        warn "原版 Yacd 目录不存在，跳过备份"
    fi
}

# 下载并部署
download_and_deploy() {
    log "下载并部署 Yacd-meta..."
    
    # 创建临时目录
    local temp_dir="/tmp/yacd-enhanced"
    rm -rf "$temp_dir"
    mkdir -p "$temp_dir"
    cd "$temp_dir"
    
    # 下载当前分支（包含构建产物）
    log "下载构建产物..."
    if wget -O yacd-enhanced.zip "https://github.com/kuku0799/yacd-enhanced/archive/refs/heads/dist.zip"; then
        success "下载完成"
    else
        error "下载失败"
        exit 1
    fi
    
    # 解压文件
    log "解压文件..."
    unzip -o yacd-enhanced.zip
    
    # 查找正确的目录
    local extracted_dir=$(find . -name "yacd-enhanced-*" -type d | head -1)
    if [ -z "$extracted_dir" ]; then
        error "解压后未找到正确的目录"
        exit 1
    fi
    
    # 重命名目录为更简单的名称
    local simple_dir="yacd-files"
    if [ -d "$simple_dir" ]; then
        rm -rf "$simple_dir"
    fi
    mv "$extracted_dir" "$simple_dir"
    
    success "文件解压完成: $simple_dir"
    log "解压目录内容:"
    ls -la "$temp_dir/$simple_dir" 2>/dev/null || log "无法列出解压目录内容"
    
    # 检查是否有 index.html
    if [ -f "$temp_dir/$simple_dir/index.html" ]; then
        log "找到 index.html，使用整个目录内容"
        local source_dir="$temp_dir/$simple_dir"
    else
        error "未找到 index.html，部署失败"
        exit 1
    fi
    
    # 部署文件
    deploy_files "$source_dir"
}

# 部署文件
deploy_files() {
    local source_dir="$1"
    
    log "部署 Yacd 文件..."
    log "源目录: $source_dir"
    log "目标目录: $YACD_PATH"
    
    # 检查源目录是否存在
    if [ ! -d "$source_dir" ]; then
        error "源目录不存在: $source_dir"
        exit 1
    fi
    
    # 显示源目录内容
    log "源目录内容:"
    ls -la "$source_dir" 2>/dev/null || log "无法列出源目录内容"
    
    # 清空目标目录
    if [ -d "$YACD_PATH" ]; then
        rm -rf "$YACD_PATH"/*
    else
        mkdir -p "$YACD_PATH"
    fi
    
    # 复制文件
    log "复制文件..."
    if cp -r "$source_dir"/* "$YACD_PATH/" 2>/dev/null; then
        success "文件复制成功"
    else
        error "文件复制失败"
        exit 1
    fi
    
    # 设置权限
    chown -R root:root "$YACD_PATH"
    chmod -R 755 "$YACD_PATH"
    
    success "Yacd 文件部署完成"
}

# 重启 OpenClash
restart_openclash() {
    log "重启 OpenClash..."
    if /etc/init.d/openclash restart; then
        success "OpenClash 重启成功"
    else
        warn "OpenClash 重启失败，请手动重启"
    fi
}

# 显示部署结果
show_deployment_result() {
    echo ""
    echo -e "${PURPLE}========================================${NC}"
    echo -e "${PURPLE}       部署完成！🎉${NC}"
    echo -e "${PURPLE}========================================${NC}"
    echo ""
    echo -e "${CYAN}📁 文件位置:${NC}"
    echo -e "  Yacd-meta: $YACD_PATH"
    echo -e "  备份文件: $BACKUP_PATH"
    echo ""
    echo -e "${CYAN}🌐 访问地址:${NC}"
    echo -e "  Yacd-meta: http://你的路由器IP:9090/ui/yacd/"
    echo ""
    echo -e "${CYAN}✨ 新功能:${NC}"
    echo -e "  ✅ 节点添加功能"
    echo -e "  ✅ 支持所有协议"
    echo -e "  ✅ 订阅链接导入"
    echo -e "  ✅ 自动同步到配置文件"
    echo -e "  ✅ 自动添加到所有策略组"
    echo ""
    echo -e "${GREEN}现在你可以在 Yacd-meta 中正常添加节点了！${NC}"
    echo ""
}

# 清理临时文件
cleanup() {
    log "清理临时文件..."
    rm -rf /tmp/yacd-enhanced
    success "清理完成"
}

# 主函数
main() {
    echo -e "${PURPLE}========================================${NC}"
    echo -e "${PURPLE}    Yacd-meta 一键部署脚本${NC}"
    echo -e "${PURPLE}========================================${NC}"
    echo ""
    
    # 检查环境
    check_root
    check_network
    
    # 备份原版
    backup_original_yacd
    
    # 下载并部署
    download_and_deploy
    
    # 重启服务
    restart_openclash
    
    # 清理
    cleanup
    
    # 显示结果
    show_deployment_result
}

# 运行主函数
main "$@" 