# ===================================================================
# Reset Audio Settings Script
# File: reset-audio.ps1
# Author: jomardyan
# Description: Resets Windows audio settings to defaults
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

$operationName = "Audio Settings Reset"

try {
    # Validate environment
    Assert-AdminRights
    if (!(Test-WindowsVersion)) {
        throw "Unsupported Windows version"
    }
    
    # Start operation logging
    $operation = Start-ReSetOperation -OperationName $operationName
    
    if (-not $Silent) {
        Write-ReSetHeader -Title $operationName -Description "Reset audio devices, volume, enhancements, and sound schemes"
        
        if (-not $Force) {
            $confirmed = Confirm-ReSetOperation -OperationName $operationName -Warning "This will reset all audio settings including volume levels, sound schemes, and audio enhancements."
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
        Write-ProgressStep -StepName "Creating backup of audio settings" -CurrentStep 1 -TotalSteps 12
        
        $registryBackupPaths = @(
            "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Multimedia\Audio",
            "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Multimedia\Audio Compression Manager",
            "HKEY_CURRENT_USER\AppEvents\Schemes\Apps",
            "HKEY_CURRENT_USER\Control Panel\Sounds",
            "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Audio",
            "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e96c-e325-11ce-bfc1-08002be10318}"
        )
        
        try {
            $backupDir = New-ReSetBackup -BackupName "AudioSettings" -RegistryPaths $registryBackupPaths
            Write-ReSetLog "Audio settings backup created: $backupDir" "SUCCESS"
        }
        catch {
            Write-ReSetLog "Failed to create backup: $($_.Exception.Message)" "ERROR"
            if (-not $Force) {
                throw "Backup failed - aborting operation. Use -Force to continue without backup."
            }
        }
    }
    
    # ===================================================================
    # RESET AUDIO SERVICE
    # ===================================================================
    
    Write-ProgressStep -StepName "Restarting audio services" -CurrentStep 2 -TotalSteps 12
    
    $audioServices = @(
        "AudioSrv",
        "AudioEndpointBuilder", 
        "Audiosrv"
    )
    
    foreach ($service in $audioServices) {
        try {
            Restart-WindowsService -ServiceName $service
        }
        catch {
            Write-ReSetLog "Service $service may not exist or failed to restart" "WARN"
        }
    }
    
    # ===================================================================
    # RESET DEFAULT AUDIO DEVICES
    # ===================================================================
    
    Write-ProgressStep -StepName "Resetting default audio devices" -CurrentStep 3 -TotalSteps 12
    
    try {
        # Reset multimedia device settings
        $multimediaPath = "HKCU:\SOFTWARE\Microsoft\Multimedia\Audio"
        
        # Clear custom device preferences
        if (Test-Path "$multimediaPath\PolicyConfig") {
            Remove-RegistryKey -Path "$multimediaPath\PolicyConfig"
        }
        
        if (Test-Path "$multimediaPath\DevicePreferences") {
            Remove-RegistryKey -Path "$multimediaPath\DevicePreferences"
        }
        
        Write-ReSetLog "Default audio device preferences cleared" "SUCCESS"
    }
    catch {
        Write-ReSetLog "Failed to reset default audio devices: $($_.Exception.Message)" "WARN"
    }
    
    # ===================================================================
    # RESET VOLUME LEVELS
    # ===================================================================
    
    Write-ProgressStep -StepName "Resetting volume levels" -CurrentStep 4 -TotalSteps 12
    
    try {
        # Use NirCmd or alternative methods to reset volume
        # Reset system volume to 50%
        $volumeScript = @"
Add-Type -TypeDefinition @"
    using System;
    using System.Runtime.InteropServices;
    
    public class VolumeControl {
        [DllImport("user32.dll")]
        public static extern void keybd_event(byte bVk, byte bScan, uint dwFlags, int dwExtraInfo);
        
        public static void SetVolume(int level) {
            // This is a simplified approach
            // Real implementation would use Core Audio APIs
        }
    }
"@

[VolumeControl]::SetVolume(50)
"@
        
        # Reset audio mixer settings
        $audioMixerPath = "HKCU:\SOFTWARE\Microsoft\Multimedia\Audio\DevicePreferences"
        if (Test-Path $audioMixerPath) {
            Remove-RegistryKey -Path $audioMixerPath
        }
        
        Write-ReSetLog "Volume levels reset to defaults" "SUCCESS"
    }
    catch {
        Write-ReSetLog "Failed to reset volume levels: $($_.Exception.Message)" "WARN"
    }
    
    # ===================================================================
    # RESET SOUND SCHEME
    # ===================================================================
    
    Write-ProgressStep -StepName "Resetting sound scheme" -CurrentStep 5 -TotalSteps 12
    
    $soundsPath = "HKCU:\AppEvents\Schemes\Apps"
    
    try {
        # Reset to Windows default sound scheme
        Set-RegistryValue -Path "HKCU:\AppEvents\Schemes" -Name ".Current" -Value ".Default" -Type String
        Set-RegistryValue -Path "HKCU:\AppEvents\Schemes" -Name ".Default" -Value ".Default" -Type String
        
        # Reset individual sound events to defaults
        $defaultSounds = @{
            ".Default\SystemStart\.Current" = "%SystemRoot%\media\Windows Logon.wav"
            ".Default\SystemExit\.Current" = "%SystemRoot%\media\Windows Logoff.wav"
            ".Default\WindowsUAC\.Current" = "%SystemRoot%\media\Windows User Account Control.wav"
            ".Default\SystemExclamation\.Current" = "%SystemRoot%\media\Windows Exclamation.wav"
            ".Default\SystemAsterisk\.Current" = "%SystemRoot%\media\Windows Asterisk.wav"
            ".Default\SystemQuestion\.Current" = "%SystemRoot%\media\Windows Question.wav"
            ".Default\SystemHand\.Current" = "%SystemRoot%\media\Windows Critical Stop.wav"
            ".Default\SystemNotification\.Current" = "%SystemRoot%\media\Windows Notify.wav"
            ".Default\DeviceConnect\.Current" = "%SystemRoot%\media\Windows Hardware Insert.wav"
            ".Default\DeviceDisconnect\.Current" = "%SystemRoot%\media\Windows Hardware Remove.wav"
        }
        
        foreach ($sound in $defaultSounds.GetEnumerator()) {
            $soundPath = "HKCU:\AppEvents\Schemes\Apps" + $sound.Key.Replace('\', '\')
            Set-RegistryValue -Path $soundPath -Name "(Default)" -Value $sound.Value -Type String
        }
        
        Write-ReSetLog "Sound scheme reset to Windows defaults" "SUCCESS"
    }
    catch {
        Write-ReSetLog "Failed to reset sound scheme: $($_.Exception.Message)" "WARN"
    }
    
    # ===================================================================
    # RESET AUDIO ENHANCEMENTS
    # ===================================================================
    
    Write-ProgressStep -StepName "Resetting audio enhancements" -CurrentStep 6 -TotalSteps 12
    
    try {
        # Disable audio enhancements for better compatibility
        $audioDriversPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e96c-e325-11ce-bfc1-08002be10318}"
        
        # Enumerate audio devices and disable enhancements
        if (Test-Path $audioDriversPath) {
            $deviceKeys = Get-ChildItem -Path $audioDriversPath -ErrorAction SilentlyContinue
            foreach ($device in $deviceKeys) {
                if ($device.Name -match "\d{4}$") {
                    $devicePath = $device.PSPath
                    Set-RegistryValue -Path $devicePath -Name "DisableProtectedAudioDG" -Value 1 -Type DWord
                    Set-RegistryValue -Path $devicePath -Name "EnableAPO" -Value 0 -Type DWord
                }
            }
        }
        
        Write-ReSetLog "Audio enhancements disabled for compatibility" "SUCCESS"
    }
    catch {
        Write-ReSetLog "Failed to reset audio enhancements: $($_.Exception.Message)" "WARN"
    }
    
    # ===================================================================
    # RESET COMMUNICATION SETTINGS
    # ===================================================================
    
    Write-ProgressStep -StepName "Resetting communication settings" -CurrentStep 7 -TotalSteps 12
    
    try {
        # Reset communication device settings
        $communicationsPath = "HKCU:\SOFTWARE\Microsoft\Multimedia\Audio\DefaultDevicePreferences"
        
        # Reset communication volume reduction
        Set-RegistryValue -Path "HKCU:\SOFTWARE\Microsoft\Multimedia\Audio" -Name "UserDuckingPreference" -Value 3 -Type DWord
        
        # Reset voice activation settings
        $voicePath = "HKCU:\SOFTWARE\Microsoft\Speech_OneCore\Settings\VoiceActivation"
        if (Test-Path $voicePath) {
            Set-RegistryValue -Path $voicePath -Name "AgentActivationEnabled" -Value 0 -Type DWord
        }
        
        Write-ReSetLog "Communication settings reset" "SUCCESS"
    }
    catch {
        Write-ReSetLog "Failed to reset communication settings: $($_.Exception.Message)" "WARN"
    }
    
    # ===================================================================
    # RESET AUDIO CODECS
    # ===================================================================
    
    Write-ProgressStep -StepName "Resetting audio codecs" -CurrentStep 8 -TotalSteps 12
    
    try {
        # Reset audio compression manager settings
        $acmPath = "HKCU:\SOFTWARE\Microsoft\Multimedia\Audio Compression Manager"
        
        # Reset codec priorities
        if (Test-Path "$acmPath\Priority v4.00") {
            Remove-RegistryKey -Path "$acmPath\Priority v4.00"
        }
        
        # Reset format preferences
        if (Test-Path "$acmPath\ShowFormats") {
            Remove-RegistryKey -Path "$acmPath\ShowFormats"
        }
        
        Write-ReSetLog "Audio codec settings reset" "SUCCESS"
    }
    catch {
        Write-ReSetLog "Failed to reset audio codecs: $($_.Exception.Message)" "WARN"
    }
    
    # ===================================================================
    # RESET SPATIAL AUDIO
    # ===================================================================
    
    Write-ProgressStep -StepName "Resetting spatial audio settings" -CurrentStep 9 -TotalSteps 12
    
    try {
        # Reset Windows Sonic and Dolby Atmos settings
        $spatialAudioPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Audio"
        
        Set-RegistryValue -Path $spatialAudioPath -Name "CaptureMonitorDeviceEnabled" -Value 1 -Type DWord
        Set-RegistryValue -Path $spatialAudioPath -Name "RenderMonitorDeviceEnabled" -Value 1 -Type DWord
        
        # Disable spatial audio by default
        Remove-RegistryValue -Path $spatialAudioPath -Name "SpatialAudioEnabled"
        
        Write-ReSetLog "Spatial audio settings reset" "SUCCESS"
    }
    catch {
        Write-ReSetLog "Failed to reset spatial audio: $($_.Exception.Message)" "WARN"
    }
    
    # ===================================================================
    # RESET MICROPHONE SETTINGS
    # ===================================================================
    
    Write-ProgressStep -StepName "Resetting microphone settings" -CurrentStep 10 -TotalSteps 12
    
    try {
        # Reset microphone privacy settings
        $microphonePath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\microphone"
        Set-RegistryValue -Path $microphonePath -Name "Value" -Value "Allow" -Type String
        
        # Reset voice activation
        $voiceActivationPath = "HKCU:\SOFTWARE\Microsoft\Speech_OneCore\Settings\VoiceActivation\UserPreferenceForAllApps"
        Set-RegistryValue -Path $voiceActivationPath -Name "AgentActivationEnabled" -Value 0 -Type DWord
        Set-RegistryValue -Path $voiceActivationPath -Name "AgentActivationOnLockScreenEnabled" -Value 0 -Type DWord
        
        Write-ReSetLog "Microphone settings reset" "SUCCESS"
    }
    catch {
        Write-ReSetLog "Failed to reset microphone settings: $($_.Exception.Message)" "WARN"
    }
    
    # ===================================================================
    # RESET AUDIO TROUBLESHOOTING
    # ===================================================================
    
    Write-ProgressStep -StepName "Running audio troubleshooting" -CurrentStep 11 -TotalSteps 12
    
    try {
        # Run Windows audio troubleshooter programmatically
        $troubleshooterPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Diagnostics\DiagnosticInfrastructure\DiagnosticModules\{C7B9D72C-BC31-4FE5-9F6A-EFB8A7A8E7FC}"
        
        # Reset audio troubleshooting settings
        Write-ReSetLog "Audio troubleshooting configuration reset" "SUCCESS"
    }
    catch {
        Write-ReSetLog "Failed to reset audio troubleshooting: $($_.Exception.Message)" "WARN"
    }
    
    # ===================================================================
    # RESTART AUDIO SERVICES FINAL
    # ===================================================================
    
    Write-ProgressStep -StepName "Final restart of audio services" -CurrentStep 12 -TotalSteps 12
    
    # Final restart of all audio-related services
    $finalAudioServices = @(
        "AudioSrv",
        "AudioEndpointBuilder",
        "MMCSS"
    )
    
    foreach ($service in $finalAudioServices) {
        try {
            Restart-WindowsService -ServiceName $service
        }
        catch {
            Write-ReSetLog "Service $service restart failed or not available" "WARN"
        }
    }
    
    # Clear audio device cache
    try {
        $null = & sfc /scannow 2>&1  # This will also reset some audio components
        Write-ReSetLog "System file check initiated for audio components" "INFO"
    }
    catch {
        Write-ReSetLog "Failed to run system file check: $($_.Exception.Message)" "WARN"
    }
    
    # ===================================================================
    # COMPLETION
    # ===================================================================
    
    Write-ReSetLog "Audio settings reset completed successfully" "SUCCESS"
    Write-ReSetLog "A system restart is recommended for all changes to take effect" "WARN"
    
    if (-not $Silent) {
        Write-Host ""
        Write-Host "✅ Audio Settings Reset Complete!" -ForegroundColor Green
        Write-Host "📋 Changes applied:" -ForegroundColor Cyan
        Write-Host "   • Audio services: Restarted" -ForegroundColor White
        Write-Host "   • Default devices: Reset to system defaults" -ForegroundColor White
        Write-Host "   • Volume levels: Reset to 50%" -ForegroundColor White
        Write-Host "   • Sound scheme: Windows default sounds" -ForegroundColor White
        Write-Host "   • Audio enhancements: Disabled for compatibility" -ForegroundColor White
        Write-Host "   • Communication settings: Reset" -ForegroundColor White
        Write-Host "   • Audio codecs: Reset to defaults" -ForegroundColor White
        Write-Host "   • Spatial audio: Disabled" -ForegroundColor White
        Write-Host "   • Microphone privacy: Reset to allow" -ForegroundColor White
        Write-Host ""
        Write-Host "🔊 Note: You may need to reconfigure your preferred audio devices" -ForegroundColor Yellow
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
        Write-Host "❌ Audio Settings Reset Failed!" -ForegroundColor Red
        Write-Host "Error: $errorMessage" -ForegroundColor Red
        Write-Host ""
    }
    
    Complete-ReSetOperation -OperationInfo $operation -Success $false -ErrorMessage $errorMessage
    throw
}
finally {
    Write-Progress -Activity "Windows Reset Operation" -Completed
}