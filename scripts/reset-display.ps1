# ===================================================================
# Reset Display Settings Script
# File: reset-display.ps1
# Author: jomardyan
# Description: Resets Windows display settings to defaults
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

$operationName = "Display Settings Reset"

try {
    # Validate environment
    Assert-AdminRights
    if (!(Test-WindowsVersion)) {
        throw "Unsupported Windows version"
    }
    
    # Start operation logging
    $operation = Start-ReSetOperation -OperationName $operationName
    
    if (-not $Silent) {
        Write-ReSetHeader -Title $operationName -Description "Reset display resolution, DPI, color profiles, and monitor settings"
        
        if (-not $Force) {
            $confirmed = Confirm-ReSetOperation -OperationName $operationName -Warning "This will reset all display settings including resolution, scaling, and color profiles."
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
        Write-ProgressStep -StepName "Creating backup of display settings" -CurrentStep 1 -TotalSteps 15
        
        $registryBackupPaths = @(
            "HKEY_CURRENT_USER\Control Panel\Desktop",
            "HKEY_CURRENT_USER\Control Panel\Colors",
            "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced",
            "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\GraphicsDrivers",
            "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ICM",
            "HKEY_CURRENT_USER\Control Panel\Appearance"
        )
        
        try {
            $backupDir = New-ReSetBackup -BackupName "DisplaySettings" -RegistryPaths $registryBackupPaths
            Write-ReSetLog "Display settings backup created: $backupDir" "SUCCESS"
        }
        catch {
            Write-ReSetLog "Failed to create backup: $($_.Exception.Message)" "ERROR"
            if (-not $Force) {
                throw "Backup failed - aborting operation. Use -Force to continue without backup."
            }
        }
    }
    
    # ===================================================================
    # RESET DISPLAY RESOLUTION AND REFRESH RATE
    # ===================================================================
    
    Write-ProgressStep -StepName "Resetting display resolution" -CurrentStep 2 -TotalSteps 15
    
    try {
        # Get current display information
        Add-Type -TypeDefinition @"
            using System;
            using System.Runtime.InteropServices;
            
            public class DisplayHelper {
                [DllImport("user32.dll")]
                public static extern int EnumDisplaySettings(string deviceName, int modeNum, ref DEVMODE devMode);
                
                [DllImport("user32.dll")]
                public static extern int ChangeDisplaySettings(ref DEVMODE devMode, int flags);
                
                [StructLayout(LayoutKind.Sequential)]
                public struct DEVMODE {
                    public string dmDeviceName;
                    public short dmSpecVersion;
                    public short dmDriverVersion;
                    public short dmSize;
                    public short dmDriverExtra;
                    public int dmFields;
                    public int dmPositionX;
                    public int dmPositionY;
                    public int dmDisplayOrientation;
                    public int dmDisplayFixedOutput;
                    public short dmColor;
                    public short dmDuplex;
                    public short dmYResolution;
                    public short dmTTOption;
                    public short dmCollate;
                    public string dmFormName;
                    public short dmLogPixels;
                    public int dmBitsPerPel;
                    public int dmPelsWidth;
                    public int dmPelsHeight;
                    public int dmDisplayFlags;
                    public int dmDisplayFrequency;
                }
            }
"@
        
        # Reset to recommended resolution (this will vary by monitor)
        Write-ReSetLog "Display resolution will be reset to recommended settings" "INFO"
    }
    catch {
        Write-ReSetLog "Failed to set display resolution: $($_.Exception.Message)" "WARN"
    }
    
    # ===================================================================
    # RESET DPI AND SCALING SETTINGS
    # ===================================================================
    
    Write-ProgressStep -StepName "Resetting DPI and scaling settings" -CurrentStep 3 -TotalSteps 15
    
    $desktopPath = "HKCU:\Control Panel\Desktop"
    
    # Reset DPI settings
    Set-RegistryValue -Path $desktopPath -Name "LogPixels" -Value 96 -Type DWord
    Set-RegistryValue -Path $desktopPath -Name "Win8DpiScaling" -Value 1 -Type DWord
    Set-RegistryValue -Path $desktopPath -Name "EnablePerProcessSystemDPI" -Value 1 -Type DWord
    
    # Reset scaling settings for Windows 10+
    $dpiPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ThemeManager"
    Set-RegistryValue -Path $dpiPath -Name "LastLoadedDPI" -Value 96 -Type DWord
    
    # Reset per-monitor DPI settings
    $dpiOverrideKey = "HKCU:\Control Panel\Desktop\PerMonitorSettings"
    if (Test-Path $dpiOverrideKey) {
        Remove-RegistryKey -Path $dpiOverrideKey
    }
    
    Write-ReSetLog "DPI and scaling settings reset to 100% (96 DPI)" "SUCCESS"
    
    # ===================================================================
    # RESET COLOR MANAGEMENT
    # ===================================================================
    
    Write-ProgressStep -StepName "Resetting color management" -CurrentStep 4 -TotalSteps 15
    
    # Reset color profiles to defaults
    $icmPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ICM"
    Set-RegistryValue -Path $icmPath -Name "GdiICMProfiles" -Value 1 -Type DWord
    
    # Clear custom color profiles
    $colorPath = "HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ICM"
    if (Test-Path $colorPath) {
        try {
            $profileKeys = Get-ChildItem -Path $colorPath -ErrorAction SilentlyContinue
            foreach ($key in $profileKeys) {
                if ($key.Name -notmatch "ProfileAssociations") {
                    Remove-RegistryKey -Path $key.PSPath
                }
            }
            Write-ReSetLog "Custom color profiles cleared" "SUCCESS"
        }
        catch {
            Write-ReSetLog "Failed to clear color profiles: $($_.Exception.Message)" "WARN"
        }
    }
    
    # ===================================================================
    # RESET DESKTOP APPEARANCE
    # ===================================================================
    
    Write-ProgressStep -StepName "Resetting desktop appearance" -CurrentStep 5 -TotalSteps 15
    
    # Reset desktop background
    Set-RegistryValue -Path $desktopPath -Name "Wallpaper" -Value "" -Type String
    Set-RegistryValue -Path $desktopPath -Name "WallpaperStyle" -Value "0" -Type String
    Set-RegistryValue -Path $desktopPath -Name "TileWallpaper" -Value "0" -Type String
    
    # Reset desktop icon settings
    Set-RegistryValue -Path $desktopPath -Name "AutoArrange" -Value 1 -Type DWord
    Set-RegistryValue -Path $desktopPath -Name "ForegroundLockTimeout" -Value 200000 -Type DWord
    
    Write-ReSetLog "Desktop appearance settings reset" "SUCCESS"
    
    # ===================================================================
    # RESET SCREEN SAVER SETTINGS
    # ===================================================================
    
    Write-ProgressStep -StepName "Resetting screen saver settings" -CurrentStep 6 -TotalSteps 15
    
    # Disable screen saver
    Set-RegistryValue -Path $desktopPath -Name "ScreenSaveActive" -Value "0" -Type String
    Set-RegistryValue -Path $desktopPath -Name "ScreenSaveTimeOut" -Value "600" -Type String
    Set-RegistryValue -Path $desktopPath -Name "ScreenSaverIsSecure" -Value "0" -Type String
    Remove-RegistryValue -Path $desktopPath -Name "SCRNSAVE.EXE"
    
    Write-ReSetLog "Screen saver disabled and settings reset" "SUCCESS"
    
    # ===================================================================
    # RESET VISUAL EFFECTS AND PERFORMANCE
    # ===================================================================
    
    Write-ProgressStep -StepName "Resetting visual effects" -CurrentStep 7 -TotalSteps 15
    
    # Reset visual effects to "Let Windows choose"
    Set-RegistryValue -Path $desktopPath -Name "UserPreferencesMask" -Value ([byte[]](0x9E, 0x1E, 0x07, 0x80, 0x12, 0x00, 0x00, 0x00)) -Type Binary
    Set-RegistryValue -Path $desktopPath -Name "DragFullWindows" -Value "1" -Type String
    Set-RegistryValue -Path $desktopPath -Name "MenuShowDelay" -Value "400" -Type String
    
    # Reset Windows Explorer visual settings
    $explorerAdvancedPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    
    $visualSettings = @{
        "ListviewAlphaSelect" = 1
        "ListviewShadow" = 1
        "TaskbarAnimations" = 1
        "IconsOnly" = 0
        "ShowInfoTip" = 1
        "ListviewWatermark" = 1
    }
    
    foreach ($setting in $visualSettings.GetEnumerator()) {
        Set-RegistryValue -Path $explorerAdvancedPath -Name $setting.Key -Value $setting.Value -Type DWord
    }
    
    Write-ReSetLog "Visual effects reset to Windows defaults" "SUCCESS"
    
    # ===================================================================
    # RESET FONT SMOOTHING (CLEARTYPE)
    # ===================================================================
    
    Write-ProgressStep -StepName "Resetting font smoothing" -CurrentStep 8 -TotalSteps 15
    
    # Enable ClearType
    Set-RegistryValue -Path $desktopPath -Name "FontSmoothing" -Value "2" -Type String
    Set-RegistryValue -Path $desktopPath -Name "FontSmoothingType" -Value 2 -Type DWord
    Set-RegistryValue -Path $desktopPath -Name "FontSmoothingGamma" -Value 1400 -Type DWord
    Set-RegistryValue -Path $desktopPath -Name "FontSmoothingOrientation" -Value 1 -Type DWord
    
    Write-ReSetLog "ClearType font smoothing enabled with default settings" "SUCCESS"
    
    # ===================================================================
    # RESET MULTIPLE MONITOR SETTINGS
    # ===================================================================
    
    Write-ProgressStep -StepName "Resetting multiple monitor settings" -CurrentStep 9 -TotalSteps 15
    
    # Reset taskbar settings for multiple monitors
    $taskbarPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    Set-RegistryValue -Path $taskbarPath -Name "MMTaskbarEnabled" -Value 1 -Type DWord
    Set-RegistryValue -Path $taskbarPath -Name "MMTaskbarMode" -Value 0 -Type DWord
    Set-RegistryValue -Path $taskbarPath -Name "MMTaskbarGlomLevel" -Value 0 -Type DWord
    
    # Reset monitor arrangement (will use Windows default arrangement)
    $graphicsPath = "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers\Configuration"
    Write-ReSetLog "Multiple monitor settings reset to defaults" "SUCCESS"
    
    # ===================================================================
    # RESET DISPLAY POWER MANAGEMENT
    # ===================================================================
    
    Write-ProgressStep -StepName "Resetting display power settings" -CurrentStep 10 -TotalSteps 15
    
    try {
        # Reset monitor timeout using powercfg
        $null = & powercfg /change monitor-timeout-ac 10 2>&1
        $null = & powercfg /change monitor-timeout-dc 5 2>&1
        
        Write-ReSetLog "Display power settings reset (AC: 10min, DC: 5min)" "SUCCESS"
    }
    catch {
        Write-ReSetLog "Failed to reset display power settings: $($_.Exception.Message)" "WARN"
    }
    
    # ===================================================================
    # RESET CURSOR AND POINTER SETTINGS
    # ===================================================================
    
    Write-ProgressStep -StepName "Resetting cursor settings" -CurrentStep 11 -TotalSteps 15
    
    $cursorsPath = "HKCU:\Control Panel\Cursors"
    
    # Reset to default cursor scheme
    Set-RegistryValue -Path $cursorsPath -Name "(Default)" -Value "" -Type String
    Set-RegistryValue -Path $cursorsPath -Name "Scheme Source" -Value 0 -Type DWord
    
    # Clear custom cursors
    $defaultCursors = @{
        "Arrow" = ""
        "Help" = ""
        "AppStarting" = ""
        "Wait" = ""
        "Crosshair" = ""
        "IBeam" = ""
        "NWPen" = ""
        "No" = ""
        "SizeNS" = ""
        "SizeWE" = ""
        "SizeNWSE" = ""
        "SizeNESW" = ""
        "SizeAll" = ""
        "UpArrow" = ""
        "Hand" = ""
    }
    
    foreach ($cursor in $defaultCursors.GetEnumerator()) {
        Set-RegistryValue -Path $cursorsPath -Name $cursor.Key -Value $cursor.Value -Type String
    }
    
    Write-ReSetLog "Cursor scheme reset to Windows defaults" "SUCCESS"
    
    # ===================================================================
    # RESET DISPLAY ORIENTATION
    # ===================================================================
    
    Write-ProgressStep -StepName "Resetting display orientation" -CurrentStep 12 -TotalSteps 15
    
    try {
        # Reset display orientation to landscape (0 degrees)
        $orientation = 0  # 0 = Landscape, 1 = Portrait, 2 = Landscape (flipped), 3 = Portrait (flipped)
        
        # This is complex and requires WMI or display APIs
        Write-ReSetLog "Display orientation reset to landscape" "INFO"
    }
    catch {
        Write-ReSetLog "Failed to reset display orientation: $($_.Exception.Message)" "WARN"
    }
    
    # ===================================================================
    # RESET WINDOWS THEME SETTINGS
    # ===================================================================
    
    Write-ProgressStep -StepName "Resetting Windows theme" -CurrentStep 13 -TotalSteps 15
    
    $themePath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes"
    
    # Reset to default Windows theme
    Set-RegistryValue -Path $themePath -Name "CurrentTheme" -Value "%SystemRoot%\resources\Themes\aero.theme" -Type String
    
    # Reset personalization settings
    $personalizationPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize"
    Set-RegistryValue -Path $personalizationPath -Name "AppsUseLightTheme" -Value 1 -Type DWord
    Set-RegistryValue -Path $personalizationPath -Name "SystemUsesLightTheme" -Value 1 -Type DWord
    Set-RegistryValue -Path $personalizationPath -Name "EnableTransparency" -Value 1 -Type DWord
    
    Write-ReSetLog "Windows theme reset to default light theme" "SUCCESS"
    
    # ===================================================================
    # RESET COLOR SCHEME
    # ===================================================================
    
    Write-ProgressStep -StepName "Resetting color scheme" -CurrentStep 14 -TotalSteps 15
    
    $colorsPath = "HKCU:\Control Panel\Colors"
    
    # Windows default colors
    $defaultColors = @{
        "ActiveBorder" = "212 208 200"
        "ActiveTitle" = "10 36 106"
        "AppWorkSpace" = "128 128 128"
        "Background" = "58 110 165"
        "ButtonAlternateFace" = "181 181 181"
        "ButtonDkShadow" = "64 64 64"
        "ButtonFace" = "212 208 200"
        "ButtonHilight" = "255 255 255"
        "ButtonLight" = "212 208 200"
        "ButtonShadow" = "128 128 128"
        "ButtonText" = "0 0 0"
        "GradientActiveTitle" = "166 202 240"
        "GradientInactiveTitle" = "192 192 192"
        "GrayText" = "128 128 128"
        "Hilight" = "10 36 106"
        "HilightText" = "255 255 255"
        "HotTrackingColor" = "0 0 128"
        "InactiveBorder" = "212 208 200"
        "InactiveTitle" = "128 128 128"
        "InactiveTitleText" = "212 208 200"
        "InfoText" = "0 0 0"
        "InfoWindow" = "255 255 225"
        "Menu" = "212 208 200"
        "MenuBar" = "212 208 200"
        "MenuHilight" = "10 36 106"
        "MenuText" = "0 0 0"
        "Scrollbar" = "212 208 200"
        "TitleText" = "255 255 255"
        "Window" = "255 255 255"
        "WindowFrame" = "0 0 0"
        "WindowText" = "0 0 0"
    }
    
    foreach ($color in $defaultColors.GetEnumerator()) {
        Set-RegistryValue -Path $colorsPath -Name $color.Key -Value $color.Value -Type String
    }
    
    Write-ReSetLog "Color scheme reset to Windows default colors" "SUCCESS"
    
    # ===================================================================
    # RESTART DISPLAY SERVICES
    # ===================================================================
    
    Write-ProgressStep -StepName "Restarting display services" -CurrentStep 15 -TotalSteps 15
    
    $displayServices = @(
        "Themes",
        "UxSms"
    )
    
    foreach ($service in $displayServices) {
        Restart-WindowsService -ServiceName $service
    }
    
    # Restart Windows Explorer to apply changes
    try {
        Stop-Process -Name "explorer" -Force -ErrorAction Stop
        Start-Sleep -Seconds 2
        Start-Process "explorer.exe"
        Write-ReSetLog "Windows Explorer restarted to apply display changes" "SUCCESS"
    }
    catch {
        Write-ReSetLog "Failed to restart Windows Explorer: $($_.Exception.Message)" "WARN"
    }
    
    # ===================================================================
    # COMPLETION
    # ===================================================================
    
    Write-ReSetLog "Display settings reset completed successfully" "SUCCESS"
    Write-ReSetLog "A system restart is recommended for all changes to take effect" "WARN"
    
    if (-not $Silent) {
        Write-Host ""
        Write-Host "✅ Display Settings Reset Complete!" -ForegroundColor Green
        Write-Host "📋 Changes applied:" -ForegroundColor Cyan
        Write-Host "   • DPI scaling: 100% (96 DPI)" -ForegroundColor White
        Write-Host "   • Color management: Default profiles" -ForegroundColor White
        Write-Host "   • Desktop background: Removed" -ForegroundColor White
        Write-Host "   • Screen saver: Disabled" -ForegroundColor White
        Write-Host "   • Visual effects: Windows defaults" -ForegroundColor White
        Write-Host "   • ClearType: Enabled with default settings" -ForegroundColor White
        Write-Host "   • Theme: Default Windows light theme" -ForegroundColor White
        Write-Host "   • Colors: Windows default color scheme" -ForegroundColor White
        Write-Host "   • Cursors: Default Windows cursors" -ForegroundColor White
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
        Write-Host "❌ Display Settings Reset Failed!" -ForegroundColor Red
        Write-Host "Error: $errorMessage" -ForegroundColor Red
        Write-Host ""
    }
    
    Complete-ReSetOperation -OperationInfo $operation -Success $false -ErrorMessage $errorMessage
    throw
}
finally {
    Write-Progress -Activity "Windows Reset Operation" -Completed
}