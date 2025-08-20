#!/bin/bash

# Emby UI Beautification Plugin - Service Management Script
# 插件服务管理脚本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[SERVICE]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SERVICE]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[SERVICE]${NC} $1"
}

log_error() {
    echo -e "${RED}[SERVICE]${NC} $1"
}

# 配置变量
PLUGIN_NAME="emby-ui-plugin"
EMBY_CONFIG_PATH="${EMBY_CONFIG_PATH:-/config}"
EMBY_WEB_PATH="${EMBY_WEB_PATH:-/opt/emby-server/system/dashboard-ui}"
PLUGIN_INSTALL_PATH="${EMBY_CONFIG_PATH}/plugins/${PLUGIN_NAME}"
WEB_PLUGIN_PATH="${EMBY_WEB_PATH}/plugins/${PLUGIN_NAME}"
PID_FILE="$PLUGIN_INSTALL_PATH/plugin.pid"
LOG_FILE="$PLUGIN_INSTALL_PATH/logs/service.log"
STATUS_FILE="$PLUGIN_INSTALL_PATH/status.json"

# 创建日志目录
mkdir -p "$(dirname "$LOG_FILE")"

# 日志记录函数
log_to_file() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# 检查插件状态
check_status() {
    local status="stopped"
    local pid=""
    local uptime=""
    local theme="unknown"
    local version="unknown"
    
    # 检查PID文件
    if [[ -f "$PID_FILE" ]]; then
        pid=$(cat "$PID_FILE" 2>/dev/null || echo "")
        if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
            status="running"
            uptime=$(ps -o etime= -p "$pid" 2>/dev/null | tr -d ' ' || echo "unknown")
        else
            # PID文件存在但进程不存在，清理PID文件
            rm -f "$PID_FILE"
        fi
    fi
    
    # 读取配置信息
    if [[ -f "$PLUGIN_INSTALL_PATH/config/runtime.json" ]]; then
        theme=$(grep -o '"currentTheme":\s*"[^"]*"' "$PLUGIN_INSTALL_PATH/config/runtime.json" 2>/dev/null | cut -d'"' -f4 || echo "unknown")
    fi
    
    if [[ -f "$PLUGIN_INSTALL_PATH/plugin-config.json" ]]; then
        version=$(grep -o '"version":\s*"[^"]*"' "$PLUGIN_INSTALL_PATH/plugin-config.json" 2>/dev/null | cut -d'"' -f4 || echo "unknown")
    fi
    
    # 创建状态JSON
    cat > "$STATUS_FILE" << EOF
{
  "status": "$status",
  "pid": "$pid",
  "uptime": "$uptime",
  "version": "$version",
  "currentTheme": "$theme",
  "lastCheck": "$(date -Iseconds)",
  "paths": {
    "install": "$PLUGIN_INSTALL_PATH",
    "web": "$WEB_PLUGIN_PATH",
    "log": "$LOG_FILE"
  }
}
EOF
    
    echo "$status"
}

# 启动插件服务
start_service() {
    log_info "启动插件服务..."
    log_to_file "启动插件服务"
    
    local current_status
    current_status=$(check_status)
    
    if [[ "$current_status" == "running" ]]; then
        log_warning "插件服务已在运行"
        return 0
    fi
    
    # 检查必要文件
    if [[ ! -f "$PLUGIN_INSTALL_PATH/plugin-config.json" ]]; then
        log_error "插件配置文件不存在"
        return 1
    fi
    
    # 启动监控进程
    (
        # 创建监控循环
        while true; do
            # 检查Emby是否运行
            if pgrep -f "EmbyServer" > /dev/null; then
                # 检查插件注入状态
                if [[ -f "$EMBY_WEB_PATH/index.html" ]]; then
                    if ! grep -q "EMBY UI PLUGIN INJECTION" "$EMBY_WEB_PATH/index.html"; then
                        log_warning "检测到插件未注入，重新注入..."
                        log_to_file "重新注入插件"
                        /tmp/emby-ui-plugin/scripts/init-plugin.sh
                    fi
                fi
            fi
            
            # 更新状态
            check_status > /dev/null
            
            # 等待30秒
            sleep 30
        done
    ) &
    
    local monitor_pid=$!
    echo "$monitor_pid" > "$PID_FILE"
    
    log_success "插件服务已启动 (PID: $monitor_pid)"
    log_to_file "插件服务已启动 (PID: $monitor_pid)"
}

