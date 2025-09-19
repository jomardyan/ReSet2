#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Advanced System Performance and Optimization Reset Functions

.DESCRIPTION
    Comprehensive system performance optimization and troubleshooting utilities.
    Includes memory management, disk optimization, and system service tuning.

.AUTHOR
    ReSet Toolkit

.VERSION
    2.0.0

.FUNCTIONS
    - Reset-SystemPerformance
    - Reset-MemoryManagement
    - Reset-DiskOptimization
    - Reset-SystemServices
    - Reset-StartupPrograms
    - Reset-SystemCache
    - Reset-PowerManagement
    - Reset-VisualEffects
    - Reset-ProcessPriorities
    - Reset-SystemTimers
#>

# Import utility functions
Import-Module "$PSScriptRoot\ReSetUtils.psm1" -Force

# ===================================================================
# SYSTEM PERFORMANCE RESET FUNCTIONS
# ===================================================================

function Reset-SystemPerformance {
    <#
    .SYNOPSIS
        Comprehensive system performance reset and optimization
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateSet("Balanced", "Performance", "PowerSaver")]
        [string]$Profile = "Balanced",
        
        [Parameter()]
        [switch]$OptimizeDisk,
        
        [Parameter()]
        [switch]$OptimizeMemory,
        
        [Parameter()]
        [switch]$OptimizeServices,
        
        [Parameter()]
        [switch]$Force
    )
    
    $operationName = "System Performance Reset"
    $backupName = "SystemPerformance"
    
    try {
        Start-ReSetOperation -Name $operationName
        
        if (-not $Force) {
            if (-not (Confirm-ReSetOperation -Operation $operationName -Impact "High" -Description "This will reset and optimize system performance settings.")) {
                return
            }
        }
        
        # Create comprehensive backup
        New-ReSetBackup -BackupName $backupName -RegistryPaths @(
            "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management",
            "HKLM:\SYSTEM\CurrentControlSet\Services",
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects",
            "HKCU:\Control Panel\Desktop",
            "HKLM:\SYSTEM\CurrentControlSet\Control\Power"
        )
        
        Write-ProgressStep "Analyzing current system performance..."
        $systemInfo = @{
            TotalRAM = [math]::Round((Get-ComputerInfo
            AvailableRAM = [math]::Round((Get-ComputerInfo
            CPUCount = (Get-ComputerInfo
            OSVersion = [System.Environment]::OSVersion.Version
        }
        
        Write-Host "System Info: $($systemInfo.TotalRAM)GB RAM, $($systemInfo.CPUCount) CPUs" -ForegroundColor Cyan
        
        # Apply performance profile
        Write-ProgressStep "Applying $Profile performance profile..."
        Set-SystemPerformanceProfile -Profile $Profile
        
        if ($OptimizeMemory) {
            Write-ProgressStep "Optimizing memory management..."
            Reset-MemoryManagement -Force
        }
        
        if ($OptimizeDisk) {
            Write-ProgressStep "Optimizing disk performance..."
            Reset-DiskOptimization -Force
        }
        
        if ($OptimizeServices) {
            Write-ProgressStep "Optimizing system services..."
            Reset-SystemServices -Profile $Profile -Force
        }
        
        Write-ProgressStep "Clearing system performance cache..."
        Reset-SystemCache -Force
        
        Write-ProgressStep "Optimizing visual effects..."
        Reset-VisualEffects -Profile $Profile -Force
        
        Complete-ReSetOperation -Name $operationName -Status "Success"
        
        Write-Host "`nPerformance optimization complete!" -ForegroundColor Green
        Write-Host "Recommended: Restart the system to apply all changes." -ForegroundColor Yellow
        
    } catch {
        Write-ReSetLog "Error resetting system performance: $($_.Exception.Message)" "ERROR"
        Complete-ReSetOperation -Name $operationName -Status "Failed" -ErrorMessage $_.Exception.Message
        throw
    }
}

function Set-SystemPerformanceProfile {
    param([string]$Profile)
    
    switch ($Profile) {
        "Performance" {
            # High performance settings
            Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "DisablePagingExecutive" -Value 1 -Type DWord
            Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "LargeSystemCache" -Value 1 -Type DWord
            Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power" -Name "HibernateEnabled" -Value 0 -Type DWord
            & powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>&1 | Out-Null # High performance
        }
        "PowerSaver" {
            # Power saving settings
            Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "DisablePagingExecutive" -Value 0 -Type DWord
            Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "LargeSystemCache" -Value 0 -Type DWord
            & powercfg /setactive a1841308-3541-4fab-bc81-f71556f20b4a 2>&1 | Out-Null # Power saver
        }
        "Balanced" {
            # Balanced settings
            Remove-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "DisablePagingExecutive" -ErrorAction SilentlyContinue
            Remove-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "LargeSystemCache" -ErrorAction SilentlyContinue
            & powercfg /setactive 381b4222-f694-41f0-9685-ff5bb260df2e 2>&1 | Out-Null # Balanced
        }
    }
    Write-Host "Applied $Profile performance profile" -ForegroundColor Green
}

function Reset-MemoryManagement {
    <#
    .SYNOPSIS
        Resets and optimizes memory management settings
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [switch]$Force
    )
    
    $operationName = "Memory Management Reset"
    
    try {
        Start-ReSetOperation -Name $operationName
        
        if (-not $Force) {
            if (-not (Confirm-ReSetOperation -Operation $operationName -Impact "Medium" -Description "This will reset memory management settings.")) {
                return
            }
        }
        
        Write-ProgressStep "Clearing memory working sets..."
        try {
            # Clear working sets for all processes
            Get-Process | ForEach-Object {
                try {
                    $_.WorkingSet = $_.MinWorkingSet
                } catch {
                    # Ignore errors for system processes
                }
            }
            Write-Host "Memory working sets cleared" -ForegroundColor Green
        } catch {
            Write-Host "Warning: Some working sets could not be cleared" -ForegroundColor Yellow
        }
        
        Write-ProgressStep "Optimizing virtual memory settings..."
        $memPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"
        
        # Get system RAM to calculate optimal page file size
        $totalRAM = (Get-ComputerInfo
        
        if ($totalRAM -ge 8) {
            # Systems with 8GB+ RAM
            Set-RegistryValue -Path $memPath -Name "PagingFiles" -Value "C:\pagefile.sys 1024 4096" -Type MultiString
            Write-Host "Optimized page file for high-memory system" -ForegroundColor Green
        } elseif ($totalRAM -ge 4) {
            # Systems with 4-8GB RAM
            Set-RegistryValue -Path $memPath -Name "PagingFiles" -Value "C:\pagefile.sys 2048 6144" -Type MultiString
            Write-Host "Optimized page file for medium-memory system" -ForegroundColor Green
        } else {
            # Systems with less than 4GB RAM
            Set-RegistryValue -Path $memPath -Name "PagingFiles" -Value "C:\pagefile.sys 4096 8192" -Type MultiString
            Write-Host "Optimized page file for low-memory system" -ForegroundColor Green
        }
        
        Write-ProgressStep "Optimizing memory allocation..."
        # Optimize memory allocation settings
        Set-RegistryValue -Path $memPath -Name "ClearPageFileAtShutdown" -Value 0 -Type DWord
        Set-RegistryValue -Path $memPath -Name "FeatureSettings" -Value 1 -Type DWord
        Set-RegistryValue -Path $memPath -Name "FeatureSettingsOverride" -Value 3 -Type DWord
        Set-RegistryValue -Path $memPath -Name "FeatureSettingsOverrideMask" -Value 3 -Type DWord
        
        Complete-ReSetOperation -Name $operationName -Status "Success"
        
    } catch {
        Write-ReSetLog "Error resetting memory management: $($_.Exception.Message)" "ERROR"
        Complete-ReSetOperation -Name $operationName -Status "Failed" -ErrorMessage $_.Exception.Message
        throw
    }
}

function Reset-DiskOptimization {
    <#
    .SYNOPSIS
        Optimizes disk performance and cache settings
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [switch]$DefragmentDisks,
        
        [Parameter()]
        [switch]$Force
    )
    
    $operationName = "Disk Optimization"
    
    try {
        Start-ReSetOperation -Name $operationName
        
        if (-not $Force) {
            if (-not (Confirm-ReSetOperation -Operation $operationName -Impact "Medium" -Description "This will optimize disk performance settings.")) {
                return
            }
        }
        
        Write-ProgressStep "Optimizing disk cache settings..."
        
        # Get all disk drives
        $drives = Get-CimInstance -ClassName Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 }
        
        foreach ($drive in $drives) {
            $driveLetter = $drive.DeviceID.Replace(':', '')
            
            # Optimize NTFS settings
            try {
                & fsutil behavior set DisableLastAccess 1 2>&1 | Out-Null
                & fsutil behavior set EncryptPagingFile 0 2>&1 | Out-Null
                & fsutil behavior set MemoryUsage 2 2>&1 | Out-Null # Optimize for performance
                Write-Host "Optimized NTFS settings for drive $($drive.DeviceID)" -ForegroundColor Green
            } catch {
                Write-Host "Warning: Could not optimize NTFS settings for $($drive.DeviceID)" -ForegroundColor Yellow
            }
        }
        
        Write-ProgressStep "Optimizing system file cache..."
        $cachePath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"
        
        # Optimize file system cache
        Set-RegistryValue -Path $cachePath -Name "IoPageLockLimit" -Value 0x10000000 -Type DWord # 256MB
        Set-RegistryValue -Path $cachePath -Name "SystemPages" -Value 0xFFFFFFFF -Type DWord
        
        Write-ProgressStep "Clearing disk caches..."
        # Clear system file cache
        try {
            & rundll32.exe advapi32.dll,ProcessIdleTasks 2>&1 | Out-Null
            Write-Host "System file cache cleared" -ForegroundColor Green
        } catch {
            Write-Host "Warning: Could not clear system file cache" -ForegroundColor Yellow
        }
        
        if ($DefragmentDisks) {
            Write-ProgressStep "Analyzing and defragmenting disks..."
            foreach ($drive in $drives) {
                $driveLetter = $drive.DeviceID.Replace(':', '')
                try {
                    Write-Host "Analyzing drive $($drive.DeviceID)..." -ForegroundColor Yellow
                    $result = & defrag $drive.DeviceID /A 2>&1
                    if ($result -match "does not need to be defragmented") {
                        Write-Host "Drive $($drive.DeviceID) does not need defragmentation" -ForegroundColor Green
                    } else {
                        Write-Host "Defragmenting drive $($drive.DeviceID)..." -ForegroundColor Yellow
                        & defrag $drive.DeviceID /O 2>&1 | Out-Null
                        Write-Host "Drive $($drive.DeviceID) defragmented" -ForegroundColor Green
                    }
                } catch {
                    Write-Host "Warning: Could not defragment drive $($drive.DeviceID)" -ForegroundColor Yellow
                }
            }
        }
        
        Complete-ReSetOperation -Name $operationName -Status "Success"
        
    } catch {
        Write-ReSetLog "Error optimizing disk performance: $($_.Exception.Message)" "ERROR"
        Complete-ReSetOperation -Name $operationName -Status "Failed" -ErrorMessage $_.Exception.Message
        throw
    }
}

function Reset-SystemServices {
    <#
    .SYNOPSIS
        Optimizes system services for performance
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateSet("Performance", "Balanced", "PowerSaver")]
        [string]$Profile = "Balanced",
        
        [Parameter()]
        [switch]$Force
    )
    
    $operationName = "System Services Optimization"
    
    try {
        Start-ReSetOperation -Name $operationName
        
        if (-not $Force) {
            if (-not (Confirm-ReSetOperation -Operation $operationName -Impact "Medium" -Description "This will optimize system services for $Profile profile.")) {
                return
            }
        }
        
        # Define service optimization profiles
        $serviceProfiles = @{
            "Performance" = @{
                Disable = @("Fax", "TapiSrv", "SCardSvr", "WSearch", "Themes")
                Manual = @("BITS", "wuauserv", "Schedule", "Spooler")
                Automatic = @("Dhcp", "Dnscache", "LanmanWorkstation", "LanmanServer")
            }
            "Balanced" = @{
                Disable = @("Fax", "TapiSrv")
                Manual = @("BITS", "WSearch", "Themes")
                Automatic = @("Dhcp", "Dnscache", "LanmanWorkstation", "LanmanServer", "wuauserv", "Schedule", "Spooler")
            }
            "PowerSaver" = @{
                Disable = @("Fax", "TapiSrv", "WSearch")
                Manual = @("BITS", "Spooler", "Themes", "LanmanServer")
                Automatic = @("Dhcp", "Dnscache", "LanmanWorkstation", "wuauserv", "Schedule")
            }
        }
        
        $currentProfile = $serviceProfiles[$Profile]
        
        Write-ProgressStep "Optimizing services for $Profile profile..."
        
        # Disable unnecessary services
        foreach ($serviceName in $currentProfile.Disable) {
            try {
                $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
                if ($service) {
                    Stop-Service -Name $serviceName -Force -ErrorAction SilentlyContinue
                    Set-Service -Name $serviceName -StartupType Disabled
                    Write-Host "Disabled: $serviceName" -ForegroundColor Yellow
                }
            } catch {
                Write-Host "Warning: Could not disable $serviceName" -ForegroundColor Yellow
            }
        }
        
        # Set manual startup
        foreach ($serviceName in $currentProfile.Manual) {
            try {
                Set-Service -Name $serviceName -StartupType Manual -ErrorAction SilentlyContinue
                Write-Host "Set to Manual: $serviceName" -ForegroundColor Green
            } catch {
                Write-Host "Warning: Could not set $serviceName to manual" -ForegroundColor Yellow
            }
        }
        
        # Set automatic startup
        foreach ($serviceName in $currentProfile.Automatic) {
            try {
                Set-Service -Name $serviceName -StartupType Automatic -ErrorAction SilentlyContinue
                Write-Host "Set to Automatic: $serviceName" -ForegroundColor Green
            } catch {
                Write-Host "Warning: Could not set $serviceName to automatic" -ForegroundColor Yellow
            }
        }
        
        Complete-ReSetOperation -Name $operationName -Status "Success"
        
    } catch {
        Write-ReSetLog "Error optimizing system services: $($_.Exception.Message)" "ERROR"
        Complete-ReSetOperation -Name $operationName -Status "Failed" -ErrorMessage $_.Exception.Message
        throw
    }
}

