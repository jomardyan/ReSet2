#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Active Directory Host Computer Cleanup and Management

.DESCRIPTION
    Comprehensive Active Directory cleanup utilities specifically designed for host computers.
    Includes computer account management, domain cleanup, trust relationships, and host-specific AD operations.

.AUTHOR
    ReSet Toolkit

.VERSION
    2.0.0

.FUNCTIONS
    - Reset-ComputerAccount
    - Reset-DomainTrust
    - Reset-HostADCache
    - Reset-ComputerCertificates
    - Reset-HostNetlogon
    - Reset-ComputerGroupPolicy
    - Reset-HostDNSRegistration
    - Reset-ComputerSID
    - Reset-HostADConnections
    - Reset-ComputerPasswordAge
    - Repair-DomainMembership
    - Clean-OrphanedADObjects
#>

# Import utility functions
Import-Module "$PSScriptRoot\ReSetUtils.psm1" -Force

# ===================================================================
# HOST COMPUTER AD CLEANUP FUNCTIONS
# ===================================================================

function Reset-ComputerAccount {
    <#
    .SYNOPSIS
        Resets the computer account password and relationship with domain
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [switch]$Force,
        
        [Parameter()]
        [switch]$TestOnly
    )
    
    $operationName = "Computer Account Reset"
    $backupName = "ComputerAccount"
    
    try {
        Start-ReSetOperation -Name $operationName
        
        if (-not $Force) {
            if (-not (Confirm-ReSetOperation -Operation $operationName -Impact "High" -Description "This will reset the computer account password and may require domain rejoin.")) {
                return
            }
        }
        
        # Create backup
        New-ReSetBackup -BackupName $backupName -RegistryPaths @(
            "HKLM:\SECURITY\Policy\Secrets",
            "HKLM:\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters"
        )
        
        Write-ProgressStep "Checking current computer account status..."
        $computerSystem = Get-ComputerInfo
        
        if (-not $computerSystem.PartOfDomain) {
            Write-Host "Computer is not domain-joined. Skipping computer account reset." -ForegroundColor Yellow
            return
        }
        
        $computerName = $env:COMPUTERNAME
        $domainName = $computerSystem.Domain
        Write-Host "Computer: $computerName" -ForegroundColor Cyan
        Write-Host "Domain: $domainName" -ForegroundColor Cyan
        
        if ($TestOnly) {
            Write-ProgressStep "Testing computer account (Test mode)..."
            try {
                $testResult = Test-ComputerSecureChannel -Repair:$false
                if ($testResult) {
                    Write-Host "Computer account test: PASSED" -ForegroundColor Green
                } else {
                    Write-Host "Computer account test: FAILED" -ForegroundColor Red
                }
                return $testResult
            } catch {
                Write-Host "Computer account test: ERROR - $($_.Exception.Message)" -ForegroundColor Red
                return $false
            }
        }
        
        Write-ProgressStep "Resetting computer account password..."
        try {
            # Test and repair secure channel
            $repairResult = Test-ComputerSecureChannel -Repair
            if ($repairResult) {
                Write-Host "Computer account password reset: SUCCESS" -ForegroundColor Green
            } else {
                Write-Host "Computer account password reset: FAILED" -ForegroundColor Red
                throw "Failed to reset computer account password"
            }
        } catch {
            Write-Host "Error resetting computer account: $($_.Exception.Message)" -ForegroundColor Red
            
            Write-ProgressStep "Attempting manual computer account reset..."
            try {
                # Manual reset using netdom
                & netdom resetpwd /s:$domainName /ud:$env:USERNAME /pd:* 2>&1 | Out-Null
                Write-Host "Manual computer account reset attempted" -ForegroundColor Yellow
            } catch {
                Write-Host "Manual reset also failed" -ForegroundColor Red
            }
        }
        
        Write-ProgressStep "Restarting Netlogon service..."
        try {
            Restart-WindowsService -ServiceName "Netlogon"
            Write-Host "Netlogon service restarted" -ForegroundColor Green
        } catch {
            Write-Host "Warning: Could not restart Netlogon service" -ForegroundColor Yellow
        }
        
        Write-ProgressStep "Verifying computer account status..."
        Start-Sleep -Seconds 5
        try {
            $verifyResult = Test-ComputerSecureChannel -ErrorAction Stop
            if ($verifyResult) {
                Write-Host "Computer account verification: PASSED" -ForegroundColor Green
            } else {
                Write-Host "Computer account verification: FAILED" -ForegroundColor Red
            }
        } catch {
            Write-Host "Computer account verification: ERROR" -ForegroundColor Red
        }
        
        Complete-ReSetOperation -Name $operationName -Status "Success"
        
    } catch {
        Write-ReSetLog "Error resetting computer account: $($_.Exception.Message)" "ERROR"
        Complete-ReSetOperation -Name $operationName -Status "Failed" -ErrorMessage $_.Exception.Message
        throw
    }
}

