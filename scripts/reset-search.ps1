# ===================================================================
# Reset Windows Search Script
# File: reset-search.ps1
# Author: jomardyan
# Description: Resets Windows Search and indexing settings
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

$operationName = "Windows Search Reset"

try {
    Assert-AdminRights
    $operation = Start-ReSetOperation -OperationName $operationName
    
    # Stop Windows Search service
    Write-ProgressStep -StepName "Stopping Windows Search service" -CurrentStep 1 -TotalSteps 8
    Stop-Service -Name "WSearch" -Force -ErrorAction SilentlyContinue
    
    # Clear search database
    Write-ProgressStep -StepName "Clearing search database" -CurrentStep 2 -TotalSteps 8
    $searchData = "$env:ProgramData\Microsoft\Search\Data"
    if (Test-Path $searchData) {
        Remove-Item -Path "$searchData\*" -Recurse -Force -ErrorAction SilentlyContinue
    }
    
    # Reset search settings
    Write-ProgressStep -StepName "Resetting search settings" -CurrentStep 3 -TotalSteps 8
    $searchPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search"
    Set-RegistryValue -Path $searchPath -Name "BingSearchEnabled" -Value 1 -Type DWord
    Set-RegistryValue -Path $searchPath -Name "AllowSearchToUseLocation" -Value 1 -Type DWord
    Set-RegistryValue -Path $searchPath -Name "CortanaEnabled" -Value 0 -Type DWord
    
    # Reset indexing locations
    Write-ProgressStep -StepName "Resetting indexing locations" -CurrentStep 4 -TotalSteps 8
    $indexPath = "HKLM:\SOFTWARE\Microsoft\Windows Search"
    Set-RegistryValue -Path $indexPath -Name "EnableIndexingOnBattery" -Value 1 -Type DWord
    
    # Rebuild search index
    Write-ProgressStep -StepName "Rebuilding search index" -CurrentStep 5 -TotalSteps 8
    try {
        $null = & rundll32 shell32.dll,Control_RunDLL srchadmin.dll 2>&1
    } catch {}
    
    # Reset search history
    Write-ProgressStep -StepName "Clearing search history" -CurrentStep 6 -TotalSteps 8
    $historyPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\WordWheelQuery"
    if (Test-Path $historyPath) {
        Remove-RegistryKey -Path $historyPath
    }
    
    # Reset search suggestions
    Write-ProgressStep -StepName "Resetting search suggestions" -CurrentStep 7 -TotalSteps 8
    Set-RegistryValue -Path $searchPath -Name "DeviceHistoryEnabled" -Value 1 -Type DWord
    Set-RegistryValue -Path $searchPath -Name "HistoryViewEnabled" -Value 1 -Type DWord
    
    # Start Windows Search service
    Write-ProgressStep -StepName "Starting Windows Search service" -CurrentStep 8 -TotalSteps 8
    Start-Service -Name "WSearch" -ErrorAction SilentlyContinue
    
    Write-ReSetLog "Windows Search reset completed successfully" "SUCCESS"
    Complete-ReSetOperation -OperationInfo $operation -Success $true
}
catch {
    Complete-ReSetOperation -OperationInfo $operation -Success $false -ErrorMessage $_.Exception.Message
    throw
}