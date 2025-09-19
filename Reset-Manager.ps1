# ===================================================================
# Windows Reset Toolkit - Interactive CLI Interface
# File: Reset-Manager.ps1
# Author: jomardyan
# Description: Interactive PowerShell CLI for Windows reset operations
# Version: 1.0.0
# ===================================================================

#Requires -Version 5.0
#Requires -RunAsAdministrator

param(
    [string[]]$Scripts = @(),
    [switch]$ListScripts,
    [switch]$Silent,
    [switch]$NoBackup,
    [switch]$Force,
    [string]$LogLevel = "INFO",
    [switch]$Help
)

# Set execution policy for current session
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

# Import utility module
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$scriptsPath = Join-Path $scriptPath "scripts"
Import-Module (Join-Path $scriptsPath "ReSetUtils.psm1") -Force

# ===================================================================
# SCRIPT CONFIGURATION
# ===================================================================

$TOOLKIT_VERSION = "1.0.0"
$TOOLKIT_NAME = "Windows Reset Toolkit (ReSet)"

# Available reset scripts with descriptions
$availableScripts = [ordered]@{
    "reset-language-settings" = "Reset language, locale, and regional settings"
    "reset-datetime" = "Reset date, time, timezone, and NTP settings"
    "reset-display" = "Reset display resolution, DPI, colors, and themes"
    "reset-audio" = "Reset audio devices, volume, and sound schemes"
    "reset-network" = "Reset network adapters, TCP/IP, and firewall"
    "reset-windows-update" = "Reset Windows Update components and cache"
    "reset-uac" = "Reset User Account Control settings"
    "reset-privacy" = "Reset privacy and app permissions"
    "reset-defender" = "Reset Windows Defender configuration"
    "reset-search" = "Reset Windows Search and indexing"
    "reset-startmenu" = "Reset Start Menu and Taskbar settings"
    "reset-shell" = "Reset Windows Explorer settings"
    "reset-file-associations" = "Reset file type associations"
    "reset-fonts" = "Reset font settings and ClearType"
    "reset-power" = "Reset power management settings"
    "reset-performance" = "Reset performance counters"
    "reset-browser" = "Reset Internet Explorer/Edge settings"
    "reset-store" = "Reset Microsoft Store configuration"
    "reset-input-devices" = "Reset mouse, keyboard, and accessibility"
    "reset-features" = "Reset Windows optional features"
    "reset-environment" = "Reset environment variables"
    "reset-registry" = "Registry cleanup and reset"
    "reset-services" = "Reset Windows services and startup programs"
    "reset-security" = "Reset security settings (combined UAC/privacy/defender)"
    "reset-advanced" = "Advanced system components and specialized resets"
}

# Script categories for organized display
$scriptCategories = [ordered]@{
    "Language & Regional" = @("reset-language-settings", "reset-datetime")
    "Display & Audio" = @("reset-display", "reset-audio")
    "Network & Connectivity" = @("reset-network", "reset-windows-update")
    "Security & Privacy" = @("reset-uac", "reset-privacy", "reset-defender")
    "Search & Interface" = @("reset-search", "reset-startmenu", "reset-shell")
    "File Management" = @("reset-file-associations", "reset-fonts")
    "Performance & Power" = @("reset-power", "reset-performance")
    "Applications & Store" = @("reset-browser", "reset-store")
    "Input & Accessibility" = @("reset-input-devices")
    "System Components" = @("reset-features", "reset-environment", "reset-registry")
    "Advanced & Services" = @("reset-services", "reset-security", "reset-advanced")
}

# ===================================================================
# HELPER FUNCTIONS
# ===================================================================

