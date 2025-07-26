#!/bin/bash

# OpenClash 策略组一键修复脚本
# 修复策略组配置，使其正确引用 Provider

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
}

# 检查配置文件
check_config() {
    log "检查配置文件..."
    
    if [ ! -f "/etc/openclash/配置.yaml" ]; then
        error "配置文件不存在: /etc/openclash/配置.yaml"
        exit 1
    fi
    
    success "配置文件存在"
}

# 备份配置文件
backup_config() {
    log "备份原配置文件..."
    
    local backup_file="/etc/openclash/配置.yaml.backup.$(date +%Y%m%d_%H%M%S)"
    cp /etc/openclash/配置.yaml "$backup_file"
    
    success "配置文件已备份到: $backup_file"
}

# 检查 Provider 配置
check_providers() {
    log "检查 Provider 配置..."
    
    if grep -q "proxy-providers:" /etc/openclash/配置.yaml; then
        local provider_name=$(grep -A 5 "proxy-providers:" /etc/openclash/配置.yaml | grep -v "proxy-providers:" | grep -v "^--" | head -1 | sed 's/^[[:space:]]*//')
        if [ -n "$provider_name" ]; then
            success "找到 Provider: $provider_name"
            echo "$provider_name"
        else
            error "未找到有效的 Provider 名称"
            exit 1
        fi
    else
        error "未找到 proxy-providers 配置"
        exit 1
    fi
}

# 修复策略组配置
fix_proxy_groups() {
    local provider_name="$1"
    log "修复策略组配置，使用 Provider: $provider_name"
    
    # 创建临时文件
    local temp_file="/tmp/openclash_config_temp.yaml"
    cp /etc/openclash/配置.yaml "$temp_file"
    
    # 使用 awk 修复策略组配置
    awk -v provider="$provider_name" '
    BEGIN { in_proxy_groups = 0; in_group = 0; added_use = 0 }
    /^proxy-groups:/ { in_proxy_groups = 1; print; next }
    /^[^[:space:]]/ { 
        if (in_proxy_groups) { 
            in_proxy_groups = 0 
        }
        if (in_group) {
            in_group = 0
            added_use = 0
        }
        print
        next
    }
    in_proxy_groups && /^[[:space:]]*- name:/ { 
        in_group = 1
        added_use = 0
        print
        next
    }
    in_group && /^[[:space:]]*type: select/ { 
        print
        next
    }
    in_group && /^[[:space:]]*proxies:/ && !added_use { 
        print "  use:"
        print "  - " provider
        added_use = 1
        print
        next
    }
    { print }
    ' "$temp_file" > /etc/openclash/配置.yaml
    
    success "策略组配置已修复"
}

# 验证修复结果
verify_fix() {
    log "验证修复结果..."
    
    # 检查是否有策略组包含 use 字段
    if grep -A 2 "use:" /etc/openclash/配置.yaml | grep -q "gfwairport5"; then
        success "策略组已正确引用 Provider"
    else
        error "策略组修复失败"
        exit 1
    fi
}

# 重启 OpenClash 服务
restart_openclash() {
    log "重启 OpenClash 服务..."
    
    /etc/init.d/openclash stop
    sleep 2
    /etc/init.d/openclash start
    
    # 等待服务启动
    sleep 5
    
    if /etc/init.d/openclash status | grep -q "running"; then
        success "OpenClash 服务已重启"
    else
        error "OpenClash 服务启动失败"
        exit 1
    fi
}

# 测试 API 连接
test_api() {
    log "测试 API 连接..."
    
    # 获取 secret
    local secret=$(grep "secret:" /etc/openclash/配置.yaml | awk '{print $2}')
    
    if [ -n "$secret" ]; then
        local response=$(curl -s -H "Authorization: Bearer $secret" http://127.0.0.1:9090/configs)
        if echo "$response" | grep -q "proxies"; then
            success "API 连接正常"
        else
            warning "API 连接可能有问题，但服务已启动"
        fi
    else
        warning "未找到 secret 配置"
    fi
}

# 显示修复结果
show_result() {
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}    OpenClash 策略组修复完成！🎉${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo -e "${BLUE}📋 修复内容:${NC}"
    echo -e "  ✅ 策略组已引用 Provider 节点"
    echo -e "  ✅ OpenClash 服务已重启"
    echo -e "  ✅ 配置文件已备份"
    echo ""
    echo -e "${BLUE}🌐 访问地址:${NC}"
    echo -e "  Yacd Enhanced: http://192.168.5.1:9090/ui/yacd/"
    echo ""
    echo -e "${BLUE}🔧 验证方法:${NC}"
    echo -e "  1. 访问 Yacd 界面"
    echo -e "  2. 查看策略组是否显示节点"
    echo -e "  3. 测试节点连接"
    echo ""
    echo -e "${YELLOW}⚠️  如果仍有问题，请检查:${NC}"
    echo -e "  - Provider 文件是否存在: /etc/openclash/proxy_provider/"
    echo -e "  - 节点订阅是否正常"
    echo -e "  - 网络连接是否正常"
    echo ""
}

# 主函数
main() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}    OpenClash 策略组一键修复脚本${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    
    # 检查是否为 root 用户
    if [ "$(id -u)" != "0" ]; then
        error "请使用 root 用户运行此脚本"
        exit 1
    fi
    
    # 执行修复步骤
    check_config
    backup_config
    provider_name=$(check_providers)
    fix_proxy_groups "$provider_name"
    verify_fix
    restart_openclash
    test_api
    show_result
}

# 运行主函数
main "$@"