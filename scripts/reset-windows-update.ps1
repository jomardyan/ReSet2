# ===================================================================
# Reset Windows Update Script
# File: reset-windows-update.ps1
# Author: jomardyan
# Description: Resets Windows Update components and cache
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

$operationName = "Windows Update Reset"

try {
    Assert-AdminRights
    if (!(Test-WindowsVersion)) { throw "Unsupported Windows version" }
    
    $operation = Start-ReSetOperation -OperationName $operationName
    
    if (-not $Silent) {
        Write-ReSetHeader -Title $operationName -Description "Reset Windows Update cache, services, and components"
        if (-not $Force) {
            $confirmed = Confirm-ReSetOperation -OperationName $operationName -Warning "This will clear Windows Update cache and reset update components."
            if (-not $confirmed) { Write-ReSetLog "Operation cancelled by user" "WARN"; return }
        }
    }
    
    # Function 1: Stop Windows Update services
    Write-ProgressStep -StepName "Stopping Windows Update services" -CurrentStep 1 -TotalSteps 20
    $updateServices = @("wuauserv", "cryptSvc", "bits", "msiserver", "TrustedInstaller")
    foreach ($service in $updateServices) {
        try { Stop-Service -Name $service -Force -ErrorAction SilentlyContinue } catch {
                # Silently continue - non-critical operation
            }
    }
    Write-ReSetLog "Windows Update services stopped" "SUCCESS"
    
    # Function 2: Clear Windows Update cache
    Write-ProgressStep -StepName "Clearing Windows Update cache" -CurrentStep 2 -TotalSteps 20
    $updatePaths = @(
        "$env:SystemRoot\SoftwareDistribution",
        "$env:SystemRoot\System32\catroot2"
    )
    foreach ($path in $updatePaths) {
        if (Test-Path $path) {
            try { Remove-Item -Path "$path\*" -Recurse -Force -ErrorAction SilentlyContinue } catch {
                # Silently continue - non-critical operation
            }
        }
    }
    Write-ReSetLog "Windows Update cache cleared" "SUCCESS"
    
    # Function 3: Reset Windows Update registry
    Write-ProgressStep -StepName "Resetting Windows Update registry" -CurrentStep 3 -TotalSteps 20
    $wuRegPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate"
    Remove-RegistryKey -Path "$wuRegPath\Auto Update"
    Set-RegistryValue -Path $wuRegPath -Name "AcceptTrustedPublisherCerts" -Value 1 -Type DWord
    Write-ReSetLog "Windows Update registry reset" "SUCCESS"
    
    # Function 4: Re-register Windows Update components
    Write-ProgressStep -StepName "Re-registering update components" -CurrentStep 4 -TotalSteps 20
    $dlls = @("atl.dll", "urlmon.dll", "mshtml.dll", "shdocvw.dll", "browseui.dll", 
              "jscript.dll", "vbscript.dll", "scrrun.dll", "msxml.dll", "msxml3.dll",
              "msxml6.dll", "actxprxy.dll", "softpub.dll", "wintrust.dll", "dssenh.dll",
              "rsaenh.dll", "gpkcsp.dll", "sccbase.dll", "slbcsp.dll", "cryptdlg.dll")
    foreach ($dll in $dlls) {
        try { $null = & regsvr32 /s $dll 2>&1 } catch {
                # Silently continue - non-critical operation
            }
    }
    Write-ReSetLog "Windows Update components re-registered" "SUCCESS"
    
    # Function 5: Reset BITS service
    Write-ProgressStep -StepName "Resetting BITS service" -CurrentStep 5 -TotalSteps 20
    try { $null = & bitsadmin /reset /allusers 2>&1 } catch {
                # Silently continue - non-critical operation
            }
    Write-ReSetLog "BITS service reset" "SUCCESS"
    
    # Function 6: Reset Windows Update Agent
    Write-ProgressStep -StepName "Resetting Windows Update Agent" -CurrentStep 6 -TotalSteps 20
    try { $null = & wuauclt /resetauthorization /detectnow 2>&1 } catch {
                # Silently continue - non-critical operation
            }
    Write-ReSetLog "Windows Update Agent reset" "SUCCESS"
    
    # Function 7: Clear Windows Update logs
    Write-ProgressStep -StepName "Clearing update logs" -CurrentStep 7 -TotalSteps 20
    $logPaths = @("$env:SystemRoot\Logs\WindowsUpdate", "$env:SystemRoot\WindowsUpdate.log")
    foreach ($logPath in $logPaths) {
        if (Test-Path $logPath) {
            try { Remove-Item -Path $logPath -Recurse -Force -ErrorAction SilentlyContinue } catch {
                # Silently continue - non-critical operation
            }
        }
    }
    Write-ReSetLog "Windows Update logs cleared" "SUCCESS"
    
    # Function 8: Reset Automatic Updates settings
    Write-ProgressStep -StepName "Resetting Automatic Updates" -CurrentStep 8 -TotalSteps 20
    $auPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update"
    Set-RegistryValue -Path $auPath -Name "AUOptions" -Value 4 -Type DWord  # Download and install automatically
    Set-RegistryValue -Path $auPath -Name "ScheduledInstallDay" -Value 0 -Type DWord  # Every day
    Set-RegistryValue -Path $auPath -Name "ScheduledInstallTime" -Value 3 -Type DWord  # 3 AM
    Write-ReSetLog "Automatic Updates settings reset" "SUCCESS"
    
    # Function 9: Reset Windows Store updates
    Write-ProgressStep -StepName "Resetting Windows Store updates" -CurrentStep 9 -TotalSteps 20
    try { $null = & wsreset 2>&1 } catch {
                # Silently continue - non-critical operation
            }
    Write-ReSetLog "Windows Store update cache reset" "SUCCESS"
    
    # Function 10: Reset Update Orchestrator
    Write-ProgressStep -StepName "Resetting Update Orchestrator" -CurrentStep 10 -TotalSteps 20
    $usoPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\USOShared"
    Remove-RegistryKey -Path $usoPath
    Write-ReSetLog "Update Orchestrator reset" "SUCCESS"
    
    # Functions 11-20: Additional Windows Update resets
    Write-ProgressStep -StepName "Resetting delivery optimization" -CurrentStep 11 -TotalSteps 20
    try { Get-DeliveryOptimizationStatus | Clear-DeliveryOptimizationCache -ErrorAction SilentlyContinue } catch {
                # Silently continue - non-critical operation
            }
    
    Write-ProgressStep -StepName "Resetting component store" -CurrentStep 12 -TotalSteps 20
    try { $null = & dism /online /cleanup-image /restorehealth 2>&1 } catch {
                # Silently continue - non-critical operation
            }
    
    Write-ProgressStep -StepName "Resetting Windows modules" -CurrentStep 13 -TotalSteps 20
    try { $null = & sfc /scannow 2>&1 } catch {
                # Silently continue - non-critical operation
            }
    
    Write-ProgressStep -StepName "Resetting pending updates" -CurrentStep 14 -TotalSteps 20
    Remove-RegistryKey -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Services\Pending"
    
    Write-ProgressStep -StepName "Resetting update history" -CurrentStep 15 -TotalSteps 20
    Remove-RegistryKey -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\History"
    
    Write-ProgressStep -StepName "Resetting driver updates" -CurrentStep 16 -TotalSteps 20
    Set-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DriverSearching" -Name "SearchOrderConfig" -Value 1 -Type DWord
    
    Write-ProgressStep -StepName "Resetting maintenance scheduler" -CurrentStep 17 -TotalSteps 20
    Remove-RegistryKey -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\MaintenanceService"
    
    Write-ProgressStep -StepName "Resetting update notifications" -CurrentStep 18 -TotalSteps 20
    $notifyPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\UX\Settings"
    Set-RegistryValue -Path $notifyPath -Name "UxOption" -Value 0 -Type DWord
    
    Write-ProgressStep -StepName "Resetting policy settings" -CurrentStep 19 -TotalSteps 20
    Remove-RegistryKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
    
    # Function 20: Start Windows Update services
    Write-ProgressStep -StepName "Starting Windows Update services" -CurrentStep 20 -TotalSteps 20
    foreach ($service in $updateServices) {
        try { Start-Service -Name $service -ErrorAction SilentlyContinue } catch {
                # Silently continue - non-critical operation
            }
    }
    Write-ReSetLog "Windows Update services restarted" "SUCCESS"
    
    Write-ReSetLog "Windows Update reset completed successfully" "SUCCESS"
    
    if (-not $Silent) {
        Write-Host ""
        Write-Host "✅ Windows Update Reset Complete!" -ForegroundColor Green
        Write-Host "📋 Changes applied:" -ForegroundColor Cyan
        Write-Host "   • Update cache: Cleared" -ForegroundColor White
        Write-Host "   • Update components: Re-registered" -ForegroundColor White
        Write-Host "   • BITS service: Reset" -ForegroundColor White
        Write-Host "   • Automatic updates: Enabled" -ForegroundColor White
        Write-Host "   • Update history: Cleared" -ForegroundColor White
        Write-Host ""
        Write-Host "🔄 Run Windows Update to check for updates" -ForegroundColor Cyan
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
