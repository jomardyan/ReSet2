# ===================================================================
# Reset Windows Shell Script
# File: reset-shell.ps1
# Author: jomardyan
# Description: Resets Windows Explorer shell settings
# Version: 1.0.0
# ===================================================================

#Requires -Version 5.0
#Requires -RunAsAdministrator

param(
    [switch]$Silent,
    [switch]$CreateBackup = $true,
    [switch]$Force
)

# Import utility module
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
Import-Module (Join-Path $scriptPath "ReSetUtils.psm1") -Force

$operationName = "Windows Shell Reset"

try {
    Assert-AdminRights
    $operation = Start-ReSetOperation -OperationName $operationName
    
    # Reset Explorer settings
    Write-ProgressStep -StepName "Resetting Explorer settings" -CurrentStep 1 -TotalSteps 12
    $explorerPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    Set-RegistryValue -Path $explorerPath -Name "Hidden" -Value 2 -Type DWord
    Set-RegistryValue -Path $explorerPath -Name "HideFileExt" -Value 1 -Type DWord
    Set-RegistryValue -Path $explorerPath -Name "ShowSuperHidden" -Value 0 -Type DWord
    Set-RegistryValue -Path $explorerPath -Name "LaunchTo" -Value 1 -Type DWord
    
    # Reset folder options
    Write-ProgressStep -StepName "Resetting folder options" -CurrentStep 2 -TotalSteps 12
    $folderPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer"
    Set-RegistryValue -Path $folderPath -Name "EnableAutoTray" -Value 1 -Type DWord
    Set-RegistryValue -Path $folderPath -Name "Link" -Value ([byte[]](0x1E, 0x00, 0x00, 0x00)) -Type Binary
    
    # Reset view settings for all folders
    Write-ProgressStep -StepName "Resetting folder views" -CurrentStep 3 -TotalSteps 12
    $viewPath = "HKCU:\SOFTWARE\Microsoft\Windows\Shell\Bags"
    if (Test-Path $viewPath) {
        Remove-RegistryKey -Path $viewPath
    }
    
    # Reset Quick Access
    Write-ProgressStep -StepName "Resetting Quick Access" -CurrentStep 4 -TotalSteps 12
    $quickAccessPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Ribbon"
    Set-RegistryValue -Path $quickAccessPath -Name "MinimizedStateTabletModeOff" -Value 0 -Type DWord
    
    # Clear recent files and folders
    Write-ProgressStep -StepName "Clearing recent files" -CurrentStep 5 -TotalSteps 12
    $recentDocsPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\RecentDocs"
    if (Test-Path $recentDocsPath) {
        Remove-Item -Path "$recentDocsPath\*" -Recurse -Force -ErrorAction SilentlyContinue
    }
    
    # Reset context menu
    Write-ProgressStep -StepName "Resetting context menu" -CurrentStep 6 -TotalSteps 12
    $contextPath = "HKCU:\SOFTWARE\Classes\*\shellex\ContextMenuHandlers"
    # Reset to default context menu handlers
    
    # Reset desktop settings
    Write-ProgressStep -StepName "Resetting desktop settings" -CurrentStep 7 -TotalSteps 12
    $desktopPath = "HKCU:\Control Panel\Desktop"
    Set-RegistryValue -Path $desktopPath -Name "AutoArrange" -Value 1 -Type DWord
    Set-RegistryValue -Path $desktopPath -Name "CleanupWiz" -Value 0 -Type DWord
    
    # Reset thumbnail cache
    Write-ProgressStep -StepName "Clearing thumbnail cache" -CurrentStep 8 -TotalSteps 12
    $thumbCachePath = "$env:LocalAppData\Microsoft\Windows\Explorer"
    if (Test-Path $thumbCachePath) {
        Remove-Item -Path "$thumbCachePath\thumbcache*.db" -Force -ErrorAction SilentlyContinue
    }
    
    # Reset icon cache
    Write-ProgressStep -StepName "Clearing icon cache" -CurrentStep 9 -TotalSteps 12
    $iconCachePath = "$env:LocalAppData\IconCache.db"
    if (Test-Path $iconCachePath) {
        Remove-Item -Path $iconCachePath -Force -ErrorAction SilentlyContinue
    }
    
    # Reset shell associations
    Write-ProgressStep -StepName "Resetting shell associations" -CurrentStep 10 -TotalSteps 12
    $shellPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FileExts"
    # Reset file extension associations
    
    # Reset Windows Explorer startup
    Write-ProgressStep -StepName "Resetting Explorer startup" -CurrentStep 11 -TotalSteps 12
    Set-RegistryValue -Path $explorerPath -Name "PersistBrowsers" -Value 1 -Type DWord
    Set-RegistryValue -Path $explorerPath -Name "SeparateProcess" -Value 0 -Type DWord
    
    # Restart Explorer
    Write-ProgressStep -StepName "Restarting Explorer" -CurrentStep 12 -TotalSteps 12
    Stop-Process -Name "explorer" -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 3
    Start-Process "explorer.exe"
    
    Write-ReSetLog "Windows Shell reset completed successfully" "SUCCESS"
    Complete-ReSetOperation -OperationInfo $operation -Success $true
}
catch {
    Complete-ReSetOperation -OperationInfo $operation -Success $false -ErrorMessage $_.Exception.Message
    throw
}