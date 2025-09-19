#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Advanced Active Directory Reset Functions

.DESCRIPTION
    Comprehensive Active Directory troubleshooting and reset utilities.
    Includes domain connectivity, cache clearing, and credential management.

.AUTHOR
    ReSet Toolkit

.VERSION
    2.0.0

.FUNCTIONS
    - Reset-DomainConnectivity
    - Reset-ADCredentials  
    - Reset-GroupPolicyCache
    - Reset-KerberosAuthentication
    - Reset-ADDNSSettings
    - Reset-ADTrust
    - Reset-ADServices
    - Reset-ADClientCache
    - Reset-LDAP
    - Reset-ADSiteServices
#>

# Import utility functions
Import-Module "$PSScriptRoot\ReSetUtils.psm1" -Force

# ===================================================================
# ACTIVE DIRECTORY RESET FUNCTIONS
# ===================================================================

function Reset-DomainConnectivity {
    <#
    .SYNOPSIS
        Resets domain connectivity and re-establishes connection
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [switch]$Force
    )
    
    $operationName = "Domain Connectivity Reset"
    $backupName = "DomainConnectivity"
    
    try {
        Start-ReSetOperation -Name $operationName
        
        if (-not $Force) {
            if (-not (Confirm-ReSetOperation -Operation $operationName -Impact "High" -Description "This will reset domain connectivity settings and may require re-authentication.")) {
                return
            }
        }
        
        # Create backup
        New-ReSetBackup -BackupName $backupName -RegistryPaths @(
            "HKLM:\SYSTEM\CurrentControlSet\Services\Netlogon",
            "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa",
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Group Policy"
        )
        
        Write-ProgressStep "Checking current domain status..."
        $computerSystem = Get-ComputerInfo
        
        if (-not $computerSystem.PartOfDomain) {
            Write-Host "Computer is not domain-joined. Skipping domain connectivity reset." -ForegroundColor Yellow
            return
        }
        
        $domainName = $computerSystem.Domain
        Write-Host "Domain: $domainName" -ForegroundColor Cyan
        
        Write-ProgressStep "Stopping domain-related services..."
        $services = @('Netlogon', 'W32Time', 'LanmanWorkstation', 'LanmanServer')
        foreach ($service in $services) {
            try {
                Stop-Service -Name $service -Force -ErrorAction SilentlyContinue
                Write-Host "Stopped $service service" -ForegroundColor Green
            } catch {
                Write-Host "Warning: Could not stop $service service" -ForegroundColor Yellow
            }
        }
        
        Write-ProgressStep "Clearing DNS cache..."
        & ipconfig /flushdns | Out-Null
        
        Write-ProgressStep "Resetting secure channel..."
        try {
            & nltest /sc_reset:$domainName | Out-Null
            Write-Host "Secure channel reset successfully" -ForegroundColor Green
        } catch {
            Write-Host "Warning: Secure channel reset may have issues" -ForegroundColor Yellow
        }
        
        Write-ProgressStep "Restarting domain services..."
        foreach ($service in $services) {
            try {
                Start-Service -Name $service -ErrorAction SilentlyContinue
                Write-Host "Started $service service" -ForegroundColor Green
            } catch {
                Write-Host "Warning: Could not start $service service" -ForegroundColor Yellow
            }
        }
        
        Write-ProgressStep "Testing domain connectivity..."
        Start-Sleep -Seconds 5
        try {
            $dcTest = Test-ComputerSecureChannel -ErrorAction Stop
            if ($dcTest) {
                Write-Host "Domain connectivity test: PASSED" -ForegroundColor Green
            } else {
                Write-Host "Domain connectivity test: FAILED" -ForegroundColor Red
            }
        } catch {
            Write-Host "Domain connectivity test: ERROR - $($_.Exception.Message)" -ForegroundColor Red
        }
        
        Complete-ReSetOperation -Name $operationName -Status "Success"
        
    } catch {
        Write-ReSetLog "Error resetting domain connectivity: $($_.Exception.Message)" "ERROR"
        Complete-ReSetOperation -Name $operationName -Status "Failed" -ErrorMessage $_.Exception.Message
        throw
    }
}

