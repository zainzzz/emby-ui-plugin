#!/bin/bash

# Emby UI Beautification Plugin - Installation Script
# 插件安装脚本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 配置变量
PLUGIN_NAME="emby-ui-plugin"
PLUGIN_VERSION="${EMBY_UI_PLUGIN_VERSION:-1.0.0}"
EMBY_CONFIG_PATH="${EMBY_CONFIG_PATH:-/config}"
EMBY_WEB_PATH="${EMBY_WEB_PATH:-/opt/emby-server/system/dashboard-ui}"
PLUGIN_SOURCE_PATH="/tmp/emby-ui-plugin"
PLUGIN_INSTALL_PATH="${EMBY_CONFIG_PATH}/plugins/${PLUGIN_NAME}"
WEB_PLUGIN_PATH="${EMBY_WEB_PATH}/plugins/${PLUGIN_NAME}"

# 检查函数
check_requirements() {
    log_info "检查安装要求..."
    
    # 检查是否为root用户或具有sudo权限
    if [[ $EUID -eq 0 ]]; then
        log_info "以root用户运行"
    elif command -v sudo >/dev/null 2>&1; then
        log_info "检测到sudo，将使用sudo执行特权操作"
        SUDO="sudo"
    else
        log_error "需要root权限或sudo来安装插件"
        exit 1
    fi
    
    # 检查必要的命令
    local required_commands=("cp" "mkdir" "chmod" "chown")
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            log_error "缺少必要命令: $cmd"
            exit 1
        fi
    done
    
    log_success "要求检查完成"
}

# 创建目录
create_directories() {
    log_info "创建插件目录..."
    
    # 创建插件配置目录
    $SUDO mkdir -p "$PLUGIN_INSTALL_PATH"
    $SUDO mkdir -p "$PLUGIN_INSTALL_PATH/themes"
    $SUDO mkdir -p "$PLUGIN_INSTALL_PATH/js"
    $SUDO mkdir -p "$PLUGIN_INSTALL_PATH/pages"
    $SUDO mkdir -p "$PLUGIN_INSTALL_PATH/config"
    $SUDO mkdir -p "$PLUGIN_INSTALL_PATH/logs"
    
    # 创建Web插件目录
    $SUDO mkdir -p "$WEB_PLUGIN_PATH"
    
    log_success "目录创建完成"
}

# 复制插件文件
copy_plugin_files() {
    log_info "复制插件文件..."
    
    if [[ ! -d "$PLUGIN_SOURCE_PATH" ]]; then
        log_error "插件源目录不存在: $PLUGIN_SOURCE_PATH"
        exit 1
    fi
    
    # 复制主要文件
    $SUDO cp -r "$PLUGIN_SOURCE_PATH/themes/" "$PLUGIN_INSTALL_PATH/"
    $SUDO cp -r "$PLUGIN_SOURCE_PATH/js/" "$PLUGIN_INSTALL_PATH/"
    $SUDO cp -r "$PLUGIN_SOURCE_PATH/pages/" "$PLUGIN_INSTALL_PATH/"
    
    # 复制配置文件
    $SUDO cp "$PLUGIN_SOURCE_PATH/plugin-config.json" "$PLUGIN_INSTALL_PATH/"
    $SUDO cp "$PLUGIN_SOURCE_PATH/theme-config.json" "$PLUGIN_INSTALL_PATH/"
    
    # 复制到Web目录（用于Web访问）
    $SUDO cp -r "$PLUGIN_SOURCE_PATH/themes/" "$WEB_PLUGIN_PATH/"
    $SUDO cp -r "$PLUGIN_SOURCE_PATH/js/" "$WEB_PLUGIN_PATH/"
    $SUDO cp -r "$PLUGIN_SOURCE_PATH/pages/" "$WEB_PLUGIN_PATH/"
    
    log_success "文件复制完成"
}

# 设置权限
set_permissions() {
    log_info "设置文件权限..."
    
    # 设置插件目录权限
    $SUDO chown -R abc:abc "$PLUGIN_INSTALL_PATH"
    $SUDO chmod -R 755 "$PLUGIN_INSTALL_PATH"
    
    # 设置Web目录权限
    $SUDO chown -R abc:abc "$WEB_PLUGIN_PATH"
    $SUDO chmod -R 755 "$WEB_PLUGIN_PATH"
    
    # 设置配置文件权限
    $SUDO chmod 644 "$PLUGIN_INSTALL_PATH/plugin-config.json"
    $SUDO chmod 644 "$PLUGIN_INSTALL_PATH/theme-config.json"
    
    log_success "权限设置完成"
}