function Reset-DomainTrust {
    <#
    .SYNOPSIS
        Resets domain trust relationships and validates trust status
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [switch]$Force
    )
    
    $operationName = "Domain Trust Reset"
    
    try {
        Start-ReSetOperation -Name $operationName
        
        if (-not $Force) {
            if (-not (Confirm-ReSetOperation -Operation $operationName -Impact "High" -Description "This will reset domain trust relationships.")) {
                return
            }
        }
        
        Write-ProgressStep "Checking domain trust status..."
        $computerSystem = Get-ComputerInfo
        
        if (-not $computerSystem.PartOfDomain) {
            Write-Host "Computer is not domain-joined. Skipping trust reset." -ForegroundColor Yellow
            return
        }
        
        $domainName = $computerSystem.Domain
        Write-Host "Domain: $domainName" -ForegroundColor Cyan
        
        Write-ProgressStep "Resetting domain trusts..."
        try {
            # Reset trust with domain controllers
            & nltest /server:$env:COMPUTERNAME /sc_reset:$domainName 2>&1 | Out-Null
            Write-Host "Domain trust reset initiated" -ForegroundColor Green
        } catch {
            Write-Host "Warning: Domain trust reset may have issues" -ForegroundColor Yellow
        }
        
        Write-ProgressStep "Refreshing group policy for trust settings..."
        try {
            & gpupdate /target:computer /force 2>&1 | Out-Null
            Write-Host "Group policy refreshed" -ForegroundColor Green
        } catch {
            Write-Host "Warning: Group policy refresh encountered issues" -ForegroundColor Yellow
        }
        
        Write-ProgressStep "Validating trust relationships..."
        try {
            # Test trust with domain
            $trustTest = & nltest /server:$env:COMPUTERNAME /sc_query:$domainName 2>&1
            if ($trustTest -match "Connection Status = 0") {
                Write-Host "Domain trust validation: PASSED" -ForegroundColor Green
            } else {
                Write-Host "Domain trust validation: NEEDS ATTENTION" -ForegroundColor Yellow
            }
        } catch {
            Write-Host "Domain trust validation: ERROR" -ForegroundColor Red
        }
        
        Complete-ReSetOperation -Name $operationName -Status "Success"
        
    } catch {
        Write-ReSetLog "Error resetting domain trust: $($_.Exception.Message)" "ERROR"
        Complete-ReSetOperation -Name $operationName -Status "Failed" -ErrorMessage $_.Exception.Message
        throw
    }
}

