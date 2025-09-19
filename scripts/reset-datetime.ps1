# ===================================================================
# Reset Date & Time Settings Script
# File: reset-datetime.ps1
# Author: jomardyan
# Description: Resets Windows date, time, and timezone settings to defaults
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

# ===================================================================
# CONFIGURATION AND VALIDATION
# ===================================================================

$operationName = "Date & Time Settings Reset"

try {
    # Validate environment
    Assert-AdminRights
    if (!(Test-WindowsVersion)) {
        throw "Unsupported Windows version"
    }
    
    # Start operation logging
    $operation = Start-ReSetOperation -OperationName $operationName
    
    if (-not $Silent) {
        Write-ReSetHeader -Title $operationName -Description "Reset time zone, NTP settings, and date/time formats"
        
        if (-not $Force) {
            $confirmed = Confirm-ReSetOperation -OperationName $operationName -Warning "This will reset all date and time settings including timezone and NTP configuration."
            if (-not $confirmed) {
                Write-ReSetLog "Operation cancelled by user" "WARN"
                return
            }
        }
    }
    
    # ===================================================================
    # BACKUP OPERATIONS
    # ===================================================================
    
    if ($CreateBackup) {
        Write-ProgressStep -StepName "Creating backup of date/time settings" -CurrentStep 1 -TotalSteps 12
        
        $registryBackupPaths = @(
            "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\TimeZoneInformation",
            "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\W32Time",
            "HKEY_CURRENT_USER\Control Panel\International",
            "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\DateTime"
        )
        
        try {
            $backupDir = New-ReSetBackup -BackupName "DateTimeSettings" -RegistryPaths $registryBackupPaths
            Write-ReSetLog "Date/Time settings backup created: $backupDir" "SUCCESS"
        }
        catch {
            Write-ReSetLog "Failed to create backup: $($_.Exception.Message)" "ERROR"
            if (-not $Force) {
                throw "Backup failed - aborting operation. Use -Force to continue without backup."
            }
        }
    }
    
    # ===================================================================
    # DETECT SYSTEM TIMEZONE
    # ===================================================================
    
    Write-ProgressStep -StepName "Detecting system timezone" -CurrentStep 2 -TotalSteps 12
    
    # Try to detect timezone based on system location
    try {
        $geoId = Get-WinHomeLocation
        Write-ReSetLog "Current Geo ID: $($geoId.GeoId)" "INFO"
        
        # Map common Geo IDs to timezones
        $timezoneMap = @{
            244 = "Eastern Standard Time"    # United States
            39  = "Central European Standard Time"  # Germany
            84  = "GMT Standard Time"        # United Kingdom
            45  = "Tokyo Standard Time"      # Japan
            23  = "AUS Eastern Standard Time" # Australia
            38  = "Central European Standard Time" # France
            16  = "China Standard Time"      # China
            37  = "India Standard Time"      # India
            14  = "Canada Central Standard Time" # Canada
            21  = "E. South America Standard Time" # Brazil
        }
        
        $suggestedTimezone = $timezoneMap[$geoId.GeoId]
        if (-not $suggestedTimezone) {
            $suggestedTimezone = "UTC"
        }
        
        Write-ReSetLog "Suggested timezone: $suggestedTimezone" "INFO"
    }
    catch {
        $suggestedTimezone = "UTC"
        Write-ReSetLog "Failed to detect timezone, defaulting to UTC" "WARN"
    }
    
    # ===================================================================
    # RESET TIMEZONE SETTINGS
    # ===================================================================
    
    Write-ProgressStep -StepName "Resetting timezone settings" -CurrentStep 3 -TotalSteps 12
    
    try {
        # Set timezone using tzutil
        $null = & tzutil /s $suggestedTimezone 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-ReSetLog "Timezone set to: $suggestedTimezone" "SUCCESS"
        } else {
            # Fallback to UTC if suggested timezone fails
            $null = & tzutil /s "UTC" 2>&1
            Write-ReSetLog "Timezone set to: UTC (fallback)" "SUCCESS"
        }
    }
    catch {
        Write-ReSetLog "Failed to set timezone: $($_.Exception.Message)" "ERROR"
    }
    
    # Reset timezone registry settings
    $timezoneRegPath = "HKLM:\SYSTEM\CurrentControlSet\Control\TimeZoneInformation"
    
    # Enable automatic daylight saving time
    Set-RegistryValue -Path $timezoneRegPath -Name "DisableAutoDaylightTimeSet" -Value 0 -Type DWord
    
    Write-ReSetLog "Automatic daylight saving time enabled" "SUCCESS"
    
    # ===================================================================
    # RESET WINDOWS TIME SERVICE (W32TIME)
    # ===================================================================
    
    Write-ProgressStep -StepName "Resetting Windows Time Service" -CurrentStep 4 -TotalSteps 12
    
    try {
        # Stop Windows Time service
        Stop-Service -Name "w32time" -Force -ErrorAction SilentlyContinue
        
        # Reset W32Time configuration
        $null = & w32tm /unregister 2>&1
        $null = & w32tm /register 2>&1
        
        Write-ReSetLog "Windows Time service re-registered" "SUCCESS"
    }
    catch {
        Write-ReSetLog "Failed to re-register Windows Time service: $($_.Exception.Message)" "WARN"
    }
    
    # Configure default NTP servers
    $w32timeRegPath = "HKLM:\SYSTEM\CurrentControlSet\Services\W32Time"
    
    # Reset time providers
    Set-RegistryValue -Path "$w32timeRegPath\Parameters" -Name "Type" -Value "NTP" -Type String
    Set-RegistryValue -Path "$w32timeRegPath\Parameters" -Name "NtpServer" -Value "time.windows.com,0x9 pool.ntp.org,0x9" -Type String
    
    # Reset time configuration
    Set-RegistryValue -Path "$w32timeRegPath\Config" -Name "AnnounceFlags" -Value 10 -Type DWord
    Set-RegistryValue -Path "$w32timeRegPath\Config" -Name "MaxNegPhaseCorrection" -Value 172800 -Type DWord
    Set-RegistryValue -Path "$w32timeRegPath\Config" -Name "MaxPosPhaseCorrection" -Value 172800 -Type DWord
    Set-RegistryValue -Path "$w32timeRegPath\Config" -Name "MaxAllowedPhaseOffset" -Value 300 -Type DWord
    
    # Reset NTP client settings
    Set-RegistryValue -Path "$w32timeRegPath\TimeProviders\NtpClient" -Name "Enabled" -Value 1 -Type DWord
    Set-RegistryValue -Path "$w32timeRegPath\TimeProviders\NtpClient" -Name "InputProvider" -Value 1 -Type DWord
    Set-RegistryValue -Path "$w32timeRegPath\TimeProviders\NtpClient" -Name "SpecialPollInterval" -Value 3600 -Type DWord
    
    Write-ReSetLog "Windows Time service configuration reset" "SUCCESS"
    
    # ===================================================================
    # RESET DATE/TIME DISPLAY FORMATS
    # ===================================================================
    
    Write-ProgressStep -StepName "Resetting date/time display formats" -CurrentStep 5 -TotalSteps 12
    
    $internationalPath = "HKCU:\Control Panel\International"
    
    # Reset date formats to US defaults
    $dateTimeFormats = @{
        "sShortDate" = "M/d/yyyy"
        "sLongDate" = "dddd, MMMM d, yyyy"
        "sTimeFormat" = "h:mm:ss tt"
        "sShortTime" = "h:mm tt"
        "s1159" = "AM"
        "s2359" = "PM"
        "sDate" = "/"
        "sTime" = ":"
        "iDate" = "0"        # Month-Day-Year
        "iTime" = "0"        # 12-hour format
        "iTLZero" = "0"      # No leading zero for hours
        "iTimePrefix" = "0"  # AM/PM suffix
        "iCalendarType" = "1" # Gregorian calendar
        "iFirstDayOfWeek" = "6" # Sunday
        "iFirstWeekOfYear" = "0" # First week contains January 1
    }
    
    foreach ($format in $dateTimeFormats.GetEnumerator()) {
        Set-RegistryValue -Path $internationalPath -Name $format.Key -Value $format.Value
    }
    
    Write-ReSetLog "Date/time display formats reset to US defaults" "SUCCESS"
    
    # ===================================================================
    # ENABLE AUTOMATIC TIME SYNCHRONIZATION
    # ===================================================================
    
    Write-ProgressStep -StepName "Enabling automatic time synchronization" -CurrentStep 6 -TotalSteps 12
    
    try {
        # Start Windows Time service
        Start-Service -Name "w32time" -ErrorAction Stop
        
        # Configure automatic startup
        Set-Service -Name "w32time" -StartupType Automatic
        
        Write-ReSetLog "Windows Time service started and set to automatic" "SUCCESS"
    }
    catch {
        Write-ReSetLog "Failed to start Windows Time service: $($_.Exception.Message)" "ERROR"
    }
    
    # Force immediate time synchronization
    try {
        $null = & w32tm /resync /force 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-ReSetLog "Time synchronized with NTP servers" "SUCCESS"
        } else {
            Write-ReSetLog "Failed to synchronize time immediately" "WARN"
        }
    }
    catch {
        Write-ReSetLog "Failed to force time sync: $($_.Exception.Message)" "WARN"
    }
    
    # ===================================================================
    # RESET TIME ZONE AUTO-DETECTION
    # ===================================================================
    
    Write-ProgressStep -StepName "Configuring timezone auto-detection" -CurrentStep 7 -TotalSteps 12
    
    # Enable automatic timezone detection (Windows 10+)
    $locationPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location"
    Set-RegistryValue -Path $locationPath -Name "Value" -Value "Allow" -Type String
    
    # Reset location settings for timezone detection
    $timezoneAutoUpdatePath = "HKLM:\SYSTEM\CurrentControlSet\Services\tzautoupdate"
    Set-RegistryValue -Path "$timezoneAutoUpdatePath\Parameters" -Name "Start" -Value 3 -Type DWord
    
    Write-ReSetLog "Timezone auto-detection configured" "SUCCESS"
    
    # ===================================================================
    # RESET CALENDAR SETTINGS
    # ===================================================================
    
    Write-ProgressStep -StepName "Resetting calendar settings" -CurrentStep 8 -TotalSteps 12
    
    # Additional calendar-related settings
    $calendarSettings = @{
        "sYearMonth" = "MMMM yyyy"
        "sMonthDay" = "MMMM dd"
        "CalendarType" = "1"    # Gregorian
        "iFirstDayOfWeek" = "6" # Sunday = 6
        "iFirstWeekOfYear" = "0" # Week containing Jan 1
    }
    
    foreach ($setting in $calendarSettings.GetEnumerator()) {
        Set-RegistryValue -Path $internationalPath -Name $setting.Key -Value $setting.Value
    }
    
    Write-ReSetLog "Calendar settings reset" "SUCCESS"
    
    # ===================================================================
    # RESET INTERNET TIME SETTINGS
    # ===================================================================
    
    Write-ProgressStep -StepName "Resetting Internet time settings" -CurrentStep 9 -TotalSteps 12
    
    # Internet Time tab settings
    $internetTimePath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DateTime\Servers"
    
    # Reset default time servers list
    Set-RegistryValue -Path $internetTimePath -Name "1" -Value "time.windows.com" -Type String
    Set-RegistryValue -Path $internetTimePath -Name "2" -Value "pool.ntp.org" -Type String
    Set-RegistryValue -Path $internetTimePath -Name "3" -Value "time.nist.gov" -Type String
    Set-RegistryValue -Path $internetTimePath -Name "(Default)" -Value "1" -Type String
    
    Write-ReSetLog "Internet time servers reset" "SUCCESS"
    
    # ===================================================================
    # CLEAR CACHED TIME DATA
    # ===================================================================
    
    Write-ProgressStep -StepName "Clearing cached time data" -CurrentStep 10 -TotalSteps 12
    
    try {
        # Clear time zone cache
        $timezoneCache = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Time Zones"
        if (Test-Path "$timezoneCache\Cached") {
            Remove-RegistryKey -Path "$timezoneCache\Cached"
        }
        
        # Clear W32Time event log
        Clear-EventLog -LogName "System" -Source "Microsoft-Windows-Time-Service" -ErrorAction SilentlyContinue
        
        Write-ReSetLog "Time caches cleared" "SUCCESS"
    }
    catch {
        Write-ReSetLog "Failed to clear time caches: $($_.Exception.Message)" "WARN"
    }
    
    # ===================================================================
    # RESET USER PROFILE TIME SETTINGS
    # ===================================================================
    
    Write-ProgressStep -StepName "Resetting user profile time settings" -CurrentStep 11 -TotalSteps 12
    
    # Reset default user profile time settings
    $defaultUserPath = "HKU:\.DEFAULT\Control Panel\International"
    if (Test-Path $defaultUserPath) {
        foreach ($format in $dateTimeFormats.GetEnumerator()) {
            Set-RegistryValue -Path $defaultUserPath -Name $format.Key -Value $format.Value
        }
        Write-ReSetLog "Default user profile time settings reset" "SUCCESS"
    }
    
    # ===================================================================
    # RESTART TIME-RELATED SERVICES
    # ===================================================================
    
    Write-ProgressStep -StepName "Restarting time-related services" -CurrentStep 12 -TotalSteps 12
    
    $timeServices = @(
        "w32time",
        "tzautoupdate"
    )
    
    foreach ($service in $timeServices) {
        try {
            Restart-WindowsService -ServiceName $service
        }
        catch {
            Write-ReSetLog "Service $service may not exist on this system" "INFO"
        }
    }
    
    # ===================================================================
    # FINAL TIME SYNCHRONIZATION
    # ===================================================================
    
    Start-Sleep -Seconds 3
    
    try {
        $null = & w32tm /resync /nowait 2>&1
        Write-ReSetLog "Final time synchronization initiated" "SUCCESS"
    }
    catch {
        Write-ReSetLog "Failed to initiate final time sync: $($_.Exception.Message)" "WARN"
    }
    
    # ===================================================================
    # COMPLETION
    # ===================================================================
    
    Write-ReSetLog "Date and time settings reset completed successfully" "SUCCESS"
    
    if (-not $Silent) {
        Write-Host ""
        Write-Host "✅ Date & Time Settings Reset Complete!" -ForegroundColor Green
        Write-Host "📋 Changes applied:" -ForegroundColor Cyan
        Write-Host "   • Timezone: $suggestedTimezone (auto-detection enabled)" -ForegroundColor White
        Write-Host "   • NTP servers: time.windows.com, pool.ntp.org" -ForegroundColor White
        Write-Host "   • Date format: M/d/yyyy (US standard)" -ForegroundColor White
        Write-Host "   • Time format: h:mm:ss tt (12-hour)" -ForegroundColor White
        Write-Host "   • Calendar: Gregorian, Sunday first day" -ForegroundColor White
        Write-Host "   • Automatic DST: Enabled" -ForegroundColor White
        Write-Host ""
        
        # Show current time
        $currentTime = Get-Date
        Write-Host "🕒 Current system time: $($currentTime.ToString('F'))" -ForegroundColor Cyan
        Write-Host ""
        
        if ($CreateBackup) {
            Write-Host "💾 Backup created in: $backupDir" -ForegroundColor Cyan
        }
    }
    
    Complete-ReSetOperation -OperationInfo $operation -Success $true
}
catch {
    $errorMessage = $_.Exception.Message
    Write-ReSetLog "Operation failed: $errorMessage" "ERROR"
    
    if (-not $Silent) {
        Write-Host ""
        Write-Host "❌ Date & Time Settings Reset Failed!" -ForegroundColor Red
        Write-Host "Error: $errorMessage" -ForegroundColor Red
        Write-Host ""
    }
    
    Complete-ReSetOperation -OperationInfo $operation -Success $false -ErrorMessage $errorMessage
    throw
}
finally {
    Write-Progress -Activity "Windows Reset Operation" -Completed
}