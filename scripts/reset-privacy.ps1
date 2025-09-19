# ===================================================================
# Reset Privacy Settings Script
# File: reset-privacy.ps1
# Author: jomardyan
# Description: Resets Windows privacy settings to defaults
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

$operationName = "Privacy Settings Reset"

try {
    Assert-AdminRights
    if (!(Test-WindowsVersion)) { throw "Unsupported Windows version" }
    
    $operation = Start-ReSetOperation -OperationName $operationName
    
    if (-not $Silent) {
        Write-ReSetHeader -Title $operationName -Description "Reset privacy settings and app permissions"
        if (-not $Force) {
            $confirmed = Confirm-ReSetOperation -OperationName $operationName -Warning "This will reset privacy settings and app permissions to Windows defaults."
            if (-not $confirmed) { Write-ReSetLog "Operation cancelled by user" "WARN"; return }
        }
    }
    
    # Backup privacy settings
    if ($CreateBackup) {
        Write-ProgressStep -StepName "Creating privacy backup" -CurrentStep 1 -TotalSteps 15
        $registryBackupPaths = @(
            "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager",
            "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Privacy",
            "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager"
        )
        try {
            $backupDir = New-ReSetBackup -BackupName "PrivacySettings" -RegistryPaths $registryBackupPaths
        } catch {
            if (-not $Force) { throw "Backup failed" }
        }
    }
    
    # Reset app permissions
    Write-ProgressStep -StepName "Resetting app permissions" -CurrentStep 2 -TotalSteps 15
    $capabilityPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore"
    
    $capabilities = @{
        "location" = "Allow"
        "camera" = "Allow" 
        "microphone" = "Allow"
        "notifications" = "Allow"
        "contacts" = "Allow"
        "calendar" = "Allow"
        "phoneCall" = "Allow"
        "callHistory" = "Allow"
        "email" = "Allow"
        "tasks" = "Allow"
        "messaging" = "Allow"
        "radios" = "Allow"
        "bluetoothSync" = "Allow"
        "appDiagnostics" = "Allow"
        "documentsLibrary" = "Allow"
        "picturesLibrary" = "Allow"
        "videosLibrary" = "Allow"
        "musicLibrary" = "Allow"
        "broadFileSystemAccess" = "Allow"
    }
    
    foreach ($capability in $capabilities.GetEnumerator()) {
        Set-RegistryValue -Path "$capabilityPath\$($capability.Key)" -Name "Value" -Value $capability.Value -Type String
    }
    
    Write-ReSetLog "App permissions reset to allow access" "SUCCESS"
    
    # Reset location settings
    Write-ProgressStep -StepName "Resetting location settings" -CurrentStep 3 -TotalSteps 15
    $locationPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Privacy"
    Set-RegistryValue -Path $locationPath -Name "TailoredExperiencesWithDiagnosticDataEnabled" -Value 1 -Type DWord
    
    $systemLocationPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location"
    Set-RegistryValue -Path $systemLocationPath -Name "Value" -Value "Allow" -Type String
    
    # Reset advertising ID
    Write-ProgressStep -StepName "Resetting advertising ID" -CurrentStep 4 -TotalSteps 15
    $advertisingPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo"
    Set-RegistryValue -Path $advertisingPath -Name "Enabled" -Value 1 -Type DWord
    Remove-RegistryValue -Path $advertisingPath -Name "Id"
    
    # Reset speech, inking & typing
    Write-ProgressStep -StepName "Resetting speech and typing" -CurrentStep 5 -TotalSteps 15
    $speechPath = "HKCU:\SOFTWARE\Microsoft\Speech_OneCore\Settings\OnlineSpeechPrivacy"
    Set-RegistryValue -Path $speechPath -Name "HasAccepted" -Value 1 -Type DWord
    
    $inputPath = "HKCU:\SOFTWARE\Microsoft\InputPersonalization"
    Set-RegistryValue -Path $inputPath -Name "RestrictImplicitInkCollection" -Value 0 -Type DWord
    Set-RegistryValue -Path $inputPath -Name "RestrictImplicitTextCollection" -Value 0 -Type DWord
    
    # Reset diagnostics & feedback
    Write-ProgressStep -StepName "Resetting diagnostics settings" -CurrentStep 6 -TotalSteps 15
    $diagnosticsPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection"
    Set-RegistryValue -Path $diagnosticsPath -Name "AllowTelemetry" -Value 1 -Type DWord  # Basic telemetry
    
    $feedbackPath = "HKCU:\SOFTWARE\Microsoft\Siuf\Rules"
    Set-RegistryValue -Path $feedbackPath -Name "NumberOfSIUFInPeriod" -Value 0 -Type DWord
    
    # Reset activity history
    Write-ProgressStep -StepName "Resetting activity history" -CurrentStep 7 -TotalSteps 15
    $activityPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Privacy"
    Set-RegistryValue -Path $activityPath -Name "PublishUserActivities" -Value 1 -Type DWord
    Set-RegistryValue -Path $activityPath -Name "UploadUserActivities" -Value 1 -Type DWord
    
    # Reset voice activation
    Write-ProgressStep -StepName "Resetting voice activation" -CurrentStep 8 -TotalSteps 15
    $voicePath = "HKCU:\SOFTWARE\Microsoft\Speech_OneCore\Settings\VoiceActivation\UserPreferenceForAllApps"
    Set-RegistryValue -Path $voicePath -Name "AgentActivationEnabled" -Value 1 -Type DWord
    Set-RegistryValue -Path $voicePath -Name "AgentActivationOnLockScreenEnabled" -Value 0 -Type DWord
    
    # Reset background apps
    Write-ProgressStep -StepName "Resetting background apps" -CurrentStep 9 -TotalSteps 15
    $backgroundPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications"
    Set-RegistryValue -Path $backgroundPath -Name "GlobalUserDisabled" -Value 0 -Type DWord
    
    # Reset app diagnostics
    Write-ProgressStep -StepName "Resetting app diagnostics" -CurrentStep 10 -TotalSteps 15
    $appDiagPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Privacy"
    Set-RegistryValue -Path $appDiagPath -Name "EnableAppDiagnostics" -Value 1 -Type DWord
    
    # Reset Windows tips
    Write-ProgressStep -StepName "Resetting Windows tips" -CurrentStep 11 -TotalSteps 15
    $tipsPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
    Set-RegistryValue -Path $tipsPath -Name "SubscribedContent-338389Enabled" -Value 1 -Type DWord
    Set-RegistryValue -Path $tipsPath -Name "SoftLandingEnabled" -Value 1 -Type DWord
    
    # Reset suggested content
    Write-ProgressStep -StepName "Resetting suggested content" -CurrentStep 12 -TotalSteps 15
    Set-RegistryValue -Path $tipsPath -Name "ContentDeliveryAllowed" -Value 1 -Type DWord
    Set-RegistryValue -Path $tipsPath -Name "OemPreInstalledAppsEnabled" -Value 1 -Type DWord
    Set-RegistryValue -Path $tipsPath -Name "PreInstalledAppsEnabled" -Value 1 -Type DWord
    
    # Reset search permissions
    Write-ProgressStep -StepName "Resetting search permissions" -CurrentStep 13 -TotalSteps 15
    $searchPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\SearchSettings"
    Set-RegistryValue -Path $searchPath -Name "SafeSearchMode" -Value 1 -Type DWord
    Set-RegistryValue -Path $searchPath -Name "IsAADCloudSearchEnabled" -Value 1 -Type DWord
    
    # Reset cloud content search
    $cloudSearchPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search"
    Set-RegistryValue -Path $cloudSearchPath -Name "BingSearchEnabled" -Value 1 -Type DWord
    Set-RegistryValue -Path $cloudSearchPath -Name "AllowSearchToUseLocation" -Value 1 -Type DWord
    
    # Reset Microsoft account settings
    Write-ProgressStep -StepName "Resetting Microsoft account sync" -CurrentStep 14 -TotalSteps 15
    $accountPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\SettingSync"
    Set-RegistryValue -Path $accountPath -Name "SyncPolicy" -Value 5 -Type DWord  # Sync enabled
    
    # Reset Windows Error Reporting
    Write-ProgressStep -StepName "Resetting error reporting" -CurrentStep 15 -TotalSteps 15
    $errorPath = "HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting"
    Set-RegistryValue -Path $errorPath -Name "Disabled" -Value 0 -Type DWord
    
    $userErrorPath = "HKCU:\SOFTWARE\Microsoft\Windows\Windows Error Reporting"
    Set-RegistryValue -Path $userErrorPath -Name "DontSendAdditionalData" -Value 0 -Type DWord
    
    Write-ReSetLog "Privacy settings reset completed successfully" "SUCCESS"
    
    if (-not $Silent) {
        Write-Host ""
        Write-Host "✅ Privacy Settings Reset Complete!" -ForegroundColor Green
        Write-Host "📋 Changes applied:" -ForegroundColor Cyan
        Write-Host "   • App permissions: Reset to allow access" -ForegroundColor White
        Write-Host "   • Location services: Enabled" -ForegroundColor White
        Write-Host "   • Advertising ID: Reset and enabled" -ForegroundColor White
        Write-Host "   • Speech & typing: Enabled" -ForegroundColor White
        Write-Host "   • Diagnostics: Basic telemetry enabled" -ForegroundColor White
        Write-Host "   • Activity history: Enabled" -ForegroundColor White
        Write-Host "   • Background apps: Enabled" -ForegroundColor White
        Write-Host "   • Windows tips: Enabled" -ForegroundColor White
        Write-Host ""
        Write-Host "ℹ️  You can adjust these settings in Settings > Privacy & Security" -ForegroundColor Cyan
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