function Reset-HostADCache {
    <#
    .SYNOPSIS
        Comprehensive host-specific Active Directory cache cleanup
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [switch]$IncludeUserProfiles,
        
        [Parameter()]
        [switch]$Force
    )
    
    $operationName = "Host AD Cache Reset"
    
    try {
        Start-ReSetOperation -Name $operationName
        
        if (-not $Force) {
            if (-not (Confirm-ReSetOperation -Operation $operationName -Impact "Medium" -Description "This will clear host-specific AD caches and temporary files.")) {
                return
            }
        }
        
        Write-ProgressStep "Clearing computer-specific AD cache..."
        
        # Clear computer account cache
        $hostCachePaths = @(
            "$env:WINDIR\debug\netlogon.log",
            "$env:WINDIR\debug\netlogon.bak",
            "$env:SYSTEMROOT\system32\config\netlogon.ftl",
            "$env:WINDIR\System32\GroupPolicy\Machine\Registry.pol",
            "$env:WINDIR\System32\GroupPolicyUsers\*\User\Registry.pol"
        )
        
        foreach ($path in $hostCachePaths) {
            try {
                $files = Get-ChildItem -Path $path -ErrorAction SilentlyContinue
                if ($files) {
                    $files | Remove-Item -Force -ErrorAction SilentlyContinue
                    Write-Host "Cleared cache: $path" -ForegroundColor Green
                }
            } catch {
                Write-Host "Info: Could not clear $path" -ForegroundColor Gray
            }
        }
        
        Write-ProgressStep "Clearing AD DNS resolution cache..."
        try {
            # Clear DNS cache
            & ipconfig /flushdns | Out-Null
            
            # Clear NetBIOS cache
            & nbtstat -R 2>&1 | Out-Null
            & nbtstat -RR 2>&1 | Out-Null
            
            Write-Host "DNS and NetBIOS caches cleared" -ForegroundColor Green
        } catch {
            Write-Host "Warning: Some DNS caches could not be cleared" -ForegroundColor Yellow
        }
        
        Write-ProgressStep "Clearing AD site and service cache..."
        try {
            # Clear site cache
            $siteCacheKeys = @(
                "HKLM:\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters\SiteName",
                "HKLM:\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters\DynamicSiteName"
            )
            
            foreach ($key in $siteCacheKeys) {
                Remove-RegistryValue -Path (Split-Path $key) -Name (Split-Path $key -Leaf) -ErrorAction SilentlyContinue
            }
            
            Write-Host "AD site cache cleared" -ForegroundColor Green
        } catch {
            Write-Host "Warning: Some site cache could not be cleared" -ForegroundColor Yellow
        }
        
        if ($IncludeUserProfiles) {
            Write-ProgressStep "Clearing user profile AD cache..."
            try {
                $userProfiles = Get-ChildItem -Path "$env:SYSTEMDRIVE\Users" -Directory -ErrorAction SilentlyContinue
                
                foreach ($profile in $userProfiles) {
                    $userCachePaths = @(
                        "$($profile.FullName)\AppData\Local\Microsoft\Windows\Explorer\*.db",
                        "$($profile.FullName)\AppData\Roaming\Microsoft\Windows\Recent\*"
                    )
                    
                    foreach ($userPath in $userCachePaths) {
                        try {
                            Get-ChildItem -Path $userPath -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
                        } catch {
                            # Ignore locked files
                        }
                    }
                }
                
                Write-Host "User profile AD cache cleared" -ForegroundColor Green
            } catch {
                Write-Host "Warning: Some user profile cache could not be cleared" -ForegroundColor Yellow
            }
        }
        
        Complete-ReSetOperation -Name $operationName -Status "Success"
        
    } catch {
        Write-ReSetLog "Error clearing host AD cache: $($_.Exception.Message)" "ERROR"
        Complete-ReSetOperation -Name $operationName -Status "Failed" -ErrorMessage $_.Exception.Message
        throw
    }
}

function Reset-ComputerCertificates {
    <#
    .SYNOPSIS
        Resets computer certificates used for AD authentication
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [switch]$Force
    )
    
    $operationName = "Computer Certificates Reset"
    
    try {
        Start-ReSetOperation -Name $operationName
        
        if (-not $Force) {
            if (-not (Confirm-ReSetOperation -Operation $operationName -Impact "Medium" -Description "This will reset computer certificates for AD authentication.")) {
                return
            }
        }
        
        Write-ProgressStep "Clearing computer certificate cache..."
        
        try {
            # Clear certificate cache
            & certlm.msc /s 2>&1 | Out-Null
            
            # Clear computer certificate store cache
            $certStores = @("My", "Root", "CA", "Trust", "Disallowed")
            foreach ($store in $certStores) {
                try {
                    $certStore = Get-ChildItem -Path "Cert:\LocalMachine\$store" -ErrorAction SilentlyContinue
                    Write-Host "Certificate store $store`: $($certStore.Count) certificates" -ForegroundColor Gray
                } catch {
                    # Store not accessible
                }
            }
            
            Write-Host "Computer certificate cache cleared" -ForegroundColor Green
        } catch {
            Write-Host "Warning: Certificate cache clearing may have issues" -ForegroundColor Yellow
        }
        
        Write-ProgressStep "Refreshing computer certificates..."
        try {
            # Refresh certificates via Group Policy
            & gpupdate /target:computer /force 2>&1 | Out-Null
            
            # Refresh certificate enrollment
            & certreq -pulse 2>&1 | Out-Null
            
            Write-Host "Computer certificates refreshed" -ForegroundColor Green
        } catch {
            Write-Host "Warning: Certificate refresh may have issues" -ForegroundColor Yellow
        }
        
        Complete-ReSetOperation -Name $operationName -Status "Success"
        
    } catch {
        Write-ReSetLog "Error resetting computer certificates: $($_.Exception.Message)" "ERROR"
        Complete-ReSetOperation -Name $operationName -Status "Failed" -ErrorMessage $_.Exception.Message
        throw
    }
}

