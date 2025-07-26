#!/bin/bash

# OpenClash 诊断脚本
# 检查配置和节点状态

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

# 检查 OpenClash 服务状态
check_service() {
    log "检查 OpenClash 服务状态..."
    
    if /etc/init.d/openclash status | grep -q "running"; then
        success "OpenClash 服务正在运行"
    else
        error "OpenClash 服务未运行"
        /etc/init.d/openclash status
    fi
}

# 检查配置文件
check_config() {
    log "检查配置文件..."
    
    if [ -f "/etc/openclash/配置.yaml" ]; then
        success "配置文件存在: /etc/openclash/配置.yaml"
        
        # 检查 Provider 配置
        if grep -q "proxy-providers:" /etc/openclash/配置.yaml; then
            success "找到 proxy-providers 配置"
            echo "Provider 配置:"
            grep -A 10 "proxy-providers:" /etc/openclash/配置.yaml
        else
            error "未找到 proxy-providers 配置"
        fi
        
        # 检查策略组配置
        echo ""
        log "检查策略组配置..."
        if grep -A 5 "use:" /etc/openclash/配置.yaml | grep -q "gfwairport5"; then
            success "策略组已引用 Provider"
        else
            error "策略组未引用 Provider"
        fi
    else
        error "配置文件不存在"
    fi
}

# 检查 Provider 文件
check_provider_files() {
    log "检查 Provider 文件..."
    
    if [ -d "/etc/openclash/proxy_provider" ]; then
        success "Provider 目录存在"
        ls -la /etc/openclash/proxy_provider/
        
        if [ -f "/etc/openclash/proxy_provider/gfwairport5.yaml" ]; then
            success "找到 Provider 文件: gfwairport5.yaml"
            echo "Provider 文件内容预览:"
            head -20 /etc/openclash/proxy_provider/gfwairport5.yaml
        else
            error "未找到 Provider 文件: gfwairport5.yaml"
        fi
    else
        error "Provider 目录不存在"
    fi
}

# 检查 API 连接
check_api() {
    log "检查 API 连接..."
    
    # 获取 secret
    local secret=$(grep "secret:" /etc/openclash/配置.yaml | awk '{print $2}')
    
    if [ -n "$secret" ]; then
        success "找到 secret: $secret"
        
        # 测试 API 连接
        local response=$(curl -s -H "Authorization: Bearer $secret" http://127.0.0.1:9090/configs)
        if echo "$response" | grep -q "proxies"; then
            success "API 连接正常"
            echo "API 响应预览:"
            echo "$response" | head -10
        else
            error "API 连接失败"
            echo "API 响应: $response"
        fi
    else
        error "未找到 secret 配置"
    fi
}

# 检查节点状态
check_proxies() {
    log "检查节点状态..."
    
    local secret=$(grep "secret:" /etc/openclash/配置.yaml | awk '{print $2}')
    
    if [ -n "$secret" ]; then
        # 获取代理列表
        local proxies_response=$(curl -s -H "Authorization: Bearer $secret" http://127.0.0.1:9090/proxies)
        
        if echo "$proxies_response" | grep -q "proxies"; then
            success "获取到代理列表"
            
            # 检查是否有节点
            local proxy_count=$(echo "$proxies_response" | grep -o '"name"' | wc -l)
            echo "找到 $proxy_count 个代理"
            
            # 显示前几个节点
            echo "节点列表预览:"
            echo "$proxies_response" | grep -A 2 '"name"' | head -15
        else
            error "无法获取代理列表"
            echo "响应: $proxies_response"
        fi
    else
        error "无法获取 secret"
    fi
}

# 检查策略组状态
check_proxy_groups() {
    log "检查策略组状态..."
    
    local secret=$(grep "secret:" /etc/openclash/配置.yaml | awk '{print $2}')
    
    if [ -n "$secret" ]; then
        # 获取策略组列表
        local groups_response=$(curl -s -H "Authorization: Bearer $secret" http://127.0.0.1:9090/proxies)
        
        if echo "$groups_response" | grep -q "proxy-groups"; then
            success "获取到策略组列表"
            
            # 显示策略组
            echo "策略组列表:"
            echo "$groups_response" | grep -A 5 '"proxy-groups"' | head -20
        else
            error "无法获取策略组列表"
        fi
    else
        error "无法获取 secret"
    fi
}

# 检查日志
check_logs() {
    log "检查 OpenClash 日志..."
    
    if [ -f "/var/log/openclash.log" ]; then
        echo "最近的日志内容:"
        tail -20 /var/log/openclash.log
    else
        warning "未找到日志文件"
    fi
}

# 显示诊断结果
show_diagnosis() {
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}    OpenClash 诊断完成${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo -e "${BLUE}🔧 常见问题解决方案:${NC}"
    echo -e "  1. 如果 Provider 文件不存在，需要更新订阅"
    echo -e "  2. 如果策略组未引用 Provider，运行修复脚本"
    echo -e "  3. 如果 API 连接失败，检查 secret 配置"
    echo -e "  4. 如果服务未运行，重启 OpenClash"
    echo ""
}

# 主函数
main() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}    OpenClash 诊断脚本${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    
    check_service
    echo ""
    check_config
    echo ""
    check_provider_files
    echo ""
    check_api
    echo ""
    check_proxies
    echo ""
    check_proxy_groups
    echo ""
    check_logs
    echo ""
    show_diagnosis
}

# 运行主函数
main "$@"