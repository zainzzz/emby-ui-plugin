#!/bin/bash

# Emby UI Beautification Plugin - Initialization Script
# 插件初始化脚本（容器启动时执行）

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INIT]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[INIT]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[INIT]${NC} $1"
}

log_error() {
    echo -e "${RED}[INIT]${NC} $1"
}

# 配置变量
PLUGIN_NAME="emby-ui-plugin"
EMBY_CONFIG_PATH="${EMBY_CONFIG_PATH:-/config}"
EMBY_WEB_PATH="${EMBY_WEB_PATH:-/opt/emby-server/system/dashboard-ui}"
PLUGIN_INSTALL_PATH="${EMBY_CONFIG_PATH}/plugins/${PLUGIN_NAME}"
WEB_PLUGIN_PATH="${EMBY_WEB_PATH}/plugins/${PLUGIN_NAME}"
PLUGIN_ENABLED="${EMBY_UI_PLUGIN_ENABLED:-true}"
PLUGIN_THEME="${EMBY_UI_PLUGIN_THEME:-dark-modern}"
PLUGIN_DEBUG="${EMBY_UI_PLUGIN_DEBUG:-false}"

# 检查插件是否启用
check_plugin_enabled() {
    if [[ "$PLUGIN_ENABLED" != "true" ]]; then
        log_warning "插件已禁用，跳过初始化"
        exit 0
    fi
}

# 等待Emby服务启动
wait_for_emby() {
    log_info "等待Emby服务启动..."
    
    local max_attempts=30
    local attempt=0
    
    while [[ $attempt -lt $max_attempts ]]; do
        if [[ -d "$EMBY_WEB_PATH" ]]; then
            log_success "Emby Web目录已就绪"
            return 0
        fi
        
        attempt=$((attempt + 1))
        log_info "等待中... ($attempt/$max_attempts)"
        sleep 2
    done
    
    log_error "等待Emby服务超时"
    return 1
}

# 检查插件文件
check_plugin_files() {
    log_info "检查插件文件..."
    
    local required_files=(
        "$PLUGIN_INSTALL_PATH/plugin-config.json"
        "$PLUGIN_INSTALL_PATH/theme-config.json"
        "$PLUGIN_INSTALL_PATH/js/emby-enhancer.js"
        "$PLUGIN_INSTALL_PATH/js/config-manager.js"
    )
    
    for file in "${required_files[@]}"; do
        if [[ ! -f "$file" ]]; then
            log_error "缺少必要文件: $file"
            return 1
        fi
    done
    
    log_success "插件文件检查完成"
}

# 创建符号链接
create_symlinks() {
    log_info "创建符号链接..."
    
    # 确保Web插件目录存在
    mkdir -p "$WEB_PLUGIN_PATH"
    
    # 创建到插件文件的符号链接
    if [[ ! -L "$WEB_PLUGIN_PATH/themes" ]]; then
        ln -sf "$PLUGIN_INSTALL_PATH/themes" "$WEB_PLUGIN_PATH/themes"
    fi
    
    if [[ ! -L "$WEB_PLUGIN_PATH/js" ]]; then
        ln -sf "$PLUGIN_INSTALL_PATH/js" "$WEB_PLUGIN_PATH/js"
    fi
    
    if [[ ! -L "$WEB_PLUGIN_PATH/pages" ]]; then
        ln -sf "$PLUGIN_INSTALL_PATH/pages" "$WEB_PLUGIN_PATH/pages"
    fi
    
    log_success "符号链接创建完成"
}

# 注入插件到Emby
inject_plugin() {
    log_info "注入插件到Emby..."
    
    local main_html="$EMBY_WEB_PATH/index.html"
    local injection_marker="<!-- EMBY UI PLUGIN INJECTION -->"
    
    if [[ ! -f "$main_html" ]]; then
        log_error "找不到Emby主页面: $main_html"
        return 1
    fi
    
    # 检查是否已经注入
    if grep -q "$injection_marker" "$main_html"; then
        log_info "插件已经注入，跳过"
        return 0
    fi
    
    # 备份原文件
    cp "$main_html" "$main_html.backup"
    
    # 创建注入代码
    local injection_code="
    $injection_marker
    <script>
        // Emby UI Plugin Auto Loader
        (function() {
            'use strict';
            
            function loadPlugin() {
                try {
                    // 加载配置管理器
                    const configScript = document.createElement('script');
                    configScript.src = '/plugins/emby-ui-plugin/js/config-manager.js';
                    configScript.onload = function() {
                        // 加载主增强器
                        const enhancerScript = document.createElement('script');
                        enhancerScript.src = '/plugins/emby-ui-plugin/js/emby-enhancer.js';
                        enhancerScript.onload = function() {
                            console.log('[Emby UI Plugin] 插件加载完成');
                            
                            // 应用默认主题
                            if (window.EmbyUIPlugin && window.EmbyUIPlugin.changeTheme) {
                                window.EmbyUIPlugin.changeTheme('$PLUGIN_THEME');
                            }
                        };
                        document.head.appendChild(enhancerScript);
                    };
                    document.head.appendChild(configScript);
                } catch (error) {
                    console.error('[Emby UI Plugin] 插件加载失败:', error);
                }
            }
            
            // 等待DOM加载完成
            if (document.readyState === 'loading') {
                document.addEventListener('DOMContentLoaded', loadPlugin);
            } else {
                loadPlugin();
            }
        })();
    </script>
    <!-- END EMBY UI PLUGIN INJECTION -->"
    
    # 在</head>标签前注入代码
    sed -i "s|</head>|$injection_code\n</head>|" "$main_html"
    
    log_success "插件注入完成"
}

