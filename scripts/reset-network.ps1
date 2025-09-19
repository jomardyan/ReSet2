# ===================================================================
# Reset Network Settings Script
# File: reset-network.ps1
# Author: jomardyan
# Description: Resets Windows network settings to defaults
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

$operationName = "Network Settings Reset"

try {
    Assert-AdminRights
    if (!(Test-WindowsVersion)) { throw "Unsupported Windows version" }
    
    $operation = Start-ReSetOperation -OperationName $operationName
    
    if (-not $Silent) {
        Write-ReSetHeader -Title $operationName -Description "Reset TCP/IP stack, DNS, firewall, and network adapters"
        if (-not $Force) {
            $confirmed = Confirm-ReSetOperation -OperationName $operationName -Warning "This will reset all network settings and may temporarily disconnect you."
            if (-not $confirmed) { Write-ReSetLog "Operation cancelled by user" "WARN"; return }
        }
    }
    
    # Backup network settings
    if ($CreateBackup) {
        Write-ProgressStep -StepName "Creating network backup" -CurrentStep 1 -TotalSteps 15
        $registryBackupPaths = @(
            "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip",
            "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Dnscache",
            "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings"
        )
        try {
            $backupDir = New-ReSetBackup -BackupName "NetworkSettings" -RegistryPaths $registryBackupPaths
        } catch {
            if (-not $Force) { throw "Backup failed" }
        }
    }
    
    # Reset TCP/IP stack
    Write-ProgressStep -StepName "Resetting TCP/IP stack" -CurrentStep 2 -TotalSteps 15
    try {
        $null = & netsh int ip reset 2>&1
        $null = & netsh winsock reset 2>&1
        Write-ReSetLog "TCP/IP stack reset successfully" "SUCCESS"
    } catch {
        Write-ReSetLog "Failed to reset TCP/IP stack: $($_.Exception.Message)" "ERROR"
    }
    
    # Reset DNS settings
    Write-ProgressStep -StepName "Resetting DNS settings" -CurrentStep 3 -TotalSteps 15
    try {
        $null = & ipconfig /flushdns 2>&1
        $null = & netsh int ip set dns "Local Area Connection" dhcp 2>&1
        $null = & netsh int ip set dns "Wi-Fi" dhcp 2>&1
        Write-ReSetLog "DNS settings reset to DHCP" "SUCCESS"
    } catch {
        Write-ReSetLog "Failed to reset DNS: $($_.Exception.Message)" "WARN"
    }
    
    # Reset Windows Firewall
    Write-ProgressStep -StepName "Resetting Windows Firewall" -CurrentStep 4 -TotalSteps 15
    try {
        $null = & netsh advfirewall reset 2>&1
        Write-ReSetLog "Windows Firewall reset to defaults" "SUCCESS"
    } catch {
        Write-ReSetLog "Failed to reset firewall: $($_.Exception.Message)" "ERROR"
    }
    
    # Reset proxy settings
    Write-ProgressStep -StepName "Resetting proxy settings" -CurrentStep 5 -TotalSteps 15
    $proxyPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings"
    Set-RegistryValue -Path $proxyPath -Name "ProxyEnable" -Value 0 -Type DWord
    Remove-RegistryValue -Path $proxyPath -Name "ProxyServer"
    Remove-RegistryValue -Path $proxyPath -Name "ProxyOverride"
    Write-ReSetLog "Proxy settings disabled" "SUCCESS"
    
    # Reset network adapters
    Write-ProgressStep -StepName "Resetting network adapters" -CurrentStep 6 -TotalSteps 15
    try {
        Get-NetAdapter | Reset-NetAdapterAdvancedProperty -DisplayName "*" -ErrorAction SilentlyContinue
        Write-ReSetLog "Network adapter properties reset" "SUCCESS"
    } catch {
        Write-ReSetLog "Failed to reset adapter properties: $($_.Exception.Message)" "WARN"
    }
    
    # Additional network resets (functions 7-15)
    Write-ProgressStep -StepName "Resetting DHCP client" -CurrentStep 7 -TotalSteps 15
    try { $null = & ipconfig /release 2>&1; $null = & ipconfig /renew 2>&1 } catch {}
    
    Write-ProgressStep -StepName "Resetting NetBIOS" -CurrentStep 8 -TotalSteps 15
    try { $null = & nbtstat -RR 2>&1 } catch {}
    
    Write-ProgressStep -StepName "Resetting routing table" -CurrentStep 9 -TotalSteps 15
    try { $null = & route -f 2>&1 } catch {}
    
    Write-ProgressStep -StepName "Resetting ARP cache" -CurrentStep 10 -TotalSteps 15
    try { $null = & arp -d * 2>&1 } catch {}
    
    Write-ProgressStep -StepName "Resetting SMB settings" -CurrentStep 11 -TotalSteps 15
    try { Set-SmbClientConfiguration -EnableMultiChannel $true -Force -ErrorAction SilentlyContinue } catch {}
    
    Write-ProgressStep -StepName "Resetting network discovery" -CurrentStep 12 -TotalSteps 15
    try { $null = & netsh advfirewall firewall set rule group="Network Discovery" new enable=Yes 2>&1 } catch {}
    
    Write-ProgressStep -StepName "Resetting file sharing" -CurrentStep 13 -TotalSteps 15
    try { $null = & netsh advfirewall firewall set rule group="File and Printer Sharing" new enable=Yes 2>&1 } catch {}
    
    Write-ProgressStep -StepName "Resetting network location" -CurrentStep 14 -TotalSteps 15
    try { Set-NetConnectionProfile -NetworkCategory Private -ErrorAction SilentlyContinue } catch {}
    
    Write-ProgressStep -StepName "Restarting network services" -CurrentStep 15 -TotalSteps 15
    $services = @("Dnscache", "Dhcp", "Netman", "NlaSvc")
    foreach ($service in $services) { Restart-WindowsService -ServiceName $service }
    
    Write-ReSetLog "Network settings reset completed successfully" "SUCCESS"
    
    if (-not $Silent) {
        Write-Host ""
        Write-Host "✅ Network Settings Reset Complete!" -ForegroundColor Green
        Write-Host "📋 Changes applied:" -ForegroundColor Cyan
        Write-Host "   • TCP/IP stack: Reset" -ForegroundColor White
        Write-Host "   • DNS settings: Reset to DHCP" -ForegroundColor White
        Write-Host "   • Windows Firewall: Reset to defaults" -ForegroundColor White
        Write-Host "   • Proxy settings: Disabled" -ForegroundColor White
        Write-Host "   • Network adapters: Properties reset" -ForegroundColor White
        Write-Host ""
        Write-Host "⚠️  Please restart your computer for all changes to take effect." -ForegroundColor Yellow
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