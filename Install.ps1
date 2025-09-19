# ===================================================================
# Windows Reset Toolkit Installation Script
# File: Install.ps1
# Author: jomardyan
# Description: Installation and setup script for the ReSet toolkit
# Version: 1.0.0
# ===================================================================

#Requires -Version 5.0
#Requires -RunAsAdministrator

param(
    [string]$InstallPath = "$env:ProgramFiles\WindowsResetToolkit",
    [switch]$CreateDesktopShortcut,
    [switch]$AddToPath,
    [switch]$Silent,
    [switch]$Uninstall
)

$TOOLKIT_VERSION = "1.0.0"
$TOOLKIT_NAME = "Windows Reset Toolkit (ReSet)"

function Write-InstallLog {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    switch ($Level) {
        "INFO"    { Write-Host $logEntry -ForegroundColor Cyan }
        "WARN"    { Write-Host $logEntry -ForegroundColor Yellow }
        "ERROR"   { Write-Host $logEntry -ForegroundColor Red }
        "SUCCESS" { Write-Host $logEntry -ForegroundColor Green }
    }
}

function Show-InstallBanner {
    Clear-Host
    Write-Host ""
    Write-Host "██████╗ ███████╗███████╗███████╗████████╗" -ForegroundColor Cyan
    Write-Host "██╔══██╗██╔════╝██╔════╝██╔════╝╚══██╔══╝" -ForegroundColor Cyan
    Write-Host "██████╔╝█████╗  ███████╗█████╗     ██║   " -ForegroundColor Cyan
    Write-Host "██╔══██╗██╔══╝  ╚════██║██╔══╝     ██║   " -ForegroundColor Cyan
    Write-Host "██║  ██║███████╗███████║███████╗   ██║   " -ForegroundColor Cyan
    Write-Host "╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝   ╚═╝   " -ForegroundColor Cyan
    Write-Host ""
    Write-Host "         $TOOLKIT_NAME v$TOOLKIT_VERSION" -ForegroundColor White
    Write-Host "                    INSTALLER" -ForegroundColor Gray
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor DarkCyan
    Write-Host ""
}

function Test-Prerequisites {
    Write-InstallLog "Checking system prerequisites..."
    
    # Check PowerShell version
    if ($PSVersionTable.PSVersion.Major -lt 5) {
        throw "PowerShell 5.0 or higher is required"
    }
    
    # Check Windows version
    $osVersion = [System.Environment]::OSVersion.Version
    if ($osVersion.Major -lt 10) {
        throw "Windows 10 or later is required"
    }
    
    # Check if running as administrator
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw "Administrator privileges are required for installation"
    }
    
    Write-InstallLog "Prerequisites check passed" "SUCCESS"
}

function Install-Toolkit {
    Write-InstallLog "Installing $TOOLKIT_NAME to $InstallPath..."
    
    try {
        # Create installation directory
        if (!(Test-Path $InstallPath)) {
            New-Item -ItemType Directory -Path $InstallPath -Force | Out-Null
            Write-InstallLog "Created installation directory: $InstallPath" "SUCCESS"
        }
        
        # Create subdirectories
        $subDirs = @("scripts", "logs", "backups", "docs", "config")
        foreach ($dir in $subDirs) {
            $dirPath = Join-Path $InstallPath $dir
            if (!(Test-Path $dirPath)) {
                New-Item -ItemType Directory -Path $dirPath -Force | Out-Null
            }
        }
        
        # Copy files from current directory to installation directory
        $currentPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
        
        # Copy main scripts
        $mainFiles = @("Reset-Manager.ps1", "README.md", "LICENSE")
        foreach ($file in $mainFiles) {
            $sourcePath = Join-Path $currentPath $file
            $destPath = Join-Path $InstallPath $file
            if (Test-Path $sourcePath) {
                Copy-Item -Path $sourcePath -Destination $destPath -Force
                Write-InstallLog "Copied $file"
            }
        }
        
        # Copy scripts directory
        $scriptsSource = Join-Path $currentPath "scripts"
        $scriptsDest = Join-Path $InstallPath "scripts"
        if (Test-Path $scriptsSource) {
            Copy-Item -Path "$scriptsSource\*" -Destination $scriptsDest -Recurse -Force
            Write-InstallLog "Copied scripts directory"
        }
        
        # Copy documentation
        $docsSource = Join-Path $currentPath "docs"
        $docsDest = Join-Path $InstallPath "docs"
        if (Test-Path $docsSource) {
            Copy-Item -Path "$docsSource\*" -Destination $docsDest -Recurse -Force
            Write-InstallLog "Copied documentation"
        }
        
        # Set execution policy for scripts
        $scriptsPath = Join-Path $InstallPath "scripts"
        Get-ChildItem -Path $scriptsPath -Filter "*.ps1" | ForEach-Object {
            Unblock-File -Path $_.FullName -ErrorAction SilentlyContinue
        }
        
        Write-InstallLog "Toolkit files installed successfully" "SUCCESS"
        
    } catch {
        throw "Failed to install toolkit files: $($_.Exception.Message)"
    }
}