# 停止插件服务
stop_service() {
    log_info "停止插件服务..."
    log_to_file "停止插件服务"
    
    if [[ -f "$PID_FILE" ]]; then
        local pid
        pid=$(cat "$PID_FILE")
        
        if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
            kill "$pid"
            
            # 等待进程结束
            local count=0
            while kill -0 "$pid" 2>/dev/null && [[ $count -lt 10 ]]; do
                sleep 1
                count=$((count + 1))
            done
            
            # 强制结束
            if kill -0 "$pid" 2>/dev/null; then
                kill -9 "$pid" 2>/dev/null || true
            fi
            
            log_success "插件服务已停止"
            log_to_file "插件服务已停止"
        else
            log_warning "插件服务未运行"
        fi
        
        rm -f "$PID_FILE"
    else
        log_warning "未找到PID文件，插件服务可能未运行"
    fi
    
    # 更新状态
    check_status > /dev/null
}

# 重启插件服务
restart_service() {
    log_info "重启插件服务..."
    stop_service
    sleep 2
    start_service
}

# 显示服务状态
show_status() {
    local status
    status=$(check_status)
    
    echo "=== Emby UI Plugin Service Status ==="
    echo "Status: $status"
    
    if [[ -f "$STATUS_FILE" ]]; then
        echo "Details:"
        cat "$STATUS_FILE" | jq . 2>/dev/null || cat "$STATUS_FILE"
    fi
    
    echo ""
    echo "=== Recent Logs ==="
    if [[ -f "$LOG_FILE" ]]; then
        tail -10 "$LOG_FILE"
    else
        echo "No logs available"
    fi
}

# 重新加载配置
reload_config() {
    log_info "重新加载配置..."
    log_to_file "重新加载配置"
    
    # 重新运行初始化脚本
    if [[ -f "/tmp/emby-ui-plugin/scripts/init-plugin.sh" ]]; then
        /tmp/emby-ui-plugin/scripts/init-plugin.sh
        log_success "配置重新加载完成"
        log_to_file "配置重新加载完成"
    else
        log_error "初始化脚本不存在"
        return 1
    fi
}

# 清理插件
cleanup() {
    log_info "清理插件..."
    log_to_file "清理插件"
    
    stop_service
    
    # 移除注入代码
    if [[ -f "$EMBY_WEB_PATH/index.html.backup" ]]; then
        mv "$EMBY_WEB_PATH/index.html.backup" "$EMBY_WEB_PATH/index.html"
        log_info "已恢复原始Emby页面"
    fi
    
    # 清理符号链接
    rm -f "$WEB_PLUGIN_PATH/themes"
    rm -f "$WEB_PLUGIN_PATH/js"
    rm -f "$WEB_PLUGIN_PATH/pages"
    
    log_success "插件清理完成"
    log_to_file "插件清理完成"
}

# 显示帮助信息
show_help() {
    echo "Emby UI Plugin Service Manager"
    echo ""
    echo "Usage: $0 {start|stop|restart|status|reload|cleanup|help}"
    echo ""
    echo "Commands:"
    echo "  start    - 启动插件服务"
    echo "  stop     - 停止插件服务"
    echo "  restart  - 重启插件服务"
    echo "  status   - 显示服务状态"
    echo "  reload   - 重新加载配置"
    echo "  cleanup  - 清理插件"
    echo "  help     - 显示此帮助信息"
    echo ""
    echo "Environment Variables:"
    echo "  EMBY_CONFIG_PATH - Emby配置路径 (默认: /config)"
    echo "  EMBY_WEB_PATH    - Emby Web路径 (默认: /opt/emby-server/system/dashboard-ui)"
}

# 主函数
main() {
    case "${1:-}" in
        start)
            start_service
            ;;
        stop)
            stop_service
            ;;
        restart)
            restart_service
            ;;
        status)
            show_status
            ;;
        reload)
            reload_config
            ;;
        cleanup)
            cleanup
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            echo "错误: 未知命令 '$1'"
            echo "使用 '$0 help' 查看可用命令"
            exit 1
            ;;
    esac
}

# 错误处理
trap 'log_error "服务管理过程中发生错误，退出码: $?"' ERR

# 执行主函数
main "$@"