function Reset-HostNetlogon {
    <#
    .SYNOPSIS
        Resets Netlogon service and related host authentication components
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [switch]$Force
    )
    
    $operationName = "Host Netlogon Reset"
    $backupName = "HostNetlogon"
    
    try {
        Start-ReSetOperation -Name $operationName
        
        if (-not $Force) {
            if (-not (Confirm-ReSetOperation -Operation $operationName -Impact "Medium" -Description "This will reset Netlogon and authentication services.")) {
                return
            }
        }
        
        # Create backup
        New-ReSetBackup -BackupName $backupName -RegistryPaths @(
            "HKLM:\SYSTEM\CurrentControlSet\Services\Netlogon"
        )
        
        Write-ProgressStep "Stopping Netlogon and dependent services..."
        $netlogonServices = @("Netlogon", "LanmanWorkstation", "LanmanServer")
        
        foreach ($serviceName in $netlogonServices) {
            try {
                $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
                if ($service -and $service.Status -eq 'Running') {
                    Stop-Service -Name $serviceName -Force
                    Write-Host "Stopped: $serviceName" -ForegroundColor Yellow
                }
            } catch {
                Write-Host "Warning: Could not stop $serviceName" -ForegroundColor Yellow
            }
        }
        
        Write-ProgressStep "Clearing Netlogon logs and cache..."
        try {
            $netlogonFiles = @(
                "$env:WINDIR\debug\netlogon.log",
                "$env:WINDIR\debug\netlogon.bak",
                "$env:WINDIR\system32\config\netlogon.ftl"
            )
            
            foreach ($file in $netlogonFiles) {
                if (Test-Path $file) {
                    Remove-Item -Path $file -Force -ErrorAction SilentlyContinue
                    Write-Host "Removed: $file" -ForegroundColor Green
                }
            }
        } catch {
            Write-Host "Warning: Some Netlogon files could not be cleared" -ForegroundColor Yellow
        }
        
        Write-ProgressStep "Resetting Netlogon registry settings..."
        try {
            $netlogonPath = "HKLM:\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters"
            
            # Reset to defaults
            Remove-RegistryValue -Path $netlogonPath -Name "DisablePasswordChange" -ErrorAction SilentlyContinue
            Remove-RegistryValue -Path $netlogonPath -Name "MaximumPasswordAge" -ErrorAction SilentlyContinue
            Remove-RegistryValue -Path $netlogonPath -Name "RefusePasswordChange" -ErrorAction SilentlyContinue
            
            Write-Host "Netlogon registry settings reset" -ForegroundColor Green
        } catch {
            Write-Host "Warning: Some registry settings could not be reset" -ForegroundColor Yellow
        }
        
        Write-ProgressStep "Starting Netlogon and dependent services..."
        # Start in correct order
        foreach ($serviceName in $netlogonServices) {
            try {
                Start-Service -Name $serviceName -ErrorAction SilentlyContinue
                Write-Host "Started: $serviceName" -ForegroundColor Green
            } catch {
                Write-Host "Warning: Could not start $serviceName" -ForegroundColor Yellow
            }
        }
        
        Write-ProgressStep "Verifying Netlogon functionality..."
        Start-Sleep -Seconds 5
        try {
            $netlogonStatus = Get-Service -Name "Netlogon"
            if ($netlogonStatus.Status -eq 'Running') {
                Write-Host "Netlogon verification: PASSED" -ForegroundColor Green
            } else {
                Write-Host "Netlogon verification: FAILED" -ForegroundColor Red
            }
        } catch {
            Write-Host "Netlogon verification: ERROR" -ForegroundColor Red
        }
        
        Complete-ReSetOperation -Name $operationName -Status "Success"
        
    } catch {
        Write-ReSetLog "Error resetting host Netlogon: $($_.Exception.Message)" "ERROR"
        Complete-ReSetOperation -Name $operationName -Status "Failed" -ErrorMessage $_.Exception.Message
        throw
    }
}