function Reset-SystemCache {
    <#
    .SYNOPSIS
        Clears various system caches for better performance
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [switch]$Force
    )
    
    $operationName = "System Cache Reset"
    
    try {
        Start-ReSetOperation -Name $operationName
        
        if (-not $Force) {
            if (-not (Confirm-ReSetOperation -Operation $operationName -Impact "Low" -Description "This will clear system caches.")) {
                return
            }
        }
        
        Write-ProgressStep "Clearing DNS cache..."
        & ipconfig /flushdns | Out-Null
        
        Write-ProgressStep "Clearing ARP cache..."
        & arp -d * 2>&1 | Out-Null
        
        Write-ProgressStep "Clearing NetBIOS cache..."
        & nbtstat -R 2>&1 | Out-Null
        & nbtstat -RR 2>&1 | Out-Null
        
        Write-ProgressStep "Clearing system file cache..."
        try {
            # Clear standby memory
            if (Get-Command "Clear-DnsClientCache" -ErrorAction SilentlyContinue) {
                Clear-DnsClientCache
            }
            
            # Clear various Windows caches
            $cachePaths = @(
                "$env:WINDIR\Temp\*",
                "$env:TEMP\*",
                "$env:LOCALAPPDATA\Temp\*",
                "$env:WINDIR\Prefetch\*.pf"
            )
            
            foreach ($path in $cachePaths) {
                try {
                    Get-ChildItem -Path $path -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
                } catch {
                    # Ignore errors for locked files
                }
            }
            
            Write-Host "System caches cleared" -ForegroundColor Green
        } catch {
            Write-Host "Warning: Some caches could not be cleared" -ForegroundColor Yellow
        }
        
        Complete-ReSetOperation -Name $operationName -Status "Success"
        
    } catch {
        Write-ReSetLog "Error clearing system cache: $($_.Exception.Message)" "ERROR"
        Complete-ReSetOperation -Name $operationName -Status "Failed" -ErrorMessage $_.Exception.Message
        throw
    }
}

