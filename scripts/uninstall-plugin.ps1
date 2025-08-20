# Emby UI Plugin Uninstallation Script for Windows
# PowerShell script to completely remove the Emby UI beautification plugin

param(
    [string]$EmbyPath = "C:\ProgramData\Emby-Server",
    [switch]$KeepConfig = $false,
    [switch]$RestoreBackup = $true,
    [switch]$Force = $false,
    [switch]$Help = $false
)

# Display help information
if ($Help) {
    Write-Host "Emby UI Plugin Uninstallation Script" -ForegroundColor Green
    Write-Host "Usage: .\uninstall-plugin.ps1 [OPTIONS]" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Options:" -ForegroundColor Yellow
    Write-Host "  -EmbyPath <path>     Emby server installation path (default: C:\ProgramData\Emby-Server)"
    Write-Host "  -KeepConfig          Keep plugin configuration files"
    Write-Host "  -RestoreBackup       Restore original index.html from backup (default: true)"
    Write-Host "  -Force               Force removal without confirmation"
    Write-Host "  -Help                Show this help message"
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor Yellow
    Write-Host "  .\uninstall-plugin.ps1"
    Write-Host "  .\uninstall-plugin.ps1 -KeepConfig -Force"
    Write-Host "  .\uninstall-plugin.ps1 -EmbyPath 'D:\Emby' -RestoreBackup:$false"
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

# Function to remove directory safely
function Remove-DirectorySafely {
    param(
        [string]$Path,
        [string]$Description
    )
    if (Test-Path $Path) {
        try {
            Remove-Item -Path $Path -Recurse -Force
            Write-ColorOutput "✓ Removed $Description" "Green"
            return $true
        } catch {
            Write-ColorOutput "✗ Failed to remove $Description`: $($_.Exception.Message)" "Red"
            return $false
        }
    } else {
        Write-ColorOutput "! $Description not found (already removed)" "Yellow"
        return $true
    }
}

# Function to remove file safely
function Remove-FileSafely {
    param(
        [string]$Path,
        [string]$Description
    )
    if (Test-Path $Path) {
        try {
            Remove-Item -Path $Path -Force
            Write-ColorOutput "✓ Removed $Description" "Green"
            return $true
        } catch {
            Write-ColorOutput "✗ Failed to remove $Description`: $($_.Exception.Message)" "Red"
            return $false
        }
    } else {
        Write-ColorOutput "! $Description not found (already removed)" "Yellow"
        return $true
    }
}

# Function to restore Emby's index.html from backup
function Restore-EmbyIndex {
    param([string]$WebPath)
    
    $indexPath = Join-Path $WebPath "index.html"
    $backupPath = "$indexPath.backup"
    
    if (-not (Test-Path $backupPath)) {
        Write-ColorOutput "! No backup found for index.html" "Yellow"
        return $true
    }
    
    try {
        Copy-Item $backupPath $indexPath -Force
        Write-ColorOutput "✓ Restored original index.html from backup" "Green"
        
        # Remove backup file
        Remove-Item $backupPath -Force
        Write-ColorOutput "✓ Removed backup file" "Green"
        
        return $true
    } catch {
        Write-ColorOutput "✗ Failed to restore index.html: $($_.Exception.Message)" "Red"
        return $false
    }
}

# Function to clean index.html manually (if no backup available)
function Clean-EmbyIndex {
    param([string]$WebPath)
    
    $indexPath = Join-Path $WebPath "index.html"
    
    if (-not (Test-Path $indexPath)) {
        Write-ColorOutput "! Emby index.html not found" "Yellow"
        return $true
    }
    
    try {
        # Read current content
        $content = Get-Content $indexPath -Raw
        
        # Remove plugin injection lines
        $cleanContent = $content -replace '\s*<script src="/plugins/emby-ui-plugin/inject\.js"[^>]*></script>\s*', ''
        
        # Check if any changes were made
        if ($content -eq $cleanContent) {
            Write-ColorOutput "! No plugin injection found in index.html" "Yellow"
            return $true
        }
        
        # Write cleaned content
        $cleanContent | Out-File -FilePath $indexPath -Encoding UTF8 -Force
        Write-ColorOutput "✓ Cleaned plugin injection from index.html" "Green"
        return $true
    } catch {
        Write-ColorOutput "✗ Failed to clean index.html: $($_.Exception.Message)" "Red"
        return $false
    }
}

# Function to get user confirmation
function Get-UserConfirmation {
    param([string]$Message)
    
    if ($Force) {
        return $true
    }
    
    $response = Read-Host "$Message (y/N)"
    return $response -match '^[Yy]'
}

# Function to list what will be removed
function Show-RemovalPlan {
    param(
        [string]$WebPath,
        [string]$ConfigPath
    )
    
    Write-ColorOutput "\nThe following items will be removed:" "Yellow"
    
    $pluginWebPath = Join-Path $WebPath "plugins\emby-ui-plugin"
    if (Test-Path $pluginWebPath) {
        Write-ColorOutput "  • Plugin web files: $pluginWebPath" "White"
    }
    
    $injectionScript = Join-Path $WebPath "plugins\emby-ui-plugin\inject.js"
    if (Test-Path $injectionScript) {
        Write-ColorOutput "  • Injection script: $injectionScript" "White"
    }
    
    if (-not $KeepConfig -and (Test-Path $ConfigPath)) {
        Write-ColorOutput "  • Configuration files: $ConfigPath" "White"
    }
    
    $indexPath = Join-Path $WebPath "index.html"
    $backupPath = "$indexPath.backup"
    if (Test-Path $indexPath) {
        if ($RestoreBackup -and (Test-Path $backupPath)) {
            Write-ColorOutput "  • Restore original index.html from backup" "White"
        } else {
            Write-ColorOutput "  • Clean plugin injection from index.html" "White"
        }
    }
    
    if ($KeepConfig) {
        Write-ColorOutput "\nConfiguration files will be preserved." "Green"
    }
    
    Write-ColorOutput ""
}

# Main uninstallation function
function Uninstall-EmbyUIPlugin {
    Write-ColorOutput "=== Emby UI Plugin Uninstallation ===" "Cyan"
    Write-ColorOutput "Emby Path: $EmbyPath" "Gray"
    Write-ColorOutput ""
    
    # Check if running as administrator
    if (-not (Test-Administrator)) {
        Write-ColorOutput "⚠ Warning: Not running as administrator. Some operations may fail." "Yellow"
        Write-ColorOutput "Consider running PowerShell as administrator for best results." "Yellow"
        Write-ColorOutput ""
    }
    
    # Validate Emby path
    if (-not (Test-Path $EmbyPath)) {
        Write-ColorOutput "✗ Emby installation path not found: $EmbyPath" "Red"
        Write-ColorOutput "Please specify correct Emby path using -EmbyPath parameter" "Yellow"
        exit 1
    }
    
    # Define target paths
    $webPath = Join-Path $EmbyPath "system\dashboard-ui"
    $pluginWebPath = Join-Path $webPath "plugins\emby-ui-plugin"
    $configPath = Join-Path $EmbyPath "config\plugins\emby-ui-plugin"
    
    # Check if plugin is installed
    if (-not (Test-Path $pluginWebPath)) {
        Write-ColorOutput "! Plugin does not appear to be installed" "Yellow"
        Write-ColorOutput "Plugin path not found: $pluginWebPath" "Gray"
        
        if (-not (Get-UserConfirmation "Continue with cleanup anyway?")) {
            Write-ColorOutput "Uninstallation cancelled." "Yellow"
            exit 0
        }
    }
    
    # Show removal plan
    Show-RemovalPlan $webPath $configPath
    
    # Get user confirmation
    if (-not (Get-UserConfirmation "Proceed with uninstallation?")) {
        Write-ColorOutput "Uninstallation cancelled." "Yellow"
        exit 0
    }
    
    Write-ColorOutput "\nStep 1: Removing plugin web files..." "Yellow"
    $success = Remove-DirectorySafely $pluginWebPath "Plugin web directory"
    
    Write-ColorOutput "\nStep 2: Cleaning Emby index.html..." "Yellow"
    if ($RestoreBackup) {
        $success = $success -and (Restore-EmbyIndex $webPath)
    } else {
        $success = $success -and (Clean-EmbyIndex $webPath)
    }
    
    if (-not $KeepConfig) {
        Write-ColorOutput "\nStep 3: Removing configuration files..." "Yellow"
        $success = $success -and (Remove-DirectorySafely $configPath "Plugin configuration directory")
    } else {
        Write-ColorOutput "\nStep 3: Keeping configuration files (as requested)" "Yellow"
        Write-ColorOutput "Configuration preserved at: $configPath" "Green"
    }
    
    # Clean up empty parent directories
    Write-ColorOutput "\nStep 4: Cleaning up empty directories..." "Yellow"
    $pluginsDir = Join-Path $webPath "plugins"
    if ((Test-Path $pluginsDir) -and ((Get-ChildItem $pluginsDir | Measure-Object).Count -eq 0)) {
        Remove-DirectorySafely $pluginsDir "Empty plugins directory"
    }
    
    if ($success) {
        Write-ColorOutput "\n=== Uninstallation Completed Successfully! ===" "Green"
        Write-ColorOutput "\nNext steps:" "Yellow"
        Write-ColorOutput "1. Restart Emby Server" "White"
        Write-ColorOutput "2. Clear browser cache and refresh Emby web interface" "White"
        
        if ($KeepConfig) {
            Write-ColorOutput "\nNote: Configuration files were preserved and can be found at:" "Yellow"
            Write-ColorOutput "$configPath" "Gray"
        }
    } else {
        Write-ColorOutput "\n⚠ Uninstallation completed with some errors" "Yellow"
        Write-ColorOutput "Please check the output above and manually remove any remaining files if necessary." "Yellow"
    }
}

# Run uninstallation
try {
    Uninstall-EmbyUIPlugin
} catch {
    Write-ColorOutput "\n✗ Uninstallation failed with error: $($_.Exception.Message)" "Red"
    Write-ColorOutput "Stack trace: $($_.ScriptStackTrace)" "Red"
    exit 1
}