# ===================================================================
# Reset File Associations Script
# File: reset-file-associations.ps1
# Author: jomardyan
# Description: Resets file type associations to Windows defaults
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

$operationName = "File Associations Reset"

try {
    Assert-AdminRights
    $operation = Start-ReSetOperation -OperationName $operationName
    
    # Export and reset default app associations
    Write-ProgressStep -StepName "Resetting default app associations" -CurrentStep 1 -TotalSteps 8
    try {
        $tempAssoc = "$env:TEMP\DefaultAssoc.xml"
        $null = & dism /online /export-defaultappassociations:$tempAssoc 2>&1
        $null = & dism /online /import-defaultappassociations:$tempAssoc 2>&1
        Remove-Item -Path $tempAssoc -Force -ErrorAction SilentlyContinue
    } catch {
                # Silently continue - non-critical operation
            }
    
    # Reset common file extensions
    Write-ProgressStep -StepName "Resetting common file extensions" -CurrentStep 2 -TotalSteps 8
    $extensions = @{
        ".txt" = "txtfile"
        ".jpg" = "jpegfile"
        ".png" = "pngfile"
        ".pdf" = "AcroExch.Document"
        ".html" = "htmlfile"
        ".mp3" = "WMP11.AssocFile.MP3"
        ".mp4" = "WMP11.AssocFile.MP4"
        ".docx" = "Word.Document.12"
        ".xlsx" = "Excel.Sheet.12"
    }
    
    foreach ($ext in $extensions.GetEnumerator()) {
        try {
            $null = & assoc $ext.Key=$ext.Value 2>&1
        } catch {
                # Silently continue - non-critical operation
            }
    }
    
    # Reset protocol associations
    Write-ProgressStep -StepName "Resetting protocol associations" -CurrentStep 3 -TotalSteps 8
    $protocols = @{
        "http" = "htmlfile"
        "https" = "htmlfile"
        "ftp" = "htmlfile"
        "mailto" = "Outlook.URL.mailto"
    }
    
    foreach ($protocol in $protocols.GetEnumerator()) {
        $protocolPath = "HKCR:\$($protocol.Key)"
        Set-RegistryValue -Path $protocolPath -Name "(Default)" -Value $protocol.Value -Type String
    }
    
    # Clear user choice associations
    Write-ProgressStep -StepName "Clearing user choice associations" -CurrentStep 4 -TotalSteps 8
    $userChoicePath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FileExts"
    if (Test-Path $userChoicePath) {
        Get-ChildItem -Path $userChoicePath | ForEach-Object {
            $ucPath = Join-Path $_.PSPath "UserChoice"
            if (Test-Path $ucPath) {
                Remove-RegistryKey -Path $ucPath
            }
        }
    }
    
    # Reset Open With associations
    Write-ProgressStep -StepName "Resetting Open With associations" -CurrentStep 5 -TotalSteps 8
    $openWithPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FileExts"
    if (Test-Path $openWithPath) {
        Get-ChildItem -Path $openWithPath | ForEach-Object {
            $owPath = Join-Path $_.PSPath "OpenWithList"
            if (Test-Path $owPath) {
                Remove-RegistryKey -Path $owPath
            }
        }
    }
    
    # Reset default programs
    Write-ProgressStep -StepName "Resetting default programs" -CurrentStep 6 -TotalSteps 8
    $defaultPrograms = "HKCU:\SOFTWARE\Microsoft\Windows\Shell\Associations\UrlAssociations"
    if (Test-Path $defaultPrograms) {
        Remove-RegistryKey -Path $defaultPrograms
    }
    
    # Reset file type associations cache
    Write-ProgressStep -StepName "Clearing association cache" -CurrentStep 7 -TotalSteps 8
    $cachePath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FileAssociation"
    if (Test-Path $cachePath) {
        Remove-RegistryKey -Path $cachePath
    }
    
    # Refresh shell
    Write-ProgressStep -StepName "Refreshing shell associations" -CurrentStep 8 -TotalSteps 8
    try {
        $null = & sfc /scannow 2>&1
    } catch {
                # Silently continue - non-critical operation
            }
    
    # Notify shell of changes
    Add-Type -TypeDefinition @"
        using System;
        using System.Runtime.InteropServices;
        public class Shell32 {
            [DllImport("shell32.dll")]
            public static extern void SHChangeNotify(uint wEventId, uint uFlags, IntPtr dwItem1, IntPtr dwItem2);
        }
"@
    [Shell32]::SHChangeNotify(0x08000000, 0x0000, [IntPtr]::Zero, [IntPtr]::Zero)
    
    Write-ReSetLog "File associations reset completed successfully" "SUCCESS"
    Complete-ReSetOperation -OperationInfo $operation -Success $true
}
catch {
    Complete-ReSetOperation -OperationInfo $operation -Success $false -ErrorMessage $_.Exception.Message
    throw
}