function Reset-ADCredentials {
    <#
    .SYNOPSIS
        Clears cached Active Directory credentials
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [switch]$IncludeKerberos,
        
        [Parameter()]
        [switch]$Force
    )
    
    $operationName = "AD Credentials Reset"
    
    try {
        Start-ReSetOperation -Name $operationName
        
        if (-not $Force) {
            if (-not (Confirm-ReSetOperation -Operation $operationName -Impact "Medium" -Description "This will clear cached AD credentials and Kerberos tickets.")) {
                return
            }
        }
        
        Write-ProgressStep "Clearing cached credentials..."
        try {
            # Clear Windows credentials
            & cmdkey /list 2>&1 | ForEach-Object {
                if ($_ -match "Target: (.+)") {
                    $target = $matches[1]
                    if ($target -match $env:USERDNSDOMAIN -or $target -match "Domain:") {
                        & cmdkey /delete:$target 2>&1 | Out-Null
                        Write-Host "Cleared credential: $target" -ForegroundColor Green
                    }
                }
            }
        } catch {
            Write-Host "Warning: Some credentials could not be cleared" -ForegroundColor Yellow
        }
        
        if ($IncludeKerberos) {
            Write-ProgressStep "Clearing Kerberos tickets..."
            try {
                & klist purge 2>&1 | Out-Null
                Write-Host "Kerberos tickets cleared" -ForegroundColor Green
            } catch {
                Write-Host "Warning: Could not clear all Kerberos tickets" -ForegroundColor Yellow
            }
        }
        
        Write-ProgressStep "Clearing LSA cache..."
        try {
            # Clear LSA cache
            Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name "DisableDomainCreds" -Value 1 -Type DWord
            Start-Sleep -Seconds 2
            Remove-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name "DisableDomainCreds"
            Write-Host "LSA cache cleared" -ForegroundColor Green
        } catch {
            Write-Host "Warning: LSA cache clearing may have issues" -ForegroundColor Yellow
        }
        
        Complete-ReSetOperation -Name $operationName -Status "Success"
        
    } catch {
        Write-ReSetLog "Error resetting AD credentials: $($_.Exception.Message)" "ERROR"
        Complete-ReSetOperation -Name $operationName -Status "Failed" -ErrorMessage $_.Exception.Message
        throw
    }
}

function Reset-GroupPolicyCache {
    <#
    .SYNOPSIS
        Resets Group Policy cache and forces refresh
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [switch]$ForceRefresh,
        
        [Parameter()]
        [switch]$Force
    )
    
    $operationName = "Group Policy Cache Reset"
    $backupName = "GroupPolicy"
    
    try {
        Start-ReSetOperation -Name $operationName
        
        if (-not $Force) {
            if (-not (Confirm-ReSetOperation -Operation $operationName -Impact "Medium" -Description "This will clear Group Policy cache and force policy refresh.")) {
                return
            }
        }
        
        # Create backup
        New-ReSetBackup -BackupName $backupName -RegistryPaths @(
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Group Policy",
            "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Group Policy"
        )
        
        Write-ProgressStep "Clearing Group Policy cache..."
        
        # Clear local Group Policy cache directories
        $gpCachePaths = @(
            "$env:WINDIR\System32\GroupPolicy",
            "$env:WINDIR\System32\GroupPolicyUsers",
            "$env:LOCALAPPDATA\Microsoft\Group Policy\History"
        )
        
        foreach ($path in $gpCachePaths) {
            if (Test-Path $path) {
                try {
                    Remove-Item -Path "$path\*" -Recurse -Force -ErrorAction SilentlyContinue
                    Write-Host "Cleared cache: $path" -ForegroundColor Green
                } catch {
                    Write-Host "Warning: Could not clear $path" -ForegroundColor Yellow
                }
            }
        }
        
        Write-ProgressStep "Clearing Group Policy registry cache..."
        try {
            # Clear GP registry cache
            Remove-RegistryKey -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Group Policy\History" -Force
            Remove-RegistryKey -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Group Policy\History" -Force
            Write-Host "Registry cache cleared" -ForegroundColor Green
        } catch {
            Write-Host "Warning: Some registry cache could not be cleared" -ForegroundColor Yellow
        }
        
        if ($ForceRefresh) {
            Write-ProgressStep "Forcing Group Policy refresh..."
            try {
                & gpupdate /force 2>&1 | Out-Null
                Write-Host "Group Policy refresh completed" -ForegroundColor Green
            } catch {
                Write-Host "Warning: Group Policy refresh encountered issues" -ForegroundColor Yellow
            }
        }
        
        Complete-ReSetOperation -Name $operationName -Status "Success"
        
    } catch {
        Write-ReSetLog "Error resetting Group Policy cache: $($_.Exception.Message)" "ERROR"
        Complete-ReSetOperation -Name $operationName -Status "Failed" -ErrorMessage $_.Exception.Message
        throw
    }
}

