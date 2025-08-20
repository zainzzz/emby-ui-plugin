# Emby UI Plugin Installation Script for Windows
# PowerShell script to install the Emby UI beautification plugin

param(
    [string]$EmbyPath = "C:\ProgramData\Emby-Server",
    [string]$PluginPath = "$PSScriptRoot\..",
    [switch]$Force = $false,
    [switch]$Help = $false
)

# Display help information
if ($Help) {
    Write-Host "Emby UI Plugin Installation Script" -ForegroundColor Green
    Write-Host "Usage: .\install-plugin.ps1 [OPTIONS]" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Options:" -ForegroundColor Yellow
    Write-Host "  -EmbyPath <path>    Emby server installation path (default: C:\ProgramData\Emby-Server)"
    Write-Host "  -PluginPath <path>  Plugin source path (default: current directory parent)"
    Write-Host "  -Force              Force installation even if plugin exists"
    Write-Host "  -Help               Show this help message"
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor Yellow
    Write-Host "  .\install-plugin.ps1"
    Write-Host "  .\install-plugin.ps1 -EmbyPath 'D:\Emby' -Force"
    exit 0
}

# Function to write colored output
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

# Function to check if running as administrator
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Function to create directory if it doesn't exist
function New-DirectoryIfNotExists {
    param([string]$Path)
    if (-not (Test-Path $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
        Write-ColorOutput "Created directory: $Path" "Green"
    }
}

# Function to copy files with error handling
function Copy-FilesSafely {
    param(
        [string]$Source,
        [string]$Destination,
        [string]$Description
    )
    try {
        Copy-Item -Path $Source -Destination $Destination -Recurse -Force
        Write-ColorOutput "✓ $Description" "Green"
        return $true
    } catch {
        Write-ColorOutput "✗ Failed to copy $Description`: $($_.Exception.Message)" "Red"
        return $false
    }
}

# Function to create injection script
function New-InjectionScript {
    param([string]$WebPath)
    
    $injectionScript = @'
// Emby UI Plugin Auto-Injection Script
(function() {
    "use strict";
    
    // Wait for DOM to be ready
    function waitForDOM(callback) {
        if (document.readyState === "loading") {
            document.addEventListener("DOMContentLoaded", callback);
        } else {
            callback();
        }
    }
    
    // Inject plugin CSS and JS
    function injectPlugin() {
        // Check if plugin is already injected
        if (document.querySelector("#emby-ui-plugin-injected")) {
            return;
        }
        
        // Create marker element
        const marker = document.createElement("div");
        marker.id = "emby-ui-plugin-injected";
        marker.style.display = "none";
        document.head.appendChild(marker);
        
        // Inject CSS
        const cssLink = document.createElement("link");
        cssLink.rel = "stylesheet";
        cssLink.href = "/plugins/emby-ui-plugin/themes/dark-modern.css";
        cssLink.id = "emby-ui-plugin-theme";
        document.head.appendChild(cssLink);
        
        // Inject main script
        const script = document.createElement("script");
        script.src = "/plugins/emby-ui-plugin/js/emby-enhancer.js";
        script.async = true;
        document.head.appendChild(script);
        
        console.log("Emby UI Plugin injected successfully");
    }
    
    // Initialize plugin
    waitForDOM(injectPlugin);
})();
'@
    
    $scriptPath = Join-Path $WebPath "plugins\emby-ui-plugin\inject.js"
    try {
        $injectionScript | Out-File -FilePath $scriptPath -Encoding UTF8 -Force
        Write-ColorOutput "✓ Created injection script" "Green"
        return $true
    } catch {
        Write-ColorOutput "✗ Failed to create injection script: $($_.Exception.Message)" "Red"
        return $false
    }
}

# Function to modify Emby's index.html
function Update-EmbyIndex {
    param([string]$WebPath)
    
    $indexPath = Join-Path $WebPath "index.html"
    
    if (-not (Test-Path $indexPath)) {
        Write-ColorOutput "✗ Emby index.html not found at: $indexPath" "Red"
        return $false
    }
    
    try {
        # Backup original index.html
        $backupPath = "$indexPath.backup"
        if (-not (Test-Path $backupPath)) {
            Copy-Item $indexPath $backupPath
            Write-ColorOutput "✓ Created backup of index.html" "Green"
        }
        
        # Read current content
        $content = Get-Content $indexPath -Raw
        
        # Check if plugin is already injected
        if ($content -match "emby-ui-plugin") {
            if (-not $Force) {
                Write-ColorOutput "! Plugin already injected in index.html (use -Force to override)" "Yellow"
                return $true
            }
        }
        
        # Inject plugin script before closing head tag
        $injectionCode = '    <script src="/plugins/emby-ui-plugin/inject.js" async></script>'
        $newContent = $content -replace "</head>", "$injectionCode`n</head>"
        
        # Write updated content
        $newContent | Out-File -FilePath $indexPath -Encoding UTF8 -Force
        Write-ColorOutput "✓ Updated Emby index.html" "Green"
        return $true
    } catch {
        Write-ColorOutput "✗ Failed to update index.html: $($_.Exception.Message)" "Red"
        return $false
    }
}

# Function to create default configuration
function New-DefaultConfig {
    param([string]$ConfigPath)
    
    $defaultConfig = @{
        "enabled" = $true
        "theme" = "dark-modern"
        "autoApply" = $true
        "allowCustomization" = $true
        "allowThemeSwitching" = $true
        "allowColorCustomization" = $true
        "debug" = $false
        "performance" = @{
            "injectDelay" = 100
            "observerThrottle" = 50
            "enableCache" = $true
            "preloadThemes" = $false
        }
        "customColors" = @{}
        "customCSS" = ""
    } | ConvertTo-Json -Depth 10
    
    $configFile = Join-Path $ConfigPath "config.json"
    try {
        $defaultConfig | Out-File -FilePath $configFile -Encoding UTF8 -Force
        Write-ColorOutput "✓ Created default configuration" "Green"
        return $true
    } catch {
        Write-ColorOutput "✗ Failed to create configuration: $($_.Exception.Message)" "Red"
        return $false
    }
}

# Main installation function
function Install-EmbyUIPlugin {
    Write-ColorOutput "=== Emby UI Plugin Installation ===" "Cyan"
    Write-ColorOutput "Plugin Path: $PluginPath" "Gray"
    Write-ColorOutput "Emby Path: $EmbyPath" "Gray"
    Write-ColorOutput ""
    
    # Check if running as administrator
    if (-not (Test-Administrator)) {
        Write-ColorOutput "⚠ Warning: Not running as administrator. Some operations may fail." "Yellow"
        Write-ColorOutput "Consider running PowerShell as administrator for best results." "Yellow"
        Write-ColorOutput ""
    }
    
    # Validate paths
    if (-not (Test-Path $PluginPath)) {
        Write-ColorOutput "✗ Plugin source path not found: $PluginPath" "Red"
        exit 1
    }
    
    if (-not (Test-Path $EmbyPath)) {
        Write-ColorOutput "✗ Emby installation path not found: $EmbyPath" "Red"
        Write-ColorOutput "Please specify correct Emby path using -EmbyPath parameter" "Yellow"
        exit 1
    }
    
    # Define target paths
    $webPath = Join-Path $EmbyPath "system\dashboard-ui"
    $pluginWebPath = Join-Path $webPath "plugins\emby-ui-plugin"
    $configPath = Join-Path $EmbyPath "config\plugins\emby-ui-plugin"
    
    Write-ColorOutput "Step 1: Creating directories..." "Yellow"
    New-DirectoryIfNotExists $pluginWebPath
    New-DirectoryIfNotExists "$pluginWebPath\themes"
    New-DirectoryIfNotExists "$pluginWebPath\js"
    New-DirectoryIfNotExists "$pluginWebPath\api"
    New-DirectoryIfNotExists "$pluginWebPath\pages"
    New-DirectoryIfNotExists $configPath
    
    Write-ColorOutput "\nStep 2: Copying plugin files..." "Yellow"
    $success = $true
    
    # Copy themes
    $success = $success -and (Copy-FilesSafely "$PluginPath\themes\*" "$pluginWebPath\themes" "Theme files")
    
    # Copy JavaScript files
    $success = $success -and (Copy-FilesSafely "$PluginPath\js\*" "$pluginWebPath\js" "JavaScript files")
    
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
    
    Write-ColorOutput "\nStep 3: Creating injection script..." "Yellow"
    if (-not (New-InjectionScript $webPath)) {
        Write-ColorOutput "✗ Failed to create injection script" "Red"
        exit 1
    }
    
    Write-ColorOutput "\nStep 4: Updating Emby index.html..." "Yellow"
    if (-not (Update-EmbyIndex $webPath)) {
        Write-ColorOutput "✗ Failed to update Emby index.html" "Red"
        exit 1
    }
    
    Write-ColorOutput "\nStep 5: Creating default configuration..." "Yellow"
    if (-not (New-DefaultConfig $configPath)) {
        Write-ColorOutput "✗ Failed to create default configuration" "Red"
        exit 1
    }
    
    Write-ColorOutput "\n=== Installation Completed Successfully! ===" "Green"
    Write-ColorOutput "\nNext steps:" "Yellow"
    Write-ColorOutput "1. Restart Emby Server" "White"
    Write-ColorOutput "2. Clear browser cache and refresh Emby web interface" "White"
    Write-ColorOutput "3. Access plugin settings at: http://your-emby-server:8096/plugins/emby-ui-plugin/pages/settings.html" "White"
    Write-ColorOutput "\nPlugin files installed to: $pluginWebPath" "Gray"
    Write-ColorOutput "Configuration stored in: $configPath" "Gray"
}

# Run installation
try {
    Install-EmbyUIPlugin
} catch {
    Write-ColorOutput "\n✗ Installation failed with error: $($_.Exception.Message)" "Red"
    Write-ColorOutput "Stack trace: $($_.ScriptStackTrace)" "Red"
    exit 1
}