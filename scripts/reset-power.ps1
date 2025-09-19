# ===================================================================
# Reset Power Management Script
# File: reset-power.ps1
# Author: jomardyan
# Description: Resets power management settings to defaults
# Version: 1.0.0
# ===================================================================

#Requires -Version 5.0
#Requires -RunAsAdministrator

param([switch]$Silent, [switch]$CreateBackup = $true, [switch]$Force)

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
Import-Module (Join-Path $scriptPath "ReSetUtils.psm1") -Force

$operationName = "Power Management Reset"

try {
    Assert-AdminRights
    $operation = Start-ReSetOperation -OperationName $operationName
    
    # Reset power schemes
    Write-ProgressStep -StepName "Resetting power schemes" -CurrentStep 1 -TotalSteps 6
    try {
        $null = & powercfg /restoredefaultschemes 2>&1
        $null = & powercfg /setactive SCHEME_BALANCED 2>&1
    } catch {}
    
    # Reset advanced power settings
    Write-ProgressStep -StepName "Resetting advanced settings" -CurrentStep 2 -TotalSteps 6
    try {
        $null = & powercfg /change monitor-timeout-ac 10 2>&1
        $null = & powercfg /change monitor-timeout-dc 5 2>&1
        $null = & powercfg /change standby-timeout-ac 30 2>&1
        $null = & powercfg /change standby-timeout-dc 15 2>&1
    } catch {}
    
    # Reset hibernation
    Write-ProgressStep -StepName "Resetting hibernation" -CurrentStep 3 -TotalSteps 6
    try {
        $null = & powercfg /hibernate on 2>&1
    } catch {}
    
    # Reset fast startup
    Write-ProgressStep -StepName "Resetting fast startup" -CurrentStep 4 -TotalSteps 6
    $fastStartupPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power"
    Set-RegistryValue -Path $fastStartupPath -Name "HiberbootEnabled" -Value 1 -Type DWord
    
    # Reset USB power settings
    Write-ProgressStep -StepName "Resetting USB power settings" -CurrentStep 5 -TotalSteps 6
    try {
        $null = & powercfg /setdcvalueindex SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0 2>&1
    } catch {}
    
    # Reset power button action
    Write-ProgressStep -StepName "Resetting power button" -CurrentStep 6 -TotalSteps 6
    $powerButtonPath = "HKCU:\Control Panel\PowerCfg"
    Set-RegistryValue -Path $powerButtonPath -Name "PowerButtonAction" -Value 1 -Type DWord
    
    Write-ReSetLog "Power management reset completed successfully" "SUCCESS"
    Complete-ReSetOperation -OperationInfo $operation -Success $true
}
catch {
    Complete-ReSetOperation -OperationInfo $operation -Success $false -ErrorMessage $_.Exception.Message
    throw
}