function Reset-KerberosAuthentication {
    <#
    .SYNOPSIS
        Resets Kerberos authentication settings and tickets
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [switch]$Force
    )
    
    $operationName = "Kerberos Authentication Reset"
    $backupName = "Kerberos"
    
    try {
        Start-ReSetOperation -Name $operationName
        
        if (-not $Force) {
            if (-not (Confirm-ReSetOperation -Operation $operationName -Impact "Medium" -Description "This will reset Kerberos authentication and clear all tickets.")) {
                return
            }
        }
        
        # Create backup
        New-ReSetBackup -BackupName $backupName -RegistryPaths @(
            "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\Kerberos"
        )
        
        Write-ProgressStep "Purging Kerberos tickets..."
        try {
            & klist purge 2>&1 | Out-Null
            Write-Host "All Kerberos tickets purged" -ForegroundColor Green
        } catch {
            Write-Host "Warning: Some tickets could not be purged" -ForegroundColor Yellow
        }
        
        Write-ProgressStep "Clearing Kerberos cache..."
        try {
            # Stop KDC service if running
            Stop-Service -Name "kdc" -Force -ErrorAction SilentlyContinue
            
            # Clear Kerberos cache files
            $krbCachePaths = @(
                "$env:TEMP\krb*",
                "$env:LOCALAPPDATA\krb*"
            )
            
            foreach ($pattern in $krbCachePaths) {
                Get-ChildItem -Path $pattern -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
            }
            
            Write-Host "Kerberos cache cleared" -ForegroundColor Green
        } catch {
            Write-Host "Warning: Some cache files could not be cleared" -ForegroundColor Yellow
        }
        
        Write-ProgressStep "Resetting Kerberos settings..."
        try {
            # Reset Kerberos registry settings to defaults
            $kerbPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\Kerberos\Parameters"
            if (Test-Path $kerbPath) {
                Remove-RegistryValue -Path $kerbPath -Name "MaxTokenSize" -ErrorAction SilentlyContinue
                Remove-RegistryValue -Path $kerbPath -Name "MaxPacketSize" -ErrorAction SilentlyContinue
            }
            Write-Host "Kerberos settings reset to defaults" -ForegroundColor Green
        } catch {
            Write-Host "Warning: Some settings could not be reset" -ForegroundColor Yellow
        }
        
        Write-ProgressStep "Restarting authentication services..."
        $authServices = @('LanmanWorkstation', 'LanmanServer', 'Netlogon')
        foreach ($service in $authServices) {
            try {
                Restart-WindowsService -ServiceName $service
                Write-Host "Restarted $service" -ForegroundColor Green
            } catch {
                Write-Host "Warning: Could not restart $service" -ForegroundColor Yellow
            }
        }
        
        Complete-ReSetOperation -Name $operationName -Status "Success"
        
    } catch {
        Write-ReSetLog "Error resetting Kerberos authentication: $($_.Exception.Message)" "ERROR"
        Complete-ReSetOperation -Name $operationName -Status "Failed" -ErrorMessage $_.Exception.Message
        throw
    }
}

