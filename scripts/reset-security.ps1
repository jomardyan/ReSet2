# ===================================================================
# Reset Security and System Settings Script
# File: reset-security.ps1  
# Author: jomardyan
# Description: Comprehensive security and system settings reset
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

$operationName = "Security and System Reset"

try {
    Assert-AdminRights
    $operation = Start-ReSetOperation -OperationName $operationName
    
    # Functions 16-25: Security and system resets
    Write-ProgressStep -StepName "Resetting UAC settings" -CurrentStep 1 -TotalSteps 10
    $uacPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
    Set-RegistryValue -Path $uacPath -Name "ConsentPromptBehaviorAdmin" -Value 5 -Type DWord
    Set-RegistryValue -Path $uacPath -Name "ConsentPromptBehaviorUser" -Value 3 -Type DWord
    Set-RegistryValue -Path $uacPath -Name "EnableLUA" -Value 1 -Type DWord
    
    Write-ProgressStep -StepName "Resetting Windows Defender" -CurrentStep 2 -TotalSteps 10
    try {
        Set-MpPreference -DisableRealtimeMonitoring $false -ErrorAction SilentlyContinue
        Set-MpPreference -DisableBehaviorMonitoring $false -ErrorAction SilentlyContinue
        Set-MpPreference -DisableIOAVProtection $false -ErrorAction SilentlyContinue
    } catch {
                # Silently continue - non-critical operation
            }
    
    Write-ProgressStep -StepName "Resetting privacy settings" -CurrentStep 3 -TotalSteps 10
    $privacyPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore"
    $capabilities = @("location", "camera", "microphone", "notifications", "contacts", "calendar")
    foreach ($cap in $capabilities) {
        Set-RegistryValue -Path "$privacyPath\$cap" -Name "Value" -Value "Allow" -Type String
    }
    
    Write-ProgressStep -StepName "Resetting Windows Search" -CurrentStep 4 -TotalSteps 10
    try {
        Stop-Service -Name "WSearch" -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "$env:ProgramData\Microsoft\Search\Data\Applications\Windows\*" -Recurse -Force -ErrorAction SilentlyContinue
        Start-Service -Name "WSearch" -ErrorAction SilentlyContinue
    } catch {
                # Silently continue - non-critical operation
            }
    
    Write-ProgressStep -StepName "Resetting Start Menu" -CurrentStep 5 -TotalSteps 10
    $startMenuPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    Set-RegistryValue -Path $startMenuPath -Name "ShowTaskViewButton" -Value 1 -Type DWord
    Set-RegistryValue -Path $startMenuPath -Name "TaskbarGlomLevel" -Value 0 -Type DWord
    
    Write-ProgressStep -StepName "Resetting file associations" -CurrentStep 6 -TotalSteps 10
    try {
        $null = & dism /online /export-defaultappassociations:"$env:TEMP\DefaultAssoc.xml" 2>&1
        $null = & dism /online /import-defaultappassociations:"$env:TEMP\DefaultAssoc.xml" 2>&1
    } catch {
                # Silently continue - non-critical operation
            }
    
    Write-ProgressStep -StepName "Resetting fonts" -CurrentStep 7 -TotalSteps 10
    $fontPath = "HKCU:\Control Panel\Desktop"
    Set-RegistryValue -Path $fontPath -Name "FontSmoothing" -Value "2" -Type String
    Set-RegistryValue -Path $fontPath -Name "FontSmoothingType" -Value 2 -Type DWord
    
    Write-ProgressStep -StepName "Resetting power settings" -CurrentStep 8 -TotalSteps 10
    try {
        $null = & powercfg /restoredefaultschemes 2>&1
        $null = & powercfg /setactive SCHEME_BALANCED 2>&1
    } catch {
                # Silently continue - non-critical operation
            }
    
    Write-ProgressStep -StepName "Resetting browser settings" -CurrentStep 9 -TotalSteps 10
    try {
        $null = & RunDll32.exe InetCpl.cpl,ResetIEtoDefaults 2>&1
    } catch {
                # Silently continue - non-critical operation
            }
    
    Write-ProgressStep -StepName "Resetting input devices" -CurrentStep 10 -TotalSteps 10
    $mousePath = "HKCU:\Control Panel\Mouse"
    Set-RegistryValue -Path $mousePath -Name "MouseSpeed" -Value "1" -Type String
    Set-RegistryValue -Path $mousePath -Name "MouseThreshold1" -Value "6" -Type String
    Set-RegistryValue -Path $mousePath -Name "MouseThreshold2" -Value "10" -Type String
    
    Write-ReSetLog "Security and system settings reset completed" "SUCCESS"
    Complete-ReSetOperation -OperationInfo $operation -Success $true
}
catch {
    Complete-ReSetOperation -OperationInfo $operation -Success $false -ErrorMessage $_.Exception.Message
    throw
}
