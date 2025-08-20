<?php
/**
 * Emby UI Plugin Configuration API
 * 处理插件配置的读取、保存和管理
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// 处理预检请求
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// 配置文件路径
$configDir = '/config/emby-ui-plugin';
$configFile = $configDir . '/config.json';
$backupDir = $configDir . '/backups';

// 确保配置目录存在
if (!is_dir($configDir)) {
    mkdir($configDir, 0755, true);
}

if (!is_dir($backupDir)) {
    mkdir($backupDir, 0755, true);
}

// 默认配置
$defaultConfig = [
    'enabled' => true,
    'autoApply' => true,
    'debugMode' => false,
    'defaultTheme' => 'dark-modern',
    'customization' => [
        'allowUserCustomization' => true,
        'allowThemeSwitching' => true,
        'allowColorCustomization' => true
    ],
    'themes' => [
        'dark-modern' => [
            'enabled' => true,
            'customColors' => []
        ],
        'light-elegant' => [
            'enabled' => true,
            'customColors' => []
        ]
    ],
    'performance' => [
        'injectDelay' => 100,
        'observerThrottle' => 50,
        'enableCache' => true,
        'preloadThemes' => false
    ],
    'advanced' => [
        'cssVariablePrefix' => '--emby-',
        'forceReinject' => false,
        'customCSS' => ''
    ]
];

/**
 * 记录日志
 */
function logMessage($message, $level = 'INFO') {
    $logFile = '/config/emby-ui-plugin/plugin.log';
    $timestamp = date('Y-m-d H:i:s');
    $logEntry = "[$timestamp] [$level] $message" . PHP_EOL;
    file_put_contents($logFile, $logEntry, FILE_APPEND | LOCK_EX);
}

/**
 * 读取配置
 */
function loadConfig() {
    global $configFile, $defaultConfig;
    
    if (file_exists($configFile)) {
        $content = file_get_contents($configFile);
        $config = json_decode($content, true);
        
        if ($config === null) {
            logMessage('配置文件格式错误，使用默认配置', 'WARNING');
            return $defaultConfig;
        }
        
        // 合并默认配置，确保所有必需的键都存在
        return array_merge_recursive($defaultConfig, $config);
    }
    
    return $defaultConfig;
}

/**
 * 保存配置
 */
