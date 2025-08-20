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
        log_error "需要root权限或sudo权限来安装插件"
        exit 1
    fi
    
    # 检查必需的命令
    local required_commands="cp mkdir chmod chown"
    for cmd in $required_commands; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            log_error "缺少必需的命令: $cmd"
            exit 1
        fi
    done
    
    log_success "所有要求检查通过"
}

# 创建目录函数
create_directories() {
    log_info "创建必要的目录..."
    
    local directories=(
        "$PLUGIN_INSTALL_PATH"
        "$WEB_PLUGIN_PATH"
        "$WEB_PLUGIN_PATH/themes"
        "$WEB_PLUGIN_PATH/js"
        "$WEB_PLUGIN_PATH/api"
        "$WEB_PLUGIN_PATH/pages"
    )
    
    for dir in "${directories[@]}"; do
        if [ ! -d "$dir" ]; then
            $SUDO mkdir -p "$dir"
            log_info "创建目录: $dir"
        fi
    done
    
    log_success "目录创建完成"
}

# 复制文件函数
copy_plugin_files() {
    log_info "复制插件文件..."
    
    local current_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local plugin_root="$(dirname "$current_dir")"
    
    # 复制主题文件
    if [ -d "$plugin_root/themes" ]; then
        $SUDO cp -r "$plugin_root/themes/"* "$WEB_PLUGIN_PATH/themes/"
        log_info "复制主题文件"
    fi
    
    # 复制JavaScript文件
    if [ -d "$plugin_root/src/js" ]; then
        $SUDO cp -r "$plugin_root/src/js/"* "$WEB_PLUGIN_PATH/js/"
        log_info "复制JavaScript文件"
    fi
    
    # 复制API文件
    if [ -d "$plugin_root/api" ]; then
        $SUDO cp -r "$plugin_root/api/"* "$WEB_PLUGIN_PATH/api/"
        log_info "复制API文件"
    fi
    
    # 复制页面文件
    if [ -d "$plugin_root/pages" ]; then
        $SUDO cp -r "$plugin_root/pages/"* "$WEB_PLUGIN_PATH/pages/"
        log_info "复制页面文件"
    fi
    
    # 复制配置文件
    if [ -f "$plugin_root/plugin-config.json" ]; then
        $SUDO cp "$plugin_root/plugin-config.json" "$WEB_PLUGIN_PATH/"
        log_info "复制配置文件"
    fi
    
    # 复制package.json
    if [ -f "$plugin_root/package.json" ]; then
        $SUDO cp "$plugin_root/package.json" "$WEB_PLUGIN_PATH/"
        log_info "复制package.json"
    fi
    
    log_success "文件复制完成"
}

# 创建注入脚本
create_injection_script() {
    log_info "创建注入脚本..."
    
    local inject_script="$WEB_PLUGIN_PATH/inject.js"
    
    cat > "$inject_script" << 'EOF'
// Emby UI Plugin Injection Script
(function() {
    'use strict';
    
    // 等待页面加载完成
    function waitForElement(selector, callback) {
        const element = document.querySelector(selector);
        if (element) {
            callback(element);
        } else {
            setTimeout(() => waitForElement(selector, callback), 100);
        }
    }
    
    // 加载CSS主题
    function loadTheme(themeName) {
        const link = document.createElement('link');
        link.rel = 'stylesheet';
        link.href = `/plugins/emby-ui-plugin/themes/${themeName}.css`;
        document.head.appendChild(link);
    }
    
    // 加载JavaScript模块
    function loadScript(scriptPath) {
        const script = document.createElement('script');
        script.src = `/plugins/emby-ui-plugin/js/${scriptPath}`;
        document.head.appendChild(script);
    }
    
    // 初始化插件
    function initPlugin() {
        // 加载默认主题
        loadTheme('default');
        
        // 加载核心脚本
        loadScript('main.js');
        
        console.log('Emby UI Plugin loaded successfully');
    }
    
    // 页面加载完成后初始化
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', initPlugin);
    } else {
        initPlugin();
    }
})();
EOF
    
    $SUDO chmod 644 "$inject_script"
    log_success "注入脚本创建完成"
}

# 更新Emby index.html
update_emby_index() {
    log_info "更新Emby index.html..."
    
    local index_file="$EMBY_WEB_PATH/index.html"
    
    if [ ! -f "$index_file" ]; then
        log_warning "未找到Emby index.html文件: $index_file"
        return
    fi
    
    # 检查是否已经注入
    if grep -q "emby-ui-plugin" "$index_file"; then
        log_info "插件脚本已存在于index.html中"
        return
    fi
    
    # 备份原文件
    $SUDO cp "$index_file" "$index_file.backup"
    
    # 在</head>标签前插入脚本
    $SUDO sed -i 's|</head>|    <script src="/plugins/emby-ui-plugin/inject.js"></script>\n</head>|' "$index_file"
    
    log_success "Emby index.html更新完成"
}

# 创建默认配置
create_default_config() {
    log_info "创建默认配置..."
    
    local config_file="$PLUGIN_INSTALL_PATH/config.json"
    
    if [ ! -f "$config_file" ]; then
        cat > "$config_file" << 'EOF'
{
    "version": "1.0.0",
    "enabled": true,
    "theme": "default",
    "features": {
        "customThemes": true,
        "enhancedUI": true,
        "customPages": true
    },
    "settings": {
        "autoUpdate": false,
        "debugMode": false
    }
}
EOF
        $SUDO chmod 644 "$config_file"
        log_success "默认配置创建完成"
    else
        log_info "配置文件已存在，跳过创建"
    fi
}

# 创建API端点
create_api_endpoints() {
    log_info "创建API端点..."
    
    local api_file="$WEB_PLUGIN_PATH/api/config.php"
    
    cat > "$api_file" << 'EOF'
<?php
// Emby UI Plugin API - Configuration Endpoint

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE');
header('Access-Control-Allow-Headers: Content-Type');

$configFile = '/config/plugins/emby-ui-plugin/config.json';

switch ($_SERVER['REQUEST_METHOD']) {
    case 'GET':
        if (file_exists($configFile)) {
            echo file_get_contents($configFile);
        } else {
            http_response_code(404);
            echo json_encode(['error' => 'Configuration not found']);
        }
        break;
        
    case 'POST':
    case 'PUT':
        $input = json_decode(file_get_contents('php://input'), true);
        if ($input) {
            file_put_contents($configFile, json_encode($input, JSON_PRETTY_PRINT));
            echo json_encode(['success' => true]);
        } else {
            http_response_code(400);
            echo json_encode(['error' => 'Invalid JSON']);
        }
        break;
        
    default:
        http_response_code(405);
        echo json_encode(['error' => 'Method not allowed']);
}
?>
EOF
    
    $SUDO chmod 644 "$api_file"
    log_success "API端点创建完成"
}

# 主安装函数
main() {
    log_info "开始安装Emby UI插件..."
    
    check_requirements
    create_directories
    copy_plugin_files
    create_injection_script
    update_emby_index
    create_default_config
    create_api_endpoints
    
    log_success "\n🎉 Emby UI插件安装完成！"
    log_info "请重启Emby服务器以使更改生效"
    log_info "插件配置文件位于: $PLUGIN_INSTALL_PATH/config.json"
    log_info "Web文件位于: $WEB_PLUGIN_PATH"
}

# 错误处理
trap 'log_error "安装过程中发生错误，请检查日志"; exit 1' ERR

# 执行主函数
main "$@"