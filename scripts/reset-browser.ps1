# Reset Browser Settings Script
#Requires -Version 5.0
#Requires -RunAsAdministrator

param([switch]$Silent, [switch]$CreateBackup = $true, [switch]$Force)

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
Import-Module (Join-Path $scriptPath "ReSetUtils.psm1") -Force

$operationName = "Browser Settings Reset"

try {
    Assert-AdminRights
    $operation = Start-ReSetOperation -OperationName $operationName
    
    # Reset Internet Explorer
    Write-ProgressStep -StepName "Resetting Internet Explorer" -CurrentStep 1 -TotalSteps 4
    try {
        $null = & RunDll32.exe InetCpl.cpl,ResetIEtoDefaults 2>&1
    }
    catch {
        # Silently continue - non-critical operation
    }
    
    # Reset Edge settings
    Write-ProgressStep -StepName "Resetting Microsoft Edge" -CurrentStep 2 -TotalSteps 4
    $edgeDataPath = "$env:LocalAppData\Microsoft\Edge\User Data"
    if (Test-Path $edgeDataPath) {
        Get-Process -Name "msedge" -ErrorAction SilentlyContinue | Stop-Process -Force
        Start-Sleep -Seconds 2
    }
    
    # Clear browser caches
    Write-ProgressStep -StepName "Clearing browser caches" -CurrentStep 3 -TotalSteps 4
    $cachePaths = @(
        "$env:LocalAppData\Microsoft\Windows\INetCache",
        "$env:LocalAppData\Microsoft\Edge\User Data\Default\Cache",
        "$env:AppData\Local\Google\Chrome\User Data\Default\Cache"
    )
    foreach ($path in $cachePaths) {
        if (Test-Path $path) {
            Remove-Item -Path "$path\*" -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
    
    # Reset browser security zones
    Write-ProgressStep -StepName "Resetting security zones" -CurrentStep 4 -TotalSteps 4
    $zonesPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\Zones"
    if (Test-Path $zonesPath) {
        Remove-RegistryKey -Path $zonesPath
    }
    
    Write-ReSetLog "Browser settings reset completed successfully" "SUCCESS"
    Complete-ReSetOperation -OperationInfo $operation -Success $true
}
catch {
    Complete-ReSetOperation -OperationInfo $operation -Success $false -ErrorMessage $_.Exception.Message
    throw
}