function saveConfig($config) {
    global $configFile;
    
    // 验证配置
    if (!validateConfig($config)) {
        return false;
    }
    
    // 创建备份
    createBackup();
    
    $jsonConfig = json_encode($config, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
    
    if (file_put_contents($configFile, $jsonConfig, LOCK_EX) !== false) {
        logMessage('配置已保存');
        return true;
    }
    
    logMessage('保存配置失败', 'ERROR');
    return false;
}

/**
 * 验证配置
 */
function validateConfig($config) {
    // 基本结构验证
    $requiredKeys = ['enabled', 'defaultTheme', 'customization', 'themes'];
    
    foreach ($requiredKeys as $key) {
        if (!isset($config[$key])) {
            logMessage("配置验证失败：缺少必需的键 '$key'", 'ERROR');
            return false;
        }
    }
    
    // 主题验证
    if (!in_array($config['defaultTheme'], ['dark-modern', 'light-elegant', 'custom'])) {
        logMessage('配置验证失败：无效的默认主题', 'ERROR');
        return false;
    }
    
    return true;
}

/**
 * 创建配置备份
 */
function createBackup() {
    global $configFile, $backupDir;
    
    if (!file_exists($configFile)) {
        return;
    }
    
    $timestamp = date('Y-m-d_H-i-s');
    $backupFile = $backupDir . "/config_backup_$timestamp.json";
    
    if (copy($configFile, $backupFile)) {
        logMessage("配置备份已创建: $backupFile");
        
        // 清理旧备份（保留最近10个）
        cleanupBackups();
    }
}

/**
 * 清理旧备份
 */
function cleanupBackups() {
    global $backupDir;
    
    $backups = glob($backupDir . '/config_backup_*.json');
    
    if (count($backups) > 10) {
        // 按修改时间排序
        usort($backups, function($a, $b) {
            return filemtime($a) - filemtime($b);
        });
        
        // 删除最旧的备份
        $toDelete = array_slice($backups, 0, count($backups) - 10);
        foreach ($toDelete as $file) {
            unlink($file);
            logMessage("已删除旧备份: $file");
        }
    }
}

/**
 * 获取备份列表
 */
function getBackups() {
    global $backupDir;
    
    $backups = glob($backupDir . '/config_backup_*.json');
    $result = [];
    
    foreach ($backups as $file) {
        $filename = basename($file);
        $timestamp = filemtime($file);
        
        $result[] = [
            'filename' => $filename,
            'date' => date('Y-m-d H:i:s', $timestamp),
            'size' => filesize($file)
        ];
    }
    
    // 按时间倒序排列
    usort($result, function($a, $b) {
        return strtotime($b['date']) - strtotime($a['date']);
    });
    
    return $result;
}

/**
 * 恢复备份
 */
function restoreBackup($filename) {
    global $backupDir, $configFile;
    
    $backupFile = $backupDir . '/' . $filename;
    
    if (!file_exists($backupFile)) {
        return false;
    }
    
    if (copy($backupFile, $configFile)) {
        logMessage("配置已从备份恢复: $filename");
        return true;
    }
    
    return false;
}

/**
 * 获取系统信息
 */
function getSystemInfo() {
    return [
        'plugin_version' => '1.0.0',
        'php_version' => phpversion(),
        'server_time' => date('Y-m-d H:i:s'),
        'config_writable' => is_writable(dirname($GLOBALS['configFile'])),
        'disk_space' => disk_free_space('/config'),
        'memory_usage' => memory_get_usage(true)
    ];
}

// 处理请求
try {
    $method = $_SERVER['REQUEST_METHOD'];
    $path = $_SERVER['PATH_INFO'] ?? '';
    
    switch ($method) {
        case 'GET':
            if ($path === '/backups') {
                // 获取备份列表
                $backups = getBackups();
                echo json_encode([
                    'success' => true,
                    'data' => $backups
                ]);
            } elseif ($path === '/system') {
                // 获取系统信息
                $systemInfo = getSystemInfo();
                echo json_encode([
                    'success' => true,
                    'data' => $systemInfo
                ]);
            } else {
                // 获取配置
                $config = loadConfig();
                echo json_encode([
                    'success' => true,
                    'data' => $config
                ]);
            }
            break;
            
        case 'POST':
        case 'PUT':
            // 保存配置
            $input = file_get_contents('php://input');
            $data = json_decode($input, true);
            
            if ($data === null) {
                http_response_code(400);
                echo json_encode([
                    'success' => false,
                    'error' => '无效的JSON数据'
                ]);
                break;
            }
            
            if (saveConfig($data)) {
                echo json_encode([
                    'success' => true,
                    'message' => '配置已保存'
                ]);
            } else {
                http_response_code(500);
                echo json_encode([
                    'success' => false,
                    'error' => '保存配置失败'
                ]);
            }
            break;
            
        case 'DELETE':
            if (preg_match('/\/backups\/(.+)/', $path, $matches)) {
                // 删除备份
                $filename = $matches[1];
                $backupFile = $backupDir . '/' . $filename;
                
                if (file_exists($backupFile) && unlink($backupFile)) {
                    logMessage("备份已删除: $filename");
                    echo json_encode([
                        'success' => true,
                        'message' => '备份已删除'
                    ]);
                } else {
                    http_response_code(404);
                    echo json_encode([
                        'success' => false,
                        'error' => '备份文件不存在'
                    ]);
                }
            } else {
                http_response_code(400);
                echo json_encode([
                    'success' => false,
                    'error' => '无效的删除请求'
                ]);
            }
            break;
            
        default:
            http_response_code(405);
            echo json_encode([
                'success' => false,
                'error' => '不支持的请求方法'
            ]);
            break;
    }
    
} catch (Exception $e) {
    logMessage('API错误: ' . $e->getMessage(), 'ERROR');
    
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => '服务器内部错误'
    ]);
}
?>