# 应用配置
apply_configuration() {
    log_info "应用插件配置..."
    
    local config_file="$PLUGIN_INSTALL_PATH/config/runtime.json"
    
    # 创建运行时配置
    cat > "$config_file" << EOF
{
  "version": "1.0.0",
  "currentTheme": "$PLUGIN_THEME",
  "enableCustomization": true,
  "debugMode": $PLUGIN_DEBUG,
  "autoApply": true,
  "environment": {
    "containerMode": true,
    "embyVersion": "$(cat /opt/emby-server/system/EmbyServer.deps.json 2>/dev/null | grep -o '\"version\":\s*\"[^\"]*\"' | head -1 | cut -d'"' -f4 || echo 'unknown')",
    "pluginPath": "$PLUGIN_INSTALL_PATH",
    "webPath": "$WEB_PLUGIN_PATH"
  },
  "features": {
    "themeSwitch": true,
    "customColors": true,
    "animations": true,
    "responsiveDesign": true
  },
  "performance": {
    "injectDelay": 100,
    "observerThrottle": 50,
    "cssVariablePrefix": "--emby-"
  }
}
EOF
    
    chown abc:abc "$config_file"
    chmod 644 "$config_file"
    
    log_success "配置应用完成"
}

# 设置权限
set_permissions() {
    log_info "设置文件权限..."
    
    # 设置插件目录权限
    chown -R abc:abc "$PLUGIN_INSTALL_PATH"
    chmod -R 755 "$PLUGIN_INSTALL_PATH"
    
    # 设置Web目录权限
    chown -R abc:abc "$WEB_PLUGIN_PATH"
    chmod -R 755 "$WEB_PLUGIN_PATH"
    
    log_success "权限设置完成"
}

# 创建健康检查
create_health_check() {
    log_info "创建健康检查..."
    
    local health_script="$PLUGIN_INSTALL_PATH/health-check.sh"
    
    cat > "$health_script" << 'EOF'
#!/bin/bash
# Emby UI Plugin Health Check

PLUGIN_PATH="/config/plugins/emby-ui-plugin"
WEB_PATH="/opt/emby-server/system/dashboard-ui/plugins/emby-ui-plugin"

# 检查插件文件
if [[ ! -f "$PLUGIN_PATH/plugin-config.json" ]]; then
    echo "UNHEALTHY: Plugin config missing"
    exit 1
fi

# 检查Web文件
if [[ ! -f "$WEB_PATH/js/emby-enhancer.js" ]]; then
    echo "UNHEALTHY: Web files missing"
    exit 1
fi

# 检查权限
if [[ ! -r "$PLUGIN_PATH/themes/dark-modern.css" ]]; then
    echo "UNHEALTHY: Permission issue"
    exit 1
fi

echo "HEALTHY: Plugin is ready"
exit 0
EOF
    
    chmod +x "$health_script"
    chown abc:abc "$health_script"
    
    log_success "健康检查创建完成"
}

# 主初始化函数
main() {
    log_info "开始初始化 Emby UI 美化插件"
    
    check_plugin_enabled
    wait_for_emby
    check_plugin_files
    create_symlinks
    inject_plugin
    apply_configuration
    set_permissions
    create_health_check
    
    log_success "插件初始化完成！"
    log_info "当前主题: $PLUGIN_THEME"
    log_info "调试模式: $PLUGIN_DEBUG"
    log_info "管理页面: http://localhost:8096/plugins/emby-ui-plugin/pages/plugin-manager.html"
}

# 错误处理
trap 'log_error "初始化过程中发生错误，退出码: $?"' ERR

# 执行主函数
main "$@"