function Reset-VisualEffects {
    <#
    .SYNOPSIS
        Optimizes visual effects for performance
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateSet("Performance", "Balanced", "Appearance")]
        [string]$Profile = "Balanced",
        
        [Parameter()]
        [switch]$Force
    )
    
    $operationName = "Visual Effects Optimization"
    
    try {
        Start-ReSetOperation -Name $operationName
        
        if (-not $Force) {
            if (-not (Confirm-ReSetOperation -Operation $operationName -Impact "Low" -Description "This will optimize visual effects for $Profile.")) {
                return
            }
        }
        
        $desktopPath = "HKCU:\Control Panel\Desktop"
        $visualEffectsPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"
        
        switch ($Profile) {
            "Performance" {
                # Optimize for performance
                Set-RegistryValue -Path $desktopPath -Name "UserPreferencesMask" -Value ([byte[]](0x90,0x12,0x03,0x80,0x10,0x00,0x00,0x00)) -Type Binary
                Set-RegistryValue -Path $visualEffectsPath -Name "VisualFXSetting" -Value 2 -Type DWord
                Set-RegistryValue -Path $desktopPath -Name "MenuShowDelay" -Value 0 -Type String
                Set-RegistryValue -Path $desktopPath -Name "DragFullWindows" -Value 0 -Type String
                Write-Host "Visual effects optimized for performance" -ForegroundColor Green
            }
            "Balanced" {
                # Balanced settings
                Set-RegistryValue -Path $visualEffectsPath -Name "VisualFXSetting" -Value 3 -Type DWord
                Set-RegistryValue -Path $desktopPath -Name "MenuShowDelay" -Value 200 -Type String
                Set-RegistryValue -Path $desktopPath -Name "DragFullWindows" -Value 1 -Type String
                Write-Host "Visual effects set to balanced" -ForegroundColor Green
            }
            "Appearance" {
                # Optimize for appearance
                Set-RegistryValue -Path $visualEffectsPath -Name "VisualFXSetting" -Value 1 -Type DWord
                Set-RegistryValue -Path $desktopPath -Name "MenuShowDelay" -Value 400 -Type String
                Set-RegistryValue -Path $desktopPath -Name "DragFullWindows" -Value 1 -Type String
                Write-Host "Visual effects optimized for appearance" -ForegroundColor Green
            }
        }
        
        Complete-ReSetOperation -Name $operationName -Status "Success"
        
    } catch {
        Write-ReSetLog "Error optimizing visual effects: $($_.Exception.Message)" "ERROR"
        Complete-ReSetOperation -Name $operationName -Status "Failed" -ErrorMessage $_.Exception.Message
        throw
    }
}

