# ===================================================================
# Reset Windows Defender Script
# File: reset-defender.ps1
# Author: jomardyan
# Description: Resets Windows Defender settings to defaults
# Version: 1.0.0
# ===================================================================

#Requires -Version 5.0
#Requires -RunAsAdministrator

param(
    [switch]$Silent,
    [switch]$CreateBackup = $true,
    [string]$BackupPath = "",
    [switch]$Force
)

# Import utility module
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
Import-Module (Join-Path $scriptPath "ReSetUtils.psm1") -Force

$operationName = "Windows Defender Reset"

try {
    Assert-AdminRights
    if (!(Test-WindowsVersion)) { throw "Unsupported Windows version" }
    
    $operation = Start-ReSetOperation -OperationName $operationName
    
    if (-not $Silent) {
        Write-ReSetHeader -Title $operationName -Description "Reset Windows Defender and security settings"
        if (-not $Force) {
            $confirmed = Confirm-ReSetOperation -OperationName $operationName -Warning "This will reset Windows Defender settings to defaults."
            if (-not $confirmed) { Write-ReSetLog "Operation cancelled by user" "WARN"; return }
        }
    }
    
    # Backup Defender settings
    if ($CreateBackup) {
        Write-ProgressStep -StepName "Creating Defender backup" -CurrentStep 1 -TotalSteps 12
        $registryBackupPaths = @(
            "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows Defender",
            "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows Defender"
        )
        try {
            $backupDir = New-ReSetBackup -BackupName "DefenderSettings" -RegistryPaths $registryBackupPaths
        } catch {
            if (-not $Force) { throw "Backup failed" }
        }
    }
    
    # Reset real-time protection
    Write-ProgressStep -StepName "Resetting real-time protection" -CurrentStep 2 -TotalSteps 12
    try {
        Set-MpPreference -DisableRealtimeMonitoring $false
        Set-MpPreference -DisableBehaviorMonitoring $false
        Set-MpPreference -DisableIOAVProtection $false
        Set-MpPreference -DisableOnAccessProtection $false
        Set-MpPreference -DisableIntrusionPreventionSystem $false
        Write-ReSetLog "Real-time protection enabled" "SUCCESS"
    } catch {
        Write-ReSetLog "Failed to reset real-time protection: $($_.Exception.Message)" "WARN"
    }
    
    # Reset scan settings
    Write-ProgressStep -StepName "Resetting scan settings" -CurrentStep 3 -TotalSteps 12
    try {
        Set-MpPreference -ScanParameters 1  # Quick scan
        Set-MpPreference -CheckForSignaturesBeforeRunningScan $true
        Set-MpPreference -ScanOnlyIfIdleEnabled $true
        Set-MpPreference -ScanScheduleDay 0  # Every day
        Set-MpPreference -ScanScheduleTime 120  # 2:00 AM
        Set-MpPreference -RemediationScheduleDay 0
        Set-MpPreference -RemediationScheduleTime 120
        Write-ReSetLog "Scan settings reset to defaults" "SUCCESS"
    } catch {
        Write-ReSetLog "Failed to reset scan settings: $($_.Exception.Message)" "WARN"
    }
    
    # Reset cloud protection
    Write-ProgressStep -StepName "Resetting cloud protection" -CurrentStep 4 -TotalSteps 12
    try {
        Set-MpPreference -MAPSReporting 2  # Advanced MAPS
        Set-MpPreference -SubmitSamplesConsent 1  # Send safe samples
        Set-MpPreference -DisableBlockAtFirstSeen $false
        Write-ReSetLog "Cloud protection enabled" "SUCCESS"
    } catch {
        Write-ReSetLog "Failed to reset cloud protection: $($_.Exception.Message)" "WARN"
    }
    
    # Clear exclusions
    Write-ProgressStep -StepName "Clearing exclusions" -CurrentStep 5 -TotalSteps 12
    try {
        # Get and remove path exclusions
        $pathExclusions = Get-MpPreference | Select-Object -ExpandProperty ExclusionPath
        if ($pathExclusions) {
            foreach ($path in $pathExclusions) {
                Remove-MpPreference -ExclusionPath $path -ErrorAction SilentlyContinue
            }
        }
        
        # Get and remove extension exclusions
        $extExclusions = Get-MpPreference | Select-Object -ExpandProperty ExclusionExtension
        if ($extExclusions) {
            foreach ($ext in $extExclusions) {
                Remove-MpPreference -ExclusionExtension $ext -ErrorAction SilentlyContinue
            }
        }
        
        # Get and remove process exclusions
        $processExclusions = Get-MpPreference | Select-Object -ExpandProperty ExclusionProcess
        if ($processExclusions) {
            foreach ($process in $processExclusions) {
                Remove-MpPreference -ExclusionProcess $process -ErrorAction SilentlyContinue
            }
        }
        
        Write-ReSetLog "All exclusions cleared" "SUCCESS"
    } catch {
        Write-ReSetLog "Failed to clear exclusions: $($_.Exception.Message)" "WARN"
    }
    
    # Reset threat actions
    Write-ProgressStep -StepName "Resetting threat actions" -CurrentStep 6 -TotalSteps 12
    try {
        Set-MpPreference -LowThreatDefaultAction 1    # Clean
        Set-MpPreference -ModerateThreatDefaultAction 1  # Clean
        Set-MpPreference -HighThreatDefaultAction 1   # Clean
        Set-MpPreference -SevereThreatDefaultAction 1 # Clean
        Write-ReSetLog "Threat actions reset to clean" "SUCCESS"
    } catch {
        Write-ReSetLog "Failed to reset threat actions: $($_.Exception.Message)" "WARN"
    }
    
    # Reset advanced features
    Write-ProgressStep -StepName "Resetting advanced features" -CurrentStep 7 -TotalSteps 12
    try {
        Set-MpPreference -DisableArchiveScanning $false
        Set-MpPreference -DisableEmailScanning $false
        Set-MpPreference -DisableRemovableDriveScanning $false
        Set-MpPreference -DisableScriptScanning $false
        Set-MpPreference -DisableCatchupFullScan $false
        Set-MpPreference -DisableCatchupQuickScan $false
        Write-ReSetLog "Advanced scanning features enabled" "SUCCESS"
    } catch {
        Write-ReSetLog "Failed to reset advanced features: $($_.Exception.Message)" "WARN"
    }
    
    # Reset Windows Firewall
    Write-ProgressStep -StepName "Resetting Windows Firewall" -CurrentStep 8 -TotalSteps 12
    try {
        $null = & netsh advfirewall reset 2>&1
        $null = & netsh advfirewall set allprofiles state on 2>&1
        Write-ReSetLog "Windows Firewall reset and enabled" "SUCCESS"
    } catch {
        Write-ReSetLog "Failed to reset firewall: $($_.Exception.Message)" "WARN"
    }
    
    # Reset SmartScreen
    Write-ProgressStep -StepName "Resetting SmartScreen" -CurrentStep 9 -TotalSteps 12
    $smartScreenPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer"
    Set-RegistryValue -Path $smartScreenPath -Name "SmartScreenEnabled" -Value "RequireAdmin" -Type String
    
    $edgeSmartScreenPath = "HKCU:\SOFTWARE\Microsoft\Edge\SmartScreenEnabled"
    Set-RegistryValue -Path $edgeSmartScreenPath -Name "(Default)" -Value 1 -Type DWord
    
    Write-ReSetLog "SmartScreen enabled" "SUCCESS"
    
    # Reset Security Center
    Write-ProgressStep -StepName "Resetting Security Center" -CurrentStep 10 -TotalSteps 12
    $secCenterPath = "HKLM:\SOFTWARE\Microsoft\Security Center"
    Set-RegistryValue -Path $secCenterPath -Name "AntiVirusDisableNotify" -Value 0 -Type DWord
    Set-RegistryValue -Path $secCenterPath -Name "FirewallDisableNotify" -Value 0 -Type DWord
    Set-RegistryValue -Path $secCenterPath -Name "UpdatesDisableNotify" -Value 0 -Type DWord
    
    # Update definitions
    Write-ProgressStep -StepName "Updating definitions" -CurrentStep 11 -TotalSteps 12
    try {
        Update-MpSignature -ErrorAction SilentlyContinue
        Write-ReSetLog "Defender definitions updated" "SUCCESS"
    } catch {
        Write-ReSetLog "Failed to update definitions: $($_.Exception.Message)" "WARN"
    }
    
    # Restart Defender services
    Write-ProgressStep -StepName "Restarting Defender services" -CurrentStep 12 -TotalSteps 12
    $defenderServices = @("WinDefend", "SecurityHealthService", "Sense")
    foreach ($service in $defenderServices) {
        try {
            Restart-WindowsService -ServiceName $service
        } catch {
            Write-ReSetLog "Service $service may not be available" "INFO"
        }
    }
    
    Write-ReSetLog "Windows Defender reset completed successfully" "SUCCESS"
    
    if (-not $Silent) {
        Write-Host ""
        Write-Host "✅ Windows Defender Reset Complete!" -ForegroundColor Green
        Write-Host "📋 Changes applied:" -ForegroundColor Cyan
        Write-Host "   • Real-time protection: Enabled" -ForegroundColor White
        Write-Host "   • Cloud protection: Enabled (Advanced MAPS)" -ForegroundColor White
        Write-Host "   • Automatic sample submission: Enabled" -ForegroundColor White
        Write-Host "   • All exclusions: Cleared" -ForegroundColor White
        Write-Host "   • Threat actions: Set to clean" -ForegroundColor White
        Write-Host "   • Advanced scanning: Enabled" -ForegroundColor White
        Write-Host "   • Windows Firewall: Reset and enabled" -ForegroundColor White
        Write-Host "   • SmartScreen: Enabled" -ForegroundColor White
        Write-Host "   • Security notifications: Enabled" -ForegroundColor White
        Write-Host ""
        Write-Host "🔄 Definitions have been updated" -ForegroundColor Green
    }
    
    Complete-ReSetOperation -OperationInfo $operation -Success $true
}
catch {
    $errorMessage = $_.Exception.Message
    Write-ReSetLog "Operation failed: $errorMessage" "ERROR"
    Complete-ReSetOperation -OperationInfo $operation -Success $false -ErrorMessage $errorMessage
    throw
}
finally {
    Write-Progress -Activity "Windows Reset Operation" -Completed
}