function Show-Help {
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host " $TOOLKIT_NAME v$TOOLKIT_VERSION" -ForegroundColor White
    Write-Host " Interactive PowerShell interface for Windows reset operations" -ForegroundColor Gray
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "USAGE:" -ForegroundColor Yellow
    Write-Host "  .\Reset-Manager.ps1 [OPTIONS]" -ForegroundColor White
    Write-Host ""
    Write-Host "OPTIONS:" -ForegroundColor Yellow
    Write-Host "  -Scripts <script1,script2>  Execute specific reset scripts" -ForegroundColor White
    Write-Host "  -ListScripts                List all available scripts" -ForegroundColor White
    Write-Host "  -Silent                     Run without user interaction" -ForegroundColor White
    Write-Host "  -CreateBackup               Create backups before reset (default: true)" -ForegroundColor White
    Write-Host "  -Force                      Skip confirmation prompts" -ForegroundColor White
    Write-Host "  -LogLevel <level>           Set logging level (INFO, WARN, ERROR)" -ForegroundColor White
    Write-Host "  -Help                       Show this help message" -ForegroundColor White
    Write-Host ""
    Write-Host "EXAMPLES:" -ForegroundColor Yellow
    Write-Host "  .\Reset-Manager.ps1" -ForegroundColor White
    Write-Host "    Launch interactive menu" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  .\Reset-Manager.ps1 -Scripts reset-display,reset-audio" -ForegroundColor White
    Write-Host "    Reset display and audio settings" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  .\Reset-Manager.ps1 -ListScripts" -ForegroundColor White
    Write-Host "    Show all available reset scripts" -ForegroundColor Gray
    Write-Host ""
    Write-Host "⚠️  IMPORTANT: Run PowerShell as Administrator" -ForegroundColor Yellow
    Write-Host ""
}

function Show-ScriptList {
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host " Available Reset Scripts" -ForegroundColor White
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    
    foreach ($category in $scriptCategories.GetEnumerator()) {
        Write-Host "📁 $($category.Key)" -ForegroundColor Yellow
        
        foreach ($script in $category.Value) {
            $description = $availableScripts[$script]
            Write-Host "   • $script" -ForegroundColor Cyan -NoNewline
            Write-Host " - $description" -ForegroundColor Gray
        }
        Write-Host ""
    }
    
    Write-Host "Total scripts: $($availableScripts.Count)" -ForegroundColor Green
    Write-Host ""
}

function Show-WelcomeBanner {
    Clear-Host
    Write-Host ""
    Write-Host "██████╗ ███████╗███████╗███████╗████████╗" -ForegroundColor Cyan
    Write-Host "██╔══██╗██╔════╝██╔════╝██╔════╝╚══██╔══╝" -ForegroundColor Cyan
    Write-Host "██████╔╝█████╗  ███████╗█████╗     ██║   " -ForegroundColor Cyan
    Write-Host "██╔══██╗██╔══╝  ╚════██║██╔══╝     ██║   " -ForegroundColor Cyan
    Write-Host "██║  ██║███████╗███████║███████╗   ██║   " -ForegroundColor Cyan
    Write-Host "╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝   ╚═╝   " -ForegroundColor Cyan
    Write-Host ""
    Write-Host "            Windows Reset Toolkit v$TOOLKIT_VERSION" -ForegroundColor White
    Write-Host "         Comprehensive Windows settings reset utility" -ForegroundColor Gray
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor DarkCyan
    Write-Host " Author: jomardyan | GitHub: github.com/jomardyan/ReSet2" -ForegroundColor Gray
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor DarkCyan
    Write-Host ""
}