function Reset-ADDNSSettings {
    <#
    .SYNOPSIS
        Resets Active Directory DNS settings and cache
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [switch]$ResetToAuto,
        
        [Parameter()]
        [switch]$Force
    )
    
    $operationName = "AD DNS Settings Reset"
    $backupName = "ADDNS"
    
    try {
        Start-ReSetOperation -Name $operationName
        
        if (-not $Force) {
            if (-not (Confirm-ReSetOperation -Operation $operationName -Impact "Medium" -Description "This will reset DNS settings for Active Directory connectivity.")) {
                return
            }
        }
        
        # Create backup
        New-ReSetBackup -BackupName $backupName -RegistryPaths @(
            "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"
        )
        
        Write-ProgressStep "Flushing DNS cache..."
        & ipconfig /flushdns | Out-Null
        
        Write-ProgressStep "Releasing and renewing IP configuration..."
        & ipconfig /release | Out-Null
        Start-Sleep -Seconds 2
        & ipconfig /renew | Out-Null
        
        Write-ProgressStep "Re-registering DNS names..."
        & ipconfig /registerdns | Out-Null
        
        if ($ResetToAuto) {
            Write-ProgressStep "Resetting DNS to automatic..."
            try {
                # Get all network adapters
                $adapters = Get-WmiObject -Class Win32_NetworkAdapterConfiguration | Where-Object { $_.IPEnabled -eq $true }
                
                foreach ($adapter in $adapters) {
                    # Set DNS to automatic (DHCP)
                    $adapter.SetDNSServerSearchOrder() | Out-Null
                    Write-Host "Reset DNS for adapter: $($adapter.Description)" -ForegroundColor Green
                }
            } catch {
                Write-Host "Warning: Could not reset all DNS settings to automatic" -ForegroundColor Yellow
            }
        }
        
        Write-ProgressStep "Testing DNS resolution..."
        try {
            $testDomains = @($env:USERDNSDOMAIN, "microsoft.com")
            foreach ($domain in $testDomains) {
                if ($domain) {
                    $result = Resolve-DnsName -Name $domain -ErrorAction Stop
                    Write-Host "DNS test for $domain`: SUCCESS" -ForegroundColor Green
                }
            }
        } catch {
            Write-Host "Warning: DNS resolution test failed" -ForegroundColor Yellow
        }
        
        Complete-ReSetOperation -Name $operationName -Status "Success"
        
    } catch {
        Write-ReSetLog "Error resetting AD DNS settings: $($_.Exception.Message)" "ERROR"
        Complete-ReSetOperation -Name $operationName -Status "Failed" -ErrorMessage $_.Exception.Message
        throw
    }
}

function Reset-ADServices {
    <#
    .SYNOPSIS
        Resets Active Directory related Windows services
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [switch]$Force
    )
    
    $operationName = "AD Services Reset"
    
    try {
        Start-ReSetOperation -Name $operationName
        
        if (-not $Force) {
            if (-not (Confirm-ReSetOperation -Operation $operationName -Impact "High" -Description "This will restart all Active Directory related services.")) {
                return
            }
        }
        
        $adServices = @(
            @{Name="Netlogon"; DisplayName="Net Logon"; Critical=$true},
            @{Name="LanmanWorkstation"; DisplayName="Workstation"; Critical=$true},
            @{Name="LanmanServer"; DisplayName="Server"; Critical=$true},
            @{Name="W32Time"; DisplayName="Windows Time"; Critical=$false},
            @{Name="DnsCache"; DisplayName="DNS Client"; Critical=$true},
            @{Name="Dhcp"; DisplayName="DHCP Client"; Critical=$true},
            @{Name="EventLog"; DisplayName="Windows Event Log"; Critical=$true},
            @{Name="CryptSvc"; DisplayName="Cryptographic Services"; Critical=$true},
            @{Name="BITS"; DisplayName="Background Intelligent Transfer Service"; Critical=$false}
        )
        
        Write-ProgressStep "Stopping AD services..."
        foreach ($service in $adServices) {
            try {
                $svc = Get-Service -Name $service.Name -ErrorAction SilentlyContinue
                if ($svc -and $svc.Status -eq 'Running') {
                    Stop-Service -Name $service.Name -Force -ErrorAction Stop
                    Write-Host "Stopped: $($service.DisplayName)" -ForegroundColor Yellow
                }
            } catch {
                if ($service.Critical) {
                    Write-Host "Warning: Could not stop critical service $($service.DisplayName)" -ForegroundColor Red
                } else {
                    Write-Host "Info: Could not stop $($service.DisplayName)" -ForegroundColor Gray
                }
            }
        }
        
        Write-ProgressStep "Waiting for services to stop..."
        Start-Sleep -Seconds 5
        
        Write-ProgressStep "Starting AD services..."
        # Start in reverse order to handle dependencies
        $adServices = $adServices | Sort-Object {$_.Critical} -Descending
        
        foreach ($service in $adServices) {
            try {
                $svc = Get-Service -Name $service.Name -ErrorAction SilentlyContinue
                if ($svc) {
                    Start-Service -Name $service.Name -ErrorAction Stop
                    Write-Host "Started: $($service.DisplayName)" -ForegroundColor Green
                }
            } catch {
                if ($service.Critical) {
                    Write-Host "Error: Could not start critical service $($service.DisplayName)" -ForegroundColor Red
                } else {
                    Write-Host "Warning: Could not start $($service.DisplayName)" -ForegroundColor Yellow
                }
            }
        }
        
        Write-ProgressStep "Verifying service status..."
        Start-Sleep -Seconds 3
        $failedServices = @()
        
        foreach ($service in $adServices) {
            $svc = Get-Service -Name $service.Name -ErrorAction SilentlyContinue
            if ($svc) {
                if ($svc.Status -eq 'Running') {
                    Write-Host "$($service.DisplayName): Running" -ForegroundColor Green
                } else {
                    Write-Host "$($service.DisplayName): $($svc.Status)" -ForegroundColor Red
                    if ($service.Critical) {
                        $failedServices += $service.DisplayName
                    }
                }
            }
        }
        
        if ($failedServices.Count -gt 0) {
            Write-Host "Warning: Critical services failed to start: $($failedServices -join ', ')" -ForegroundColor Red
        }
        
        Complete-ReSetOperation -Name $operationName -Status "Success"
        
    } catch {
        Write-ReSetLog "Error resetting AD services: $($_.Exception.Message)" "ERROR"
        Complete-ReSetOperation -Name $operationName -Status "Failed" -ErrorMessage $_.Exception.Message
        throw
    }
}