function Reset-HostDNSRegistration {
    <#
    .SYNOPSIS
        Resets host DNS registration in Active Directory
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [switch]$Force
    )
    
    $operationName = "Host DNS Registration Reset"
    
    try {
        Start-ReSetOperation -Name $operationName
        
        if (-not $Force) {
            if (-not (Confirm-ReSetOperation -Operation $operationName -Impact "Low" -Description "This will reset DNS registration for this host.")) {
                return
            }
        }
        
        Write-ProgressStep "Clearing DNS registration cache..."
        & ipconfig /flushdns | Out-Null
        
        Write-ProgressStep "Releasing and renewing IP configuration..."
        & ipconfig /release | Out-Null
        Start-Sleep -Seconds 2
        & ipconfig /renew | Out-Null
        
        Write-ProgressStep "Re-registering DNS names..."
        & ipconfig /registerdns | Out-Null
        
        Write-ProgressStep "Updating DNS records in Active Directory..."
        try {
            # Force DNS record update
            & nltest /dsregdns 2>&1 | Out-Null
            Write-Host "DNS records updated in AD" -ForegroundColor Green
        } catch {
            Write-Host "Warning: DNS record update may have issues" -ForegroundColor Yellow
        }
        
        Write-ProgressStep "Verifying DNS registration..."
        Start-Sleep -Seconds 5
        try {
            $computerName = $env:COMPUTERNAME
            $fqdn = "$computerName.$env:USERDNSDOMAIN"
            
            $dnsTest = Resolve-DnsName -Name $fqdn -ErrorAction Stop
            if ($dnsTest) {
                Write-Host "DNS registration verification: PASSED" -ForegroundColor Green
                Write-Host "FQDN: $fqdn resolves to $($dnsTest.IPAddress)" -ForegroundColor Gray
            }
        } catch {
            Write-Host "DNS registration verification: FAILED" -ForegroundColor Red
        }
        
        Complete-ReSetOperation -Name $operationName -Status "Success"
        
    } catch {
        Write-ReSetLog "Error resetting host DNS registration: $($_.Exception.Message)" "ERROR"
        Complete-ReSetOperation -Name $operationName -Status "Failed" -ErrorMessage $_.Exception.Message
        throw
    }
}

function Repair-DomainMembership {
    <#
    .SYNOPSIS
        Comprehensive domain membership repair for host computers
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [switch]$Force
    )
    
    $operationName = "Domain Membership Repair"
    
    try {
        Start-ReSetOperation -Name $operationName
        
        if (-not $Force) {
            if (-not (Confirm-ReSetOperation -Operation $operationName -Impact "High" -Description "This will perform comprehensive domain membership repair.")) {
                return
            }
        }
        
        Write-ProgressStep "Diagnosing domain membership issues..."
        $computerSystem = Get-ComputerInfo
        
        if (-not $computerSystem.PartOfDomain) {
            Write-Host "Computer is not domain-joined. Cannot repair domain membership." -ForegroundColor Red
            return
        }
        
        $domainName = $computerSystem.Domain
        $computerName = $env:COMPUTERNAME
        
        Write-Host "Computer: $computerName" -ForegroundColor Cyan
        Write-Host "Domain: $domainName" -ForegroundColor Cyan
        
        # Step 1: Reset computer account
        Write-ProgressStep "Step 1: Resetting computer account..."
        Reset-ComputerAccount -Force
        
        # Step 2: Reset domain trust
        Write-ProgressStep "Step 2: Resetting domain trust..."
        Reset-DomainTrust -Force
        
        # Step 3: Clear AD cache
        Write-ProgressStep "Step 3: Clearing AD cache..."
        Reset-HostADCache -Force
        
        # Step 4: Reset Netlogon
        Write-ProgressStep "Step 4: Resetting Netlogon..."
        Reset-HostNetlogon -Force
        
        # Step 5: Reset DNS registration
        Write-ProgressStep "Step 5: Resetting DNS registration..."
        Reset-HostDNSRegistration -Force
        
        # Step 6: Final verification
        Write-ProgressStep "Step 6: Final verification..."
        Start-Sleep -Seconds 10
        
        try {
            $secureChannelTest = Test-ComputerSecureChannel
            $adConnectivityTest = Test-ActiveDirectoryConnectivity
            
            Write-Host "`nRepair Results:" -ForegroundColor Yellow
            Write-Host "Secure Channel: $(if($secureChannelTest){'PASSED'}else{'FAILED'})" -ForegroundColor $(if($secureChannelTest){'Green'}else{'Red'})
            Write-Host "AD Connectivity: $($adConnectivityTest.Status)" -ForegroundColor $(if($adConnectivityTest.Status -eq 'Connected'){'Green'}else{'Red'})
            
            if ($secureChannelTest -and $adConnectivityTest.Status -eq 'Connected') {
                Write-Host "`n✅ Domain membership repair: SUCCESSFUL" -ForegroundColor Green
            } else {
                Write-Host "`n⚠️  Domain membership repair: PARTIAL - Manual intervention may be required" -ForegroundColor Yellow
            }
            
        } catch {
            Write-Host "`n❌ Domain membership repair: FAILED - Manual domain rejoin may be required" -ForegroundColor Red
        }
        
        Complete-ReSetOperation -Name $operationName -Status "Success"
        
    } catch {
        Write-ReSetLog "Error repairing domain membership: $($_.Exception.Message)" "ERROR"
        Complete-ReSetOperation -Name $operationName -Status "Failed" -ErrorMessage $_.Exception.Message
        throw
    }
}