function Show-MainMenu {
    do {
        Clear-Host
        Show-WelcomeBanner
        
        Write-Host "📋 MAIN MENU" -ForegroundColor Yellow
        Write-Host ""
        Write-Host " [1]  🌐 Language & Regional Settings" -ForegroundColor Cyan
        Write-Host " [2]  🖥️  Display & Audio Settings" -ForegroundColor Cyan
        Write-Host " [3]  🌐 Network & Connectivity" -ForegroundColor Cyan
        Write-Host " [4]  🔐 Security & Privacy" -ForegroundColor Cyan
        Write-Host " [5]  🔍 Search & Interface" -ForegroundColor Cyan
        Write-Host " [6]  📁 File Management" -ForegroundColor Cyan
        Write-Host " [7]  ⚡ Performance & Power" -ForegroundColor Cyan
        Write-Host " [8]  🌐 Applications & Store" -ForegroundColor Cyan
        Write-Host " [9]  ⌨️  Input & Accessibility" -ForegroundColor Cyan
        Write-Host " [10] 🛠️  System Components" -ForegroundColor Cyan
        Write-Host " [11] ⚡ Advanced & Services" -ForegroundColor Cyan
        Write-Host ""
        Write-Host " [A]  🚀 Run All Reset Scripts" -ForegroundColor Green
        Write-Host " [L]  📄 List All Available Scripts" -ForegroundColor White
        Write-Host " [B]  💾 Backup Management" -ForegroundColor Magenta
        Write-Host " [H]  ❓ Help & Documentation" -ForegroundColor White
        Write-Host " [0]  ❌ Exit" -ForegroundColor Red
        Write-Host ""
        
        # Show system information
        $osVersion = [System.Environment]::OSVersion.VersionString
        $psVersion = $PSVersionTable.PSVersion.ToString()
        Write-Host "💻 System: $osVersion | PowerShell: v$psVersion" -ForegroundColor DarkGray
        Write-Host ""
        
        $choice = Read-Host "Select an option"
        
        switch ($choice.ToUpper()) {
            "1" { Show-CategoryMenu -Category "Language & Regional" }
            "2" { Show-CategoryMenu -Category "Display & Audio" }
            "3" { Show-CategoryMenu -Category "Network & Connectivity" }
            "4" { Show-CategoryMenu -Category "Security & Privacy" }
            "5" { Show-CategoryMenu -Category "Search & Interface" }
            "6" { Show-CategoryMenu -Category "File Management" }
            "7" { Show-CategoryMenu -Category "Performance & Power" }
            "8" { Show-CategoryMenu -Category "Applications & Store" }
            "9" { Show-CategoryMenu -Category "Input & Accessibility" }
            "10" { Show-CategoryMenu -Category "System Components" }
            "11" { Show-CategoryMenu -Category "Advanced & Services" }
            "A" { Invoke-AllScripts }
            "L" { Show-ScriptList; Read-Host "Press Enter to continue" }
            "B" { Show-BackupMenu }
            "H" { Show-Help; Read-Host "Press Enter to continue" }
            "0" { return }
            default { 
                Write-Host "Invalid choice. Press Enter to try again." -ForegroundColor Red
                Read-Host
            }
        }
    } while ($true)
}

function Show-CategoryMenu {
    param([string]$Category)
    
    $scripts = $scriptCategories[$Category]
    
    do {
        Clear-Host
        Write-ReSetHeader -Title "$Category Reset Scripts" -Description "Select scripts to run from this category"
        
        for ($i = 0; $i -lt $scripts.Count; $i++) {
            $script = $scripts[$i]
            $description = $availableScripts[$script]
            Write-Host " [$($i + 1)] " -ForegroundColor Yellow -NoNewline
            Write-Host "$script" -ForegroundColor Cyan -NoNewline
            Write-Host " - $description" -ForegroundColor Gray
        }
        
        Write-Host ""
        Write-Host " [A] Run All Scripts in Category" -ForegroundColor Green
        Write-Host " [B] Back to Main Menu" -ForegroundColor White
        Write-Host ""
        
        $choice = Read-Host "Select script to run"
        
        if ($choice.ToUpper() -eq "A") {
            Invoke-CategoryScripts -Category $Category
            Read-Host "Press Enter to continue"
        }
        elseif ($choice.ToUpper() -eq "B") {
            return
        }
        elseif ($choice -match '^\d+$') {
            $index = [int]$choice - 1
            if ($index -ge 0 -and $index -lt $scripts.Count) {
                $scriptName = $scripts[$index]
                Invoke-ResetScript -ScriptName $scriptName
                Read-Host "Press Enter to continue"
            } else {
                Write-Host "Invalid choice. Press Enter to try again." -ForegroundColor Red
                Read-Host
            }
        } else {
            Write-Host "Invalid choice. Press Enter to try again." -ForegroundColor Red
            Read-Host
        }
    } while ($true)
}

