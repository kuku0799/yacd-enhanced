#!/bin/bash

# Yacd 增强版一键部署脚本
# 支持 OpenWrt/LEDE 系统

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印带颜色的消息
print_message() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# 检查是否为 root 用户
check_root() {
    if [ "$EUID" -ne 0 ]; then
        print_error "请使用 root 用户运行此脚本"
        exit 1
    fi
}

# 检查系统类型
check_system() {
    if [ -f /etc/openwrt_release ]; then
        print_message "检测到 OpenWrt/LEDE 系统"
    else
        print_warning "未检测到 OpenWrt 系统，但脚本将继续执行"
    fi
}

# 安装必要的工具
install_tools() {
    print_step "检查并安装必要的工具..."
    
    # 检查 wget
    if ! command -v wget &> /dev/null; then
        print_message "安装 wget..."
        opkg update
        opkg install wget
    fi
    
    # 检查 unzip
    if ! command -v unzip &> /dev/null; then
        print_message "安装 unzip..."
        opkg update
        opkg install unzip
    fi
    
    print_message "工具检查完成"
}

# 查找 OpenClash 安装路径
find_openclash_path() {
    print_step "查找 OpenClash 安装路径..."
    
    # 常见的 OpenClash 路径
    local paths=(
        "/usr/share/openclash/ui/yacd"
        "/usr/lib/lua/luci/view/openclash/yacd"
        "/www/luci-static/openclash/yacd"
        "/usr/share/luci-app-openclash/yacd"
    )
    
    for path in "${paths[@]}"; do
        if [ -d "$path" ]; then
            YACD_PATH="$path"
            print_message "找到 Yacd 路径: $YACD_PATH"
            return 0
        fi
    done
    
    # 如果没找到，尝试搜索
    local found_path=$(find / -name "yacd" -type d 2>/dev/null | head -1)
    if [ -n "$found_path" ]; then
        YACD_PATH="$found_path"
        print_message "通过搜索找到 Yacd 路径: $YACD_PATH"
        return 0
    fi
    
    print_error "未找到 OpenClash 的 Yacd 目录"
    print_message "请手动指定路径或检查 OpenClash 是否正确安装"
    return 1
}

# 备份原版
backup_original() {
    print_step "备份原版 Yacd..."
    
    if [ -d "$YACD_PATH" ]; then
        local backup_path="${YACD_PATH}_backup_$(date +%Y%m%d_%H%M%S)"
        cp -r "$YACD_PATH" "$backup_path"
        print_message "原版已备份到: $backup_path"
    else
        print_warning "未找到原版 Yacd，跳过备份"
    fi
}

# 下载增强版
download_enhanced() {
    print_step "下载增强版 Yacd..."
    
    cd /tmp
    
    # 清理旧文件
    rm -rf yacd-enhanced-dist dist.zip
    
    # 下载最新版本
    print_message "正在下载增强版..."
    if wget -O dist.zip https://github.com/kuku0799/yacd-enhanced/archive/dist.zip; then
        print_message "下载完成"
    else
        print_error "下载失败，尝试备用链接..."
        if wget -O dist.zip https://github.com/kuku0799/yacd-enhanced/archive/refs/heads/dist.zip; then
            print_message "备用下载完成"
        else
            print_error "所有下载方式都失败了"
            return 1
        fi
    fi
    
    # 解压文件
    print_message "正在解压文件..."
    unzip -o dist.zip
    
    if [ ! -d "yacd-enhanced-dist" ]; then
        print_error "解压失败或目录结构不正确"
        return 1
    fi
    
    print_message "解压完成"
}

# 部署文件
deploy_files() {
    print_step "部署增强版文件..."
    
    # 创建目录（如果不存在）
    mkdir -p "$YACD_PATH"
    
    # 清空原目录
    rm -rf "$YACD_PATH"/*
    
    # 复制新文件
    cp -r /tmp/yacd-enhanced-dist/dist/* "$YACD_PATH/"
    
    # 设置权限
    chmod -R 755 "$YACD_PATH/"
    chown -R root:root "$YACD_PATH/"
    
    print_message "文件部署完成"
}

# 验证部署
verify_deployment() {
    print_step "验证部署..."
    
    local required_files=("index.html" "assets" "manifest.webmanifest" "sw.js")
    local missing_files=()
    
    for file in "${required_files[@]}"; do
        if [ ! -e "$YACD_PATH/$file" ]; then
            missing_files+=("$file")
        fi
    done
    
    if [ ${#missing_files[@]} -eq 0 ]; then
        print_message "部署验证成功"
        return 0
    else
        print_error "部署验证失败，缺少文件: ${missing_files[*]}"
        return 1
    fi
}

# 重启服务
restart_services() {
    print_step "重启相关服务..."
    
    # 重启 OpenClash
    if [ -f /etc/init.d/openclash ]; then
        print_message "重启 OpenClash..."
        /etc/init.d/openclash restart
    fi
    
    # 重启 uhttpd（如果存在）
    if [ -f /etc/init.d/uhttpd ]; then
        print_message "重启 uhttpd..."
        /etc/init.d/uhttpd restart
    fi
    
    # 重启 nginx（如果存在）
    if [ -f /etc/init.d/nginx ]; then
        print_message "重启 nginx..."
        /etc/init.d/nginx restart
    fi
    
    print_message "服务重启完成"
}

# 清理临时文件
cleanup() {
    print_step "清理临时文件..."
    
    cd /tmp
    rm -rf yacd-enhanced-dist dist.zip
    
    print_message "清理完成"
}

# 显示使用说明
show_usage() {
    print_message "部署完成！"
    echo
    echo "使用方法："
    echo "1. 访问 OpenClash 管理界面"
    echo "2. 进入 Yacd 界面"
    echo "3. 点击代理页面顶部的 '+' 按钮"
    echo "4. 测试新功能："
    echo "   - 添加节点（手动/链接/文本）"
    echo "   - 删除节点（指定/全部策略组）"
    echo
    echo "如果遇到问题，请检查："
    echo "- OpenClash 是否正确安装"
    echo "- 网络连接是否正常"
    echo "- 浏览器缓存是否已清理"
    echo
    echo "备份文件位置: ${YACD_PATH}_backup_*"
}

# 主函数
main() {
    echo "=========================================="
    echo "    Yacd 增强版一键部署脚本"
    echo "=========================================="
    echo
    
    # 检查环境
    check_root
    check_system
    install_tools
    
    # 查找路径
    if ! find_openclash_path; then
        print_error "无法找到 OpenClash 路径，请手动安装 OpenClash"
        exit 1
    fi
    
    # 执行部署
    backup_original
    download_enhanced
    deploy_files
    
    # 验证部署
    if verify_deployment; then
        restart_services
        cleanup
        show_usage
        print_message "部署成功完成！"
    else
        print_error "部署验证失败，请检查错误信息"
        exit 1
    fi
}

# 处理命令行参数
case "${1:-}" in
    --help|-h)
        echo "Yacd 增强版一键部署脚本"
        echo
        echo "用法: $0 [选项]"
        echo
        echo "选项:"
        echo "  --help, -h    显示此帮助信息"
        echo "  --path PATH   指定 Yacd 安装路径"
        echo
        echo "示例:"
        echo "  $0                    # 自动查找路径并部署"
        echo "  $0 --path /custom/path # 指定路径部署"
        exit 0
        ;;
    --path)
        if [ -n "${2:-}" ]; then
            YACD_PATH="$2"
            print_message "使用指定路径: $YACD_PATH"
            shift 2
        else
            print_error "请指定路径"
            exit 1
        fi
        ;;
esac

# 运行主函数
main "$@" 