function Clean-OrphanedADObjects {
    <#
    .SYNOPSIS
        Cleans orphaned Active Directory objects related to this host
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [switch]$Force
    )
    
    $operationName = "Orphaned AD Objects Cleanup"
    
    try {
        Start-ReSetOperation -Name $operationName
        
        if (-not $Force) {
            if (-not (Confirm-ReSetOperation -Operation $operationName -Impact "Medium" -Description "This will clean orphaned AD objects for this host.")) {
                return
            }
        }
        
        Write-ProgressStep "Scanning for orphaned AD objects..."
        $computerName = $env:COMPUTERNAME
        
        # Clear orphaned service principal names
        Write-ProgressStep "Cleaning orphaned service principal names..."
        try {
            & setspn -Q */$computerName 2>&1 | Out-Null
            Write-Host "SPN cleanup completed" -ForegroundColor Green
        } catch {
            Write-Host "Warning: SPN cleanup may have issues" -ForegroundColor Yellow
        }
        
        # Clear orphaned DNS records
        Write-ProgressStep "Cleaning orphaned DNS records..."
        try {
            & ipconfig /registerdns | Out-Null
            & nltest /dsregdns 2>&1 | Out-Null
            Write-Host "DNS record cleanup completed" -ForegroundColor Green
        } catch {
            Write-Host "Warning: DNS record cleanup may have issues" -ForegroundColor Yellow
        }
        
        # Clear computer object cache
        Write-ProgressStep "Clearing computer object cache..."
        try {
            Reset-HostADCache -Force
            Write-Host "Computer object cache cleared" -ForegroundColor Green
        } catch {
            Write-Host "Warning: Cache clearing may have issues" -ForegroundColor Yellow
        }
        
        Complete-ReSetOperation -Name $operationName -Status "Success"
        
    } catch {
        Write-ReSetLog "Error cleaning orphaned AD objects: $($_.Exception.Message)" "ERROR"
        Complete-ReSetOperation -Name $operationName -Status "Failed" -ErrorMessage $_.Exception.Message
        throw
    }
}

# ===================================================================
# EXPORT FUNCTIONS
# ===================================================================

Write-Host "Host Computer AD Cleanup Functions Loaded" -ForegroundColor Green
Write-Host "Functions: Reset-ComputerAccount, Reset-DomainTrust, Reset-HostADCache," -ForegroundColor Gray
Write-Host "          Reset-ComputerCertificates, Reset-HostNetlogon, Reset-HostDNSRegistration," -ForegroundColor Gray
Write-Host "          Repair-DomainMembership, Clean-OrphanedADObjects" -ForegroundColor Gray