function Show-BackupMenu {
    do {
        Clear-Host
        Write-ReSetHeader -Title "Backup Management" -Description "Manage backups and restore operations"
        
        Write-Host " [1] View Available Backups" -ForegroundColor Cyan
        Write-Host " [2] Create Manual Backup" -ForegroundColor Cyan
        Write-Host " [3] Restore from Backup" -ForegroundColor Cyan
        Write-Host " [4] Clean Old Backups" -ForegroundColor Cyan
        Write-Host " [B] Back to Main Menu" -ForegroundColor White
        Write-Host ""
        
        $choice = Read-Host "Select option"
        
        switch ($choice.ToUpper()) {
            "1" { Show-AvailableBackups }
            "2" { Invoke-ManualBackup }
            "3" { Invoke-BackupRestore }
            "4" { Invoke-CleanBackups }
            "B" { return }
            default { 
                Write-Host "Invalid choice. Press Enter to try again." -ForegroundColor Red
                Read-Host
            }
        }
    } while ($true)
}

function Invoke-ResetScript {
    param([string]$ScriptName)
    
    $scriptFile = Join-Path $scriptsPath "$ScriptName.ps1"
    
    if (!(Test-Path $scriptFile)) {
        Write-Host "❌ Script not found: $scriptFile" -ForegroundColor Red
        return
    }
    
    try {
        Write-Host ""
        Write-Host "🚀 Executing: $ScriptName" -ForegroundColor Green
        Write-Host "📁 Script: $scriptFile" -ForegroundColor Gray
        Write-Host ""
        
        $params = @{
            Silent = $Silent
            CreateBackup = (-not $NoBackup)
            Force = $Force
        }
        
        & $scriptFile @params
        
        Write-Host ""
        Write-Host "✅ Script completed: $ScriptName" -ForegroundColor Green
    }
    catch {
        Write-Host ""
        Write-Host "❌ Script failed: $ScriptName" -ForegroundColor Red
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
        Write-ReSetLog "Script execution failed: $ScriptName - $($_.Exception.Message)" "ERROR"
    }
}

function Invoke-CategoryScripts {
    param([string]$Category)
    
    $scripts = $scriptCategories[$Category]
    $totalScripts = $scripts.Count
    $successCount = 0
    $failCount = 0
    
    Write-Host ""
    Write-Host "🚀 Running all scripts in category: $Category" -ForegroundColor Green
    Write-Host "📊 Total scripts: $totalScripts" -ForegroundColor Cyan
    Write-Host ""
    
    for ($i = 0; $i -lt $scripts.Count; $i++) {
        $script = $scripts[$i]
        $current = $i + 1
        
        Write-Host "[$current/$totalScripts] Executing: $script" -ForegroundColor Yellow
        
        try {
            Invoke-ResetScript -ScriptName $script
            $successCount++
        }
        catch {
            $failCount++
            Write-Host "Failed: $script" -ForegroundColor Red
        }
        
        if ($i -lt $scripts.Count - 1) {
            Start-Sleep -Seconds 2
        }
    }
    
    Write-Host ""
    Write-Host "📊 Category Execution Summary:" -ForegroundColor Cyan
    Write-Host "   ✅ Successful: $successCount" -ForegroundColor Green
    Write-Host "   ❌ Failed: $failCount" -ForegroundColor Red
    Write-Host "   📈 Success Rate: $([math]::Round(($successCount / $totalScripts) * 100, 1))%" -ForegroundColor White
}