function New-DesktopShortcut {
    if ($CreateDesktopShortcut) {
        Write-InstallLog "Creating desktop shortcut..."
        
        try {
            $desktopPath = [Environment]::GetFolderPath("Desktop")
            $shortcutPath = Join-Path $desktopPath "Windows Reset Toolkit.lnk"
            $targetPath = Join-Path $InstallPath "Reset-Manager.ps1"
            
            $shell = New-Object -ComObject WScript.Shell
            $shortcut = $shell.CreateShortcut($shortcutPath)
            $shortcut.TargetPath = "powershell.exe"
            $shortcut.Arguments = "-ExecutionPolicy Bypass -File `"$targetPath`""
            $shortcut.WorkingDirectory = $InstallPath
            $shortcut.Description = "Windows Reset Toolkit - System settings reset utility"
            $shortcut.Save()
            
            Write-InstallLog "Desktop shortcut created: $shortcutPath" "SUCCESS"
        } catch {
            Write-InstallLog "Failed to create desktop shortcut: $($_.Exception.Message)" "WARN"
        }
    }
}

function Add-ToSystemPath {
    if ($AddToPath) {
        Write-InstallLog "Adding toolkit to system PATH..."
        
        try {
            $currentPath = [Environment]::GetEnvironmentVariable("PATH", "Machine")
            if ($currentPath -notlike "*$InstallPath*") {
                $newPath = $currentPath + ";" + $InstallPath
                [Environment]::SetEnvironmentVariable("PATH", $newPath, "Machine")
                Write-InstallLog "Added to system PATH" "SUCCESS"
            } else {
                Write-InstallLog "Already in system PATH" "INFO"
            }
        } catch {
            Write-InstallLog "Failed to add to PATH: $($_.Exception.Message)" "WARN"
        }
    }
}

function Register-ScheduledTask {
    Write-InstallLog "Registering scheduled maintenance task..."
    
    try {
        $taskName = "WindowsResetToolkit-Maintenance"
        $taskDescription = "Windows Reset Toolkit maintenance and cleanup"
        $scriptPath = Join-Path $InstallPath "scripts\maintenance.ps1"
        
        # Create maintenance script
        $maintenanceScript = @"
# Maintenance script for Windows Reset Toolkit
try {
    # Clean old logs (older than 30 days)
    `$logPath = "$InstallPath\logs"
    Get-ChildItem -Path `$logPath -Filter "*.log" | Where-Object { `$_.LastWriteTime -lt (Get-Date).AddDays(-30) } | Remove-Item -Force
    
    # Clean old backups (older than 90 days)
    `$backupPath = "$InstallPath\backups"
    Get-ChildItem -Path `$backupPath -Directory | Where-Object { `$_.LastWriteTime -lt (Get-Date).AddDays(-90) } | Remove-Item -Recurse -Force
    
    Write-EventLog -LogName Application -Source "WindowsResetToolkit" -EntryType Information -EventId 1000 -Message "Maintenance completed successfully"
} catch {
    Write-EventLog -LogName Application -Source "WindowsResetToolkit" -EntryType Error -EventId 1001 -Message "Maintenance failed: `$(`$_.Exception.Message)"
}
"@
        
        $maintenanceScript | Out-File -FilePath $scriptPath -Encoding UTF8 -Force
        
        # Register event source
        try {
            New-EventLog -LogName Application -Source "WindowsResetToolkit" -ErrorAction SilentlyContinue
        } catch {}
        
        # Create scheduled task
        $action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -File `"$scriptPath`""
        $trigger = New-ScheduledTaskTrigger -Weekly -WeeksInterval 1 -DaysOfWeek Sunday -At 2AM
        $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
        $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
        
        Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Description $taskDescription -Force
        
        Write-InstallLog "Scheduled maintenance task registered" "SUCCESS"
    } catch {
        Write-InstallLog "Failed to register scheduled task: $($_.Exception.Message)" "WARN"
    }
}

function Remove-Toolkit {
    Write-InstallLog "Uninstalling $TOOLKIT_NAME..."
    
    try {
        # Remove scheduled task
        try {
            Unregister-ScheduledTask -TaskName "WindowsResetToolkit-Maintenance" -Confirm:$false -ErrorAction SilentlyContinue
            Write-InstallLog "Removed scheduled task"
        } catch {}
        
        # Remove from PATH
        try {
            $currentPath = [Environment]::GetEnvironmentVariable("PATH", "Machine")
            $newPath = $currentPath -replace [regex]::Escape(";$InstallPath"), ""
            $newPath = $newPath -replace [regex]::Escape("$InstallPath;"), ""
            $newPath = $newPath -replace [regex]::Escape($InstallPath), ""
            [Environment]::SetEnvironmentVariable("PATH", $newPath, "Machine")
            Write-InstallLog "Removed from system PATH"
        } catch {}
        
        # Remove desktop shortcut
        try {
            $desktopPath = [Environment]::GetFolderPath("Desktop")
            $shortcutPath = Join-Path $desktopPath "Windows Reset Toolkit.lnk"
            if (Test-Path $shortcutPath) {
                Remove-Item -Path $shortcutPath -Force
                Write-InstallLog "Removed desktop shortcut"
            }
        } catch {}
        
        # Remove installation directory
        if (Test-Path $InstallPath) {
            Remove-Item -Path $InstallPath -Recurse -Force
            Write-InstallLog "Removed installation directory: $InstallPath"
        }
        
        Write-InstallLog "Uninstallation completed successfully" "SUCCESS"
        
    } catch {
        Write-InstallLog "Uninstallation failed: $($_.Exception.Message)" "ERROR"
        throw
    }
}

function Show-CompletionMessage {
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Green
    Write-Host " INSTALLATION COMPLETE!" -ForegroundColor White -BackgroundColor Green
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Green
    Write-Host ""
    Write-Host "📁 Installation path: $InstallPath" -ForegroundColor Cyan
    Write-Host "🚀 Launch command: Reset-Manager.ps1" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "USAGE:" -ForegroundColor Yellow
    Write-Host "  cd `"$InstallPath`"" -ForegroundColor White
    Write-Host "  .\Reset-Manager.ps1" -ForegroundColor White
    Write-Host ""
    
    if ($CreateDesktopShortcut) {
        Write-Host "🖥️  Desktop shortcut created" -ForegroundColor Green
    }
    
    if ($AddToPath) {
        Write-Host "🔧 Added to system PATH (restart required)" -ForegroundColor Green
    }
    
    Write-Host ""
    Write-Host "For help and documentation, visit:" -ForegroundColor Gray
    Write-Host "https://github.com/jomardyan/ReSet2" -ForegroundColor Cyan
    Write-Host ""
}

# ===================================================================
# MAIN EXECUTION
# ===================================================================

try {
    Show-InstallBanner
    
    if ($Uninstall) {
        if (-not $Silent) {
            $confirm = Read-Host "Are you sure you want to uninstall $TOOLKIT_NAME? (y/N)"
            if ($confirm.ToLower() -ne "y") {
                Write-Host "Uninstallation cancelled." -ForegroundColor Gray
                exit 0
            }
        }
        
        Remove-Toolkit
        Write-Host "✅ $TOOLKIT_NAME has been uninstalled successfully." -ForegroundColor Green
        exit 0
    }
    
    # Installation process
    if (-not $Silent) {
        Write-Host "This will install $TOOLKIT_NAME to: $InstallPath" -ForegroundColor Cyan
        Write-Host ""
        $confirm = Read-Host "Do you want to continue? (Y/n)"
        if ($confirm.ToLower() -eq "n") {
            Write-Host "Installation cancelled." -ForegroundColor Gray
            exit 0
        }
    }
    
    Test-Prerequisites
    Install-Toolkit
    New-DesktopShortcut
    Add-ToSystemPath
    Register-ScheduledTask
    
    if (-not $Silent) {
        Show-CompletionMessage
    } else {
        Write-InstallLog "Installation completed successfully" "SUCCESS"
    }
    
} catch {
    Write-InstallLog "Installation failed: $($_.Exception.Message)" "ERROR"
    Write-Host ""
    Write-Host "❌ Installation failed. Please check the error above and try again." -ForegroundColor Red
    exit 1
}