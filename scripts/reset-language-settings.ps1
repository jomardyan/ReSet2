# ===================================================================
# Reset Language & Regional Settings Script
# File: reset-language-settings.ps1
# Author: jomardyan
# Description: Resets Windows language and regional settings to defaults
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

$operationName = "Language & Regional Settings Reset"

try {
    # Validate environment
    Assert-AdminRights
    if (!(Test-WindowsVersion)) {
        throw "Unsupported Windows version"
    }
    
    # Start operation logging
    $operation = Start-ReSetOperation -OperationName $operationName
    
    if (-not $Silent) {
        Write-ReSetHeader -Title $operationName -Description "Reset system locale, formats, and keyboard layouts"
        
        if (-not $Force) {
            $confirmed = Confirm-ReSetOperation -OperationName $operationName -Warning "This will reset all language and regional settings to Windows defaults."
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
        Write-ProgressStep -StepName "Creating backup of language settings" -CurrentStep 1 -TotalSteps 10
        
        $registryBackupPaths = @(
            "HKEY_CURRENT_USER\Control Panel\International",
            "HKEY_CURRENT_USER\Keyboard Layout",
            "HKEY_CURRENT_USER\Control Panel\Desktop",
            "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Nls",
            "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Keyboard Layout",
            "HKEY_USERS\.DEFAULT\Control Panel\International",
            "HKEY_USERS\.DEFAULT\Keyboard Layout"
        )
        
        try {
            $backupDir = New-ReSetBackup -BackupName "LanguageSettings" -RegistryPaths $registryBackupPaths
            Write-ReSetLog "Language settings backup created: $backupDir" "SUCCESS"
        }
        catch {
            Write-ReSetLog "Failed to create backup: $($_.Exception.Message)" "ERROR"
            if (-not $Force) {
                throw "Backup failed - aborting operation. Use -Force to continue without backup."
            }
        }
    }
    
    # ===================================================================
    # RESET USER LOCALE SETTINGS
    # ===================================================================
    
    Write-ProgressStep -StepName "Resetting user locale settings" -CurrentStep 2 -TotalSteps 10
    
    $internationalPath = "HKCU:\Control Panel\International"
    
    # Reset to English (United States) locale defaults
    $localeSettings = @{
        "Locale" = "00000409"  # English (United States)
        "LocaleName" = "en-US"
        "s1159" = "AM"
        "s2359" = "PM"
        "sCountry" = "United States"
        "sCurrency" = "`$"
        "sDate" = "/"
        "sDecimal" = "."
        "sGrouping" = "3;0"
        "sList" = ","
        "sLongDate" = "dddd, MMMM d, yyyy"
        "sMonDecimalSep" = "."
        "sMonGrouping" = "3;0"
        "sMonThousandSep" = ","
        "sNativeDigits" = "0123456789"
        "sNegativeSign" = "-"
        "sPositiveSign" = ""
        "sShortDate" = "M/d/yyyy"
        "sThousand" = ","
        "sTime" = ":"
        "sTimeFormat" = "h:mm:ss tt"
        "sShortTime" = "h:mm tt"
        "iCalendarType" = "1"
        "iCountry" = "1"
        "iCurrDigits" = "2"
        "iCurrency" = "0"
        "iDate" = "0"
        "iDigits" = "2"
        "NumShape" = "1"
        "iFirstDayOfWeek" = "6"
        "iFirstWeekOfYear" = "0"
        "iLZero" = "1"
        "iMeasure" = "1"
        "iNegCurr" = "0"
        "iNegNumber" = "1"
        "iPaperSize" = "1"
        "iTime" = "0"
        "iTimePrefix" = "0"
        "iTLZero" = "0"
    }
    
    foreach ($setting in $localeSettings.GetEnumerator()) {
        Set-RegistryValue -Path $internationalPath -Name $setting.Key -Value $setting.Value -Type String
    }
    
    Write-ReSetLog "User locale settings reset to English (United States)" "SUCCESS"
    
    # ===================================================================
    # RESET SYSTEM LOCALE SETTINGS
    # ===================================================================
    
    Write-ProgressStep -StepName "Resetting system locale settings" -CurrentStep 3 -TotalSteps 10
    
    # Reset system locale using PowerShell cmdlets
    try {
        Set-WinSystemLocale -SystemLocale "en-US"
        Write-ReSetLog "System locale set to en-US" "SUCCESS"
    }
    catch {
        Write-ReSetLog "Failed to set system locale: $($_.Exception.Message)" "WARN"
    }
    
    # Reset culture and UI language
    try {
        Set-Culture -CultureInfo "en-US"
        Write-ReSetLog "Culture set to en-US" "SUCCESS"
    }
    catch {
        Write-ReSetLog "Failed to set culture: $($_.Exception.Message)" "WARN"
    }
    
    # ===================================================================
    # RESET KEYBOARD LAYOUT
    # ===================================================================
    
    Write-ProgressStep -StepName "Resetting keyboard layout" -CurrentStep 4 -TotalSteps 10
    
    $keyboardPath = "HKCU:\Keyboard Layout"
    
    # Set default keyboard layout to US English
    Set-RegistryValue -Path "$keyboardPath\Preload" -Name "1" -Value "00000409" -Type String
    
    # Remove additional keyboard layouts
    try {
        $preloadKey = Get-Item -Path "$keyboardPath\Preload" -ErrorAction SilentlyContinue
        if ($preloadKey) {
            $properties = $preloadKey.GetValueNames() | Where-Object { $_ -ne "1" }
            foreach ($prop in $properties) {
                Remove-RegistryValue -Path "$keyboardPath\Preload" -Name $prop
            }
        }
    }
    catch {
        Write-ReSetLog "Failed to clean additional keyboard layouts: $($_.Exception.Message)" "WARN"
    }
    
    # Reset substitutes
    Remove-RegistryKey -Path "$keyboardPath\Substitutes"
    
    Write-ReSetLog "Keyboard layout reset to US English" "SUCCESS"
    
    # ===================================================================
    # RESET INPUT METHOD SETTINGS
    # ===================================================================
    
    Write-ProgressStep -StepName "Resetting input method settings" -CurrentStep 5 -TotalSteps 10
    
    $inputPath = "HKCU:\Control Panel\Input Method"
    
    # Reset input method hot keys
    Set-RegistryValue -Path $inputPath -Name "Hot Keys" -Value "1" -Type String
    Set-RegistryValue -Path $inputPath -Name "Show Status" -Value "1" -Type String
    
    # Reset advanced text services
    $textServicesPath = "HKCU:\SOFTWARE\Microsoft\CTF"
    if (Test-Path $textServicesPath) {
        Remove-RegistryKey -Path "$textServicesPath\LangBar"
        Remove-RegistryKey -Path "$textServicesPath\DirectSwitchHotkeys"
    }
    
    Write-ReSetLog "Input method settings reset" "SUCCESS"
    
    # ===================================================================
    # RESET TIME AND DATE FORMATS
    # ===================================================================
    
    Write-ProgressStep -StepName "Resetting time and date formats" -CurrentStep 6 -TotalSteps 10
    
    # Additional date/time format settings
    $dateTimeSettings = @{
        "sYearMonth" = "MMMM yyyy"
        "sMonthDay" = "MMMM dd"
        "CalendarType" = "1"
    }
    
    foreach ($setting in $dateTimeSettings.GetEnumerator()) {
        Set-RegistryValue -Path $internationalPath -Name $setting.Key -Value $setting.Value -Type String
    }
    
    Write-ReSetLog "Date and time formats reset" "SUCCESS"
    
    # ===================================================================
    # RESET NUMBER FORMATS
    # ===================================================================
    
    Write-ProgressStep -StepName "Resetting number formats" -CurrentStep 7 -TotalSteps 10
    
    # Reset measurement system
    Set-RegistryValue -Path $internationalPath -Name "iMeasure" -Value "1" -Type String  # Imperial
    
    # Reset digit substitution
    Set-RegistryValue -Path $internationalPath -Name "NumShape" -Value "1" -Type String  # None
    
    Write-ReSetLog "Number formats reset" "SUCCESS"
    
    # ===================================================================
    # RESET USER PROFILE DEFAULTS
    # ===================================================================
    
    Write-ProgressStep -StepName "Resetting user profile defaults" -CurrentStep 8 -TotalSteps 10
    
    $defaultUserPath = "HKU:\.DEFAULT\Control Panel\International"
    if (Test-Path $defaultUserPath) {
        foreach ($setting in $localeSettings.GetEnumerator()) {
            Set-RegistryValue -Path $defaultUserPath -Name $setting.Key -Value $setting.Value -Type String
        }
        Write-ReSetLog "Default user profile locale settings reset" "SUCCESS"
    }
    
    # ===================================================================
    # CLEAR LANGUAGE PREFERENCES
    # ===================================================================
    
    Write-ProgressStep -StepName "Clearing language preferences" -CurrentStep 9 -TotalSteps 10
    
    try {
        # Reset Windows display language preferences
        $languagePath = "HKCU:\Control Panel\Desktop"
        Set-RegistryValue -Path $languagePath -Name "PreferredUILanguages" -Value "en-US" -Type String
        Set-RegistryValue -Path $languagePath -Name "PreferredUILanguagesPending" -Value "en-US" -Type String
        
        # Clear MUI settings
        $muiPath = "HKCU:\Control Panel\Desktop\MuiCached"
        if (Test-Path $muiPath) {
            Remove-RegistryKey -Path $muiPath
        }
        
        Write-ReSetLog "Language preferences cleared" "SUCCESS"
    }
    catch {
        Write-ReSetLog "Failed to clear language preferences: $($_.Exception.Message)" "WARN"
    }
    
    # ===================================================================
    # RESTART REQUIRED SERVICES
    # ===================================================================
    
    Write-ProgressStep -StepName "Restarting language services" -CurrentStep 10 -TotalSteps 10
    
    # Services that need to be restarted for language changes
    $servicesToRestart = @(
        "TabletInputService",
        "TextInputManagementService"
    )
    
    foreach ($service in $servicesToRestart) {
        Restart-WindowsService -ServiceName $service
    }
    
    # ===================================================================
    # COMPLETION
    # ===================================================================
    
    Write-ReSetLog "Language and regional settings reset completed successfully" "SUCCESS"
    Write-ReSetLog "A system restart is recommended for all changes to take effect" "WARN"
    
    if (-not $Silent) {
        Write-Host ""
        Write-Host "✅ Language and Regional Settings Reset Complete!" -ForegroundColor Green
        Write-Host "📋 Changes applied:" -ForegroundColor Cyan
        Write-Host "   • System locale: English (United States)" -ForegroundColor White
        Write-Host "   • Keyboard layout: US English" -ForegroundColor White
        Write-Host "   • Date/time formats: US standard" -ForegroundColor White
        Write-Host "   • Number formats: US standard" -ForegroundColor White
        Write-Host "   • Currency format: US Dollar" -ForegroundColor White
        Write-Host ""
        Write-Host "⚠️  Please restart your computer for all changes to take effect." -ForegroundColor Yellow
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
        Write-Host "❌ Language Settings Reset Failed!" -ForegroundColor Red
        Write-Host "Error: $errorMessage" -ForegroundColor Red
        Write-Host ""
    }
    
    Complete-ReSetOperation -OperationInfo $operation -Success $false -ErrorMessage $errorMessage
    throw
}
finally {
    Write-Progress -Activity "Windows Reset Operation" -Completed
}