function Invoke-AllScripts {
    if (-not $Force) {
        Write-Host ""
        Write-Host "⚠️  WARNING: This will run ALL reset scripts!" -ForegroundColor Yellow
        Write-Host "This operation will reset most Windows settings to defaults." -ForegroundColor Yellow
        Write-Host ""
        $confirm = Read-Host "Are you sure you want to continue? (y/N)"
        
        if ($confirm.ToLower() -ne "y") {
            Write-Host "Operation cancelled." -ForegroundColor Gray
            return
        }
    }
    
    $allScripts = $availableScripts.Keys
    $totalScripts = $allScripts.Count
    $successCount = 0
    $failCount = 0
    
    Write-Host ""
    Write-Host "🚀 Running ALL reset scripts..." -ForegroundColor Green
    Write-Host "📊 Total scripts: $totalScripts" -ForegroundColor Cyan
    Write-Host ""
    
    foreach ($category in $scriptCategories.GetEnumerator()) {
        Write-Host ""
        Write-Host "📁 Category: $($category.Key)" -ForegroundColor Yellow
        Write-Host "─" * 50 -ForegroundColor DarkGray
        
        foreach ($script in $category.Value) {
            try {
                Invoke-ResetScript -ScriptName $script
                $successCount++
            }
            catch {
                $failCount++
            }
            
            Start-Sleep -Seconds 1
        }
    }
    
    Write-Host ""
    Write-Host "🎉 ALL SCRIPTS EXECUTION COMPLETE!" -ForegroundColor Green
    Write-Host "📊 Final Summary:" -ForegroundColor Cyan
    Write-Host "   ✅ Successful: $successCount" -ForegroundColor Green
    Write-Host "   ❌ Failed: $failCount" -ForegroundColor Red
    Write-Host "   📈 Success Rate: $([math]::Round(($successCount / $totalScripts) * 100, 1))%" -ForegroundColor White
    Write-Host ""
    Write-Host "⚠️  IMPORTANT: Please restart your computer for all changes to take effect." -ForegroundColor Yellow
}

function Show-AvailableBackups {
    $backupPath = Join-Path $scriptPath "backups"
    
    if (!(Test-Path $backupPath)) {
        Write-Host "No backups found." -ForegroundColor Yellow
        Read-Host "Press Enter to continue"
        return
    }
    
    $backups = Get-ChildItem -Path $backupPath -Directory | Sort-Object LastWriteTime -Descending
    
    if ($backups.Count -eq 0) {
        Write-Host "No backups found." -ForegroundColor Yellow
        Read-Host "Press Enter to continue"
        return
    }
    
    Write-Host ""
    Write-Host "💾 Available Backups:" -ForegroundColor Cyan
    Write-Host ""
    
    for ($i = 0; $i -lt $backups.Count; $i++) {
        $backup = $backups[$i]
        $size = (Get-ChildItem -Path $backup.FullName -Recurse | Measure-Object -Property Length -Sum).Sum
        $sizeStr = if ($size -gt 1MB) { "{0:N1} MB" -f ($size / 1MB) } else { "{0:N0} KB" -f ($size / 1KB) }
        
        Write-Host " [$($i + 1)] " -ForegroundColor Yellow -NoNewline
        Write-Host "$($backup.Name)" -ForegroundColor White -NoNewline
        Write-Host " ($sizeStr, $($backup.LastWriteTime.ToString('yyyy-MM-dd HH:mm')))" -ForegroundColor Gray
    }
    
    Read-Host "`nPress Enter to continue"
}

function Invoke-ManualBackup {
    Write-Host "Manual backup functionality would be implemented here." -ForegroundColor Yellow
    Read-Host "Press Enter to continue"
}

function Invoke-BackupRestore {
    Write-Host "Backup restore functionality would be implemented here." -ForegroundColor Yellow
    Read-Host "Press Enter to continue"
}

function Invoke-CleanBackups {
    Write-Host "Backup cleanup functionality would be implemented here." -ForegroundColor Yellow
    Read-Host "Press Enter to continue"
}

# ===================================================================
# MAIN EXECUTION
# ===================================================================

function Main {
    try {
        # Validate environment
        Assert-AdminRights
        
        if (!(Test-WindowsVersion)) {
            throw "This toolkit requires Windows 10 or later"
        }
        
        # Handle command line arguments
        if ($Help) {
            Show-Help
            return
        }
        
        if ($ListScripts) {
            Show-ScriptList
            return
        }
        
        if ($Scripts.Count -gt 0) {
            # Execute specified scripts
            foreach ($script in $Scripts) {
                if ($availableScripts.ContainsKey($script)) {
                    Invoke-ResetScript -ScriptName $script
                } else {
                    Write-Host "Unknown script: $script" -ForegroundColor Red
                }
            }
            return
        }
        
        # Launch interactive menu
        Show-MainMenu
        
    }
    catch {
        Write-Host ""
        Write-Host "❌ Fatal Error: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host ""
        exit 1
    }
}

# Run the main function
Main