# ===================================================================
# Reset UAC Settings Script
# File: reset-uac.ps1
# Author: jomardyan
# Description: Resets User Account Control settings to defaults
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

$operationName = "UAC Settings Reset"

try {
    Assert-AdminRights
    if (!(Test-WindowsVersion)) { throw "Unsupported Windows version" }
    
    $operation = Start-ReSetOperation -OperationName $operationName
    
    if (-not $Silent) {
        Write-ReSetHeader -Title $operationName -Description "Reset User Account Control to default security settings"
        if (-not $Force) {
            $confirmed = Confirm-ReSetOperation -OperationName $operationName -Warning "This will reset UAC settings to Windows defaults."
            if (-not $confirmed) { Write-ReSetLog "Operation cancelled by user" "WARN"; return }
        }
    }
    
    # Backup UAC settings
    if ($CreateBackup) {
        Write-ProgressStep -StepName "Creating UAC backup" -CurrentStep 1 -TotalSteps 8
        $registryBackupPaths = @(
            "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
        )
        try {
            $backupDir = New-ReSetBackup -BackupName "UACSettings" -RegistryPaths $registryBackupPaths
        } catch {
            if (-not $Force) { throw "Backup failed" }
        }
    }
    
    # Reset UAC registry settings
    Write-ProgressStep -StepName "Resetting UAC registry settings" -CurrentStep 2 -TotalSteps 8
    $uacPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
    
    # Default UAC settings for Windows 10/11
    Set-RegistryValue -Path $uacPath -Name "ConsentPromptBehaviorAdmin" -Value 5 -Type DWord  # Prompt for consent for non-Windows binaries
    Set-RegistryValue -Path $uacPath -Name "ConsentPromptBehaviorUser" -Value 3 -Type DWord   # Prompt for credentials
    Set-RegistryValue -Path $uacPath -Name "EnableInstallerDetection" -Value 1 -Type DWord   # Detect application installations
    Set-RegistryValue -Path $uacPath -Name "EnableLUA" -Value 1 -Type DWord                  # Enable Limited User Account
    Set-RegistryValue -Path $uacPath -Name "EnableSecureUIAPaths" -Value 1 -Type DWord       # Only elevate UIAccess applications
    Set-RegistryValue -Path $uacPath -Name "EnableUIADesktopToggle" -Value 0 -Type DWord     # Disable desktop toggle
    Set-RegistryValue -Path $uacPath -Name "EnableVirtualization" -Value 1 -Type DWord       # Enable file and registry virtualization
    Set-RegistryValue -Path $uacPath -Name "PromptOnSecureDesktop" -Value 1 -Type DWord      # Switch to secure desktop
    
    Write-ReSetLog "UAC registry settings reset to defaults" "SUCCESS"
    
    # Remove UAC policy overrides
    Write-ProgressStep -StepName "Removing UAC policy overrides" -CurrentStep 3 -TotalSteps 8
    $policyPaths = @(
        "HKLM:\SOFTWARE\Policies\Microsoft\Windows\safer",
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\CredUI"
    )
    
    foreach ($path in $policyPaths) {
        if (Test-Path $path) {
            Remove-RegistryKey -Path $path
        }
    }
    
    # Reset UAC file/folder virtualization
    Write-ProgressStep -StepName "Resetting UAC virtualization" -CurrentStep 4 -TotalSteps 8
    $virtPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\Audit"
    Remove-RegistryKey -Path $virtPath
    
    # Reset elevation settings
    Write-ProgressStep -StepName "Resetting elevation settings" -CurrentStep 5 -TotalSteps 8
    $elevationPath = "HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers"
    if (Test-Path $elevationPath) {
        # Remove any application-specific elevation settings
        $apps = Get-ItemProperty -Path $elevationPath -ErrorAction SilentlyContinue
        if ($apps) {
            $apps.PSObject.Properties | Where-Object { $_.Name -notmatch "PS" } | ForEach-Object {
                if ($_.Value -match "RUNASADMIN") {
                    Remove-RegistryValue -Path $elevationPath -Name $_.Name
                }
            }
        }
    }
    
    # Reset UAC notification settings
    Write-ProgressStep -StepName "Resetting UAC notifications" -CurrentStep 6 -TotalSteps 8
    $notificationPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\UserAccountControl"
    Set-RegistryValue -Path $notificationPath -Name "Settings" -Value 1 -Type DWord
    
    # Reset admin approval mode
    Write-ProgressStep -StepName "Resetting admin approval mode" -CurrentStep 7 -TotalSteps 8
    Set-RegistryValue -Path $uacPath -Name "FilterAdministratorToken" -Value 1 -Type DWord
    
    # Restart required services
    Write-ProgressStep -StepName "Restarting related services" -CurrentStep 8 -TotalSteps 8
    $services = @("AppIDSvc", "Appinfo")
    foreach ($service in $services) {
        Restart-WindowsService -ServiceName $service
    }
    
    Write-ReSetLog "UAC settings reset completed successfully" "SUCCESS"
    
    if (-not $Silent) {
        Write-Host ""
        Write-Host "✅ UAC Settings Reset Complete!" -ForegroundColor Green
        Write-Host "📋 Changes applied:" -ForegroundColor Cyan
        Write-Host "   • UAC level: Default (Notify me only when apps try to make changes)" -ForegroundColor White
        Write-Host "   • Admin approval mode: Enabled" -ForegroundColor White
        Write-Host "   • Secure desktop prompts: Enabled" -ForegroundColor White
        Write-Host "   • File/registry virtualization: Enabled" -ForegroundColor White
        Write-Host ""
        Write-Host "ℹ️  UAC changes take effect immediately" -ForegroundColor Cyan
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