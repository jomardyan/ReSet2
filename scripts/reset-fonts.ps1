# ===================================================================
# Reset Fonts Script
# File: reset-fonts.ps1
# Author: jomardyan
# Description: Resets font settings and ClearType configuration
# Version: 1.0.0
# ===================================================================

#Requires -Version 5.0
#Requires -RunAsAdministrator

param(
    [switch]$Silent,
    [switch]$CreateBackup = $true,
    [switch]$Force
)

# Import utility module
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
Import-Module (Join-Path $scriptPath "ReSetUtils.psm1") -Force

$operationName = "Fonts and Text Settings Reset"

try {
    Assert-AdminRights
    $operation = Start-ReSetOperation -OperationName $operationName
    
    # Reset ClearType settings
    Write-ProgressStep -StepName "Resetting ClearType settings" -CurrentStep 1 -TotalSteps 10
    $desktopPath = "HKCU:\Control Panel\Desktop"
    Set-RegistryValue -Path $desktopPath -Name "FontSmoothing" -Value "2" -Type String
    Set-RegistryValue -Path $desktopPath -Name "FontSmoothingType" -Value 2 -Type DWord
    Set-RegistryValue -Path $desktopPath -Name "FontSmoothingGamma" -Value 1400 -Type DWord
    Set-RegistryValue -Path $desktopPath -Name "FontSmoothingOrientation" -Value 1 -Type DWord
    
    # Reset system fonts
    Write-ProgressStep -StepName "Resetting system fonts" -CurrentStep 2 -TotalSteps 10
    $metricsPath = "HKCU:\Control Panel\Desktop\WindowMetrics"
    $defaultFonts = @{
        "CaptionFont" = ([byte[]](0xF4, 0xFF, 0xFF, 0xFF, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x90, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x53, 0x00, 0x65, 0x00, 0x67, 0x00, 0x6F, 0x00, 0x65, 0x00, 0x20, 0x00, 0x55, 0x00, 0x49, 0x00))
        "SmCaptionFont" = ([byte[]](0xF4, 0xFF, 0xFF, 0xFF, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x90, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x53, 0x00, 0x65, 0x00, 0x67, 0x00, 0x6F, 0x00, 0x65, 0x00, 0x20, 0x00, 0x55, 0x00, 0x49, 0x00))
        "MenuFont" = ([byte[]](0xF4, 0xFF, 0xFF, 0xFF, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x90, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x53, 0x00, 0x65, 0x00, 0x67, 0x00, 0x6F, 0x00, 0x65, 0x00, 0x20, 0x00, 0x55, 0x00, 0x49, 0x00))
        "StatusFont" = ([byte[]](0xF4, 0xFF, 0xFF, 0xFF, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x90, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x53, 0x00, 0x65, 0x00, 0x67, 0x00, 0x6F, 0x00, 0x65, 0x00, 0x20, 0x00, 0x55, 0x00, 0x49, 0x00))
        "MessageFont" = ([byte[]](0xF4, 0xFF, 0xFF, 0xFF, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x90, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x53, 0x00, 0x65, 0x00, 0x67, 0x00, 0x6F, 0x00, 0x65, 0x00, 0x20, 0x00, 0x55, 0x00, 0x49, 0x00))\n    }\n    \n    foreach ($font in $defaultFonts.GetEnumerator()) {\n        Set-RegistryValue -Path $metricsPath -Name $font.Key -Value $font.Value -Type Binary\n    }\n    \n    # Reset text scaling\n    Write-ProgressStep -StepName \"Resetting text scaling\" -CurrentStep 3 -TotalSteps 10\n    Set-RegistryValue -Path $desktopPath -Name \"LogPixels\" -Value 96 -Type DWord\n    Set-RegistryValue -Path $desktopPath -Name \"Win8DpiScaling\" -Value 1 -Type DWord\n    \n    # Clear font cache\n    Write-ProgressStep -StepName \"Clearing font cache\" -CurrentStep 4 -TotalSteps 10\n    $fontCachePath = \"$env:SystemRoot\\ServiceProfiles\\LocalService\\AppData\\Local\\FontCache\"\n    if (Test-Path $fontCachePath) {\n        Stop-Service -Name \"FontCache\" -Force -ErrorAction SilentlyContinue\n        Remove-Item -Path \"$fontCachePath\\*\" -Recurse -Force -ErrorAction SilentlyContinue\n        Start-Service -Name \"FontCache\" -ErrorAction SilentlyContinue\n    }\n    \n    # Reset console fonts\n    Write-ProgressStep -StepName \"Resetting console fonts\" -CurrentStep 5 -TotalSteps 10\n    $consolePath = \"HKCU:\\Console\"\n    Set-RegistryValue -Path $consolePath -Name \"FaceName\" -Value \"Consolas\" -Type String\n    Set-RegistryValue -Path $consolePath -Name \"FontFamily\" -Value 54 -Type DWord\n    Set-RegistryValue -Path $consolePath -Name \"FontSize\" -Value 1048576 -Type DWord\n    Set-RegistryValue -Path $consolePath -Name \"FontWeight\" -Value 400 -Type DWord\n    \n    # Reset PowerShell console fonts\n    Write-ProgressStep -StepName \"Resetting PowerShell fonts\" -CurrentStep 6 -TotalSteps 10\n    $psConsolePath = \"HKCU:\\Console\\%SystemRoot%_System32_WindowsPowerShell_v1.0_powershell.exe\"\n    Set-RegistryValue -Path $psConsolePath -Name \"FaceName\" -Value \"Consolas\" -Type String\n    Set-RegistryValue -Path $psConsolePath -Name \"FontFamily\" -Value 54 -Type DWord\n    \n    # Reset Internet Explorer fonts\n    Write-ProgressStep -StepName \"Resetting browser fonts\" -CurrentStep 7 -TotalSteps 10\n    $ieFontsPath = \"HKCU:\\SOFTWARE\\Microsoft\\Internet Explorer\\International\\Scripts\\3\"\n    Set-RegistryValue -Path $ieFontsPath -Name \"IEFixedFontName\" -Value \"Courier New\" -Type String\n    Set-RegistryValue -Path $ieFontsPath -Name \"IEPropFontName\" -Value \"Times New Roman\" -Type String\n    \n    # Reset Office fonts (if installed)\n    Write-ProgressStep -StepName \"Resetting Office fonts\" -CurrentStep 8 -TotalSteps 10\n    $officePath = \"HKCU:\\SOFTWARE\\Microsoft\\Office\"\n    if (Test-Path $officePath) {\n        # Reset default Office fonts to Calibri/Calibri Light\n        $officeVersions = Get-ChildItem -Path $officePath -ErrorAction SilentlyContinue\n        foreach ($version in $officeVersions) {\n            $commonPath = Join-Path $version.PSPath \"Common\\Font\"\n            if (Test-Path $commonPath) {\n                Set-RegistryValue -Path $commonPath -Name \"Theme Font\" -Value \"Calibri\" -Type String\n            }\n        }\n    }\n    \n    # Reset Windows font substitution\n    Write-ProgressStep -StepName \"Resetting font substitution\" -CurrentStep 9 -TotalSteps 10\n    $substitutePath = \"HKLM:\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\FontSubstitutes\"\n    # Clear custom font substitutions except system defaults\n    if (Test-Path $substitutePath) {\n        $defaultSubstitutes = @(\"Arial\", \"Courier New\", \"Times New Roman\", \"Symbol\", \"Wingdings\")\n        $items = Get-ItemProperty -Path $substitutePath -ErrorAction SilentlyContinue\n        if ($items) {\n            $items.PSObject.Properties | Where-Object { $_.Name -notmatch \"PS\" -and $_.Name -notin $defaultSubstitutes } | ForEach-Object {\n                Remove-RegistryValue -Path $substitutePath -Name $_.Name\n            }\n        }\n    }\n    \n    # Restart font-related services\n    Write-ProgressStep -StepName \"Restarting font services\" -CurrentStep 10 -TotalSteps 10\n    $fontServices = @(\"FontCache\", \"Themes\")\n    foreach ($service in $fontServices) {\n        Restart-WindowsService -ServiceName $service\n    }\n    \n    Write-ReSetLog \"Fonts and text settings reset completed successfully\" \"SUCCESS\"\n    Complete-ReSetOperation -OperationInfo $operation -Success $true\n}\ncatch {\n    Complete-ReSetOperation -OperationInfo $operation -Success $false -ErrorMessage $_.Exception.Message\n    throw\n}