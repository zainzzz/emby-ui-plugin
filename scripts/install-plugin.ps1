# Emby UI Beautification Plugin - PowerShell Installation Script
# 插件安装脚本 (Windows)

param(
    [string]$EmbyPath = "C:\ProgramData\Emby-Server",
    [string]$PluginPath = (Split-Path -Parent $PSScriptRoot),
    [switch]$Force,
    [switch]$Help
)

# 显示帮助信息
if ($Help) {
    Write-Host @"
Emby UI Plugin Installation Script

参数:
  -EmbyPath     Emby服务器安装路径 (默认: C:\ProgramData\Emby-Server)
  -PluginPath   插件源代码路径 (默认: 脚本所在目录的父目录)
  -Force        强制覆盖现有文件
  -Help         显示此帮助信息

示例:
  .\install-plugin.ps1
  .\install-plugin.ps1 -EmbyPath "D:\Emby" -Force
"@
    exit 0
}

# 颜色输出函数
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

# 检查管理员权限
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# 创建目录（如果不存在）
function New-DirectoryIfNotExists {
    param([string]$Path)
    if (-not (Test-Path $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
        Write-ColorOutput "✓ 创建目录: $Path" "Green"
    }
}

# 安全复制文件
function Copy-FilesSafely {
    param(
        [string]$Source,
        [string]$Destination,
        [string]$Description
    )
    
    try {
        if (Test-Path $Source) {
            New-DirectoryIfNotExists (Split-Path $Destination -Parent)
            Copy-Item -Path $Source -Destination $Destination -Recurse -Force
            Write-ColorOutput "✓ 复制 $Description" "Green"
            return $true
        } else {
            Write-ColorOutput "⚠ 源路径不存在: $Source" "Yellow"
            return $false
        }
    } catch {
        Write-ColorOutput "✗ 复制 $Description 失败: $($_.Exception.Message)" "Red"
        return $false
    }
}

# 创建注入脚本
function New-InjectionScript {
    param([string]$PluginWebPath)
    
    $injectScript = @'
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
'@
    
    $injectPath = Join-Path $PluginWebPath "inject.js"
    $injectScript | Out-File -FilePath $injectPath -Encoding UTF8
    Write-ColorOutput "✓ 创建注入脚本" "Green"
}

# 更新Emby index.html
function Update-EmbyIndexHtml {
    param(
        [string]$EmbyWebPath,
        [string]$PluginName
    )
    
    $indexPath = Join-Path $EmbyWebPath "index.html"
    
    if (-not (Test-Path $indexPath)) {
        Write-ColorOutput "⚠ 未找到 Emby index.html: $indexPath" "Yellow"
        return $false
    }
    
    try {
        $content = Get-Content $indexPath -Raw
        
        # 检查是否已经注入
        if ($content -match "emby-ui-plugin") {
            Write-ColorOutput "✓ 插件脚本已存在于 index.html" "Green"
            return $true
        }
        
        # 备份原文件
        Copy-Item $indexPath "$indexPath.backup" -Force
        
        # 在</head>前插入脚本
        $scriptTag = '    <script src="/plugins/emby-ui-plugin/inject.js"></script>'
        $newContent = $content -replace '</head>', "$scriptTag`n</head>"
        
        $newContent | Out-File -FilePath $indexPath -Encoding UTF8
        Write-ColorOutput "✓ 更新 Emby index.html" "Green"
        return $true
    } catch {
        Write-ColorOutput "✗ 更新 index.html 失败: $($_.Exception.Message)" "Red"
        return $false
    }
}

# 创建默认配置
function New-DefaultConfig {
    param([string]$ConfigPath)
    
    $configFile = Join-Path $ConfigPath "config.json"
    
    if (-not (Test-Path $configFile) -or $Force) {
        $config = @{
            version = "1.0.0"
            enabled = $true
            theme = "default"
            features = @{
                customThemes = $true
                enhancedUI = $true
                customPages = $true
            }
            settings = @{
                autoUpdate = $false
                debugMode = $false
            }
        } | ConvertTo-Json -Depth 3
        
        $config | Out-File -FilePath $configFile -Encoding UTF8
        Write-ColorOutput "✓ 创建默认配置" "Green"
    } else {
        Write-ColorOutput "✓ 配置文件已存在" "Green"
    }
}

# 创建API端点
function New-ApiEndpoints {
    param([string]$ApiPath)
    
    $configApi = @'
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
'@
    
    $apiFile = Join-Path $ApiPath "config.php"
    $configApi | Out-File -FilePath $apiFile -Encoding UTF8
    Write-ColorOutput "✓ 创建API端点" "Green"
}

# 主安装函数
function Install-EmbyUIPlugin {
    Write-ColorOutput "\n🚀 开始安装 Emby UI 插件..." "Cyan"
    
    # 检查管理员权限
    if (-not (Test-Administrator)) {
        Write-ColorOutput "\n⚠ 警告: 未以管理员身份运行，可能无法完成某些操作" "Yellow"
    }
    
    # 验证路径
    if (-not (Test-Path $EmbyPath)) {
        Write-ColorOutput "\n✗ 未找到 Emby 安装路径: $EmbyPath" "Red"
        Write-ColorOutput "请使用 -EmbyPath 参数指定正确的路径" "Yellow"
        exit 1
    }
    
    if (-not (Test-Path $PluginPath)) {
        Write-ColorOutput "\n✗ 未找到插件源代码路径: $PluginPath" "Red"
        exit 1
    }
    
    # 定义路径
    $embyWebPath = Join-Path $EmbyPath "system\dashboard-ui"
    $pluginWebPath = Join-Path $embyWebPath "plugins\emby-ui-plugin"
    $configPath = Join-Path $EmbyPath "config\plugins\emby-ui-plugin"
    
    Write-ColorOutput "\n📁 安装路径:" "Cyan"
    Write-ColorOutput "  Emby: $EmbyPath" "Gray"
    Write-ColorOutput "  插件源码: $PluginPath" "Gray"
    Write-ColorOutput "  Web插件: $pluginWebPath" "Gray"
    Write-ColorOutput "  配置: $configPath" "Gray"
    
    # 创建目录
    Write-ColorOutput "\n📂 创建目录..." "Cyan"
    New-DirectoryIfNotExists $pluginWebPath
    New-DirectoryIfNotExists (Join-Path $pluginWebPath "themes")
    New-DirectoryIfNotExists (Join-Path $pluginWebPath "js")
    New-DirectoryIfNotExists (Join-Path $pluginWebPath "api")
    New-DirectoryIfNotExists (Join-Path $pluginWebPath "pages")
    New-DirectoryIfNotExists $configPath
    
    # 复制文件
    Write-ColorOutput "\n📋 复制插件文件..." "Cyan"
    $success = $true
    
    # Copy themes
    $success = $success -and (Copy-FilesSafely "$PluginPath\themes\*" "$pluginWebPath\themes" "Theme files")
    
    # Copy JavaScript files
    $success = $success -and (Copy-FilesSafely "$PluginPath\src\js\*" "$pluginWebPath\js" "JavaScript files")
    
    # Copy API files
    $success = $success -and (Copy-FilesSafely "$PluginPath\api\*" "$pluginWebPath\api" "API files")
    
    # Copy page files
    $success = $success -and (Copy-FilesSafely "$PluginPath\pages\*" "$pluginWebPath\pages" "Page files")
    
    # Copy configuration files
    $success = $success -and (Copy-FilesSafely "$PluginPath\*.json" $pluginWebPath "Configuration files")
    
    if (-not $success) {
        Write-ColorOutput "\n✗ Installation failed due to file copy errors" "Red"
        exit 1
    }
    
    # 创建注入脚本
    Write-ColorOutput "\n⚙️ 配置插件..." "Cyan"
    New-InjectionScript $pluginWebPath
    
    # 更新Emby index.html
    Update-EmbyIndexHtml $embyWebPath "emby-ui-plugin"
    
    # 创建配置和API
    New-DefaultConfig $configPath
    New-ApiEndpoints (Join-Path $pluginWebPath "api")
    
    Write-ColorOutput "\n🎉 Emby UI 插件安装完成！" "Green"
    Write-ColorOutput "\n📋 安装摘要:" "Cyan"
    Write-ColorOutput "  ✓ 插件文件已复制到: $pluginWebPath" "Green"
    Write-ColorOutput "  ✓ 配置文件已创建: $configPath\config.json" "Green"
    Write-ColorOutput "  ✓ API端点已配置" "Green"
    Write-ColorOutput "  ✓ Emby index.html 已更新" "Green"
    
    Write-ColorOutput "\n🔄 请重启 Emby 服务器以使更改生效" "Yellow"
    Write-ColorOutput "\n🌐 访问 Emby Web 界面查看新的 UI 增强功能" "Cyan"
}

# 错误处理
trap {
    Write-ColorOutput "\n✗ 安装过程中发生错误: $($_.Exception.Message)" "Red"
    exit 1
}

# 执行安装
Install-EmbyUIPlugin