# ===================================================================
# Reset Start Menu and Taskbar Script
# File: reset-startmenu.ps1
# Author: jomardyan
# Description: Resets Start Menu and Taskbar settings
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

$operationName = "Start Menu and Taskbar Reset"

try {
    Assert-AdminRights
    $operation = Start-ReSetOperation -OperationName $operationName
    
    # Reset Start Menu layout
    Write-ProgressStep -StepName "Resetting Start Menu layout" -CurrentStep 1 -TotalSteps 10
    $startMenuPath = "$env:LocalAppData\Microsoft\Windows\Shell"
    if (Test-Path $startMenuPath) {
        Remove-Item -Path "$startMenuPath\*" -Recurse -Force -ErrorAction SilentlyContinue
    }
    
    # Reset taskbar settings
    Write-ProgressStep -StepName "Resetting taskbar settings" -CurrentStep 2 -TotalSteps 10
    $taskbarPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    Set-RegistryValue -Path $taskbarPath -Name "TaskbarGlomLevel" -Value 0 -Type DWord
    Set-RegistryValue -Path $taskbarPath -Name "TaskbarSizeMove" -Value 1 -Type DWord
    Set-RegistryValue -Path $taskbarPath -Name "ShowTaskViewButton" -Value 1 -Type DWord
    Set-RegistryValue -Path $taskbarPath -Name "ShowCortanaButton" -Value 0 -Type DWord
    
    # Reset Start Menu settings
    Write-ProgressStep -StepName "Resetting Start Menu settings" -CurrentStep 3 -TotalSteps 10
    $startPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    Set-RegistryValue -Path $startPath -Name "Start_TrackDocs" -Value 1 -Type DWord
    Set-RegistryValue -Path $startPath -Name "Start_TrackProgs" -Value 1 -Type DWord
    Set-RegistryValue -Path $startPath -Name "StartMenuInit" -Value 7 -Type DWord
    
    # Clear pinned items
    Write-ProgressStep -StepName "Clearing pinned items" -CurrentStep 4 -TotalSteps 10
    $pinnedPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Taskband"
    if (Test-Path $pinnedPath) {
        Remove-RegistryKey -Path $pinnedPath
    }
    
    # Reset jump lists
    Write-ProgressStep -StepName "Clearing jump lists" -CurrentStep 5 -TotalSteps 10
    $jumpListPath = "$env:AppData\Microsoft\Windows\Recent\AutomaticDestinations"
    if (Test-Path $jumpListPath) {
        Remove-Item -Path "$jumpListPath\*" -Force -ErrorAction SilentlyContinue
    }
    
    # Reset recent items
    Write-ProgressStep -StepName "Clearing recent items" -CurrentStep 6 -TotalSteps 10
    $recentPath = "$env:AppData\Microsoft\Windows\Recent"
    if (Test-Path $recentPath) {
        Remove-Item -Path "$recentPath\*" -Force -ErrorAction SilentlyContinue
    }
    
    # Reset notification area icons
    Write-ProgressStep -StepName "Resetting notification area" -CurrentStep 7 -TotalSteps 10
    $notifyPath = "HKCU:\SOFTWARE\Classes\Local Settings\Software\Microsoft\Windows\CurrentVersion\TrayNotify"
    if (Test-Path $notifyPath) {
        Remove-RegistryKey -Path $notifyPath
    }
    
    # Reset Start Menu tiles
    Write-ProgressStep -StepName "Resetting Start Menu tiles" -CurrentStep 8 -TotalSteps 10
    $tilesPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\CloudStore"
    if (Test-Path $tilesPath) {
        Remove-RegistryKey -Path $tilesPath
    }
    
    # Reset search box
    Write-ProgressStep -StepName "Resetting search box" -CurrentStep 9 -TotalSteps 10
    Set-RegistryValue -Path $taskbarPath -Name "SearchboxTaskbarMode" -Value 1 -Type DWord
    
    # Restart Explorer
    Write-ProgressStep -StepName "Restarting Explorer" -CurrentStep 10 -TotalSteps 10
    Stop-Process -Name "explorer" -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    Start-Process "explorer.exe"
    
    Write-ReSetLog "Start Menu and Taskbar reset completed successfully" "SUCCESS"
    Complete-ReSetOperation -OperationInfo $operation -Success $true
}
catch {
    Complete-ReSetOperation -OperationInfo $operation -Success $false -ErrorMessage $_.Exception.Message
    throw
}