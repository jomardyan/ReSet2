# ===================================================================
# Reset Advanced System Components Script
# File: reset-advanced.ps1
# Author: jomardyan  
# Description: Advanced system component resets and specialized functions
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

$operationName = "Advanced System Reset"

try {
    Assert-AdminRights
    $operation = Start-ReSetOperation -OperationName $operationName
    
    # Functions 26-50: Advanced system resets
    Write-ProgressStep -StepName "Resetting Windows features" -CurrentStep 1 -TotalSteps 25
    try {
        Enable-WindowsOptionalFeature -Online -FeatureName "NetFx3" -All -NoRestart -ErrorAction SilentlyContinue
        Enable-WindowsOptionalFeature -Online -FeatureName "IIS-WebServerRole" -All -NoRestart -ErrorAction SilentlyContinue
    } catch {
                # Silently continue - non-critical operation
            }
    
    Write-ProgressStep -StepName "Resetting environment variables" -CurrentStep 2 -TotalSteps 25
    [Environment]::SetEnvironmentVariable("TEMP", "$env:SystemRoot\TEMP", "Machine")
    [Environment]::SetEnvironmentVariable("TMP", "$env:SystemRoot\TEMP", "Machine")
    
    Write-ProgressStep -StepName "Resetting registry permissions" -CurrentStep 3 -TotalSteps 25
    try {
        $null = & icacls "$env:SystemRoot\System32\config\SOFTWARE" /grant "NT AUTHORITY\SYSTEM:(F)" 2>&1
    } catch {
                # Silently continue - non-critical operation
            }
    
    Write-ProgressStep -StepName "Resetting system restore" -CurrentStep 4 -TotalSteps 25
    try {
        Enable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue
        $null = & vssadmin resize shadowstorage /for=C: /on=C: /maxsize=10% 2>&1
    } catch {
                # Silently continue - non-critical operation
            }
    
    Write-ProgressStep -StepName "Resetting Windows licensing" -CurrentStep 5 -TotalSteps 25
    try {
        $null = & slmgr /rearm 2>&1
    } catch {
                # Silently continue - non-critical operation
            }
    
    Write-ProgressStep -StepName "Resetting component store" -CurrentStep 6 -TotalSteps 25
    try {
        $null = & dism /online /cleanup-image /startcomponentcleanup /resetbase 2>&1
    } catch {
                # Silently continue - non-critical operation
            }
    
    Write-ProgressStep -StepName "Resetting WMI repository" -CurrentStep 7 -TotalSteps 25
    try {
        $null = & winmgmt /resetrepository 2>&1
    } catch {
                # Silently continue - non-critical operation
            }
    
    Write-ProgressStep -StepName "Resetting print spooler" -CurrentStep 8 -TotalSteps 25
    try {
        Stop-Service -Name "Spooler" -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "$env:SystemRoot\System32\spool\PRINTERS\*" -Force -ErrorAction SilentlyContinue
        Start-Service -Name "Spooler" -ErrorAction SilentlyContinue
    } catch {
                # Silently continue - non-critical operation
            }
    
    Write-ProgressStep -StepName "Resetting event logs" -CurrentStep 9 -TotalSteps 25
    $logs = @("Application", "System", "Security", "Setup")
    foreach ($log in $logs) {
        try { Clear-EventLog -LogName $log -ErrorAction SilentlyContinue } catch {
                # Silently continue - non-critical operation
            }
    }
    
    Write-ProgressStep -StepName "Resetting user profiles" -CurrentStep 10 -TotalSteps 25
    $profilePath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList"
    Set-RegistryValue -Path $profilePath -Name "UseDefaultProfile" -Value 0 -Type DWord
    
    Write-ProgressStep -StepName "Resetting themes and appearance" -CurrentStep 11 -TotalSteps 25
    $themePath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize"
    Set-RegistryValue -Path $themePath -Name "AppsUseLightTheme" -Value 1 -Type DWord
    Set-RegistryValue -Path $themePath -Name "SystemUsesLightTheme" -Value 1 -Type DWord
    
    Write-ProgressStep -StepName "Resetting desktop icons" -CurrentStep 12 -TotalSteps 25
    $desktopPath = "HKCU:\SOFTWARE\Microsoft\Windows\Shell\Bags\1\Desktop"
    Set-RegistryValue -Path $desktopPath -Name "IconSize" -Value 48 -Type DWord
    
    Write-ProgressStep -StepName "Resetting taskbar settings" -CurrentStep 13 -TotalSteps 25
    $taskbarPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    Set-RegistryValue -Path $taskbarPath -Name "TaskbarSizeMove" -Value 1 -Type DWord
    
    Write-ProgressStep -StepName "Resetting notification settings" -CurrentStep 14 -TotalSteps 25
    $notificationPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\PushNotifications"
    Set-RegistryValue -Path $notificationPath -Name "ToastEnabled" -Value 1 -Type DWord
    
    Write-ProgressStep -StepName "Resetting telemetry settings" -CurrentStep 15 -TotalSteps 25
    $telemetryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection"
    Set-RegistryValue -Path $telemetryPath -Name "AllowTelemetry" -Value 1 -Type DWord
    
    Write-ProgressStep -StepName "Resetting storage sense" -CurrentStep 16 -TotalSteps 25
    $storagePath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\StorageSense"
    Set-RegistryValue -Path $storagePath -Name "01" -Value 1 -Type DWord
    
    Write-ProgressStep -StepName "Resetting cortana settings" -CurrentStep 17 -TotalSteps 25
    $cortanaPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search"
    Set-RegistryValue -Path $cortanaPath -Name "CortanaEnabled" -Value 0 -Type DWord
    
    Write-ProgressStep -StepName "Resetting onedrive settings" -CurrentStep 18 -TotalSteps 25
    $onedrivePath = "HKCU:\SOFTWARE\Microsoft\OneDrive"
    Set-RegistryValue -Path $onedrivePath -Name "DisableFileSyncNGSC" -Value 0 -Type DWord
    
    Write-ProgressStep -StepName "Resetting accessibility settings" -CurrentStep 19 -TotalSteps 25
    $accessPath = "HKCU:\Control Panel\Accessibility"
    Set-RegistryValue -Path "$accessPath\StickyKeys" -Name "Flags" -Value "510" -Type String
    Set-RegistryValue -Path "$accessPath\Keyboard Response" -Name "Flags" -Value "122" -Type String
    
    Write-ProgressStep -StepName "Resetting error reporting" -CurrentStep 20 -TotalSteps 25
    $errorPath = "HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting"
    Set-RegistryValue -Path $errorPath -Name "Disabled" -Value 0 -Type DWord
    
    Write-ProgressStep -StepName "Resetting automatic maintenance" -CurrentStep 21 -TotalSteps 25
    $maintPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\Maintenance"
    Set-RegistryValue -Path $maintPath -Name "MaintenanceDisabled" -Value 0 -Type DWord
    
    Write-ProgressStep -StepName "Resetting windows tips" -CurrentStep 22 -TotalSteps 25
    $tipsPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
    Set-RegistryValue -Path $tipsPath -Name "SoftLandingEnabled" -Value 1 -Type DWord
    
    Write-ProgressStep -StepName "Resetting game mode" -CurrentStep 23 -TotalSteps 25
    $gamePath = "HKCU:\SOFTWARE\Microsoft\GameBar"
    Set-RegistryValue -Path $gamePath -Name "AllowAutoGameMode" -Value 1 -Type DWord
    
    Write-ProgressStep -StepName "Resetting clipboard history" -CurrentStep 24 -TotalSteps 25
    $clipboardPath = "HKCU:\SOFTWARE\Microsoft\Clipboard"
    Set-RegistryValue -Path $clipboardPath -Name "EnableClipboardHistory" -Value 1 -Type DWord
    
    Write-ProgressStep -StepName "Final system cleanup" -CurrentStep 25 -TotalSteps 25
    try {
        $null = & cleanmgr /sagerun:1 2>&1
        $null = & sfc /scannow 2>&1
    } catch {
                # Silently continue - non-critical operation
            }
    
    Write-ReSetLog "Advanced system components reset completed" "SUCCESS"
    Complete-ReSetOperation -OperationInfo $operation -Success $true
}
catch {
    Complete-ReSetOperation -OperationInfo $operation -Success $false -ErrorMessage $_.Exception.Message
    throw
}
