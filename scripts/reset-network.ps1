# ===================================================================
# Reset Network Settings Script (GPO-Enhanced)
# File: reset-network.ps1
# Author: jomardyan
# Description: Resets Windows network settings to defaults with Group Policy integration
# Version: 2.0.0
# ===================================================================

#Requires -Version 5.0
#Requires -RunAsAdministrator

param(
    [switch]$Silent,
    [switch]$CreateBackup = $true,
    [string]$BackupPath = "",
    [switch]$Force,
    [string]$ConfigurationFile,
    [switch]$IgnoreGroupPolicy,
    [switch]$AuditOnly,
    [int]$TimeoutMinutes = 30
)

# Import utility module
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
Import-Module (Join-Path $scriptPath "ReSetUtils.psm1") -Force

$operationName = "Network Settings Reset"
$operationType = "Reset"

try {
    # Validate administrative rights
    Assert-AdminRights
    if (!(Test-WindowsVersion)) { throw "Unsupported Windows version" }
    
    # GPO Compliance Check
    if (-not $IgnoreGroupPolicy) {
        try {
            Assert-GroupPolicyCompliance -OperationType $operationType -OperationName $operationName
            Write-ReSetLog "Group Policy compliance check passed" "SUCCESS"
        } catch {
            Write-ReSetLog "Operation blocked by Group Policy: $($_.Exception.Message)" "ERROR"
            if ($Silent) {
                Write-GroupPolicyAuditLog -OperationType $operationType -OperationName $operationName -Status "Blocked" -Details $_.Exception.Message
                exit 1
            } else {
                throw
            }
        }
    }
    
    # Load configuration from Group Policy or file
    $config = Get-GroupPolicyConfiguration
    if ($ConfigurationFile -and (Test-Path $ConfigurationFile)) {
        $fileConfig = Get-Content $ConfigurationFile | ConvertFrom-Json
        Write-ReSetLog "Configuration loaded from file: $ConfigurationFile" "INFO"
    }
    
    # Apply policy-based settings
    if ($config.EffectiveSettings.RequireBackup) {
        $CreateBackup = $true
        Write-ReSetLog "Backup required by Group Policy" "INFO"
    }
    
    if ($config.EffectiveSettings.AuditMode) {
        Write-ReSetLog "Audit mode enabled by Group Policy" "INFO"
        Write-GroupPolicyAuditLog -OperationType $operationType -OperationName $operationName -Status "Started"
    }
    
    # Start operation with enhanced logging
    $operation = Start-ReSetOperation -OperationName $operationName
    
    # Audit-only mode (compliance testing)
    if ($AuditOnly) {
        Write-ReSetLog "Running in audit-only mode - no changes will be made" "INFO"
        $auditResults = Test-NetworkConfiguration
        Write-ReSetLog "Network audit completed: $($auditResults.Status)" "INFO"
        if ($config.EffectiveSettings.AuditMode) {
            Write-GroupPolicyAuditLog -OperationType $operationType -OperationName $operationName -Status "Completed" -Details "Audit-only mode: $($auditResults.Status)"
        }
        return $auditResults
    }
    
    # Enhanced user interaction for non-silent mode
    if (-not $Silent) {
        Write-ReSetHeader -Title $operationName -Description "Reset TCP/IP stack, DNS, firewall, and network adapters (GPO-Enhanced)"
        
        # Show policy information
        if ($config.EffectiveSettings.OperationsEnabled) {
            Write-Host "Group Policy Status: Operations Enabled" -ForegroundColor Green
        }
        if ($config.ComputerPolicy.MaintenanceWindow) {
            $windowStatus = Test-MaintenanceWindow
            Write-Host "Maintenance Window: $($windowStatus.Message)" -ForegroundColor $(if($windowStatus.InWindow){'Green'}else{'Yellow'})
        }
        
        if (-not $Force) {
            $confirmed = Confirm-ReSetOperation -OperationName $operationName -Warning "This will reset all network settings and may temporarily disconnect you."
            if (-not $confirmed) { 
                Write-ReSetLog "Operation cancelled by user" "WARN"
                if ($config.EffectiveSettings.AuditMode) {
                    Write-GroupPolicyAuditLog -OperationType $operationType -OperationName $operationName -Status "Blocked" -Details "User cancelled operation"
                }
                return 
            }
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
    try { $null = & ipconfig /release 2>&1; $null = & ipconfig /renew 2>&1 } catch {
                # Silently continue - non-critical operation
            }
    
    Write-ProgressStep -StepName "Resetting NetBIOS" -CurrentStep 8 -TotalSteps 15
    try { $null = & nbtstat -RR 2>&1 } catch {
                # Silently continue - non-critical operation
            }
    
    Write-ProgressStep -StepName "Resetting routing table" -CurrentStep 9 -TotalSteps 15
    try { $null = & route -f 2>&1 } catch {
                # Silently continue - non-critical operation
            }
    
    Write-ProgressStep -StepName "Resetting ARP cache" -CurrentStep 10 -TotalSteps 15
    try { $null = & arp -d * 2>&1 } catch {
                # Silently continue - non-critical operation
            }
    
    Write-ProgressStep -StepName "Resetting SMB settings" -CurrentStep 11 -TotalSteps 15
    try { Set-SmbClientConfiguration -EnableMultiChannel $true -Force -ErrorAction SilentlyContinue } catch {
                # Silently continue - non-critical operation
            }
    
    Write-ProgressStep -StepName "Resetting network discovery" -CurrentStep 12 -TotalSteps 15
    try { $null = & netsh advfirewall firewall set rule group="Network Discovery" new enable=Yes 2>&1 } catch {
                # Silently continue - non-critical operation
            }
    
    Write-ProgressStep -StepName "Resetting file sharing" -CurrentStep 13 -TotalSteps 15
    try { $null = & netsh advfirewall firewall set rule group="File and Printer Sharing" new enable=Yes 2>&1 } catch {
                # Silently continue - non-critical operation
            }
    
    Write-ProgressStep -StepName "Resetting network location" -CurrentStep 14 -TotalSteps 15
    try { Set-NetConnectionProfile -NetworkCategory Private -ErrorAction SilentlyContinue } catch {
                # Silently continue - non-critical operation
            }
    
    Write-ProgressStep -StepName "Restarting network services" -CurrentStep 15 -TotalSteps 15
    $services = @("Dnscache", "Dhcp", "Netman", "NlaSvc")
    foreach ($service in $services) { Restart-WindowsService -ServiceName $service }
    
    Write-ReSetLog "Network settings reset completed successfully" "SUCCESS"
    
    # GPO Audit Logging
    if ($config.EffectiveSettings.AuditMode) {
        Write-GroupPolicyAuditLog -OperationType $operationType -OperationName $operationName -Status "Completed" -Details "Network reset completed successfully"
    }
    
    if (-not $Silent) {
        Write-Host ""
        Write-Host "✅ Network Settings Reset Complete!" -ForegroundColor Green
        Write-Host "📋 Changes applied:" -ForegroundColor Cyan
        Write-Host "   • TCP/IP stack: Reset" -ForegroundColor White
        Write-Host "   • DNS settings: Reset to DHCP" -ForegroundColor White
        Write-Host "   • Windows Firewall: Reset to defaults" -ForegroundColor White
        Write-Host "   • Proxy settings: Disabled" -ForegroundColor White
        Write-Host "   • Network adapters: Properties reset" -ForegroundColor White
        
        # Show policy compliance status
        if (-not $IgnoreGroupPolicy) {
            Write-Host ""
            Write-Host "🔒 Group Policy Compliance: Verified" -ForegroundColor Green
            if ($config.EffectiveSettings.AuditMode) {
                Write-Host "📊 Audit logging: Enabled" -ForegroundColor Cyan
            }
        }
        
        Write-Host ""
        Write-Host "⚠️  Please restart your computer for all changes to take effect." -ForegroundColor Yellow
    }
    
    Complete-ReSetOperation -OperationInfo $operation -Success $true

} catch {
    $errorMessage = $_.Exception.Message
    Write-ReSetLog "Operation failed: $errorMessage" "ERROR"
    
    # GPO Audit Logging for failures
    if ($config.EffectiveSettings.AuditMode -and -not $IgnoreGroupPolicy) {
        Write-GroupPolicyAuditLog -OperationType $operationType -OperationName $operationName -Status "Failed" -Details $errorMessage
    }
    
    Complete-ReSetOperation -OperationInfo $operation -Success $false -ErrorMessage $errorMessage
    
    if ($Silent) {
        exit 1
    } else {
        throw
    }
} finally {
    Write-Progress -Activity "Windows Reset Operation" -Completed
}

# ===================================================================
# HELPER FUNCTIONS FOR GPO INTEGRATION
# ===================================================================

function Test-NetworkConfiguration {
    <#
    .SYNOPSIS
        Tests current network configuration for compliance auditing
    #>
    try {
        $results = @{
            Status = "Healthy"
            Issues = @()
            Timestamp = Get-Date
        }
        
        # Test network connectivity (using Google DNS as external test)
        $testServer = "8.8.8.8"  # Google DNS - well-known external server
        $connectivity = Test-NetConnection -ComputerName $testServer -Port 53 -InformationLevel Quiet
        if (-not $connectivity) {
            $results.Issues += "External connectivity failed"
        }
        
        # Test DNS resolution
        try {
            $dnsTest = Resolve-DnsName -Name "microsoft.com" -ErrorAction Stop
            if (-not $dnsTest) {
                $results.Issues += "DNS resolution failed"
            }
        } catch {
            $results.Issues += "DNS resolution error: $($_.Exception.Message)"
        }
        
        # Check network adapters
        $adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
        if ($adapters.Count -eq 0) {
            $results.Issues += "No active network adapters found"
        }
        
        # Determine overall status
        if ($results.Issues.Count -gt 0) {
            $results.Status = "Issues Found"
        }
        
        return $results
        
    } catch {
        return @{
            Status = "Error"
            Issues = @("Configuration test failed: $($_.Exception.Message)")
            Timestamp = Get-Date
        }
    }
}