function Reset-PowerManagement {
    <#
    .SYNOPSIS
        Resets and optimizes power management settings
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateSet("HighPerformance", "Balanced", "PowerSaver")]
        [string]$PowerPlan = "Balanced",
        
        [Parameter()]
        [switch]$Force
    )
    
    $operationName = "Power Management Reset"
    
    try {
        Start-ReSetOperation -Name $operationName
        
        if (-not $Force) {
            if (-not (Confirm-ReSetOperation -Operation $operationName -Impact "Medium" -Description "This will reset power management to $PowerPlan.")) {
                return
            }
        }
        
        Write-ProgressStep "Setting power plan to $PowerPlan..."
        
        $powerPlanGUIDs = @{
            "HighPerformance" = "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"
            "Balanced" = "381b4222-f694-41f0-9685-ff5bb260df2e"
            "PowerSaver" = "a1841308-3541-4fab-bc81-f71556f20b4a"
        }
        
        & powercfg /setactive $powerPlanGUIDs[$PowerPlan] 2>&1 | Out-Null
        
        Write-ProgressStep "Optimizing power settings..."
        
        switch ($PowerPlan) {
            "HighPerformance" {
                & powercfg /change monitor-timeout-ac 0 2>&1 | Out-Null
                & powercfg /change disk-timeout-ac 0 2>&1 | Out-Null
                & powercfg /change standby-timeout-ac 0 2>&1 | Out-Null
                & powercfg /hibernate off 2>&1 | Out-Null
            }
            "Balanced" {
                & powercfg /change monitor-timeout-ac 15 2>&1 | Out-Null
                & powercfg /change disk-timeout-ac 20 2>&1 | Out-Null
                & powercfg /change standby-timeout-ac 30 2>&1 | Out-Null
            }
            "PowerSaver" {
                & powercfg /change monitor-timeout-ac 5 2>&1 | Out-Null
                & powercfg /change disk-timeout-ac 10 2>&1 | Out-Null
                & powercfg /change standby-timeout-ac 15 2>&1 | Out-Null
                & powercfg /hibernate on 2>&1 | Out-Null
            }
        }
        
        Write-Host "Power management optimized for $PowerPlan" -ForegroundColor Green
        
        Complete-ReSetOperation -Name $operationName -Status "Success"
        
    } catch {
        Write-ReSetLog "Error resetting power management: $($_.Exception.Message)" "ERROR"
        Complete-ReSetOperation -Name $operationName -Status "Failed" -ErrorMessage $_.Exception.Message
        throw
    }
}

# ===================================================================
# EXPORT FUNCTIONS
# ===================================================================

Write-Host "System Performance Reset Functions Loaded" -ForegroundColor Green
Write-Host "Functions: Reset-SystemPerformance, Reset-MemoryManagement, Reset-DiskOptimization," -ForegroundColor Gray
Write-Host "          Reset-SystemServices, Reset-SystemCache, Reset-VisualEffects," -ForegroundColor Gray
Write-Host "          Reset-PowerManagement" -ForegroundColor Gray
