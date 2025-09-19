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
        
        # Create enhanced admin tools
        Write-InstallLog "Creating enhanced admin tools..."
        New-EnhancedAdminTools
        
        Write-InstallLog "Toolkit files installed successfully" "SUCCESS"
        
    } catch {
        throw "Failed to install toolkit files: $($_.Exception.Message)"
    }
}

function New-DesktopShortcut {
    if ($CreateDesktopShortcut) {
        Write-InstallLog "Creating desktop shortcuts..."
        
        try {
            $desktopPath = [Environment]::GetFolderPath("Desktop")
            $shell = New-Object -ComObject WScript.Shell
            
            # Main toolkit shortcut
            $shortcutPath = Join-Path $desktopPath "Windows Reset Toolkit.lnk"
            $targetPath = Join-Path $InstallPath "Reset-Manager.ps1"
            $shortcut = $shell.CreateShortcut($shortcutPath)
            $shortcut.TargetPath = "powershell.exe"
            $shortcut.Arguments = "-ExecutionPolicy Bypass -File `"$targetPath`""
            $shortcut.WorkingDirectory = $InstallPath
            $shortcut.Description = "Windows Reset Toolkit - System settings reset utility"
            $shortcut.Save()
            Write-InstallLog "Created shortcut: Windows Reset Toolkit.lnk"
            
            # Health Check shortcut
            $healthShortcut = Join-Path $desktopPath "System Health Check.lnk"
            $healthTarget = Join-Path $InstallPath "HealthCheck.ps1"
            $healthShortcutObj = $shell.CreateShortcut($healthShortcut)
            $healthShortcutObj.TargetPath = "powershell.exe"
            $healthShortcutObj.Arguments = "-ExecutionPolicy Bypass -File `"$healthTarget`""
            $healthShortcutObj.WorkingDirectory = $InstallPath
            $healthShortcutObj.Description = "Quick System Health Check"
            $healthShortcutObj.Save()
            Write-InstallLog "Created shortcut: System Health Check.lnk"
            
            # AD Tools shortcut
            $adShortcut = Join-Path $desktopPath "AD Tools.lnk"
            $adTarget = Join-Path $InstallPath "AD-Tools.ps1"
            $adShortcutObj = $shell.CreateShortcut($adShortcut)
            $adShortcutObj.TargetPath = "powershell.exe"
            $adShortcutObj.Arguments = "-ExecutionPolicy Bypass -File `"$adTarget`""
            $adShortcutObj.WorkingDirectory = $InstallPath
            $adShortcutObj.Description = "Active Directory Troubleshooting Tools"
            $adShortcutObj.Save()
            Write-InstallLog "Created shortcut: AD Tools.lnk"
            
            Write-InstallLog "Desktop shortcuts created successfully" "SUCCESS"
        } catch {
            Write-InstallLog "Failed to create desktop shortcuts: $($_.Exception.Message)" "WARN"
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
        } catch {
                # Silently continue - non-critical operation
            }
        
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
        } catch {
                # Silently continue - non-critical operation
            }
        
        # Remove from PATH
        try {
            $currentPath = [Environment]::GetEnvironmentVariable("PATH", "Machine")
            $newPath = $currentPath -replace [regex]::Escape(";$InstallPath"), ""
            $newPath = $newPath -replace [regex]::Escape("$InstallPath;"), ""
            $newPath = $newPath -replace [regex]::Escape($InstallPath), ""
            [Environment]::SetEnvironmentVariable("PATH", $newPath, "Machine")
            Write-InstallLog "Removed from system PATH"
        } catch {
                # Silently continue - non-critical operation
            }
        
        # Remove desktop shortcut
        try {
            $desktopPath = [Environment]::GetFolderPath("Desktop")
            $shortcutPath = Join-Path $desktopPath "Windows Reset Toolkit.lnk"
            if (Test-Path $shortcutPath) {
                Remove-Item -Path $shortcutPath -Force
                Write-InstallLog "Removed desktop shortcut"
            }
        } catch {
                # Silently continue - non-critical operation
            }
        
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

function New-EnhancedAdminTools {
    try {
        # Create System Health Check script
        $healthCheckScript = @'
#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Quick System Health Check Tool
.DESCRIPTION
    Performs rapid system health assessment using ReSet toolkit
#>

Import-Module "$PSScriptRoot\scripts\ReSetUtils.psm1" -Force

Write-Host "Windows System Health Check" -ForegroundColor Cyan
Write-Host "===========================" -ForegroundColor Cyan

$health = Get-SystemHealth
$report = Invoke-SystemReport

Write-Host "`nHealth Summary:" -ForegroundColor Yellow
Write-Host "System Files: $($health.SystemFiles)" -ForegroundColor $(if($health.SystemFiles -eq 'Healthy'){'Green'}else{'Red'})
Write-Host "Registry: $($health.RegistryHealth)" -ForegroundColor $(if($health.RegistryHealth -eq 'Healthy'){'Green'}else{'Yellow'})
Write-Host "Disk Health: $($health.DiskHealth)" -ForegroundColor $(if($health.DiskHealth -eq 'Healthy'){'Green'}else{'Yellow'})
Write-Host "Services: $($health.ServiceHealth)" -ForegroundColor $(if($health.ServiceHealth -eq 'Healthy'){'Green'}else{'Yellow'})
Write-Host "Network: $($health.NetworkHealth)" -ForegroundColor $(if($health.NetworkHealth -eq 'Healthy'){'Green'}else{'Red'})
Write-Host "Memory: $($health.MemoryHealth)" -ForegroundColor $(if($health.MemoryHealth -eq 'Healthy'){'Green'}else{'Yellow'})

Write-Host "`nDetailed report saved to: $report" -ForegroundColor Cyan

if ($health.SystemFiles -ne 'Healthy' -or $health.NetworkHealth -ne 'Healthy') {
    Write-Host "`n⚠ Critical issues detected. Consider running Reset-Manager.ps1 for repairs." -ForegroundColor Red
}

Read-Host "`nPress Enter to exit"
'@

        $healthCheckScript | Out-File -FilePath (Join-Path $InstallPath "HealthCheck.ps1") -Encoding UTF8
        Write-InstallLog "Created HealthCheck.ps1"

        # Create AD Tools script
        $adToolsScript = @'
#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Active Directory Troubleshooting Tools
.DESCRIPTION
    Collection of AD diagnostic and reset tools
#>

Import-Module "$PSScriptRoot\scripts\ReSetUtils.psm1" -Force

Write-Host "Active Directory Tools" -ForegroundColor Cyan
Write-Host "======================" -ForegroundColor Cyan

do {
    Write-Host "`nSelect an option:" -ForegroundColor Yellow
    Write-Host "1. Test AD Connectivity" -ForegroundColor White
    Write-Host "2. Reset AD Cache" -ForegroundColor White
    Write-Host "3. Clear Kerberos Tickets" -ForegroundColor White
    Write-Host "4. Flush DNS and Reset Network" -ForegroundColor White
    Write-Host "5. Complete AD Reset (All Above)" -ForegroundColor White
    Write-Host "6. Exit" -ForegroundColor White
    
    $choice = Read-Host "`nEnter your choice (1-6)"
    
    switch ($choice) {
        "1" {
            Write-Host "`nTesting AD connectivity..." -ForegroundColor Yellow
            $adStatus = Test-ActiveDirectoryConnectivity
            Write-Host "Status: $($adStatus.Status)" -ForegroundColor $(if($adStatus.Status -eq 'Connected'){'Green'}else{'Red'})
            Write-Host "Message: $($adStatus.Message)" -ForegroundColor Gray
            if ($adStatus.Domain) { Write-Host "Domain: $($adStatus.Domain)" -ForegroundColor Gray }
            if ($adStatus.DomainController) { Write-Host "DC: $($adStatus.DomainController)" -ForegroundColor Gray }
        }
        "2" {
            Write-Host "`nResetting AD cache..." -ForegroundColor Yellow
            $results = Reset-ActiveDirectoryCache -ClearCredentialCache
            foreach ($key in $results.Keys) {
                Write-Host "$key`: $($results[$key])" -ForegroundColor Green
            }
        }
        "3" {
            Write-Host "`nClearing Kerberos tickets..." -ForegroundColor Yellow
            $results = Reset-ActiveDirectoryCache -ClearKerberosTickets
            Write-Host "Kerberos Tickets: $($results.KerberosTickets)" -ForegroundColor Green
        }
        "4" {
            Write-Host "`nFlushing DNS and resetting network..." -ForegroundColor Yellow
            $results = Reset-ActiveDirectoryCache -FlushDNSCache
            Write-Host "DNS Cache: $($results.DNSCache)" -ForegroundColor Green
        }
        "5" {
            Write-Host "`nPerforming complete AD reset..." -ForegroundColor Yellow
            $results = Reset-ActiveDirectoryCache -ClearKerberosTickets -ClearCredentialCache -FlushDNSCache
            foreach ($key in $results.Keys) {
                Write-Host "$key`: $($results[$key])" -ForegroundColor Green
            }
        }
        "6" {
            Write-Host "Exiting..." -ForegroundColor Green
            break
        }
        default {
            Write-Host "Invalid choice. Please try again." -ForegroundColor Red
        }
    }
    
    if ($choice -ne "6") {
        Read-Host "`nPress Enter to continue"
    }
} while ($choice -ne "6")
'@

        $adToolsScript | Out-File -FilePath (Join-Path $InstallPath "AD-Tools.ps1") -Encoding UTF8
        Write-InstallLog "Created AD-Tools.ps1"

        # Create System Cleanup script
        $cleanupScript = @'
#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Advanced System Cleanup Tool
.DESCRIPTION
    Comprehensive system cleanup using ReSet toolkit
#>

Import-Module "$PSScriptRoot\scripts\ReSetUtils.psm1" -Force

Write-Host "Advanced System Cleanup" -ForegroundColor Cyan
Write-Host "=======================" -ForegroundColor Cyan

Write-Host "`nThis tool will perform comprehensive system cleanup." -ForegroundColor Yellow
Write-Host "Select cleanup options:" -ForegroundColor Yellow

$options = @()
Write-Host "1. Temporary Files" -ForegroundColor White
$temp = Read-Host "   Include? (y/n)"
if ($temp -eq 'y') { $options += 'Temp' }

Write-Host "2. Event Logs (non-critical)" -ForegroundColor White
$events = Read-Host "   Include? (y/n)"
if ($events -eq 'y') { $options += 'Events' }

Write-Host "3. Recycle Bin" -ForegroundColor White
$recycle = Read-Host "   Include? (y/n)"
if ($recycle -eq 'y') { $options += 'Recycle' }

Write-Host "4. Prefetch Files" -ForegroundColor White
$prefetch = Read-Host "   Include? (y/n)"
if ($prefetch -eq 'y') { $options += 'Prefetch' }

Write-Host "5. Windows Update Cache" -ForegroundColor White
$update = Read-Host "   Include? (y/n)"
if ($update -eq 'y') { $options += 'Update' }

Write-Host "6. Browser Caches" -ForegroundColor White
$browser = Read-Host "   Include? (y/n)"
if ($browser -eq 'y') { $options += 'Browser' }

if ($options.Count -eq 0) {
    Write-Host "No cleanup options selected. Exiting." -ForegroundColor Yellow
    exit
}

Write-Host "`nStarting cleanup..." -ForegroundColor Green

$params = @{}
if ($options -contains 'Temp') { $params.IncludeTempFiles = $true }
if ($options -contains 'Events') { $params.IncludeEventLogs = $true }
if ($options -contains 'Recycle') { $params.IncludeRecycleBin = $true }
if ($options -contains 'Prefetch') { $params.IncludePrefetch = $true }
if ($options -contains 'Update') { $params.IncludeWindowsUpdate = $true }
if ($options -contains 'Browser') { $params.IncludeBrowserCache = $true }

$results = Invoke-AdvancedCleanup @params

Write-Host "`nCleanup Results:" -ForegroundColor Green
foreach ($key in $results.Keys) {
    Write-Host "$key`: $($results[$key])" -ForegroundColor White
}

Read-Host "`nCleanup complete. Press Enter to exit"
'@

        $cleanupScript | Out-File -FilePath (Join-Path $InstallPath "SystemCleanup.ps1") -Encoding UTF8
        Write-InstallLog "Created SystemCleanup.ps1"
        
        # Set execution policy for new scripts
        $newScripts = @("HealthCheck.ps1", "AD-Tools.ps1", "SystemCleanup.ps1")
        foreach ($script in $newScripts) {
            $scriptPath = Join-Path $InstallPath $script
            if (Test-Path $scriptPath) {
                Unblock-File -Path $scriptPath -ErrorAction SilentlyContinue
            }
        }
        
        Write-InstallLog "Enhanced admin tools created successfully" "SUCCESS"
        
    } catch {
        Write-InstallLog "Failed to create enhanced admin tools: $($_.Exception.Message)" "ERROR"
        throw
    }
}

function Show-CompletionMessage {
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Green
    Write-Host " ENHANCED INSTALLATION COMPLETE!" -ForegroundColor White -BackgroundColor Green
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Green
    Write-Host ""
    Write-Host "📁 Installation path: $InstallPath" -ForegroundColor Cyan
    Write-Host "🚀 Launch command: Reset-Manager.ps1" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "AVAILABLE TOOLS:" -ForegroundColor Yellow
    Write-Host "  • Reset-Manager.ps1    - Main interactive toolkit" -ForegroundColor White
    Write-Host "  • HealthCheck.ps1      - Quick system health assessment" -ForegroundColor White
    Write-Host "  • AD-Tools.ps1         - Active Directory troubleshooting" -ForegroundColor White
    Write-Host "  • SystemCleanup.ps1    - Advanced system cleanup" -ForegroundColor White
    Write-Host "  • scripts\*.ps1        - Individual reset modules" -ForegroundColor White
    Write-Host ""
    Write-Host "USAGE:" -ForegroundColor Yellow
    Write-Host "  cd `"$InstallPath`"" -ForegroundColor White
    Write-Host "  .\Reset-Manager.ps1     # For interactive menu" -ForegroundColor White
    Write-Host "  .\HealthCheck.ps1       # For system health check" -ForegroundColor White
    Write-Host "  .\AD-Tools.ps1          # For AD troubleshooting" -ForegroundColor White
    Write-Host ""
    
    if ($CreateDesktopShortcut) {
        Write-Host "🖥️  Desktop shortcuts created for main tools" -ForegroundColor Green
    }
    
    if ($AddToPath) {
        Write-Host "🔧 Added to system PATH (restart required)" -ForegroundColor Green
    }
    
    Write-Host ""
    Write-Host "NEW FEATURES:" -ForegroundColor Yellow
    Write-Host "  ✅ 50+ Reset functions across all Windows components" -ForegroundColor Green
    Write-Host "  ✅ Advanced system health monitoring" -ForegroundColor Green
    Write-Host "  ✅ Active Directory integration and tools" -ForegroundColor Green
    Write-Host "  ✅ Comprehensive backup and restore system" -ForegroundColor Green
    Write-Host "  ✅ Enhanced logging and reporting" -ForegroundColor Green
    Write-Host "  ✅ Professional admin toolkit integration" -ForegroundColor Green
    Write-Host ""
    Write-Host "For help and documentation, see README.md or visit:" -ForegroundColor Gray
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