# 创建插件注入脚本
create_injection_script() {
    log_info "创建插件注入脚本..."
    
    local injection_script="$PLUGIN_INSTALL_PATH/inject.js"
    
    cat > "$injection_script" << 'EOF'
// Emby UI Plugin - Auto Injection Script
// 自动注入脚本

(function() {
    'use strict';
    
    // 等待页面加载完成
    function waitForEmby() {
        if (typeof window !== 'undefined' && document.readyState === 'complete') {
            injectPlugin();
        } else {
            setTimeout(waitForEmby, 100);
        }
    }
    
    // 注入插件
    function injectPlugin() {
        try {
            // 加载配置管理器
            loadScript('/plugins/emby-ui-plugin/js/config-manager.js', function() {
                // 加载主增强器
                loadScript('/plugins/emby-ui-plugin/js/emby-enhancer.js', function() {
                    console.log('[Emby UI Plugin] 插件加载完成');
                });
            });
        } catch (error) {
            console.error('[Emby UI Plugin] 插件加载失败:', error);
        }
    }
    
    // 动态加载脚本
    function loadScript(src, callback) {
        const script = document.createElement('script');
        script.src = src;
        script.onload = callback;
        script.onerror = function() {
            console.error('[Emby UI Plugin] 脚本加载失败:', src);
        };
        document.head.appendChild(script);
    }
    
    // 开始等待
    waitForEmby();
})();
EOF
    
    $SUDO chown abc:abc "$injection_script"
    $SUDO chmod 644 "$injection_script"
    
    log_success "注入脚本创建完成"
}

# 创建默认配置
create_default_config() {
    log_info "创建默认配置..."
    
    local config_file="$PLUGIN_INSTALL_PATH/config/default.json"
    
    cat > "$config_file" << 'EOF'
{
  "version": "1.0.0",
  "currentTheme": "dark-modern",
  "enableCustomization": true,
  "debugMode": false,
  "autoApply": true,
  "customColors": {},
  "userPreferences": {
    "animationSpeed": "normal",
    "borderRadius": "medium",
    "cardSpacing": "normal"
  },
  "advanced": {
    "injectDelay": 100,
    "observerThrottle": 50,
    "cssVariablePrefix": "--emby-"
  }
}
EOF
    
    $SUDO chown abc:abc "$config_file"
    $SUDO chmod 644 "$config_file"
    
    log_success "默认配置创建完成"
}

# 创建API端点
create_api_endpoints() {
    log_info "创建API端点..."
    
    local api_dir="$WEB_PLUGIN_PATH/api"
    $SUDO mkdir -p "$api_dir"
    
    # 创建配置API
    cat > "$api_dir/config.php" << 'EOF'
<?php
// Emby UI Plugin - Configuration API
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

$configFile = '/config/plugins/emby-ui-plugin/config/user.json';
$defaultConfigFile = '/config/plugins/emby-ui-plugin/config/default.json';

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    // 读取配置
    if (file_exists($configFile)) {
        echo file_get_contents($configFile);
    } elseif (file_exists($defaultConfigFile)) {
        echo file_get_contents($defaultConfigFile);
    } else {
        echo json_encode(['error' => 'Configuration not found']);
    }
} elseif ($_SERVER['REQUEST_METHOD'] === 'POST') {
    // 保存配置
    $input = file_get_contents('php://input');
    $config = json_decode($input, true);
    
    if ($config) {
        if (file_put_contents($configFile, json_encode($config, JSON_PRETTY_PRINT))) {
            echo json_encode(['success' => true]);
        } else {
            echo json_encode(['error' => 'Failed to save configuration']);
        }
    } else {
        echo json_encode(['error' => 'Invalid JSON']);
    }
}
?>
EOF
    
    $SUDO chown abc:abc "$api_dir/config.php"
    $SUDO chmod 644 "$api_dir/config.php"
    
    log_success "API端点创建完成"
}

# 主安装函数
main() {
    log_info "开始安装 Emby UI 美化插件 v$PLUGIN_VERSION"
    
    check_requirements
    create_directories
    copy_plugin_files
    set_permissions
    create_injection_script
    create_default_config
    create_api_endpoints
    
    log_success "插件安装完成！"
    log_info "插件安装路径: $PLUGIN_INSTALL_PATH"
    log_info "Web访问路径: $WEB_PLUGIN_PATH"
    log_info "管理页面: http://your-emby-server:8096/plugins/emby-ui-plugin/pages/plugin-manager.html"
    log_warning "请重启 Emby 服务器以使插件生效"
}

# 错误处理
trap 'log_error "安装过程中发生错误，退出码: $?"' ERR

# 执行主函数
main "$@"