function Reset-ADClientCache {
    <#
    .SYNOPSIS
        Clears Active Directory client-side cache
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [switch]$Force
    )
    
    $operationName = "AD Client Cache Reset"
    
    try {
        Start-ReSetOperation -Name $operationName
        
        if (-not $Force) {
            if (-not (Confirm-ReSetOperation -Operation $operationName -Impact "Low" -Description "This will clear AD client-side cache files.")) {
                return
            }
        }
        
        Write-ProgressStep "Clearing AD client cache files..."
        
        $cachePaths = @(
            "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\ExplorerStartupLog.etl",
            "$env:TEMP\kerb*",
            "$env:WINDIR\Temp\*krb*",
            "$env:SYSTEMROOT\debug\netlogon.log"
        )
        
        foreach ($pattern in $cachePaths) {
            try {
                $files = Get-ChildItem -Path $pattern -ErrorAction SilentlyContinue
                if ($files) {
                    $files | Remove-Item -Force -ErrorAction SilentlyContinue
                    Write-Host "Cleared cache: $pattern" -ForegroundColor Green
                }
            } catch {
                Write-Host "Info: Could not clear $pattern" -ForegroundColor Gray
            }
        }
        
        Write-ProgressStep "Clearing AD registry cache..."
        try {
            $cacheKeys = @(
                "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\UserAssist",
                "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Group Policy\State"
            )
            
            foreach ($key in $cacheKeys) {
                if (Test-Path $key) {
                    Remove-Item -Path $key -Recurse -Force -ErrorAction SilentlyContinue
                    Write-Host "Cleared registry cache: $key" -ForegroundColor Green
                }
            }
        } catch {
            Write-Host "Warning: Some registry cache could not be cleared" -ForegroundColor Yellow
        }
        
        Complete-ReSetOperation -Name $operationName -Status "Success"
        
    } catch {
        Write-ReSetLog "Error clearing AD client cache: $($_.Exception.Message)" "ERROR"
        Complete-ReSetOperation -Name $operationName -Status "Failed" -ErrorMessage $_.Exception.Message
        throw
    }
}

# ===================================================================
# EXPORT FUNCTIONS
# ===================================================================

Write-Host "Active Directory Reset Functions Loaded" -ForegroundColor Green
Write-Host "Functions: Reset-DomainConnectivity, Reset-ADCredentials, Reset-GroupPolicyCache," -ForegroundColor Gray
Write-Host "          Reset-KerberosAuthentication, Reset-ADDNSSettings, Reset-ADServices," -ForegroundColor Gray
Write-Host "          Reset-ADClientCache" -ForegroundColor Gray
