# ===================================================================
# Reset Services and Startup Programs Script
# File: reset-services.ps1
# Author: jomardyan
# Description: Resets Windows services and startup programs
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

$operationName = "Services and Startup Reset"

try {
    Assert-AdminRights
    $operation = Start-ReSetOperation -OperationName $operationName
    
    # Essential Windows services and their default startup types
    $defaultServices = @{
        "AudioSrv" = "Automatic"
        "BITS" = "Automatic (Delayed Start)"
        "BrokerInfrastructure" = "Automatic"
        "CryptSvc" = "Automatic"
        "DcomLaunch" = "Automatic"
        "Dhcp" = "Automatic"
        "Dnscache" = "Automatic"
        "EventLog" = "Automatic"
        "EventSystem" = "Automatic"
        "gpsvc" = "Automatic"
        "LanmanServer" = "Automatic"
        "LanmanWorkstation" = "Automatic"
        "lmhosts" = "Manual"
        "MMCSS" = "Automatic"
        "MpsSvc" = "Automatic"
        "netprofm" = "Manual"
        "NlaSvc" = "Automatic"
        "nsi" = "Automatic"
        "PlugPlay" = "Automatic"
        "PolicyAgent" = "Manual"
        "Power" = "Automatic"
        "ProfSvc" = "Automatic"
        "RpcEptMapper" = "Automatic"
        "RpcSs" = "Automatic"
        "SamSs" = "Automatic"
        "Schedule" = "Automatic"
        "SENS" = "Automatic"
        "SessionEnv" = "Manual"
        "ShellHWDetection" = "Automatic"
        "Spooler" = "Automatic"
        "SSDPSRV" = "Manual"
        "SysMain" = "Automatic"
        "Themes" = "Automatic"
        "TrkWks" = "Automatic"
        "TrustedInstaller" = "Manual"
        "UmRdpService" = "Manual"
        "UxSms" = "Automatic"
        "Winmgmt" = "Automatic"
        "WinRM" = "Manual"
        "Wlansvc" = "Automatic (Delayed Start)"
        "WSearch" = "Automatic (Delayed Start)"
        "wuauserv" = "Manual"
    }
    
    # Functions 1-10: Reset core system services
    for ($i = 1; $i -le 10; $i++) {
        Write-ProgressStep -StepName "Resetting core services batch $i" -CurrentStep $i -TotalSteps 15
        $serviceBatch = $defaultServices.GetEnumerator() | Select-Object -Skip (($i-1)*4) -First 4
        foreach ($service in $serviceBatch) {
            try {
                $startupType = $service.Value
                if ($startupType -eq "Automatic (Delayed Start)") {
                    Set-Service -Name $service.Key -StartupType Automatic -ErrorAction SilentlyContinue
                    $null = & sc config $service.Key start= delayed-auto 2>&1
                } else {
                    Set-Service -Name $service.Key -StartupType $startupType -ErrorAction SilentlyContinue
                }
            } catch {
                # Silently continue - non-critical operation
            }
        }
    }
    
    # Function 11: Reset startup programs
    Write-ProgressStep -StepName "Clearing startup programs" -CurrentStep 11 -TotalSteps 15
    $startupPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce"
    )
    foreach ($path in $startupPaths) {
        if (Test-Path $path) {
            $items = Get-ItemProperty -Path $path -ErrorAction SilentlyContinue
            if ($items) {
                $items.PSObject.Properties | Where-Object { $_.Name -notmatch "PS" } | ForEach-Object {
                    if ($_.Name -notmatch "SecurityHealth|OneDrive|Windows") {
                        Remove-RegistryValue -Path $path -Name $_.Name
                    }
                }
            }
        }
    }
    
    # Function 12: Reset scheduled tasks
    Write-ProgressStep -StepName "Resetting scheduled tasks" -CurrentStep 12 -TotalSteps 15
    try {
        Get-ScheduledTask | Where-Object { $_.TaskPath -like "*Microsoft*" -and $_.State -eq "Disabled" } | 
            Enable-ScheduledTask -ErrorAction SilentlyContinue
    } catch {
                # Silently continue - non-critical operation
            }
    
    # Function 13: Reset Windows services dependencies
    Write-ProgressStep -StepName "Resetting service dependencies" -CurrentStep 13 -TotalSteps 15
    try {
        $null = & sc sdset BITS "D:(A;;CCLCSWRPWPDTLOCRRC;;;SY)(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;BA)(A;;CCLCSWLOCRRC;;;AU)(A;;CCLCSWRPWPDTLOCRRC;;;PU)" 2>&1
    } catch {
                # Silently continue - non-critical operation
            }
    
    # Function 14: Reset performance counters
    Write-ProgressStep -StepName "Rebuilding performance counters" -CurrentStep 14 -TotalSteps 15
    try {
        $null = & lodctr /R 2>&1
    } catch {
                # Silently continue - non-critical operation
            }
    
    # Function 15: Reset service recovery options
    Write-ProgressStep -StepName "Resetting service recovery" -CurrentStep 15 -TotalSteps 15
    $criticalServices = @("AudioSrv", "BITS", "Dhcp", "Dnscache", "EventLog", "RpcSs", "Winmgmt")
    foreach ($service in $criticalServices) {
        try {
            $null = & sc failure $service reset= 86400 actions= restart/60000/restart/60000/restart/60000 2>&1
        } catch {
                # Silently continue - non-critical operation
            }
    }
    
    Write-ReSetLog "Services and startup programs reset completed" "SUCCESS"
    Complete-ReSetOperation -OperationInfo $operation -Success $true
}
catch {
    Complete-ReSetOperation -OperationInfo $operation -Success $false -ErrorMessage $_.Exception.Message
    throw
}
